# 8-bit Processor

This repository contains a Verilog implementation of a basic 8-bit processor based on the Harvard architecture. The processor has separate data and program memories, a register file, a stack, I/O ports, and a set of instructions for arithmetic, logic, and control operations.

## Features

- 8-bit data width
- Separate data and program memories
- 8 general-purpose registers
- A stack for subroutine calls and temporary storage
- A variety of instructions for arithmetic, logic, and control operations

## Verilog Module

The main Verilog module for the processor is `Processor`. The module has a single input, `clk`, which is the clock signal for the processor.

The processor's internal components include:

- Register file: 8 general-purpose registers
- Data memory: 256 bytes of data memory
- Program memory: 256 bytes of program memory
- Program counter: 8-bit program counter
- Temporary register: 8-bit temporary register
- Flag register: 8-bit flag register
- Stack: 31-byte stack
- I/O ports: 256 I/O ports

The processor's instruction set includes instructions for:

- Data movement (MOV, SWAP, PUSH, POP, etc.)
- Arithmetic operations (ADD, SUB, INC, DEC, etc.)
- Logic operations (AND, OR, XOR, NOT, etc.)
- Control flow (JP, CALL, RET, etc.)

## Usage

To use the processor, instantiate the `Processor` module in your Verilog design and connect the `clk` input to your clock signal. You will need to initialize the register file, data memory, program memory, and I/O ports with appropriate values.

The processor will execute instructions from the program memory based on the program counter. You can write your program in assembly language and convert it to machine code for loading into the program memory.

## Example Program

An example program is provided in the `Processor.v` file. This program demonstrates various instructions and their usage. You can use this program as a starting point for your own programs.

## License

This project is licensed under the MIT License - see the `LICENSE` file for details.
