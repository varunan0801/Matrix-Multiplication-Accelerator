# Systolic Matrix Multiplication Accelerator (Verilog)

## NxN Systolic Array Matrix Multiplier

A parameterizable **N×N matrix multiplier** implemented in Verilog using a **systolic array** architecture. The design supports signed integers, is fully pipelined, and includes a self-checking testbench.

---

## Architecture Overview

The multiplier is built around a 2D array of **Processing Elements (PEs)** arranged in a systolic fashion. Each PE performs a Multiply-Accumulate (MAC) operation and passes data to its right and downward neighbours on every clock cycle.
              b[0]  b[1]  b[2]
                |     |     |
      a[0] --> PE -- PE -- PE
      |     |     |
      a[1] --> PE -- PE -- PE
      |     |     |
      a[2] --> PE -- PE -- PE

### Key Design Decisions

- **Skew buffer**: Input vectors `a` and `b` are diagonally skewed before entering the array so that the correct elements meet at each PE at the right time.
- **Overflow prevention**: The accumulator width is set to `2*DATA_WIDTH + ceil(log2(N))` bits, ensuring no overflow during the MAC accumulation.
- **`valid_out` signal**: After `3*N` clock cycles from the start of a computation, `valid_out` is asserted to indicate the result matrix `c_flat` is ready.
- **`clear` signal**: Resets all accumulators and the skew buffer between back-to-back multiplications without needing a full reset.

---

## File Structure

| File | Description |
|---|---|
| `pe.v` | Processing Element — performs MAC and passes data to neighbours |
| `NxN_multiplier.v` | Top-level module — instantiates the PE array and manages data skewing |
| `tb_NxN_multiplier.v` | Self-checking testbench with 5 test cases |

---

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `N` | `5` | Matrix dimension (N×N) |
| `DATA_WIDTH` | `16` | Bit width of each input element |
| `ACC_WIDTH` | `2*DATA_WIDTH + $clog2(N)` | Bit width of each output/accumulator element |

---

## I/O Ports

### `NxN_multiplier`

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk` | Input | 1 | Clock |
| `reset` | Input | 1 | Synchronous reset |
| `clear` | Input | 1 | Clears accumulators for next multiplication |
| `a_flat` | Input | `N*DATA_WIDTH` | Row-major flattened matrix A |
| `b_flat` | Input | `N*DATA_WIDTH` | Row-major flattened matrix B |
| `c_flat` | Output | `N*N*ACC_WIDTH` | Row-major flattened result matrix C = A×B |
| `valid_out` | Output | 1 | Asserted when `c_flat` holds a valid result |

> **Note:** Verilog does not support 2D arrays as ports, so all matrices are passed as flattened 1D buses.

### `pe` (Processing Element)

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk` | Input | 1 | Clock |
| `reset` | Input | 1 | Synchronous reset |
| `clear` | Input | 1 | Clears accumulator |
| `a_in` | Input | `DATA_WIDTH` | Data from the left |
| `b_in` | Input | `DATA_WIDTH` | Data from above |
| `a_out` | Output | `DATA_WIDTH` | Passes `a_in` to the right |
| `b_out` | Output | `DATA_WIDTH` | Passes `b_in` downward |
| `acc` | Output | `ACC_WIDTH` | Running accumulation result |

---

## Timing

The design has a latency of **`3*N` clock cycles** from when the first input column is presented to when `valid_out` is asserted.

For the default `N=5`, that is a 15-cycle latency.

### Drive Sequence (per multiplication)

1. Assert `clear` on a negedge; drive column 0 of A and row 0 of B.
2. Deassert `clear` on the next negedge; drive column 0 again (first real data latch).
3. Drive columns 1 through N-1 on each subsequent negedge.
4. Zero the inputs after the last column.
5. Wait for `valid_out` to be asserted — `c_flat` now holds C = A×B.

---

## Testbench

`tb_NxN_multiplier.v` tests a 3×3 instance (`N=3`, `DATA_WIDTH=16`) against a software golden reference with 5 test cases:

| Test | Description |
|---|---|
| 1 | A × Identity = A |
| 2 | General positive integers |
| 3 | Mixed negative integers |
| 4 | All-zeros matrices |
| 5 | Back-to-back multiplication (verifies `clear` behaviour) |
