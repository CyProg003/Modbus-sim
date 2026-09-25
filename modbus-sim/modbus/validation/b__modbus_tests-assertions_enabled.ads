pragma Warnings (Off);
pragma Ada_95;
with System;
with System.Parameters;
with System.Secondary_Stack;
package ada_main is

   gnat_argc : Integer;
   gnat_argv : System.Address;
   gnat_envp : System.Address;

   pragma Import (C, gnat_argc);
   pragma Import (C, gnat_argv);
   pragma Import (C, gnat_envp);

   gnat_exit_status : Integer;
   pragma Import (C, gnat_exit_status);

   GNAT_Version : constant String :=
                    "GNAT Version: 16.1.0" & ASCII.NUL;
   pragma Export (C, GNAT_Version, "__gnat_version");

   GNAT_Version_Address : constant System.Address := GNAT_Version'Address;
   pragma Export (C, GNAT_Version_Address, "__gnat_version_address");

   Ada_Main_Program_Name : constant String := "_ada_modbus_tests__assertions_enabled" & ASCII.NUL;
   pragma Export (C, Ada_Main_Program_Name, "__gnat_ada_main_program_name");

   procedure adainit;
   pragma Export (C, adainit, "adainit");

   procedure adafinal;
   pragma Export (C, adafinal, "adafinal");

   function main
     (argc : Integer;
      argv : System.Address;
      envp : System.Address)
      return Integer;
   pragma Export (C, main, "main");

   type Version_32 is mod 2 ** 32;
   u00001 : constant Version_32 := 16#a968aa5c#;
   pragma Export (C, u00001, "modbus_tests__assertions_enabledB");
   u00002 : constant Version_32 := 16#b2cfab41#;
   pragma Export (C, u00002, "system__standard_libraryB");
   u00003 : constant Version_32 := 16#f0b96e04#;
   pragma Export (C, u00003, "system__standard_libraryS");
   u00004 : constant Version_32 := 16#04356d51#;
   pragma Export (C, u00004, "ada__exceptionsB");
   u00005 : constant Version_32 := 16#677117e5#;
   pragma Export (C, u00005, "ada__exceptionsS");
   u00006 : constant Version_32 := 16#76789da1#;
   pragma Export (C, u00006, "adaS");
   u00007 : constant Version_32 := 16#85bf25f7#;
   pragma Export (C, u00007, "ada__exceptions__last_chance_handlerB");
   u00008 : constant Version_32 := 16#c1262c0b#;
   pragma Export (C, u00008, "ada__exceptions__last_chance_handlerS");
   u00009 : constant Version_32 := 16#e2b7c99d#;
   pragma Export (C, u00009, "systemS");
   u00010 : constant Version_32 := 16#7fa0a598#;
   pragma Export (C, u00010, "system__soft_linksB");
   u00011 : constant Version_32 := 16#c40bf0df#;
   pragma Export (C, u00011, "system__soft_linksS");
   u00012 : constant Version_32 := 16#33935a56#;
   pragma Export (C, u00012, "system__secondary_stackB");
   u00013 : constant Version_32 := 16#d845cfdc#;
   pragma Export (C, u00013, "system__secondary_stackS");
   u00014 : constant Version_32 := 16#3007a9ef#;
   pragma Export (C, u00014, "system__parametersB");
   u00015 : constant Version_32 := 16#431962c1#;
   pragma Export (C, u00015, "system__parametersS");
   u00016 : constant Version_32 := 16#2e691d75#;
   pragma Export (C, u00016, "system__storage_elementsS");
   u00017 : constant Version_32 := 16#0286ce9f#;
   pragma Export (C, u00017, "system__soft_links__initializeB");
   u00018 : constant Version_32 := 16#ac2e8b53#;
   pragma Export (C, u00018, "system__soft_links__initializeS");
   u00019 : constant Version_32 := 16#8599b27b#;
   pragma Export (C, u00019, "system__stack_checkingB");
   u00020 : constant Version_32 := 16#25e8dc8b#;
   pragma Export (C, u00020, "system__stack_checkingS");
   u00021 : constant Version_32 := 16#45e1965e#;
   pragma Export (C, u00021, "system__exception_tableB");
   u00022 : constant Version_32 := 16#6f9cbf84#;
   pragma Export (C, u00022, "system__exception_tableS");
   u00023 : constant Version_32 := 16#d01276af#;
   pragma Export (C, u00023, "system__exceptionsS");
   u00024 : constant Version_32 := 16#c367aa24#;
   pragma Export (C, u00024, "system__exceptions__machineB");
   u00025 : constant Version_32 := 16#8d1d496c#;
   pragma Export (C, u00025, "system__exceptions__machineS");
   u00026 : constant Version_32 := 16#2f7ce883#;
   pragma Export (C, u00026, "system__exceptions_debugB");
   u00027 : constant Version_32 := 16#d2b991ce#;
   pragma Export (C, u00027, "system__exceptions_debugS");
   u00028 : constant Version_32 := 16#7597daaf#;
   pragma Export (C, u00028, "system__img_intS");
   u00029 : constant Version_32 := 16#5c7d9c20#;
   pragma Export (C, u00029, "system__tracebackB");
   u00030 : constant Version_32 := 16#642d3d20#;
   pragma Export (C, u00030, "system__tracebackS");
   u00031 : constant Version_32 := 16#5f6b6486#;
   pragma Export (C, u00031, "system__traceback_entriesB");
   u00032 : constant Version_32 := 16#2aab7611#;
   pragma Export (C, u00032, "system__traceback_entriesS");
   u00033 : constant Version_32 := 16#61e81064#;
   pragma Export (C, u00033, "system__traceback__symbolicB");
   u00034 : constant Version_32 := 16#3e2e1203#;
   pragma Export (C, u00034, "system__traceback__symbolicS");
   u00035 : constant Version_32 := 16#179d7d28#;
   pragma Export (C, u00035, "ada__containersS");
   u00036 : constant Version_32 := 16#701f9d88#;
   pragma Export (C, u00036, "ada__exceptions__tracebackB");
   u00037 : constant Version_32 := 16#47e3d2a3#;
   pragma Export (C, u00037, "ada__exceptions__tracebackS");
   u00038 : constant Version_32 := 16#9111f9c1#;
   pragma Export (C, u00038, "interfacesS");
   u00039 : constant Version_32 := 16#b9ada65a#;
   pragma Export (C, u00039, "interfaces__cB");
   u00040 : constant Version_32 := 16#09d5a0e7#;
   pragma Export (C, u00040, "interfaces__cS");
   u00041 : constant Version_32 := 16#0978786d#;
   pragma Export (C, u00041, "system__bounded_stringsB");
   u00042 : constant Version_32 := 16#954ae884#;
   pragma Export (C, u00042, "system__bounded_stringsS");
   u00043 : constant Version_32 := 16#22b1fb99#;
   pragma Export (C, u00043, "system__crtlB");
   u00044 : constant Version_32 := 16#c12207f7#;
   pragma Export (C, u00044, "system__crtlS");
   u00045 : constant Version_32 := 16#71c7401b#;
   pragma Export (C, u00045, "system__dwarf_linesB");
   u00046 : constant Version_32 := 16#029d32b0#;
   pragma Export (C, u00046, "system__dwarf_linesS");
   u00047 : constant Version_32 := 16#5b4659fa#;
   pragma Export (C, u00047, "ada__charactersS");
   u00048 : constant Version_32 := 16#75913d83#;
   pragma Export (C, u00048, "ada__characters__handlingB");
   u00049 : constant Version_32 := 16#729cc5db#;
   pragma Export (C, u00049, "ada__characters__handlingS");
   u00050 : constant Version_32 := 16#cde9ea2d#;
   pragma Export (C, u00050, "ada__characters__latin_1S");
   u00051 : constant Version_32 := 16#e6d4fa36#;
   pragma Export (C, u00051, "ada__stringsS");
   u00052 : constant Version_32 := 16#9a8aed35#;
   pragma Export (C, u00052, "ada__strings__mapsB");
   u00053 : constant Version_32 := 16#879d83f1#;
   pragma Export (C, u00053, "ada__strings__mapsS");
   u00054 : constant Version_32 := 16#d55f7fbe#;
   pragma Export (C, u00054, "system__bit_opsB");
   u00055 : constant Version_32 := 16#2f4465a1#;
   pragma Export (C, u00055, "system__bit_opsS");
   u00056 : constant Version_32 := 16#189db6c4#;
   pragma Export (C, u00056, "system__unsigned_typesS");
   u00057 : constant Version_32 := 16#5c2ece6d#;
   pragma Export (C, u00057, "ada__strings__maps__constantsS");
   u00058 : constant Version_32 := 16#f9910acc#;
   pragma Export (C, u00058, "system__address_imageB");
   u00059 : constant Version_32 := 16#435b54a7#;
   pragma Export (C, u00059, "system__address_imageS");
   u00060 : constant Version_32 := 16#d7092338#;
   pragma Export (C, u00060, "system__img_address_32S");
   u00061 : constant Version_32 := 16#fa2982ba#;
   pragma Export (C, u00061, "system__img_address_64S");
   u00062 : constant Version_32 := 16#b9ea0573#;
   pragma Export (C, u00062, "system__img_unsS");
   u00063 : constant Version_32 := 16#20ec7aa3#;
   pragma Export (C, u00063, "system__ioB");
   u00064 : constant Version_32 := 16#7cf53ed2#;
   pragma Export (C, u00064, "system__ioS");
   u00065 : constant Version_32 := 16#e15ca368#;
   pragma Export (C, u00065, "system__mmapB");
   u00066 : constant Version_32 := 16#5d1b9a97#;
   pragma Export (C, u00066, "system__mmapS");
   u00067 : constant Version_32 := 16#367911c4#;
   pragma Export (C, u00067, "ada__io_exceptionsS");
   u00068 : constant Version_32 := 16#193b6ddb#;
   pragma Export (C, u00068, "system__mmap__os_interfaceB");
   u00069 : constant Version_32 := 16#f34495e5#;
   pragma Export (C, u00069, "system__mmap__os_interfaceS");
   u00070 : constant Version_32 := 16#7d07d9b0#;
   pragma Export (C, u00070, "system__mmap__unixS");
   u00071 : constant Version_32 := 16#861c956a#;
   pragma Export (C, u00071, "system__os_libB");
   u00072 : constant Version_32 := 16#dc62b743#;
   pragma Export (C, u00072, "system__os_libS");
   u00073 : constant Version_32 := 16#94d23d25#;
   pragma Export (C, u00073, "system__atomic_operations__test_and_setB");
   u00074 : constant Version_32 := 16#57acee8e#;
   pragma Export (C, u00074, "system__atomic_operations__test_and_setS");
   u00075 : constant Version_32 := 16#25d4b3b8#;
   pragma Export (C, u00075, "system__atomic_operationsS");
   u00076 : constant Version_32 := 16#553a519e#;
   pragma Export (C, u00076, "system__atomic_primitivesB");
   u00077 : constant Version_32 := 16#d8f6eff3#;
   pragma Export (C, u00077, "system__atomic_primitivesS");
   u00078 : constant Version_32 := 16#14fb286b#;
   pragma Export (C, u00078, "system__case_utilB");
   u00079 : constant Version_32 := 16#3c4f28f7#;
   pragma Export (C, u00079, "system__case_utilS");
   u00080 : constant Version_32 := 16#8b956324#;
   pragma Export (C, u00080, "system__case_util_nssB");
   u00081 : constant Version_32 := 16#87d84db7#;
   pragma Export (C, u00081, "system__case_util_nssS");
   u00082 : constant Version_32 := 16#256dbbe5#;
   pragma Export (C, u00082, "system__stringsB");
   u00083 : constant Version_32 := 16#7935c985#;
   pragma Export (C, u00083, "system__stringsS");
   u00084 : constant Version_32 := 16#8d759e14#;
   pragma Export (C, u00084, "system__object_readerB");
   u00085 : constant Version_32 := 16#ee235c84#;
   pragma Export (C, u00085, "system__object_readerS");
   u00086 : constant Version_32 := 16#b14bacb0#;
   pragma Export (C, u00086, "system__val_lliS");
   u00087 : constant Version_32 := 16#7d4c7c5b#;
   pragma Export (C, u00087, "system__val_lluS");
   u00088 : constant Version_32 := 16#0d1904b9#;
   pragma Export (C, u00088, "system__val_utilB");
   u00089 : constant Version_32 := 16#0e1c2bbe#;
   pragma Export (C, u00089, "system__val_utilS");
   u00090 : constant Version_32 := 16#382ef1e7#;
   pragma Export (C, u00090, "system__exception_tracesB");
   u00091 : constant Version_32 := 16#0e2fa0fb#;
   pragma Export (C, u00091, "system__exception_tracesS");
   u00092 : constant Version_32 := 16#fd158a37#;
   pragma Export (C, u00092, "system__wch_conB");
   u00093 : constant Version_32 := 16#3bb4eafe#;
   pragma Export (C, u00093, "system__wch_conS");
   u00094 : constant Version_32 := 16#5c289972#;
   pragma Export (C, u00094, "system__wch_stwB");
   u00095 : constant Version_32 := 16#16a5c6ff#;
   pragma Export (C, u00095, "system__wch_stwS");
   u00096 : constant Version_32 := 16#7cd63de5#;
   pragma Export (C, u00096, "system__wch_cnvB");
   u00097 : constant Version_32 := 16#3d74208e#;
   pragma Export (C, u00097, "system__wch_cnvS");
   u00098 : constant Version_32 := 16#e538de43#;
   pragma Export (C, u00098, "system__wch_jisB");
   u00099 : constant Version_32 := 16#88c342a4#;
   pragma Export (C, u00099, "system__wch_jisS");
   u00100 : constant Version_32 := 16#dc2e8af0#;
   pragma Export (C, u00100, "modbus_testsS");
   u00101 : constant Version_32 := 16#8b2c6428#;
   pragma Export (C, u00101, "ada__assertionsB");
   u00102 : constant Version_32 := 16#cc3ec2fd#;
   pragma Export (C, u00102, "ada__assertionsS");
   u00103 : constant Version_32 := 16#83571fa6#;
   pragma Export (C, u00103, "system__assertionsB");
   u00104 : constant Version_32 := 16#c4b4b606#;
   pragma Export (C, u00104, "system__assertionsS");
   u00105 : constant Version_32 := 16#a56a70fa#;
   pragma Export (C, u00105, "system__memoryB");
   u00106 : constant Version_32 := 16#fa235587#;
   pragma Export (C, u00106, "system__memoryS");

   --  BEGIN ELABORATION ORDER
   --  ada%s
   --  ada.characters%s
   --  ada.characters.latin_1%s
   --  interfaces%s
   --  system%s
   --  system.atomic_operations%s
   --  system.case_util_nss%s
   --  system.case_util_nss%b
   --  system.io%s
   --  system.io%b
   --  system.parameters%s
   --  system.parameters%b
   --  system.crtl%s
   --  system.crtl%b
   --  system.storage_elements%s
   --  system.img_address_32%s
   --  system.img_address_64%s
   --  system.stack_checking%s
   --  system.stack_checking%b
   --  system.strings%s
   --  system.strings%b
   --  system.traceback_entries%s
   --  system.traceback_entries%b
   --  system.unsigned_types%s
   --  system.wch_con%s
   --  system.wch_con%b
   --  system.wch_jis%s
   --  system.wch_jis%b
   --  system.wch_cnv%s
   --  system.wch_cnv%b
   --  system.img_int%s
   --  system.img_uns%s
   --  system.traceback%s
   --  system.traceback%b
   --  ada.characters.handling%s
   --  system.atomic_operations.test_and_set%s
   --  system.case_util%s
   --  system.os_lib%s
   --  system.secondary_stack%s
   --  system.standard_library%s
   --  ada.exceptions%s
   --  system.exceptions_debug%s
   --  system.exceptions_debug%b
   --  system.soft_links%s
   --  system.val_util%s
   --  system.val_util%b
   --  system.val_llu%s
   --  system.val_lli%s
   --  system.wch_stw%s
   --  system.wch_stw%b
   --  ada.exceptions.last_chance_handler%s
   --  ada.exceptions.last_chance_handler%b
   --  ada.exceptions.traceback%s
   --  ada.exceptions.traceback%b
   --  system.address_image%s
   --  system.address_image%b
   --  system.bit_ops%s
   --  system.bit_ops%b
   --  system.bounded_strings%s
   --  system.bounded_strings%b
   --  system.case_util%b
   --  system.exception_table%s
   --  system.exception_table%b
   --  ada.containers%s
   --  ada.io_exceptions%s
   --  ada.strings%s
   --  ada.strings.maps%s
   --  ada.strings.maps%b
   --  ada.strings.maps.constants%s
   --  interfaces.c%s
   --  interfaces.c%b
   --  system.atomic_primitives%s
   --  system.atomic_primitives%b
   --  system.exceptions%s
   --  system.exceptions.machine%s
   --  system.exceptions.machine%b
   --  ada.characters.handling%b
   --  system.atomic_operations.test_and_set%b
   --  system.exception_traces%s
   --  system.exception_traces%b
   --  system.memory%s
   --  system.memory%b
   --  system.mmap%s
   --  system.mmap.os_interface%s
   --  system.mmap%b
   --  system.mmap.unix%s
   --  system.mmap.os_interface%b
   --  system.object_reader%s
   --  system.object_reader%b
   --  system.dwarf_lines%s
   --  system.dwarf_lines%b
   --  system.os_lib%b
   --  system.secondary_stack%b
   --  system.soft_links.initialize%s
   --  system.soft_links.initialize%b
   --  system.soft_links%b
   --  system.standard_library%b
   --  system.traceback.symbolic%s
   --  system.traceback.symbolic%b
   --  ada.exceptions%b
   --  ada.assertions%s
   --  ada.assertions%b
   --  system.assertions%s
   --  system.assertions%b
   --  modbus_tests%s
   --  modbus_tests.assertions_enabled%b
   --  END ELABORATION ORDER

end ada_main;
