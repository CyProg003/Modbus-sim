with Modbus.RTU.CRC;

package body Modbus.RTU.Framer is

   use type Interfaces.Unsigned_8;

   --  Offset in a frame of the byte count of functions 0F and 10:
   --  address, function, start (2), quantity (2), byte count
   Byte_Count_Position : constant := 7;

   --  Longest data part that still fits in a PDU (253 - function code
   --  - start (2) - quantity (2) - byte count)
   Max_Byte_Count : constant := 247;

   function Is_Multiple_Write (FC : Byte) return Boolean is
     (FC = Code_Of (Write_Multiple_Coils)
      or else FC = Code_Of (Write_Multiple_Registers));

   --  Total length of the frame being received, or 0 while it cannot be
   --  known yet. Needs Count >= 2 and a known function code.
   function Expected_Length (F : State) return Natural;

   procedure Fail (F : in out State; Result : out Event);

   ---------------------
   -- Expected_Length --
   ---------------------

   function Expected_Length (F : State) return Natural is
   begin
      if F.Count < 2 then
         return 0;
      elsif Is_Multiple_Write (F.Buffer (2)) then
         if F.Count < Byte_Count_Position then
            return 0;
         else
            --  address, function, start (2), quantity (2), byte count,
            --  data, CRC (2)
            return 9 + Natural (F.Buffer (Byte_Count_Position));
         end if;
      else
         --  address, function, 4 data bytes, CRC (2)
         return 8;
      end if;
   end Expected_Length;

   ----------
   -- Fail --
   ----------

   procedure Fail (F : in out State; Result : out Event) is
   begin
      F.Mode := Discarding;
      Result := Frame_Bad;
   end Fail;

   -----------
   -- Reset --
   -----------

   procedure Reset (F : out State) is
   begin
      F := (Mode   => Collecting,
            Buffer => (others => 0),
            Count  => 0);
   end Reset;

   ----------
   -- Idle --
   ----------

   procedure Idle (F : in out State) is
   begin
      Reset (F);
   end Idle;

   ----------
   -- Feed --
   ----------

   procedure Feed (F : in out State; B : Byte; Result : out Event) is
   begin
      Result := None;

      if F.Mode = Complete then
         Reset (F);
      end if;

      if F.Mode = Discarding then
         return;
      end if;

      F.Count := F.Count + 1;
      F.Buffer (F.Count) := B;

      case F.Count is
         when 1 =>
            if B > Slave_Address'Last then
               Fail (F, Result);
            end if;
         when 2 =>
            if not Is_Known (B) then
               Fail (F, Result);
            end if;
         when Byte_Count_Position =>
            if Is_Multiple_Write (F.Buffer (2)) and then B > Max_Byte_Count
            then
               Fail (F, Result);
            end if;
         when others =>
            null;
      end case;

      if Result = None and then F.Count = Expected_Length (F) then
         if CRC.CRC16 (F.Buffer (1 .. F.Count)) = 0 then
            F.Mode := Complete;
            Result := Frame_Ready;
         else
            Fail (F, Result);
         end if;
      end if;
   end Feed;

   -----------
   -- Ready --
   -----------

   function Ready (F : State) return Boolean is
   begin
      return F.Mode = Complete;
   end Ready;

   -----------
   -- Slave --
   -----------

   function Slave (F : State) return Slave_Address is
   begin
      return F.Buffer (1);
   end Slave;

   -------------
   -- Request --
   -------------

   function Request (F : State) return PDU_T is
      Result : PDU_T;
      Last   : constant Natural := F.Count - 3;   --  PDU length
   begin
      Result.Length := Last;
      Result.Data (1 .. Last) := F.Buffer (2 .. F.Count - 2);
      return Result;
   end Request;

   ------------
   -- Encode --
   ------------

   procedure Encode
     (Unit   : Slave_Address;
      Reply  : PDU_T;
      Frame  : out Frame_Bytes;
      Length : out Frame_Length)
   is
      Last : constant Natural := 1 + Reply.Length;   --  address + PDU
      Sum  : Word;
   begin
      Frame := (others => 0);
      Frame (1) := Unit;
      Frame (2 .. Last) := Reply.Data (1 .. Reply.Length);
      Sum := CRC.CRC16 (Frame (1 .. Last));
      Frame (Last + 1) := Low (Sum);
      Frame (Last + 2) := High (Sum);
      Length := Last + 2;
   end Encode;

end Modbus.RTU.Framer;
