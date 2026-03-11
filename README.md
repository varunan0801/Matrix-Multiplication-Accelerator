# Systolic Matrix Multiplication Accelerator (Verilog)

## Overview
This project implements a **matrix multiplication accelerator using a systolic array architecture** in **Verilog HDL**.

The design is built using a grid of **processing elements (PEs)** that perform **multiply–accumulate (MAC) operations**. Data flows rhythmically through the array, allowing multiple partial products to be computed in parallel.

## Architecture

### Processing Element (PE)
Each processing element performs a **multiply-accumulate operation**:

C = C + (A × B)

Each PE:
- Receives elements of matrix **A** from the left
- Receives elements of matrix **B** from the top
- Multiplies the inputs
- Accumulates the result
- Passes data to neighboring PEs

### Systolic Array
The PEs are arranged in a **2D processing array** where:
- Matrix **A values propagate horizontally**
- Matrix **B values propagate vertically**
- Partial sums accumulate locally in each PE

This architecture enables **high parallelism and efficient data reuse**, making it well suited for hardware acceleration.

## Implementation
- Written in **Verilog HDL**
- Modular **processing element design**
- 2D **systolic processing array**
- Multiply–accumulate datapath

## Purpose
The project demonstrates how **matrix multiplication can be accelerated in hardware using systolic architectures**, which are widely used in **AI accelerators, GPUs, and tensor processors**.
