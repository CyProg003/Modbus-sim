pragma Warnings (Off);
pragma Ada_95;
pragma Source_File_Name (ada_main, Spec_File_Name => "b__modbus_tests-assertions_enabled.ads");
pragma Source_File_Name (ada_main, Body_File_Name => "b__modbus_tests-assertions_enabled.adb");
pragma Suppress (Overflow_Check);

package body ada_main is

   E072 : Short_Integer; pragma Import (Ada, E072, "system__os_lib_E");
   E005 : Short_Integer; pragma Import (Ada, E005, "ada__exceptions_E");
   E011 : Short_Integer; pragma Import (Ada, E011, "system__soft_links_E");
   E022 : Short_Integer; pragma Import (Ada, E022, "system__exception_table_E");
   E035 : Short_Integer; pragma Import (Ada, E035, "ada__containers_E");
   E067 : Short_Integer; pragma Import (Ada, E067, "ada__io_exceptions_E");
   E051 : Short_Integer; pragma Import (Ada, E051, "ada__strings_E");
   E053 : Short_Integer; pragma Import (Ada, E053, "ada__strings__maps_E");
   E057 : Short_Integer; pragma Import (Ada, E057, "ada__strings__maps__constants_E");
   E040 : Short_Integer; pragma Import (Ada, E040, "interfaces__c_E");
   E023 : Short_Integer; pragma Import (Ada, E023, "system__exceptions_E");
   E085 : Short_Integer; pragma Import (Ada, E085, "system__object_reader_E");
   E046 : Short_Integer; pragma Import (Ada, E046, "system__dwarf_lines_E");
   E018 : Short_Integer; pragma Import (Ada, E018, "system__soft_links__initialize_E");
   E034 : Short_Integer; pragma Import (Ada, E034, "system__traceback__symbolic_E");
   E102 : Short_Integer; pragma Import (Ada, E102, "ada__assertions_E");

   Sec_Default_Sized_Stacks : array (1 .. 1) of aliased System.Secondary_Stack.SS_Stack (System.Parameters.Runtime_Default_Sec_Stack_Size);

   Local_Priority_Specific_Dispatching : constant String := "";
   Local_Interrupt_States : constant String := "";

   Is_Elaborated : Boolean := False;

   procedure adafinal is
      procedure s_stalib_adafinal;
      pragma Import (Ada, s_stalib_adafinal, "system__standard_library__adafinal");

      procedure Runtime_Finalize;
      pragma Import (C, Runtime_Finalize, "__gnat_runtime_finalize");

   begin
      if not Is_Elaborated then
         return;
      end if;
      Is_Elaborated := False;
      Runtime_Finalize;
      s_stalib_adafinal;
   end adafinal;

   type No_Param_Proc is access procedure;
   pragma Favor_Top_Level (No_Param_Proc);

   procedure adainit is
      Main_Priority : Integer;
      pragma Import (C, Main_Priority, "__gl_main_priority");
      Time_Slice_Value : Integer;
      pragma Import (C, Time_Slice_Value, "__gl_time_slice_val");
      WC_Encoding : Character;
      pragma Import (C, WC_Encoding, "__gl_wc_encoding");
      Locking_Policy : Character;
      pragma Import (C, Locking_Policy, "__gl_locking_policy");
      Queuing_Policy : Character;
      pragma Import (C, Queuing_Policy, "__gl_queuing_policy");
      Task_Dispatching_Policy : Character;
      pragma Import (C, Task_Dispatching_Policy, "__gl_task_dispatching_policy");
      Priority_Specific_Dispatching : System.Address;
      pragma Import (C, Priority_Specific_Dispatching, "__gl_priority_specific_dispatching");
      Num_Specific_Dispatching : Integer;
      pragma Import (C, Num_Specific_Dispatching, "__gl_num_specific_dispatching");
      Main_CPU : Integer;
      pragma Import (C, Main_CPU, "__gl_main_cpu");
      Interrupt_States : System.Address;
      pragma Import (C, Interrupt_States, "__gl_interrupt_states");
      Num_Interrupt_States : Integer;
      pragma Import (C, Num_Interrupt_States, "__gl_num_interrupt_states");
      Unreserve_All_Interrupts : Integer;
      pragma Import (C, Unreserve_All_Interrupts, "__gl_unreserve_all_interrupts");
      Exception_Tracebacks : Integer;
      pragma Import (C, Exception_Tracebacks, "__gl_exception_tracebacks");
      Exception_Tracebacks_Symbolic : Integer;
      pragma Import (C, Exception_Tracebacks_Symbolic, "__gl_exception_tracebacks_symbolic");
      Detect_Blocking : Integer;
      pragma Import (C, Detect_Blocking, "__gl_detect_blocking");
      Default_Stack_Size : Integer;
      pragma Import (C, Default_Stack_Size, "__gl_default_stack_size");
      Default_Secondary_Stack_Size : System.Parameters.Size_Type;
      pragma Import (C, Default_Secondary_Stack_Size, "__gnat_default_ss_size");
      Bind_Env_Addr : System.Address;
      pragma Import (C, Bind_Env_Addr, "__gl_bind_env_addr");
      Interrupts_Default_To_System : Integer;
      pragma Import (C, Interrupts_Default_To_System, "__gl_interrupts_default_to_system");

      procedure Runtime_Initialize (Install_Handler : Integer);
      pragma Import (C, Runtime_Initialize, "__gnat_runtime_initialize");

      Finalize_Library_Objects : No_Param_Proc;
      pragma Import (C, Finalize_Library_Objects, "__gnat_finalize_library_objects");
      Binder_Sec_Stacks_Count : Natural;
      pragma Import (Ada, Binder_Sec_Stacks_Count, "__gnat_binder_ss_count");
      Default_Sized_SS_Pool : System.Address;
      pragma Import (Ada, Default_Sized_SS_Pool, "__gnat_default_ss_pool");

   begin
      if Is_Elaborated then
         return;
      end if;
      Is_Elaborated := True;
      Main_Priority := -1;
      Time_Slice_Value := -1;
      WC_Encoding := '8';
      Locking_Policy := ' ';
      Queuing_Policy := ' ';
      Task_Dispatching_Policy := ' ';
      Priority_Specific_Dispatching :=
        Local_Priority_Specific_Dispatching'Address;
      Num_Specific_Dispatching := 0;
      Main_CPU := -1;
      Interrupt_States := Local_Interrupt_States'Address;
      Num_Interrupt_States := 0;
      Unreserve_All_Interrupts := 0;
      Exception_Tracebacks := 1;
      Exception_Tracebacks_Symbolic := 1;
      Detect_Blocking := 0;
      Default_Stack_Size := -1;

      ada_main'Elab_Body;
      Default_Secondary_Stack_Size := System.Parameters.Runtime_Default_Sec_Stack_Size;
      Binder_Sec_Stacks_Count := 1;
      Default_Sized_SS_Pool := Sec_Default_Sized_Stacks'Address;

      Runtime_Initialize (1);

      Finalize_Library_Objects := null;

      Ada.Exceptions'Elab_Spec;
      System.Soft_Links'Elab_Spec;
      System.Exception_Table'Elab_Body;
      E022 := E022 + 1;
      Ada.Containers'Elab_Spec;
      E035 := E035 + 1;
      Ada.Io_Exceptions'Elab_Spec;
      E067 := E067 + 1;
      Ada.Strings'Elab_Spec;
      E051 := E051 + 1;
      Ada.Strings.Maps'Elab_Spec;
      E053 := E053 + 1;
      Ada.Strings.Maps.Constants'Elab_Spec;
      E057 := E057 + 1;
      Interfaces.C'Elab_Spec;
      E040 := E040 + 1;
      System.Exceptions'Elab_Spec;
      E023 := E023 + 1;
      System.Object_Reader'Elab_Spec;
      E085 := E085 + 1;
      System.Dwarf_Lines'Elab_Spec;
      E046 := E046 + 1;
      System.Os_Lib'Elab_Body;
      E072 := E072 + 1;
      System.Soft_Links.Initialize'Elab_Body;
      E018 := E018 + 1;
      E011 := E011 + 1;
      System.Traceback.Symbolic'Elab_Body;
      E034 := E034 + 1;
      E005 := E005 + 1;
      Ada.Assertions'Elab_Spec;
      E102 := E102 + 1;
   end adainit;

   procedure Ada_Main_Program;
   pragma Import (Ada, Ada_Main_Program, "_ada_modbus_tests__assertions_enabled");

   function main
     (argc : Integer;
      argv : System.Address;
      envp : System.Address)
      return Integer
   is
      procedure Initialize (Addr : System.Address);
      pragma Import (C, Initialize, "__gnat_initialize");

      procedure Finalize;
      pragma Import (C, Finalize, "__gnat_finalize");
      SEH : aliased array (1 .. 2) of Integer;

      Ensure_Reference : aliased System.Address := Ada_Main_Program_Name'Address;
      pragma Volatile (Ensure_Reference);

   begin
      if gnat_argc = 0 then
         gnat_argc := argc;
         gnat_argv := argv;
      end if;
      gnat_envp := envp;

      Initialize (SEH'Address);
      adainit;
      Ada_Main_Program;
      adafinal;
      Finalize;
      return (gnat_exit_status);
   end;

--  BEGIN Object file/option list
   --   /home/ohenley/capstones_2026_2027/FIU/modbus-sim/modbus/obj/validation/modbus_tests.o
   --   /home/ohenley/capstones_2026_2027/FIU/modbus-sim/modbus/obj/validation/modbus_tests-assertions_enabled.o
   --   -L/home/ohenley/capstones_2026_2027/FIU/modbus-sim/modbus/obj/validation/
   --   -L/home/ohenley/capstones_2026_2027/FIU/modbus-sim/modbus/obj/validation/
   --   -L/home/ohenley/capstones_2026_2027/FIU/modbus-sim/modbus/lib/
   --   -L/home/ohenley/.local/share/alire/toolchains/gnat_native_16.1.0_9f74f58a/lib/gcc/x86_64-pc-linux-gnu/16.1.0/adalib/
   --   -static
   --   -lgnat
   --   -ldl
--  END Object file/option list   

end ada_main;
