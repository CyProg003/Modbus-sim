with Interfaces;

package Modbus is
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
end Modbus;