package Modbus.PDU is
   pragma Elaborate_Body;

   --  A PDU is [function code : 1 byte][data : 0 .. 252 bytes]. In PDU_T,
   --  Data (1) is the function code and Length counts every byte in use.
   --  Multi-byte fields are big-endian: high byte first.

   --  A malformed request is reported through Result_Code, never through
   --  an Ada exception. On any result other than Success, the out
   --  parameters hold harmless defaults and must not be used.

   ----------------------
   -- Request decoding --
   ----------------------

   --  Raw function code of a request. It may not be one we support, so it
   --  is returned as a byte. Use Is_Known and To_Function to classify it.
   function Function_Byte (P : PDU_T) return Byte
     with Pre => P.Length >= 1;

   --  FC 03 / 04 request: [FC][start : 2][quantity : 2]
   procedure Decode_Read_Registers
     (P      : PDU_T;
      Start  : out Address;
      Count  : out Read_Registers_Quantity;
      Result : out Result_Code);

   --  FC 06 request: [FC][address : 2][value : 2]
   procedure Decode_Write_Single
     (P      : PDU_T;
      Target : out Address;
      Value  : out Word;
      Result : out Result_Code);

   --  FC 16 request: [FC][start : 2][quantity : 2][byte count : 1][values]
   --  Checks the quantity, the byte count and the total length.
   procedure Decode_Write_Multiple
     (P      : PDU_T;
      Start  : out Address;
      Count  : out Write_Registers_Quantity;
      Result : out Result_Code);

   --  The Index-th register value (1-based) of an FC 16 request that
   --  Decode_Write_Multiple has accepted.
   function Write_Value
     (P     : PDU_T;
      Index : Write_Registers_Quantity) return Word
     with Pre => P.Length >= 6 + 2 * Natural (Index);

   --------------------
   -- Reply encoding --
   --------------------

   --  Error reply: [FC with the top bit set][exception code]
   procedure Encode_Exception
     (Reply : out PDU_T;
      FC    : Byte;
      Code  : Exception_Code);

   --  FC 03 / 04 reply: [FC][byte count = 2 * Count][values]
   --  Begin_Read_Reply writes the header and zeroed values, then
   --  Set_Register fills in each value (Index is 1-based).
   procedure Begin_Read_Reply
     (Reply : out PDU_T;
      FC    : Byte;
      Count : Read_Registers_Quantity);

   procedure Set_Register
     (Reply : in out PDU_T;
      Index : Read_Registers_Quantity;
      Value : Word)
     with Pre => Reply.Length >= 2 + 2 * Natural (Index);

   --  FC 06 reply: an echo of the request, [FC][address : 2][value : 2]
   procedure Encode_Write_Single_Reply
     (Reply  : out PDU_T;
      Target : Address;
      Value  : Word);

   --  FC 16 reply: [FC][start : 2][quantity : 2]
   procedure Encode_Write_Multiple_Reply
     (Reply : out PDU_T;
      Start : Address;
      Count : Write_Registers_Quantity);

end Modbus.PDU;
