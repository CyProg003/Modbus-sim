package body Modbus.RTU.CRC is

   function CRC16 (Data : Byte_Array) return Word is
      CRC : Word := 16#FFFF#;
   begin
      for B of Data loop
         CRC := CRC xor Word (B);
         for I in 1 .. 8 loop
            if (CRC and 1) /= 0 then
               CRC := Interfaces.Shift_Right (CRC, 1) xor 16#A001#;
            else
               CRC := Interfaces.Shift_Right (CRC, 1);
            end if;
         end loop;
      end loop;
      return CRC;
   end CRC16;

end Modbus.RTU.CRC;

