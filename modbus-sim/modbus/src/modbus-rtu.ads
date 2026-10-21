package Modbus.RTU is

   --  Address byte of an RTU frame: 0 is broadcast (every slave acts and
   --  none replies), 1 .. 247 are individual devices.
   subtype Slave_Address is Byte range 0 .. 247;

   --  Longest RTU frame: 1 address byte + 253 PDU bytes + 2 CRC bytes
   Max_Frame_Length : constant := 256;
   subtype Frame_Length is Natural range 0 .. Max_Frame_Length;
   subtype Frame_Bytes  is Byte_Array (1 .. Max_Frame_Length);

end Modbus.RTU;
