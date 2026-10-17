with Interfaces;

package Modbus with SPARK_Mode => On is
   use type Interfaces.Unsigned_16;

   subtype Byte is Interfaces.Unsigned_8;
   subtype Word is Interfaces.Unsigned_16;

   type Byte_Array is array (Positive range <>) of Byte;

   function High (W : Word) return Byte;
   function Low  (W : Word) return Byte;
   function To_Word (Hi, Lo : Byte) return Word is
     (Interfaces.Shift_Left (Word (Hi), 8) or Word (Lo));

   ---------
   -- PDU --
   ---------

   Max_PDU_Length : constant := 253;
   subtype PDU_Length is Natural range 0 .. Max_PDU_Length;

   type PDU_T is record
      Length : PDU_Length := 0;
      Data   : Byte_Array (1 .. Max_PDU_Length) := (others => 0);
   end record;

   ----------------
   -- Data model --
   ----------------

   --  Address as sent on the wire, 0-based. Not modular on purpose:
   --  Start + Count going past 65535 is a protocol error, not a wraparound.
   type Address is range 0 .. 2**16 - 1;

   type Quantity is range 0 .. 2000;
   subtype Read_Bits_Quantity       is Quantity range 1 .. 2000;  --  FC 01, 02
   subtype Read_Registers_Quantity  is Quantity range 1 .. 125;   --  FC 03, 04
   subtype Write_Bits_Quantity      is Quantity range 1 .. 1968;  --  FC 15
   subtype Write_Registers_Quantity is Quantity range 1 .. 123;   --  FC 16

   --  True when Start .. Start + Count - 1 stays inside the address space
   function Fits (Start : Address; Count : Quantity) return Boolean is
     (Count >= 1 and then Address (Count) - 1 <= Address'Last - Start);

   --------------------
   -- Function codes --
   --------------------

   type Function_Code is
     (Read_Coils,
      Read_Discrete_Inputs,
      Read_Holding_Registers,
      Read_Input_Registers,
      Write_Single_Coil,
      Write_Single_Register,
      Write_Multiple_Coils,
      Write_Multiple_Registers);

   Code_Of : constant array (Function_Code) of Byte :=
     (16#01#, 16#02#, 16#03#, 16#04#, 16#05#, 16#06#, 16#0F#, 16#10#);

   function Is_Known (Raw : Byte) return Boolean is
     (Raw in 16#01# .. 16#06# | 16#0F# | 16#10#);

   function To_Function (Raw : Byte) return Function_Code is
     (case Raw is
        when 16#01# => Read_Coils,
        when 16#02# => Read_Discrete_Inputs,
        when 16#03# => Read_Holding_Registers,
        when 16#04# => Read_Input_Registers,
        when 16#05# => Write_Single_Coil,
        when 16#06# => Write_Single_Register,
        when 16#0F# => Write_Multiple_Coils,
        when 16#10# => Write_Multiple_Registers,
        when others => raise Program_Error)
   with Pre => Is_Known (Raw);

   --  OR'ed into the function code of an error reply
   Exception_Flag : constant Byte := 16#80#;

   ------------------
   -- Result codes --
   ------------------

   type Result_Code is
     (Success,
      Illegal_Function,
      Illegal_Data_Address,
      Illegal_Data_Value,
      Server_Device_Failure);

   subtype Exception_Code is Result_Code
     range Illegal_Function .. Server_Device_Failure;

   Exception_Byte : constant array (Exception_Code) of Byte :=
     (16#01#, 16#02#, 16#03#, 16#04#);

end Modbus;
