generic
   with function Read_Holding  (A : Address; V : out Word)
     return Result_Code;
   with function Write_Holding (A : Address; V : Word)
     return Result_Code;
   --  The device supplies its storage through these two functions, so the
   --  server never owns any data. Both return Illegal_Data_Address for an
   --  address the device does not have. V is only used when the result is
   --  Success. Coils, discrete inputs and input registers are added the
   --  same way later.
package Modbus.Server is
   pragma Elaborate_Body;

   --  Turns one request PDU into one reply PDU. Supported functions are
   --  03 (read holding registers), 06 (write single register) and
   --  16 (write multiple registers). Every other function code is
   --  answered with Illegal_Function.
   --
   --  Handle never raises and always fills in Reply. A bad request, or a
   --  callback that returns anything but Success, becomes an exception
   --  reply instead of an Ada exception.
   --
   --  A write of several registers is not atomic: if the device refuses
   --  register N, registers before N stay written and the reply is the
   --  exception.
   procedure Handle (Request : PDU_T; Reply : out PDU_T);

end Modbus.Server;
