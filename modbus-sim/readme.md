# MODBUS-SIM



## Claude dump

# Modbus, from zero to an Ada slave simulator

These notes explain the Modbus protocol in plain terms, then walk through the design of a small Modbus slave (device simulator) written in Ada. The simulator runs on a PC first and moves to real hardware later without rewriting the protocol code.

---

## Part 1: What Modbus is

### The one-sentence version

Modbus lets one device read and write another device's registers over a wire. If you have ever read a sensor register over I2C, you already understand most of it. Modbus is the same idea, made to work over long cables or a network.

### Who talks

- **Master** (newer name: client): the only device allowed to start a conversation.
- **Slave** (newer name: server): answers only when asked. It never speaks first.

This is strict request/response. There are no interrupts and no events. If the master wants to know whether something changed, it has to poll.

---

## Part 2: The data model

Every slave exposes **four separate tables**. Each table has addresses 0 to 65535.

| Table | Size of one entry | Access | Typical use |
|---|---|---|---|
| Coils | 1 bit | read/write | relay outputs, enables |
| Discrete inputs | 1 bit | read only | switches, limit sensors |
| Input registers | 16 bits | read only | measurements |
| Holding registers | 16 bits | read/write | setpoints, configuration |

The table is really a 2×2 grid:

| | read only | read/write |
|---|---|---|
| **1 bit** | discrete input | coil |
| **16 bits** | input register | holding register |

That is the whole data model. There are no types, no names, and no floats. A register is just 16 bits, and the device's manual tells you what each one means.

### Why "coil"?

"Coil" is not an example. It is the official name of that table in the specification, and all four names above are official.

The name comes from where Modbus was born. In 1979, Modicon made PLCs (the industrial controllers that replaced cabinets full of electromechanical relays). Their programming style, ladder logic, was designed to look like relay wiring diagrams. In a relay, you drive current through a **coil**, the coil becomes a magnet, and the magnet pulls a switch closed. So "energize coil 5" meant "turn output 5 on", and the name stuck.

In modern terms:

- **Coil** = a 1-bit output the master can read and write. It might drive a real relay, or it might just be a software flag like "pump enable" or "reset alarm".
- **Discrete input** = a 1-bit input the master can only read, like a button or limit switch.
- **Input register** = a 16-bit value the master can only read, like a temperature reading.
- **Holding register** = a 16-bit value the master can read and write, like a setpoint. It is called "holding" because it holds whatever you last wrote to it.

---

## Part 3: Function codes and errors

Each request starts with a one-byte **function code** that says what the master wants:

| Code | Action |
|---|---|
| 0x01 | read coils |
| 0x02 | read discrete inputs |
| 0x03 | read holding registers |
| 0x04 | read input registers |
| 0x05 | write single coil (value `FF00` = on, `0000` = off) |
| 0x06 | write single holding register |
| 0x0F | write multiple coils |
| 0x10 | write multiple holding registers |

**Errors.** If the slave refuses a request, it replies with the same function code with its top bit set (`0x03` becomes `0x83`), followed by an exception code:

| Exception code | Meaning |
|---|---|
| 01 | illegal function (function code not supported) |
| 02 | illegal data address (address out of range) |
| 03 | illegal data value (bad quantity or value) |
| 04 | server device failure |

---

## Part 4: Messages and transports

### The core message (PDU)

Every request and reply has the same shape, called the **PDU** (Protocol Data Unit):

```
[function code : 1 byte][data : 0..252 bytes]
```

The same PDU is wrapped differently depending on the transport. The wrapped version is called the **ADU** (Application Data Unit). There are three transports.

### 1. Modbus RTU (serial, usually RS-485)

The most common one in industrial equipment. It is binary. The frame looks like this:

```
[slave addr : 1][PDU][CRC-16 : 2, low byte first]
```

