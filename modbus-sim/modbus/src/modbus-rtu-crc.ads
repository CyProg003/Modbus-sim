package Modbus.RTU.CRC is
   pragma Elaborate_Body;

   --  Modbus RTU CRC-16: reflected polynomial 16#A001#, initial value
   --  16#FFFF#. The result goes on the wire low byte first, so a frame
   --  ends with Low (CRC16 (Frame)) followed by High (CRC16 (Frame)).
   function CRC16 (Data : Byte_Array) return Word;

end Modbus.RTU.CRC;
