package body Modbus is
   function High (W : Word) return Byte is 
   begin
      return Byte (Interfaces.Shift_Right (W, 8));
   end;

   function Low  (W : Word) return Byte is 
   begin
      return Byte (W and 16#FF#);
   end;
end Modbus;