- **Slave address**: 1 to 247. Address 0 means broadcast: every slave executes the request and none of them replies.
- **CRC**: Modbus CRC-16 (reflected polynomial `0xA001`, initial value `0xFFFF`). Unlike everything else in Modbus, it is sent low byte first.
- **Framing is done by silence.** There is no start byte and no length field. A frame ends when the line stays idle for **3.5 character times**. A gap longer than 1.5 character times inside a frame means the frame is broken. Above 19200 baud, the spec fixes these gaps at 1.75 ms and 750 µs.
- **Consequence for firmware.** You detect the end of a frame with a UART idle timer, not by parsing. On half-duplex RS-485 you also have to release the DE/RE (driver enable) pin at the right moment: after the last byte leaves the shift register, not when it leaves the FIFO. Many "Modbus doesn't work" bugs live right there.
- Maximum frame size: 256 bytes (1 address + 253 PDU + 2 CRC).

### 2. Modbus ASCII

Same idea, but every byte is sent as two hex characters. Frames start with `:` and end with CR LF, and use an LRC checksum instead of a CRC. The LRC is simple: add up the bytes, keep 8 bits, and negate. It is rare today.

### 3. Modbus TCP

Uses TCP port 502. There is no CRC, because TCP already guarantees delivery. It adds a 7-byte header called **MBAP**:

```
[transaction id : 2][protocol id : 2 = 0][length : 2][unit id : 1][PDU]
```

- **Transaction id**: the master picks a number, and the slave echoes it back so replies can be matched to requests.
- **Protocol id**: always 0 for Modbus.
- **Length**: the number of bytes that follow the length field, counting the unit id.
- **Unit id**: the old serial slave address. It matters when a TCP-to-RS485 gateway sits in front of several serial slaves. Otherwise it is usually `1` or `0xFF`.

---

## Part 5: Worked example

Read 3 holding registers, starting at address `0x006B`, from slave `0x11`.

**RTU request:**

```
11  03  00 6B  00 03  CC CC
|   |   |      |      +-- CRC (2 bytes, low byte first)
|   |   |      +--------- quantity = 3
|   |   +---------------- start address = 0x006B
|   +-------------------- function: read holding registers
+------------------------ slave 0x11
```

**RTU reply:**

```
11  03  06  AE 41  56 52  43 40  CC CC
        |   |      |      |
        |   reg0   reg1   reg2   (each big-endian)
        +-- byte count = 6
```

**The same request in ASCII:**

```
:1103006B00037E<CR><LF>
```

(LRC check: 0x11 + 0x03 + 0x00 + 0x6B + 0x00 + 0x03 = 0x82, and 0x100 - 0x82 = 0x7E.)

**The same request over TCP:**

```
00 01  00 00  00 06  11  03 00 6B 00 03
tx id  proto  len=6  uid PDU
```

---

## Part 6: Traps everyone hits

1. **Off-by-one addressing.** Manuals often say "register 40108". That is the old Modicon notation: the leading `4` means "holding register" and numbering starts at 1. The actual address on the wire is `107` (`0x006B`).
2. **32-bit values.** A 32-bit integer or float is spread across two registers. The spec does not say which register comes first. Vendors do both orders (called "ABCD" vs "CDAB"), and some swap bytes too. You find out from the manual or by experimenting.
3. **No security at all.** There is no authentication and no encryption. Anyone who can reach port 502 can write to your coils.
4. **No discovery.** You cannot ask a device what registers it has. The register map exists only in its manual.
5. **RS-485 electrical problems.** You need 120 Ω termination at both ends of the bus, bias resistors so the idle line reads a stable level, and a daisy-chain layout (not a star). A mistake here corrupts CRCs intermittently, and it looks like a software bug.

### Mental model to keep

Modbus is a remote peek/poke over four memory-mapped register banks. The protocol is mostly just which byte sits where. Everything meaningful (units, scaling, what a bit means) lives in the vendor's documentation, not in the protocol.

---

## Part 7: Building a slave simulator in Ada

The goal: a small simulated device that speaks Modbus. It runs on a PC first, then moves to a microcontroller with a UART link, reusing the same protocol code.

### Choosing where to start

Ranked from simplest to hardest:

**0. No transport at all.** Build just the PDU handler and feed it byte arrays in unit tests. There is no I/O, so you verify the core logic in isolation. Every other option builds on this, so do it first.

**1. Modbus ASCII over serial.** The simplest real wire: character framing, trivial checksum, and you can type frames by hand in a serial terminal. Downside: almost no real devices use it, so you learn a variant you will probably never ship.

