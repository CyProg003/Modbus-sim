package body Modbus.PDU is

   use type Interfaces.Unsigned_8;

   -------------------
   -- Function_Byte --
   -------------------

   function Function_Byte (P : PDU_T) return Byte is
   begin
      return P.Data (1);
   end Function_Byte;

   ---------------------------
   -- Decode_Read_Registers --
   ---------------------------

   procedure Decode_Read_Registers
     (P      : PDU_T;
      Start  : out Address;
      Count  : out Read_Registers_Quantity;
      Result : out Result_Code)
   is
      Min_Count : constant Word := Word (Read_Registers_Quantity'First);
      Max_Count : constant Word := Word (Read_Registers_Quantity'Last);
   begin
      Start := 0;
      Count := Read_Registers_Quantity'First;

      if P.Length /= 5 then
         Result := Illegal_Data_Value;
      else
         declare
            Raw_Start : constant Word := To_Word (P.Data (2), P.Data (3));
            Raw_Count : constant Word := To_Word (P.Data (4), P.Data (5));
         begin
            if Raw_Count not in Min_Count .. Max_Count then
               Result := Illegal_Data_Value;
            elsif not Fits (Address (Raw_Start), Quantity (Raw_Count)) then
               Result := Illegal_Data_Address;
            else
               Start  := Address (Raw_Start);
               Count  := Read_Registers_Quantity (Raw_Count);
               Result := Success;
            end if;
         end;
      end if;
   end Decode_Read_Registers;

   -------------------------
   -- Decode_Write_Single --
   -------------------------

   procedure Decode_Write_Single
     (P      : PDU_T;
      Target : out Address;
      Value  : out Word;
      Result : out Result_Code)
   is
   begin
      Target := 0;
      Value  := 0;

      if P.Length /= 5 then
         Result := Illegal_Data_Value;
      else
         Target := Address (To_Word (P.Data (2), P.Data (3)));
         Value  := To_Word (P.Data (4), P.Data (5));
         Result := Success;
      end if;
   end Decode_Write_Single;

   ---------------------------
   -- Decode_Write_Multiple --
   ---------------------------

   procedure Decode_Write_Multiple
     (P      : PDU_T;
      Start  : out Address;
      Count  : out Write_Registers_Quantity;
      Result : out Result_Code)
   is
      Min_Count : constant Word := Word (Write_Registers_Quantity'First);
      Max_Count : constant Word := Word (Write_Registers_Quantity'Last);
   begin
      Start := 0;
      Count := Write_Registers_Quantity'First;

      if P.Length < 6 then
         Result := Illegal_Data_Value;
      else
         declare
            Raw_Start  : constant Word := To_Word (P.Data (2), P.Data (3));
            Raw_Count  : constant Word := To_Word (P.Data (4), P.Data (5));
            Byte_Count : constant Natural := Natural (P.Data (6));
         begin
            if Raw_Count not in Min_Count .. Max_Count then
               Result := Illegal_Data_Value;
            elsif Byte_Count /= 2 * Natural (Raw_Count)
              or else P.Length /= 6 + Byte_Count
            then
               Result := Illegal_Data_Value;
            elsif not Fits (Address (Raw_Start), Quantity (Raw_Count)) then
               Result := Illegal_Data_Address;
            else
               Start  := Address (Raw_Start);
               Count  := Write_Registers_Quantity (Raw_Count);
               Result := Success;
            end if;
         end;
      end if;
   end Decode_Write_Multiple;

   -----------------
   -- Write_Value --
   -----------------

   function Write_Value
     (P     : PDU_T;
      Index : Write_Registers_Quantity) return Word
   is
      First : constant Positive := 5 + 2 * Natural (Index);
   begin
      return To_Word (P.Data (First), P.Data (First + 1));
   end Write_Value;

   ----------------------
   -- Encode_Exception --
   ----------------------

   procedure Encode_Exception
     (Reply : out PDU_T;
      FC    : Byte;
      Code  : Exception_Code)
   is
   begin
      Reply := (Length => 2,
                Data   => (1      => FC or Exception_Flag,
                           2      => Exception_Byte (Code),
                           others => 0));
   end Encode_Exception;

   ----------------------
   -- Begin_Read_Reply --
   ----------------------

   procedure Begin_Read_Reply
     (Reply : out PDU_T;
      FC    : Byte;
      Count : Read_Registers_Quantity)
   is
      Byte_Count : constant Natural := 2 * Natural (Count);
   begin
      Reply := (Length => 2 + Byte_Count,
                Data   => (1      => FC,
                           2      => Byte (Byte_Count),
                           others => 0));
   end Begin_Read_Reply;

   ------------------
   -- Set_Register --
   ------------------

   procedure Set_Register
     (Reply : in out PDU_T;
      Index : Read_Registers_Quantity;
      Value : Word)
   is
      First : constant Positive := 1 + 2 * Natural (Index);
   begin
      Reply.Data (First)     := High (Value);
      Reply.Data (First + 1) := Low (Value);
   end Set_Register;

   -------------------------------
   -- Encode_Write_Single_Reply --
   -------------------------------

   procedure Encode_Write_Single_Reply
     (Reply  : out PDU_T;
      Target : Address;
      Value  : Word)
   is
   begin
      Reply := (Length => 5,
                Data   => (1      => Code_Of (Write_Single_Register),
                           2      => High (Word (Target)),
                           3      => Low (Word (Target)),
                           4      => High (Value),
                           5      => Low (Value),
                           others => 0));
   end Encode_Write_Single_Reply;

   ---------------------------------
   -- Encode_Write_Multiple_Reply --
   ---------------------------------

   procedure Encode_Write_Multiple_Reply
     (Reply : out PDU_T;
      Start : Address;
      Count : Write_Registers_Quantity)
   is
   begin
      Reply := (Length => 5,
                Data   => (1      => Code_Of (Write_Multiple_Registers),
                           2      => High (Word (Start)),
                           3      => Low (Word (Start)),
                           4      => High (Word (Count)),
                           5      => Low (Word (Count)),
                           others => 0));
   end Encode_Write_Multiple_Reply;

end Modbus.PDU;
