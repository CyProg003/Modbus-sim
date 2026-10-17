with Ada.Assertions;
with Ada.Text_IO;

with Modbus;         use Modbus;
with Modbus.RTU.CRC; use Modbus.RTU.CRC;

--  Known-good CRC-16/Modbus values. The expected numbers come from an
--  independent calculation, not from the code under test. Note that the
--  readme's worked example shows "CC CC" as a placeholder checksum; the
--  real CRC of 11 03 00 6B 00 03 is 8776, sent on the wire as 76 87.
procedure Test_Crc is

   use type Modbus.Word;
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

   --  Checks the CRC value and the two bytes as they go on the wire
   procedure Expect_CRC
     (Name : String;
      Data : Byte_Array;
      CRC  : Word;
      Lo   : Byte;
      Hi   : Byte)
   is
      Got : constant Word := CRC16 (Data);
   begin
      Expect (Name & ": CRC", Got = CRC);
      Expect (Name & ": low byte goes first", Low (Got) = Lo);
      Expect (Name & ": high byte goes second", High (Got) = Hi);
   end Expect_CRC;

   Empty : constant Byte_Array (1 .. 0) := (others => 0);

   --  ASCII "123456789", the standard CRC check string
   Check_String : constant Byte_Array :=
     (16#31#, 16#32#, 16#33#, 16#34#, 16#35#, 16#36#, 16#37#, 16#38#, 16#39#);

   --  Worked example from the readme: read 3 holding registers from
   --  address 16#006B#, slave 16#11#
   Readme_Request : constant Byte_Array :=
     (16#11#, 16#03#, 16#00#, 16#6B#, 16#00#, 16#03#);

   --  ...and its reply: three registers AE41, 5652 and 4340
   Readme_Reply : constant Byte_Array :=
     (16#11#, 16#03#, 16#06#, 16#AE#, 16#41#, 16#56#, 16#52#, 16#43#,
      16#40#);

   --  Read one holding register at address 0 from slave 1
   Read_One : constant Byte_Array :=
     (16#01#, 16#03#, 16#00#, 16#00#, 16#00#, 16#01#);

   --  Read ten holding registers at address 0 from slave 1
   Read_Ten : constant Byte_Array :=
     (16#01#, 16#03#, 16#00#, 16#00#, 16#00#, 16#0A#);

   --  Write the value 3 to register 1 of slave 1
   Write_One : constant Byte_Array :=
     (16#01#, 16#06#, 16#00#, 16#01#, 16#00#, 16#03#);

begin
   Expect ("empty input gives the initial value FFFF",
           CRC16 (Empty) = 16#FFFF#);

   Expect_CRC ("ASCII 123456789 (standard check value)",
               Check_String, 16#4B37#, 16#37#, 16#4B#);

   Expect_CRC ("readme request 11 03 00 6B 00 03",
               Readme_Request, 16#8776#, 16#76#, 16#87#);

   Expect_CRC ("readme reply 11 03 06 AE 41 56 52 43 40",
               Readme_Reply, 16#AD49#, 16#49#, 16#AD#);

   Expect_CRC ("read 1 register 01 03 00 00 00 01",
               Read_One, 16#0A84#, 16#84#, 16#0A#);

   Expect_CRC ("read 10 registers 01 03 00 00 00 0A",
               Read_Ten, 16#CDC5#, 16#C5#, 16#CD#);

   Expect_CRC ("write register 01 06 00 01 00 03",
               Write_One, 16#0B98#, 16#98#, 16#0B#);

   Expect ("single byte 00 gives 40BF",
           CRC16 (Byte_Array'(1 => 16#00#)) = 16#40BF#);

   Expect ("single byte FF gives 00FF",
           CRC16 (Byte_Array'(1 => 16#FF#)) = 16#00FF#);

   --  A receiver checks a frame by running the CRC over everything,
   --  including the two CRC bytes (low byte first). A good frame gives 0.
   declare
      CRC   : constant Word := CRC16 (Readme_Request);
      Frame : constant Byte_Array :=
        Readme_Request & Low (CRC) & High (CRC);
   begin
      Expect ("a request followed by its CRC checks out to 0",
              CRC16 (Frame) = 0);
   end;

   declare
      CRC   : constant Word := CRC16 (Readme_Reply);
      Frame : constant Byte_Array := Readme_Reply & Low (CRC) & High (CRC);
   begin
      Expect ("a reply followed by its CRC checks out to 0",
              CRC16 (Frame) = 0);
   end;

   --  A damaged frame must not check out
   declare
      Frame : Byte_Array := Readme_Request & 16#76# & 16#87#;
   begin
      Expect ("an intact frame checks out", CRC16 (Frame) = 0);
      Frame (4) := Frame (4) xor 16#01#;   --  flip one bit in the address
      Expect ("a frame with one flipped bit is rejected",
              CRC16 (Frame) /= 0);
   end;

   --  The CRC depends on byte order
   Expect ("swapping two bytes changes the CRC",
           CRC16 (Byte_Array'(16#01#, 16#02#)) /=
           CRC16 (Byte_Array'(16#02#, 16#01#)));

   Ada.Text_IO.Put_Line ("test_crc: all checks passed");
end Test_Crc;