**2. Modbus RTU over a virtual serial pair (recommended).** The real protocol, the one used on embedded devices, with no hardware needed. `socat` creates two linked virtual serial ports. The simulator opens one, and `mbpoll` (a command-line Modbus master) opens the other:

```
socat -d -d pty,raw,echo=0 pty,raw,echo=0      # prints /dev/pts/A and /dev/pts/B
mbpoll -m rtu -b 19200 -P none -a 1 -r 1 -c 2 /dev/pts/B
```

**3. Modbus TCP.** Also easy on a PC (no CRC, no timing), but it teaches nothing about serial framing, which is what the embedded version needs. Good as a later addition.

### Making RTU easy

**CRC-16** is about 15 lines:

```ada
function CRC16 (Data : Byte_Array) return Unsigned_16 is
   CRC : Unsigned_16 := 16#FFFF#;
begin
   for B of Data loop
      CRC := CRC xor Unsigned_16 (B);
      for I in 1 .. 8 loop
         if (CRC and 1) /= 0 then
            CRC := Shift_Right (CRC, 1) xor 16#A001#;
         else
            CRC := Shift_Right (CRC, 1);
         end if;
      end loop;
   end loop;
   return CRC;   --  send low byte first
end CRC16;
```

**Framing:** skip the 3.5-character silence timing and find the frame length from the function code instead. On a virtual port, timing gaps mean nothing anyway, and many real slaves do the same thing.

| Received so far | Then read |
|---|---|
| addr, FC `03` or `06` | 6 more bytes (4 data + 2 CRC) |
| addr, FC `10` | 5 more bytes (address, quantity, byte count N), then N + 2 |
| addr, unknown FC | length unknown: discard input until the line is idle for a short timeout, then resync |

That last row is the only place a timer is needed.

### Scope for version 1

- **Data:** a small array of 16-bit holding registers (say 16). No coils or input registers yet.
- **Functions:** `0x03` read holding registers, `0x06` write single register, `0x10` write multiple registers. Any other function code gets exception `01`. An out-of-range address gets exception `02`.
- **Fake device:** a thermostat.
  - Register 0 = temperature × 10, drifting toward the setpoint every tick.
  - Register 1 = setpoint, writable by the master.

Test it with `mbpoll`. Note that `mbpoll -r 1` means address 0 on the wire: `mbpoll` numbers registers from 1 by default. That is the off-by-one trap from Part 6, seen firsthand.

### Suggested path

1. PDU handler + unit tests.
2. RTU on a `socat` pair, with length-based framing.
3. Move to a USB-RS485 dongle, then to a microcontroller. The handler stays the same. Only the byte source and the DE/RE pin handling change.

---

## Part 8: Project structure

The design rule: **everything that does not touch hardware lives in a portable core with no I/O at all.** Hardware-specific code sits behind a small spec, and the build selects which body to compile per target. The same main logic runs on the PC against a virtual serial port, then on a board over a real UART.

### Layout

Two Alire crates: the protocol library and the application that uses it.

```
modbus-sim/
├── .vscode/
│   ├── settings.json            ada.projectFile -> sim/sim.gpr
│   └── tasks.json               alr build / alr run / run tests
│
├── modbus/                      CRATE 1: portable protocol, zero I/O
│   ├── alire.toml
│   ├── modbus.gpr
│   ├── src/
│   │   ├── modbus.ads                       base types (see Part 9)
│   │   ├── modbus-pdu.ads/.adb              decode/encode of request/reply fields
│   │   ├── modbus-server.ads/.adb           generic slave: PDU in -> PDU out
│   │   ├── modbus-rtu.ads                   RTU constants, slave address type
│   │   ├── modbus-rtu-crc.ads/.adb
│   │   └── modbus-rtu-framer.ads/.adb       byte-push state machine
│   └── tests/                               separate test crate, PC only
│       ├── alire.toml
│       └── src/  test_crc, test_framer, test_server (golden frames)
│
└── sim/                         CRATE 2: the simulated device
    ├── alire.toml               depends on modbus (pinned to ../modbus)
    ├── sim.gpr                  scenario TARGET := "pc" | "board"
    └── src/
        ├── common/              portable, compiled for every target
        │   ├── thermostat.ads/.adb          device physics, knows nothing about Modbus
        │   ├── register_map.ads/.adb        binds addresses to thermostat state,
        │   │                                instantiates Modbus.Server
        │   └── app.ads/.adb                 the main loop
        └── platform/
            ├── link.ads                     byte link spec (shared)
            ├── clock.ads                    monotonic time spec (shared)
            ├── pc/
            │   ├── link.adb                 GNAT.Serial_Communications on a pty
            │   ├── clock.adb                Ada.Real_Time
            │   └── main.adb                 parses argv (port path), calls App.Run
            └── board/
                ├── link.adb                 board HAL UART + DE/RE pin control
                ├── clock.adb                SysTick / hardware timer
                └── main.adb                 board init, calls App.Run
```

