# Systolic Matrix Multiplication Accelerator (Verilog)

## Overview
This project implements a **matrix multiplication accelerator using a systolic array architecture** in **Verilog HDL**.

The design consists of a grid of **processing elements (PEs)** that perform **multiply–accumulate (MAC) operations** while data flows through the array in a pipelined manner.

## Processing Element (PE)

Each processing element performs a **multiply–accumulate operation**:

C = C + (A × B)

Each PE:
- Receives matrix **A** values from the left
- Receives matrix **B** values from the top
- Multiplies the inputs
- Accumulates the result locally
- Forwards A to the right and B downward

## Systolic Processing Array

The processing elements are arranged in a **2D grid** where:

- **A matrix elements propagate horizontally**
- **B matrix elements propagate vertically**
- **Partial sums accumulate inside each PE**

This allows multiple partial products to be computed **simultaneously**, improving throughput.

## Input Buffering

To ensure correct alignment of operands inside the systolic array, the input streams are **staggered using buffering**.

Rows of matrix **A** and columns of matrix **B** are delayed before entering the array so that the correct operands arrive at each processing element at the same clock cycle.

This buffering ensures that:
- Each PE receives the appropriate pair \(A_{ik}\) and \(B_{kj}\)
- Multiply–accumulate operations occur in the correct sequence
- Data flows through the array in a synchronized pipeline

## Implementation
- Written in **Verilog HDL**
- Modular **processing element design**
- **2D systolic processing array**
- **Buffered input streams for proper data alignment**
