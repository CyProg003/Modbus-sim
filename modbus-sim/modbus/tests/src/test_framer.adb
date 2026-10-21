with Ada.Assertions;
with Ada.Text_IO;

with Modbus;              use Modbus;
with Modbus.RTU;          use Modbus.RTU;
with Modbus.RTU.CRC;
with Modbus.RTU.Framer;   use Modbus.RTU.Framer;

--  Feeds known-good frames, damaged frames and edge cases to the framer.
--  The CRC bytes in the frames were calculated independently of the code
--  under test (see test_crc.adb for the CRC itself).
procedure Test_Framer is

   use type Modbus.Byte;

   procedure Expect (Name : String; Condition : Boolean) is
   begin
      if Condition then
         Ada.Text_IO.Put_Line ("PASS  " & Name);
      else
         Ada.Text_IO.Put_Line ("FAIL  " & Name);
         raise Ada.Assertions.Assertion_Error with Name;
      end if;
   end Expect;

   --  Feeds every byte and reports what happened
   type Outcome is record
      Last      : Event;    --  event after the last byte
      Early     : Boolean;  --  True if any earlier byte gave a non-None event
      First_Bad : Natural;  --  index of the byte that gave Frame_Bad, or 0
   end record;

   procedure Push (F : in out State; Data : Byte_Array; Out_Come : out Outcome)
   is
      Ev : Event;
   begin
      Out_Come := (Last => None, Early => False, First_Bad => 0);
      for I in Data'Range loop
         Feed (F, Data (I), Ev);
         if Ev = Frame_Bad and then Out_Come.First_Bad = 0 then
            Out_Come.First_Bad := I - Data'First + 1;
         end if;
         if I < Data'Last and then Ev /= None then
            Out_Come.Early := True;
         end if;
         Out_Come.Last := Ev;
      end loop;
   end Push;

   --  Frames (CRC low byte first, as on the wire)
   Readme_Request : constant Byte_Array :=
     (16#11#, 16#03#, 16#00#, 16#6B#, 16#00#, 16#03#, 16#76#, 16#87#);

   Write_One : constant Byte_Array :=
     (16#01#, 16#06#, 16#00#, 16#01#, 16#00#, 16#03#, 16#98#, 16#0B#);

   Write_Many : constant Byte_Array :=
     (16#01#, 16#10#, 16#00#, 16#01#, 16#00#, 16#02#, 16#04#,
      16#00#, 16#0A#, 16#01#, 16#02#, 16#92#, 16#30#);

   Broadcast : constant Byte_Array :=
     (16#00#, 16#06#, 16#00#, 16#01#, 16#00#, 16#03#, 16#99#, 16#DA#);

   Slave_247 : constant Byte_Array :=
     (16#F7#, 16#03#, 16#00#, 16#00#, 16#00#, 16#01#, 16#90#, 16#9C#);

   F  : State;
   O  : Outcome;
   Ev : Event;

begin
   ---------------------------------------------------------------------
   --  Good frames
   ---------------------------------------------------------------------
   Reset (F);
   Expect ("a new framer is not ready", not Ready (F));
   Push (F, Readme_Request, O);
   Expect ("readme request: Frame_Ready on the last byte",
           O.Last = Frame_Ready);
   Expect ("readme request: nothing reported before the last byte",
           not O.Early);
   Expect ("readme request: ready", Ready (F));
   Expect ("readme request: slave is 11", Slave (F) = 16#11#);
   declare
      P : constant PDU_T := Request (F);
   begin
      Expect ("readme request: PDU is 5 bytes long", P.Length = 5);
      Expect ("readme request: PDU holds 03 00 6B 00 03",
              P.Data (1 .. 5) = (16#03#, 16#00#, 16#6B#, 16#00#, 16#03#));
      Expect ("readme request: unused PDU bytes are zero",
              P.Data (6) = 0 and then P.Data (Max_PDU_Length) = 0);
   end;

   Reset (F);
   Push (F, Write_One, O);
   Expect ("write one register: Frame_Ready", O.Last = Frame_Ready
          and then not O.Early);
   Expect ("write one register: slave 1", Slave (F) = 1);
   Expect ("write one register: PDU length 5", Request (F).Length = 5);

   Reset (F);
   Push (F, Write_Many, O);
   Expect ("write many registers: Frame_Ready", O.Last = Frame_Ready
          and then not O.Early);
   Expect ("write many registers: PDU length 10", Request (F).Length = 10);
   Expect ("write many registers: last data byte kept",
           Request (F).Data (10) = 16#02#);

   Reset (F);
   Push (F, Broadcast, O);
   Expect ("broadcast address 0 is accepted", O.Last = Frame_Ready
          and then Slave (F) = 0);

   Reset (F);
   Push (F, Slave_247, O);
   Expect ("highest slave address 247 is accepted", O.Last = Frame_Ready
          and then Slave (F) = 247);

   ---------------------------------------------------------------------
   --  Frames follow one another
   ---------------------------------------------------------------------
   Reset (F);
   Push (F, Readme_Request, O);
   Push (F, Write_One, O);
   Expect ("second frame without Idle in between is read",
           O.Last = Frame_Ready and then Slave (F) = 1
           and then Request (F).Data (1) = 16#06#);

   Push (F, Readme_Request, O);
   Idle (F);
   Expect ("Idle after a frame clears Ready", not Ready (F));
   Push (F, Write_One, O);
   Expect ("frame after Idle is read", O.Last = Frame_Ready);

   ---------------------------------------------------------------------
   --  Idle resynchronises
   ---------------------------------------------------------------------
   Reset (F);
   Push (F, Readme_Request (1 .. 4), O);
   Expect ("half a frame gives no event", O.Last = None);
   Idle (F);
   Push (F, Write_One, O);
   Expect ("Idle drops a half frame and the next frame is read",
           O.Last = Frame_Ready and then Slave (F) = 1
           and then Request (F).Data (1) = 16#06#);

   ---------------------------------------------------------------------
   --  Bad frames
   ---------------------------------------------------------------------
   declare
      Damaged : Byte_Array := Readme_Request;
   begin
      Damaged (4) := Damaged (4) xor 16#01#;   --  one flipped bit
      Reset (F);
      Push (F, Damaged, O);
      Expect ("bad CRC: Frame_Bad on the last byte",
              O.Last = Frame_Bad and then O.First_Bad = 8);
      Expect ("bad CRC: not ready", not Ready (F));
   end;

   Reset (F);
   Push (F, Readme_Request (1 .. 7) & 16#00#, O);
   Expect ("wrong CRC high byte is rejected", O.Last = Frame_Bad);

   --  After Frame_Bad all bytes are ignored until Idle, even a good frame
   Push (F, Readme_Request, O);
   Expect ("after Frame_Bad a good frame is ignored until Idle",
           O.Last = None and then not Ready (F));
   Idle (F);
   Push (F, Readme_Request, O);
   Expect ("after Idle the good frame is read",
           O.Last = Frame_Ready and then Slave (F) = 16#11#);

   --  A flood of noise after a bad frame must not overflow the buffer
   Reset (F);
   Push (F, Byte_Array'(16#01#, 16#07#), O);
   Push (F, Byte_Array'(1 .. 600 => 16#55#), O);
   Expect ("600 bytes of noise after Frame_Bad are ignored",
           O.Last = None and then not Ready (F));
   Idle (F);
   Push (F, Write_One, O);
   Expect ("the framer recovers after the noise", O.Last = Frame_Ready);

   Reset (F);
   Push (F, Byte_Array'(16#F8#, 16#03#), O);
   Expect ("address 248 is rejected on the first byte",
           O.First_Bad = 1);

   Reset (F);
   Push (F, Byte_Array'(16#01#, 16#07#), O);
   Expect ("unknown function 07 is rejected on the second byte",
           O.First_Bad = 2);

   Reset (F);
   Push (F, Byte_Array'(16#01#, 16#00#), O);
   Expect ("function 00 is rejected", O.First_Bad = 2);

   Reset (F);
   Push (F, Byte_Array'(16#01#, 16#83#), O);
   Expect ("an exception function code is not a request",
           O.First_Bad = 2);

   ---------------------------------------------------------------------
   --  Longest frames
   ---------------------------------------------------------------------
   declare
      --  Function 10 with a 247-byte data part: a 256-byte frame, the
      --  longest possible. The framer only checks the length and CRC;
      --  whether quantity matches is the server's job.
      Frame : Byte_Array (1 .. 256) := (others => 16#5A#);
      Sum   : Word;
   begin
      Frame (1 .. 7) := (1, 16#10#, 0, 0, 0, 16#7B#, 247);
      Sum := CRC.CRC16 (Frame (1 .. 254));
      Frame (255) := Low (Sum);
      Frame (256) := High (Sum);
      Reset (F);
      Push (F, Frame, O);
      Expect ("longest frame (256 bytes) is accepted",
              O.Last = Frame_Ready and then not O.Early);
      Expect ("longest frame: PDU is 253 bytes long",
              Request (F).Length = 253);
      Expect ("longest frame: last PDU byte is the last data byte",
              Request (F).Data (253) = 16#5A#);
   end;

   Reset (F);
   Push (F, Byte_Array'(1, 16#10#, 0, 0, 0, 16#7B#, 248), O);
   Expect ("byte count 248 is rejected on the byte count itself",
           O.First_Bad = 7);

   Reset (F);
   Push (F, Byte_Array'(1, 16#0F#, 0, 0, 0, 8, 255), O);
   Expect ("byte count 255 of function 0F is rejected", O.First_Bad = 7);

   Reset (F);
   Push (F, Byte_Array'(1, 16#10#, 0, 0, 0, 0, 0, 16#00#, 16#00#), O);
   Expect ("a zero byte count only completes with its CRC",
           O.Last = Frame_Bad);

   ---------------------------------------------------------------------
   --  Encode
   ---------------------------------------------------------------------
   declare
      Reply : constant PDU_T :=
        (Length => 8,
         Data   => (16#03#, 16#06#, 16#AE#, 16#41#, 16#56#, 16#52#,
                    16#43#, 16#40#, others => 0));
      Frame : Frame_Bytes;
      Len   : Frame_Length;
   begin
      Encode (16#11#, Reply, Frame, Len);
      Expect ("encoded reply is 11 bytes long", Len = 11);
      Expect ("encoded reply: address, PDU, CRC low byte first",
              Frame (1 .. 11) =
                (16#11#, 16#03#, 16#06#, 16#AE#, 16#41#, 16#56#, 16#52#,
                 16#43#, 16#40#, 16#49#, 16#AD#));
      Expect ("encoded reply: bytes after the frame are zero",
              Frame (12) = 0 and then Frame (256) = 0);
   end;

   declare
      Reply : constant PDU_T :=
        (Length => 2, Data => (16#83#, 16#02#, others => 0));
      Frame : Frame_Bytes;
      Len   : Frame_Length;
   begin
      Encode (1, Reply, Frame, Len);
      Expect ("exception reply frame 01 83 02 C0 F1",
              Len = 5 and then Frame (1 .. 5) =
                (16#01#, 16#83#, 16#02#, 16#C0#, 16#F1#));
   end;

   --  What Encode builds, the framer accepts: a write-single reply is
   --  the same 8 bytes as a write-single request
   declare
      Reply : constant PDU_T :=
        (Length => 5,
         Data   => (16#06#, 16#00#, 16#10#, 16#12#, 16#34#, others => 0));
      Frame : Frame_Bytes;
      Len   : Frame_Length;
   begin
      Encode (16#11#, Reply, Frame, Len);
      Expect ("encoded write reply has the independent CRC 87 E8",
              Frame (7) = 16#87# and then Frame (8) = 16#E8#);
      Reset (F);
      Push (F, Frame (1 .. Len), O);
      Expect ("a frame built by Encode is read back by the framer",
              O.Last = Frame_Ready and then Slave (F) = 16#11#
              and then Request (F) = Reply);
   end;

   Reset (F);
   Feed (F, 16#01#, Ev);
   Expect ("Feed of a single byte returns None", Ev = None);

   Ada.Text_IO.Put_Line ("test_framer: all checks passed");
end Test_Framer;