In `sim.gpr`, the target is selected like this:

```ada
Target := external ("TARGET", "pc");
for Source_Dirs use ("src/common", "src/platform", "src/platform/" & Target);
```

`link.ads` exists once, and each target provides its own `link.adb`. The swap happens at compile time, with no dispatching and no runtime cost.

### Rules for the `modbus` crate

These are what make it reusable on real hardware:

1. **No I/O**, meaning no sockets, files or Text_IO. It never calls out to anything.
2. **No heap and no tasking.** It must build under a light runtime. The crate does not pick a runtime; the application does.
3. **Time is passed in, never read.** The framer receives an `Idle` event from the caller. It never reads a clock itself.
4. **Protocol errors are values, not Ada exceptions.** They come back as an exception code inside the reply PDU.
5. **`SPARK_Mode => On` from day one.** Proving the absence of runtime errors on the framer and server is a realistic goal.

### The two key interfaces

**Framer.** It is push-based, one byte at a time. That fits a UART interrupt handler on a board and a blocking read on a PC equally well.

```ada
package Modbus.RTU.Framer is
   type State is private;
   type Event is (None, Frame_Ready, Frame_Bad);

   procedure Reset (F : out State);
   procedure Feed  (F : in out State; B : Byte; Result : out Event);
   procedure Idle  (F : in out State);                   --  resync after silence
   function  Slave   (F : State) return Slave_Address;   --  valid after Frame_Ready
   function  Request (F : State) return PDU;             --  valid after Frame_Ready
end Modbus.RTU.Framer;
```

**Server.** It is generic over the data model. The device provides storage through formal subprograms, so the handler never owns any data. Tables a device does not have can use default formals that return `Illegal_Data_Address`.

```ada
generic
   with function Read_Holding  (A : Address; V : out Word) return Result_Code;
   with function Write_Holding (A : Address; V : Word)     return Result_Code;
   --  coils, discrete inputs, input registers: added the same way later
package Modbus.Server is
   procedure Handle (Request : PDU; Reply : out PDU);
end Modbus.Server;
```

### The application loop

Identical on both targets. `App` orchestrates, and the core just transforms data.

```
loop
   if Link.Read (B) then Framer.Feed (B, Ev)
   elsif Clock.Idle_For (Gap) then Framer.Idle
   end if
   if Ev = Frame_Ready and Framer.Slave = My_Address then
      Server.Handle (Framer.Request, Reply)
      Link.Write (RTU.Encode (My_Address, Reply))   --  adds address + CRC
   end if
   Thermostat.Tick (Clock.Now)
end loop
```

### How it scales

| Future feature | What changes |
|---|---|
| Modbus TCP | new `modbus-tcp-mbap` package in core, plus a `pc/` link variant using sockets |
| Master role | new generic `modbus-client` in core; the framer is reused |
| More devices | new `common/` device package and register map; the core is untouched |
| New board | new `platform/<board>/` directory with 3 files |
| Several slaves on one bus | `App` checks several addresses, with one `Server` instance per device |

---

## Part 9: The base package `Modbus`

Only types that every other package needs go here: the raw wire units, the data model, function codes, and result codes. Anything specific to one transport stays out.

