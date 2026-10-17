with Ada.Assertions;
with Ada.Text_IO;

with Modbus; use Modbus;
with Modbus.Server;

--  Golden-frame tests for Modbus.Server (and, through it, Modbus.PDU).
--  Every request and expected reply below is written out byte by byte, as
--  it would appear on the wire without the address and CRC (or MBAP
--  header). The first test is the readme's worked example.
procedure Test_Server is

   use type Modbus.Word;
   use type Modbus.Byte;

   ----------------------------------------------------------------------
   --  A small simulated device: 256 holding registers, addresses 0 .. 255
   ----------------------------------------------------------------------

   Regs   : array (Address range 0 .. 255) of Word := (others => 0);
   Reads  : Natural := 0;   --  how often the device was asked to read
   Writes : Natural := 0;   --  how often the device was asked to write

   --  Register 200 only accepts values up to 1000, to show that an error
   --  chosen by the device reaches the master unchanged.
   Limited_Register : constant Address := 200;
   Limit            : constant Word    := 1000;

   function Read_Reg (A : Address; V : out Word) return Result_Code is
   begin
      Reads := Reads + 1;
      if A in Regs'Range then
         V := Regs (A);
         return Success;
      else
         V := 0;
         return Illegal_Data_Address;
      end if;
   end Read_Reg;

   function Write_Reg (A : Address; V : Word) return Result_Code is
   begin
      Writes := Writes + 1;
      if A not in Regs'Range then
         return Illegal_Data_Address;
      elsif A = Limited_Register and then V > Limit then
         return Illegal_Data_Value;
      else
         Regs (A) := V;
         return Success;
      end if;
   end Write_Reg;

   package Device is new Modbus.Server
     (Read_Holding  => Read_Reg,
      Write_Holding => Write_Reg);

   --  A broken device that refuses every access
   function Read_Broken (A : Address; V : out Word) return Result_Code is
      pragma Unreferenced (A);
   begin
      V := 0;
      return Server_Device_Failure;
   end Read_Broken;

   function Write_Broken (A : Address; V : Word) return Result_Code is
      pragma Unreferenced (A, V);
   begin
      return Server_Device_Failure;
   end Write_Broken;

   package Broken is new Modbus.Server
     (Read_Holding  => Read_Broken,
      Write_Holding => Write_Broken);

   --  A device that has every address 0 .. 65535. Each register reads back
   --  its own address, so no storage is needed. Used to test the edge of
   --  the address space, which the 256-register device cannot show.
   function Read_Full (A : Address; V : out Word) return Result_Code is
   begin
      V := Word (A);
      return Success;
   end Read_Full;

   function Write_Full (A : Address; V : Word) return Result_Code is
      pragma Unreferenced (A, V);
   begin
      return Success;
   end Write_Full;

   package Full_Device is new Modbus.Server
     (Read_Holding  => Read_Full,
      Write_Holding => Write_Full);

   ----------------------------------------------------------------------
   --  Helpers
   ----------------------------------------------------------------------

   procedure Expect (Name : String; Condition : Boolean) is
   begin
      if Condition then
         Ada.Text_IO.Put_Line ("PASS  " & Name);
      else
         Ada.Text_IO.Put_Line ("FAIL  " & Name);
         raise Ada.Assertions.Assertion_Error with Name;
      end if;
   end Expect;

   function Make (B : Byte_Array) return PDU_T is
      R : PDU_T;
   begin
      R.Length := B'Length;
      R.Data (1 .. B'Length) := B;
      return R;
   end Make;

   --  True when the PDU holds exactly these bytes and nothing else
   function Is_Bytes (P : PDU_T; B : Byte_Array) return Boolean is
   begin
      return P.Length = B'Length and then P.Data (1 .. P.Length) = B;
   end Is_Bytes;

   Reply : PDU_T;

begin
   --  The readme's registers: addresses 107, 108 and 109 (16#6B# ..)
   Regs (107) := 16#AE41#;
   Regs (108) := 16#5652#;
   Regs (109) := 16#4340#;

   ----------------------------------------------------------------------
   --  Function 03: read holding registers
   ----------------------------------------------------------------------

   --  Readme worked example: read 3 registers starting at 16#006B#
   Device.Handle (Make ((16#03#, 16#00#, 16#6B#, 16#00#, 16#03#)), Reply);
   Expect ("03 readme example: 03 06 AE41 5652 4340",
           Is_Bytes (Reply, (16#03#, 16#06#, 16#AE#, 16#41#, 16#56#, 16#52#,
                             16#43#, 16#40#)));

   Device.Handle (Make ((16#03#, 16#00#, 16#6B#, 16#00#, 16#01#)), Reply);
   Expect ("03 read one register",
           Is_Bytes (Reply, (16#03#, 16#02#, 16#AE#, 16#41#)));

   Device.Handle (Make ((16#03#, 16#00#, 16#FF#, 16#00#, 16#01#)), Reply);
   Expect ("03 read the last register on the device (255)",
           Is_Bytes (Reply, (16#03#, 16#02#, 16#00#, 16#00#)));

   Device.Handle (Make ((16#03#, 16#00#, 16#00#, 16#00#, 16#7D#)), Reply);
   Expect ("03 read the maximum of 125 registers",
           Reply.Length = 252 and then Reply.Data (1) = 16#03#
           and then Reply.Data (2) = 250);

   --  Errors: exception reply is the function code + 16#80#, then a code
   Device.Handle (Make ((16#03#, 16#00#, 16#00#, 16#00#, 16#00#)), Reply);
   Expect ("03 quantity 0 gives 83 03 (illegal data value)",
           Is_Bytes (Reply, (16#83#, 16#03#)));

   Device.Handle (Make ((16#03#, 16#00#, 16#00#, 16#00#, 16#7E#)), Reply);
   Expect ("03 quantity 126 gives 83 03 (illegal data value)",
           Is_Bytes (Reply, (16#83#, 16#03#)));

   Device.Handle (Make ((16#03#, 16#00#, 16#00#, 16#FF#, 16#FF#)), Reply);
   Expect ("03 quantity 65535 gives 83 03, no overflow",
           Is_Bytes (Reply, (16#83#, 16#03#)));

   Device.Handle (Make ((16#03#, 16#00#, 16#00#, 16#00#)), Reply);
   Expect ("03 truncated request gives 83 03",
           Is_Bytes (Reply, (16#83#, 16#03#)));

   Device.Handle (Make ((16#03#, 16#00#, 16#00#, 16#00#, 16#01#, 16#09#)),
                  Reply);
   Expect ("03 request with an extra byte gives 83 03",
           Is_Bytes (Reply, (16#83#, 16#03#)));

   Device.Handle (Make ((1 => 16#03#)), Reply);
   Expect ("03 with no data at all gives 83 03",
           Is_Bytes (Reply, (16#83#, 16#03#)));

   Device.Handle (Make ((16#03#, 16#00#, 16#FF#, 16#00#, 16#02#)), Reply);
   Expect ("03 runs past the end of the device: 83 02",
           Is_Bytes (Reply, (16#83#, 16#02#)));

   declare
      Before : constant Natural := Reads;
   begin
      Device.Handle (Make ((16#03#, 16#FF#, 16#FF#, 16#00#, 16#02#)), Reply);
      Expect ("03 start 65535 count 2 gives 83 02 (illegal data address)",
              Is_Bytes (Reply, (16#83#, 16#02#)));
      Expect ("03 a request that is wrong on the wire never reaches the "
              & "device", Reads = Before);
   end;

   ----------------------------------------------------------------------
   --  Function 06: write single register
   ----------------------------------------------------------------------

   --  Classic example: write 3 to register 1. The reply echoes the request
   Device.Handle (Make ((16#06#, 16#00#, 16#01#, 16#00#, 16#03#)), Reply);
   Expect ("06 write register 1 = 3 echoes the request",
           Is_Bytes (Reply, (16#06#, 16#00#, 16#01#, 16#00#, 16#03#)));
   Expect ("06 the device now holds 3", Regs (1) = 3);

   Device.Handle (Make ((16#03#, 16#00#, 16#01#, 16#00#, 16#01#)), Reply);
   Expect ("06 reading it back returns 0003",
           Is_Bytes (Reply, (16#03#, 16#02#, 16#00#, 16#03#)));

   Device.Handle (Make ((16#06#, 16#00#, 16#00#, 16#FF#, 16#FF#)), Reply);
   Expect ("06 value FFFF is stored as it is",
           Is_Bytes (Reply, (16#06#, 16#00#, 16#00#, 16#FF#, 16#FF#))
           and then Regs (0) = 16#FFFF#);

   Device.Handle (Make ((16#06#, 16#01#, 16#00#, 16#00#, 16#01#)), Reply);
   Expect ("06 address 256 is not on the device: 86 02",
           Is_Bytes (Reply, (16#86#, 16#02#)));

   Device.Handle (Make ((16#06#, 16#00#, 16#C8#, 16#03#, 16#E8#)), Reply);
   Expect ("06 register 200 accepts 1000",
           Is_Bytes (Reply, (16#06#, 16#00#, 16#C8#, 16#03#, 16#E8#)));

   Device.Handle (Make ((16#06#, 16#00#, 16#C8#, 16#03#, 16#E9#)), Reply);
   Expect ("06 register 200 refuses 1001: the device's own error, 86 03",
           Is_Bytes (Reply, (16#86#, 16#03#)));
   Expect ("06 and the refused value was not stored", Regs (200) = 1000);

   declare
      Before : constant Natural := Writes;
   begin
      Device.Handle (Make ((16#06#, 16#00#, 16#01#, 16#00#)), Reply);
      Expect ("06 truncated request gives 86 03",
              Is_Bytes (Reply, (16#86#, 16#03#)));
      Expect ("06 a truncated request never reaches the device",
              Writes = Before);
   end;

   ----------------------------------------------------------------------
   --  Function 16 (hex 10): write multiple registers
   ----------------------------------------------------------------------

   --  Classic example: write 000A and 0102 to registers 1 and 2
   Device.Handle (Make ((16#10#, 16#00#, 16#01#, 16#00#, 16#02#, 16#04#,
                         16#00#, 16#0A#, 16#01#, 16#02#)), Reply);
   Expect ("10 write registers 1..2: reply is 10 0001 0002",
           Is_Bytes (Reply, (16#10#, 16#00#, 16#01#, 16#00#, 16#02#)));
   Expect ("10 register 1 now holds 000A", Regs (1) = 16#000A#);
   Expect ("10 register 2 now holds 0102", Regs (2) = 16#0102#);

   declare
      Before : constant Natural := Writes;
   begin
      Device.Handle (Make ((16#10#, 16#00#, 16#01#, 16#00#, 16#02#, 16#03#,
                            16#00#, 16#0A#, 16#01#, 16#02#)), Reply);
      Expect ("10 wrong byte count gives 90 03",
              Is_Bytes (Reply, (16#90#, 16#03#)));
      Expect ("10 a request with a wrong byte count never reaches the "
              & "device", Writes = Before);
   end;

   Device.Handle (Make ((16#10#, 16#00#, 16#01#, 16#00#, 16#02#, 16#04#,
                         16#00#, 16#0A#, 16#01#)), Reply);
   Expect ("10 truncated payload gives 90 03",
           Is_Bytes (Reply, (16#90#, 16#03#)));

   Device.Handle (Make ((16#10#, 16#00#, 16#01#, 16#00#, 16#02#, 16#04#,
                         16#00#, 16#0A#, 16#01#, 16#02#, 16#07#)), Reply);
   Expect ("10 extra trailing byte gives 90 03",
           Is_Bytes (Reply, (16#90#, 16#03#)));

   Device.Handle (Make ((16#10#, 16#00#, 16#01#, 16#00#, 16#00#, 16#00#)),
                  Reply);
   Expect ("10 quantity 0 gives 90 03",
           Is_Bytes (Reply, (16#90#, 16#03#)));

   Device.Handle (Make ((16#10#, 16#00#, 16#01#, 16#00#, 16#7C#, 16#F8#)),
                  Reply);
   Expect ("10 quantity 124 gives 90 03",
           Is_Bytes (Reply, (16#90#, 16#03#)));

   Device.Handle (Make ((16#10#, 16#FF#, 16#FF#, 16#00#, 16#02#, 16#04#,
                         16#00#, 16#01#, 16#00#, 16#02#)), Reply);
   Expect ("10 start 65535 count 2 gives 90 02",
           Is_Bytes (Reply, (16#90#, 16#02#)));

   --  The device refuses the second register. The first one stays
   --  written: a multi-register write is not atomic (see modbus-server.ads)
   Regs (254) := 0;
   Device.Handle (Make ((16#10#, 16#00#, 16#FE#, 16#00#, 16#03#, 16#06#,
                         16#00#, 16#07#, 16#00#, 16#08#, 16#00#, 16#09#)),
                  Reply);
   Expect ("10 runs past the end of the device: 90 02",
           Is_Bytes (Reply, (16#90#, 16#02#)));
   Expect ("10 registers before the refused one stay written",
           Regs (254) = 7 and then Regs (255) = 8);

   --  Largest legal write: 123 registers, 6 + 246 = 252 bytes
   declare
      Big : PDU_T;
   begin
      Big.Length   := 252;
      Big.Data (1) := 16#10#;
      Big.Data (5) := 16#7B#;   --  quantity 123
      Big.Data (6) := 16#F6#;   --  byte count 246
      Big.Data (251) := 16#BE#; --  last register = BEEF
      Big.Data (252) := 16#EF#;
      Device.Handle (Big, Reply);
      Expect ("10 the maximum of 123 registers: reply 10 0000 007B",
              Is_Bytes (Reply, (16#10#, 16#00#, 16#00#, 16#00#, 16#7B#)));
      Expect ("10 the last of them holds BEEF", Regs (122) = 16#BEEF#);
   end;

   ----------------------------------------------------------------------
   --  Function codes the server does not support or does not know
   ----------------------------------------------------------------------

   Device.Handle (Make ((16#01#, 16#00#, 16#00#, 16#00#, 16#01#)), Reply);
   Expect ("01 read coils is not supported: 81 01",
           Is_Bytes (Reply, (16#81#, 16#01#)));

   Device.Handle (Make ((16#02#, 16#00#, 16#00#, 16#00#, 16#01#)), Reply);
   Expect ("02 read discrete inputs is not supported: 82 01",
           Is_Bytes (Reply, (16#82#, 16#01#)));

   Device.Handle (Make ((16#04#, 16#00#, 16#00#, 16#00#, 16#01#)), Reply);
   Expect ("04 read input registers is not supported: 84 01",
           Is_Bytes (Reply, (16#84#, 16#01#)));

   Device.Handle (Make ((16#05#, 16#00#, 16#00#, 16#FF#, 16#00#)), Reply);
   Expect ("05 write single coil is not supported: 85 01",
           Is_Bytes (Reply, (16#85#, 16#01#)));

   Device.Handle (Make ((16#0F#, 16#00#, 16#00#, 16#00#, 16#01#, 16#01#,
                         16#01#)), Reply);
   Expect ("0F write multiple coils is not supported: 8F 01",
           Is_Bytes (Reply, (16#8F#, 16#01#)));

   Device.Handle (Make ((16#2B#, 16#0E#)), Reply);
   Expect ("2B unknown function code: AB 01",
           Is_Bytes (Reply, (16#AB#, 16#01#)));

   Device.Handle (Make ((16#7F#, 16#00#)), Reply);
   Expect ("7F highest valid function code: FF 01",
           Is_Bytes (Reply, (16#FF#, 16#01#)));

   Device.Handle (Make ((16#00#, 16#00#)), Reply);
   Expect ("00 function code zero: 80 01",
           Is_Bytes (Reply, (16#80#, 16#01#)));

   Device.Handle (PDU_T'(Length => 0, Data => (others => 0)), Reply);
   Expect ("an empty request still gets an answer: 80 01",
           Is_Bytes (Reply, (16#80#, 16#01#)));

   ----------------------------------------------------------------------
   --  The edge of the address space (addresses are 0 .. 65535)
   ----------------------------------------------------------------------

   Full_Device.Handle (Make ((16#03#, 16#FF#, 16#FF#, 16#00#, 16#01#)),
                       Reply);
   Expect ("edge: read address 65535 alone is fine, value FFFF",
           Is_Bytes (Reply, (16#03#, 16#02#, 16#FF#, 16#FF#)));

   Full_Device.Handle (Make ((16#03#, 16#FF#, 16#FE#, 16#00#, 16#02#)),
                       Reply);
   Expect ("edge: read the last two addresses 65534 and 65535",
           Is_Bytes (Reply, (16#03#, 16#04#, 16#FF#, 16#FE#, 16#FF#,
                             16#FF#)));

   Full_Device.Handle (Make ((16#03#, 16#FF#, 16#FF#, 16#00#, 16#02#)),
                       Reply);
   Expect ("edge: read 65535 plus one more gives 83 02, never wraps to 0",
           Is_Bytes (Reply, (16#83#, 16#02#)));

   Full_Device.Handle (Make ((16#06#, 16#FF#, 16#FF#, 16#00#, 16#05#)),
                       Reply);
   Expect ("edge: write single register at 65535",
           Is_Bytes (Reply, (16#06#, 16#FF#, 16#FF#, 16#00#, 16#05#)));

   Full_Device.Handle (Make ((16#10#, 16#FF#, 16#FE#, 16#00#, 16#02#, 16#04#,
                              16#00#, 16#01#, 16#00#, 16#02#)), Reply);
   Expect ("edge: write the last two addresses 65534 and 65535",
           Is_Bytes (Reply, (16#10#, 16#FF#, 16#FE#, 16#00#, 16#02#)));

   Full_Device.Handle (Make ((16#10#, 16#FF#, 16#FF#, 16#00#, 16#02#, 16#04#,
                              16#00#, 16#01#, 16#00#, 16#02#)), Reply);
   Expect ("edge: write 65535 plus one more gives 90 02",
           Is_Bytes (Reply, (16#90#, 16#02#)));

   ----------------------------------------------------------------------
   --  A device that fails: its error is passed on to the master
   ----------------------------------------------------------------------

   Broken.Handle (Make ((16#03#, 16#00#, 16#00#, 16#00#, 16#02#)), Reply);
   Expect ("broken device, read: 83 04",
           Is_Bytes (Reply, (16#83#, 16#04#)));

   Broken.Handle (Make ((16#06#, 16#00#, 16#00#, 16#00#, 16#01#)), Reply);
   Expect ("broken device, write single: 86 04",
           Is_Bytes (Reply, (16#86#, 16#04#)));

   Broken.Handle (Make ((16#10#, 16#00#, 16#00#, 16#00#, 16#01#, 16#02#,
                         16#00#, 16#01#)), Reply);
   Expect ("broken device, write multiple: 90 04",
           Is_Bytes (Reply, (16#90#, 16#04#)));

   Broken.Handle (Make ((16#03#, 16#00#, 16#00#, 16#00#, 16#7D#)), Reply);
   Expect ("broken device, largest read: 83 04, nothing half-built",
           Is_Bytes (Reply, (16#83#, 16#04#)));

   Ada.Text_IO.Put_Line ("test_server: all checks passed");
end Test_Server;
