with Modbus.PDU;

package body Modbus.Server is

   use Modbus.PDU;

   procedure Handle_Read_Holding
     (Request : PDU_T;
      Reply   : out PDU_T);

   procedure Handle_Write_Single
     (Request : PDU_T;
      Reply   : out PDU_T);

   procedure Handle_Write_Multiple
     (Request : PDU_T;
      Reply   : out PDU_T);

   ------------
   -- Handle --
   ------------

   procedure Handle (Request : PDU_T; Reply : out PDU_T) is
   begin
      if Request.Length = 0 then
         --  No function code at all, so there is nothing to echo back
         Encode_Exception (Reply, 0, Illegal_Function);
      else
         declare
            FC : constant Byte := Function_Byte (Request);
         begin
            if not Is_Known (FC) then
               Encode_Exception (Reply, FC, Illegal_Function);
            else
               case To_Function (FC) is
                  when Read_Holding_Registers =>
                     Handle_Read_Holding (Request, Reply);
                  when Write_Single_Register =>
                     Handle_Write_Single (Request, Reply);
                  when Write_Multiple_Registers =>
                     Handle_Write_Multiple (Request, Reply);
                  when others =>
                     Encode_Exception (Reply, FC, Illegal_Function);
               end case;
            end if;
         end;
      end if;
   end Handle;

   -------------------------
   -- Handle_Read_Holding --
   -------------------------

   procedure Handle_Read_Holding
     (Request : PDU_T;
      Reply   : out PDU_T)
   is
      FC     : constant Byte := Function_Byte (Request);
      Start  : Address;
      Count  : Read_Registers_Quantity;
      Result : Result_Code;
      Item   : Word;
   begin
      Decode_Read_Registers (Request, Start, Count, Result);
      if Result /= Success then
         Encode_Exception (Reply, FC, Exception_Code (Result));
         return;
      end if;

      Begin_Read_Reply (Reply, FC, Count);
      for I in 1 .. Count loop
         Result := Read_Holding (Start + Address (I - 1), Item);
         if Result /= Success then
            Encode_Exception (Reply, FC, Exception_Code (Result));
            return;
         end if;
         Set_Register (Reply, I, Item);
      end loop;
   end Handle_Read_Holding;

   -------------------------
   -- Handle_Write_Single --
   -------------------------

   procedure Handle_Write_Single
     (Request : PDU_T;
      Reply   : out PDU_T)
   is
      FC     : constant Byte := Function_Byte (Request);
      Target : Address;
      Value  : Word;
      Result : Result_Code;
   begin
      Decode_Write_Single (Request, Target, Value, Result);
      if Result = Success then
         Result := Write_Holding (Target, Value);
      end if;

      if Result = Success then
         Encode_Write_Single_Reply (Reply, Target, Value);
      else
         Encode_Exception (Reply, FC, Exception_Code (Result));
      end if;
   end Handle_Write_Single;

   ---------------------------
   -- Handle_Write_Multiple --
   ---------------------------

   procedure Handle_Write_Multiple
     (Request : PDU_T;
      Reply   : out PDU_T)
   is
      FC     : constant Byte := Function_Byte (Request);
      Start  : Address;
      Count  : Write_Registers_Quantity;
      Result : Result_Code;
   begin
      Decode_Write_Multiple (Request, Start, Count, Result);
      if Result = Success then
         for I in 1 .. Count loop
            declare
               A : constant Address := Start + Address (I - 1);
               V : constant Word    := Write_Value (Request, I);
            begin
               Result := Write_Holding (A, V);
            end;
            exit when Result /= Success;
         end loop;
      end if;

      if Result = Success then
         Encode_Write_Multiple_Reply (Reply, Start, Count);
      else
         Encode_Exception (Reply, FC, Exception_Code (Result));
      end if;
   end Handle_Write_Multiple;

end Modbus.Server;