```ada
with Interfaces;

package Modbus
  with Pure, SPARK_Mode => On
is
   use type Interfaces.Unsigned_16;

   ---------------------
   --  Raw wire units --
   ---------------------

   subtype Byte is Interfaces.Unsigned_8;
   subtype Word is Interfaces.Unsigned_16;

   type Byte_Array is array (Positive range <>) of Byte;

   --  Big-endian: high byte goes on the wire first
   function High (W : Word) return Byte is (Byte (Interfaces.Shift_Right (W, 8)));
   function Low  (W : Word) return Byte is (Byte (W and 16#FF#));
   function To_Word (Hi, Lo : Byte) return Word is
     (Interfaces.Shift_Left (Word (Hi), 8) or Word (Lo));

   ---------
   -- PDU --
   ---------

   Max_PDU_Length : constant := 253;
   subtype PDU_Length is Natural range 0 .. Max_PDU_Length;

   type PDU is record
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

   Exception_Flag : constant Byte := 16#80#;   --  OR'ed into the FC of an error reply

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
```

### Why each choice

**`Byte` and `Word` are subtypes, not new types.** The CRC and the hardware layer already use `Interfaces` types, so a subtype avoids conversions at every boundary. Type safety comes from the next layer up, `Address` and `Quantity`, where mixing things up would actually be a bug.

**`PDU` is a record with a fixed buffer, not a function returning `Byte_Array`.** Returning an unconstrained array needs the secondary stack, which is fragile or unavailable on small runtimes. That is why `Server.Handle` is a procedure with an `out PDU` parameter.

**`Address` uses a range type, not `mod`.** A modular type would silently wrap `65535 + 1` to `0`. The spec says that case must produce `Illegal_Data_Address`. `Fits` checks it without needing a wider integer type.

**One quantity subtype per function.** The limits come from the spec: a reply must fit in 253 bytes. Decoding into these subtypes catches `Illegal_Data_Value` at the type level.

**`Function_Code` is an enumeration without a representation clause.** Raw bytes arrive from the wire and can hold anything. If the enum had a representation clause, converting a bad byte with `Unchecked_Conversion` would produce an invalid value with undefined behavior. Instead, the byte goes through `Is_Known` and then `To_Function`. SPARK proves the `Program_Error` branch cannot be reached, because of the precondition.

**`Exception_Code` is a subtype of `Result_Code`.** It is a single type. Data-model callbacks return `Result_Code`, and the server passes anything other than `Success` straight into an error reply, with no translation table.

### Kept out of the base package

| Item | Where it goes |
|---|---|
| Slave address (1..247, 0 = broadcast) | `Modbus.RTU`, because TCP uses a unit id instead |
| CRC, framer state, ADU size (256) | `Modbus.RTU.*` |
| MBAP header | future `Modbus.TCP` |
| Coil wire encoding (`FF00` / `0000`) | `Modbus.PDU`, used only by FC 05 |
| Register meanings | `sim/register_map`, which belongs to the device |

---

## Glossary

| Term | Meaning |
|---|---|
| ADU | Application Data Unit: the PDU plus the transport wrapper (address + CRC for RTU, MBAP header for TCP) |
| Broadcast | RTU request sent to address 0: all slaves execute it, none reply |
| Coil | 1-bit read/write table entry (name from relay coils) |
| CRC-16 | Checksum used by RTU; polynomial `0xA001` reflected, initial value `0xFFFF`, sent low byte first |
| DE/RE | Driver Enable / Receiver Enable pins of an RS-485 transceiver; control who drives the half-duplex bus |
| Discrete input | 1-bit read-only table entry |
| Exception code | Error number returned by a slave (01 to 04 in v1) |
| FC | Function code: first byte of every PDU, says what the request does |
| Holding register | 16-bit read/write table entry |
| Input register | 16-bit read-only table entry |
| LRC | Longitudinal Redundancy Check: the simple checksum used by Modbus ASCII |
| MBAP | Modbus Application Protocol header: the 7-byte header of Modbus TCP |
| Master / client | The device that sends requests |
| PDU | Protocol Data Unit: function code + data, identical across transports |
| RTU | Remote Terminal Unit: the binary serial variant of Modbus |
| Slave / server | The device that answers requests |
| Unit id | Last byte of the MBAP header; the slave address when a TCP gateway forwards to serial |