Aditya Patel: November 27, 2025


This project implements a hardware controller for a 16-bit RISC-style processor. The controller consists of:

Instruction Register (IR): Holds the current instruction being executed
Instruction Decoder: Decodes the instruction and generates appropriate control signals for the datapath

The design was synthesized and used to generate an APR (Automatic Place and Route) layout using industry-standard tools:

Cadence Virtuoso - For custom layout and verification
Synopsys Design Compiler - For synthesis and optimization

This controller serves as the brain of the processor, orchestrating all operations including ALU operations, memory access, branching, and register file management.

Project Structure
.
├── decoder.v           # Verilog RTL implementation of the controller
├── Machine_code.g1     # Machine code test vectors for all instructions
└── README.md          # This file


Hardware Features for the 16-bit processor:

16-bit instruction format with variable encoding
16 general-purpose registers (R0-R15)
Comprehensive instruction set including:

Arithmetic Logic Unit (ALU) operations: (ADD, SUB, AND, OR, XOR)
Immediate operations: (ADDI, SUBI, ANDI, ORI, XORI, MOVI)
Shift operations: (LSH, LSHI)
Memory operations: (LOAD, STOR)
Control flow: (BCOND, JCOND, JAL)
Data manipulation: (LUI, MOV, CMP)


Flag-based conditional execution (Zero, Negative, Overflow flags)
Scan chain support for design-for-testability (DFT)
Synchronous design with clock and reset management

Design Features

Combinational decoder logic for fast instruction decode
Sequential flag register updates
Pipeline-friendly design
Support for branch prediction and control hazards
Memory interface control (CEB, WEB signals)

┌─────────────────────────────┐
                    │                             │
  instruction[15:0] │                             │
         ────────────►   Instruction Register     │
                    │         (IR)                │
                    │                             │
                    └──────────────┬──────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────┐
                    │                             │
                    │    Instruction Decoder      │
                    │   (Combinational Logic)     │
                    │                             │
                    └──────────────┬──────────────┘
                                   │
           ┌───────────────────────┼───────────────────────┐
           │                       │                       │
           ▼                       ▼                       ▼
    ┌────────────┐         ┌────────────┐         ┌────────────┐
    │   ALU      │         │  Memory    │         │  Branch    │
    │  Control   │         │  Control   │         │  Control   │
    │  Signals   │         │  Signals   │         │  Signals   │
    └────────────┘         └────────────┘         └────────────┘


The controller generates control signals for:

Register File: Read/Write addresses and write enable
ALU: Operation select, carry-in, operand muxing
Shifter: Shift type and amount
Memory: Chip enable and write enable
Program Counter: Branch/Jump conditions and displacement


