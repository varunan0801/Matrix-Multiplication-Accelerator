`timescale 1ns / 1ps
module tb_NxN_multiplier;

  // ----------------------------------------------------------------
  // Parameters
  // ----------------------------------------------------------------
  parameter integer N          = 3;
  parameter integer DATA_WIDTH = 16;
  parameter integer ACC_WIDTH  = 2*DATA_WIDTH + $clog2(N);
  parameter integer CLK_PERIOD = 10;

  // ----------------------------------------------------------------
  // DUT signals
  // ----------------------------------------------------------------
  reg                             clk;
  reg                             reset;
  reg                             clear;
  reg  signed [N*DATA_WIDTH-1:0]  a_flat;
  reg  signed [N*DATA_WIDTH-1:0]  b_flat;
  wire signed [N*N*ACC_WIDTH-1:0] c_flat;
  wire                            valid_out;

  // debug unpacking
  wire signed [ACC_WIDTH-1:0] c_dbg [0:N-1][0:N-1];
  genvar l, m;
  generate
    for (l = 0; l < N; l = l + 1) begin
      for (m = 0; m < N; m = m + 1) begin
        assign c_dbg[l][m] = c_flat[(l*N+m+1)*ACC_WIDTH-1 -: ACC_WIDTH];
        end
      end
  endgenerate

  // ----------------------------------------------------------------
  // DUT instantiation
  // ----------------------------------------------------------------
  NxN_multiplier #(
    .N          (N),
    .DATA_WIDTH (DATA_WIDTH),
    .ACC_WIDTH  (ACC_WIDTH)
  ) dut (
    .clk       (clk),
    .reset     (reset),
    .clear     (clear),
    .a_flat    (a_flat),
    .b_flat    (b_flat),
    .c_flat    (c_flat),
    .valid_out (valid_out)
  );

  // ----------------------------------------------------------------
  // Clock
  // ----------------------------------------------------------------
  initial clk = 0;
  always #(CLK_PERIOD/2) clk = ~clk;

  // ----------------------------------------------------------------
  // Storage
  // ----------------------------------------------------------------
  reg signed [DATA_WIDTH-1:0] A_mat [0:N-1][0:N-1];
  reg signed [DATA_WIDTH-1:0] B_mat [0:N-1][0:N-1];
  reg signed [ACC_WIDTH-1:0]  C_exp [0:N-1][0:N-1];
  integer row, col, pass_count, fail_count;

  // ----------------------------------------------------------------
  // Task: golden reference
  // ----------------------------------------------------------------
  task compute_golden;
    integer r, c, kk;
    begin
      for (r = 0; r < N; r = r + 1)
        for (c = 0; c < N; c = c + 1) begin
          C_exp[r][c] = 0;
          for (kk = 0; kk < N; kk = kk + 1)
            C_exp[r][c] = C_exp[r][c] + A_mat[r][kk] * B_mat[kk][c];
        end
    end
  endtask

  // ----------------------------------------------------------------
  // Task: check and print PASS/FAIL
  // ----------------------------------------------------------------
  task check_result;
    input integer test_id;
    integer r, c;
    reg failed;
    begin
      failed = 0;
      for (r = 0; r < N; r = r + 1)
        for (c = 0; c < N; c = c + 1)
          if (c_dbg[r][c] !== C_exp[r][c]) begin
            $display("  FAIL test %0d: C[%0d][%0d] expected %0d got %0d",
                     test_id, r, c, C_exp[r][c], c_dbg[r][c]);
            failed = 1;
          end
      if (!failed) begin
        $display("  PASS test %0d", test_id);
        pass_count = pass_count + 1;
      end else
        fail_count = fail_count + 1;
    end
  endtask

  // ----------------------------------------------------------------
  // Task: drive column t of A and row t of B into flat inputs
  // ----------------------------------------------------------------
  task drive_col;
    input integer t;
    integer r, c;
    begin
      for (r = 0; r < N; r = r + 1)
        a_flat[(r+1)*DATA_WIDTH-1 -: DATA_WIDTH] = A_mat[r][t];
      for (c = 0; c < N; c = c + 1)
        b_flat[(c+1)*DATA_WIDTH-1 -: DATA_WIDTH] = B_mat[t][c];
    end
  endtask

  // ----------------------------------------------------------------
  // Task: run one full multiplication
  //
  // Timing (verified by simulation trace):
  //   negedge: assert clear AND drive col 0 simultaneously
  //   next posedge: DUT latches clear=1 - resets accumulators and skew buf
  //   next negedge: deassert clear, drive col 0 again (first real data)
  //   next posedge: DUT latches clear=0, latches col 0 into A_d[i][0]
  //   next negedge: drive col 1
  //   ... and so on for N columns total
  // ----------------------------------------------------------------
  task run_test;
    input integer test_id;
    integer t;
    begin
      // assert clear on negedge, drive col 0 at the same time
      @(negedge clk);
      clear = 1;
      drive_col(0);

      // deassert clear on next negedge, keep col 0 on inputs
      // this is the first cycle the skew buffer will latch real data
      @(negedge clk);
      clear = 0;
      drive_col(0);

      // drive col 1 .. N-1 on subsequent negedges
      for (t = 1; t < N; t = t + 1) begin
        @(negedge clk);
        drive_col(t);
      end

      // zero inputs after last column
      @(negedge clk);
      a_flat = 0;
      b_flat = 0;

      // wait for valid_out then settle
      @(posedge valid_out);
      @(negedge clk);

      compute_golden;
      check_result(test_id);
    end
  endtask

  // ----------------------------------------------------------------
  // Test sequence
  // ----------------------------------------------------------------
  initial begin
    $dumpfile("tb_NxN_multiplier.vcd");
    $dumpvars(0, tb_NxN_multiplier);

    pass_count = 0;
    fail_count = 0;
    reset  = 1;
    clear  = 0;
    a_flat = 0;
    b_flat = 0;
    repeat(4) @(posedge clk);
    reset = 0;

    // ----------------------------------------
    // Test 1: A x Identity = A
    // ----------------------------------------
    $display("Test 1: A x Identity");
    A_mat[0][0]=1;  A_mat[0][1]=2;  A_mat[0][2]=3;
    A_mat[1][0]=4;  A_mat[1][1]=5;  A_mat[1][2]=6;
    A_mat[2][0]=7;  A_mat[2][1]=8;  A_mat[2][2]=9;
    B_mat[0][0]=1;  B_mat[0][1]=0;  B_mat[0][2]=0;
    B_mat[1][0]=0;  B_mat[1][1]=1;  B_mat[1][2]=0;
    B_mat[2][0]=0;  B_mat[2][1]=0;  B_mat[2][2]=1;
    run_test(1);

    // ----------------------------------------
    // Test 2: general positive
    // ----------------------------------------
    $display("Test 2: general positive");
    A_mat[0][0]=1;  A_mat[0][1]=2;  A_mat[0][2]=3;
    A_mat[1][0]=4;  A_mat[1][1]=5;  A_mat[1][2]=6;
    A_mat[2][0]=7;  A_mat[2][1]=8;  A_mat[2][2]=9;
    B_mat[0][0]=9;  B_mat[0][1]=8;  B_mat[0][2]=7;
    B_mat[1][0]=6;  B_mat[1][1]=5;  B_mat[1][2]=4;
    B_mat[2][0]=3;  B_mat[2][1]=2;  B_mat[2][2]=1;
    run_test(2);

    // ----------------------------------------
    // Test 3: negative numbers
    // ----------------------------------------
    $display("Test 3: negative numbers");
    A_mat[0][0]=-1; A_mat[0][1]=2;  A_mat[0][2]=-3;
    A_mat[1][0]=4;  A_mat[1][1]=-5; A_mat[1][2]=6;
    A_mat[2][0]=-7; A_mat[2][1]=8;  A_mat[2][2]=-9;
    B_mat[0][0]=1;  B_mat[0][1]=-2; B_mat[0][2]=3;
    B_mat[1][0]=-4; B_mat[1][1]=5;  B_mat[1][2]=-6;
    B_mat[2][0]=7;  B_mat[2][1]=-8; B_mat[2][2]=9;
    run_test(3);

    // ----------------------------------------
    // Test 4: all zeros
    // ----------------------------------------
    $display("Test 4: all zeros");
    for (row = 0; row < N; row = row + 1)
      for (col = 0; col < N; col = col + 1) begin
        A_mat[row][col] = 0;
        B_mat[row][col] = 0;
      end
    run_test(4);

    // ----------------------------------------
    // Test 5: back-to-back (verifies clear works)
    // ----------------------------------------
    $display("Test 5: back-to-back (verifies clear)");
    A_mat[0][0]=1;  A_mat[0][1]=2;  A_mat[0][2]=3;
    A_mat[1][0]=4;  A_mat[1][1]=5;  A_mat[1][2]=6;
    A_mat[2][0]=7;  A_mat[2][1]=8;  A_mat[2][2]=9;
    B_mat[0][0]=9;  B_mat[0][1]=8;  B_mat[0][2]=7;
    B_mat[1][0]=6;  B_mat[1][1]=5;  B_mat[1][2]=4;
    B_mat[2][0]=3;  B_mat[2][1]=2;  B_mat[2][2]=1;
    run_test(5);

    // ----------------------------------------
    // Summary
    // ----------------------------------------
    $display("----------------------------------------");
    $display("Results: %0d / %0d passed", pass_count, pass_count+fail_count);
    if (fail_count == 0)
      $display("ALL TESTS PASSED");
    else
      $display("SOME TESTS FAILED - open tb_NxN_multiplier.vcd to debug");
    $display("----------------------------------------");
    $finish;
  end

endmodule
