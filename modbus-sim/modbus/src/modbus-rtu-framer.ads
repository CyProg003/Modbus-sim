package Modbus.RTU.Framer is
   pragma Elaborate_Body;

   --  Turns a stream of bytes into RTU request frames, one byte at a time.
   --  It does no I/O and never reads a clock: the caller pushes bytes in
   --  with Feed and reports silence on the line with Idle.
   --
   --  The end of a frame is found from its function code instead of from
   --  the 3.5 character silence (see the readme). That works for the
   --  functions listed in Modbus.Function_Code. A frame with any other
   --  function code is reported as Frame_Bad, so the server never gets to
   --  answer it with Illegal_Function.
   --
   --  Frame_Bad means: address above 247, unknown function code, a byte
   --  count that cannot fit in a PDU, or a CRC mismatch. After Frame_Bad
   --  every byte is ignored (Feed returns None) until Idle is called.

   type State is private;

   type Event is (None, Frame_Ready, Frame_Bad);

   --  Forget everything and wait for the first byte of a frame
   procedure Reset (F : out State);

   --  Push one received byte. Result is Frame_Ready on the last byte of a
   --  complete frame with a good CRC. A byte that arrives after
   --  Frame_Ready starts the next frame, so Slave and Request must be
   --  read before the next Feed.
   procedure Feed (F : in out State; B : Byte; Result : out Event);

   --  Silence on the line: drop a half-received or damaged frame and
   --  start again. Same effect as Reset.
   procedure Idle (F : in out State);

   --  True between a Frame_Ready and the next Feed, Idle or Reset
   function Ready (F : State) return Boolean;

   function Slave (F : State) return Slave_Address
     with Pre => Ready (F);

   --  The PDU of the frame: function code and data, without the address
   --  and without the CRC
   function Request (F : State) return PDU_T
     with Pre => Ready (F);

   --  Builds the reply frame: address, PDU, then the CRC low byte first.
   --  Only Frame (1 .. Length) is meaningful.
   procedure Encode
     (Unit   : Slave_Address;
      Reply  : PDU_T;
      Frame  : out Frame_Bytes;
      Length : out Frame_Length);

private

   type Mode_Kind is
     (Collecting,   --  receiving the bytes of a frame
      Complete,     --  a good frame is waiting to be read
      Discarding);  --  bad frame, ignoring bytes until Idle

   type State is record
      Mode   : Mode_Kind := Collecting;
      Buffer : Frame_Bytes := (others => 0);
      Count  : Frame_Length := 0;
   end record;

end Modbus.RTU.Framer;
