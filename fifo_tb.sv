`timescale 1ns/1ps

module fifo_tb;

    localparam DEPTH = 8;
    localparam WIDTH = 8;

    logic clk, rst_n, wr_en, rd_en;
    logic [WIDTH-1:0] din;
    logic [WIDTH-1:0] dout;
    logic full, empty;
    logic [$clog2(DEPTH):0] count;

    int pass_count = 0;
    int fail_count = 0;

    fifo #(.depth(DEPTH), .width(WIDTH)) dut (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .rd_en(rd_en),
        .din(din), .dout(dout),
        .full(full), .empty(empty), .count(count)
    );

    always #5 clk = ~clk;

    logic [WIDTH-1:0] ref_queue[$];

    task automatic check_data(input [WIDTH-1:0] expected, input [WIDTH-1:0] actual, input string label);
        if (expected === actual) begin
            pass_count++;
            $display("[PASS] %-40s expected=0x%0h actual=0x%0h", label, expected, actual);
        end else begin
            fail_count++;
            $error("[FAIL] %-40s expected=0x%0h actual=0x%0h", label, expected, actual);
        end
    endtask
//Hi
    task automatic check_count(input int expected, input string label);
        if (expected === count) begin
            pass_count++;
            $display("[PASS] %-40s expected count=%0d actual count=%0d", label, expected, count);
        end else begin
            fail_count++;
            $error("[FAIL] %-40s expected count=%0d actual count=%0d", label, expected, count);
        end
    endtask

    // Stimulus set up on negedge (settles well before next posedge samples it)
    task automatic do_write(input [WIDTH-1:0] data);
        @(negedge clk);
        wr_en = 1; din = data;
        if (!full) ref_queue.push_back(data);
        @(negedge clk);
        wr_en = 0;
    endtask

    task automatic do_read();
        @(negedge clk);
        rd_en = 1;
        @(negedge clk);
        rd_en = 0;
    endtask

    task automatic do_read_and_check(input string label);
        automatic logic [WIDTH-1:0] expected;
        do_read();
        expected = ref_queue.pop_front();
        check_data(expected, dout, label);
    endtask

    initial begin
        clk = 0; rst_n = 0; wr_en = 0; rd_en = 0; din = 0;

        #12 rst_n = 1;
        @(negedge clk);
        check_count(0, "Reset: count == 0");
        if (empty !== 1) begin fail_count++; $error("[FAIL] Reset: empty should be 1"); end
        else begin pass_count++; $display("[PASS] Reset: empty == 1"); end

        do_write(8'hAA);
        check_count(1, "After 1 write: count == 1");
        do_read_and_check("Write then read: dout matches din");
        check_count(0, "After matching read: count == 0");

        for (int i = 0; i < DEPTH; i++) do_write(i);
        check_count(DEPTH, "Continuous write: count == DEPTH");
        if (full !== 1) begin fail_count++; $error("[FAIL] full should assert at DEPTH entries"); end
        else begin pass_count++; $display("[PASS] full asserts at DEPTH entries"); end

        do_write(8'hFF);  // should be dropped
        check_count(DEPTH, "Overflow protection: count still == DEPTH after write-while-full");

        for (int i = 0; i < DEPTH; i++) begin
            do_read_and_check($sformatf("Sequential read #%0d matches write order", i));
        end
        check_count(0, "Continuous read: count == 0");
        if (empty !== 1) begin fail_count++; $error("[FAIL] empty should assert at 0 entries"); end
        else begin pass_count++; $display("[PASS] empty asserts at 0 entries"); end

        do_read();  // should have no effect
        check_count(0, "Underflow protection: count still == 0 after read-while-empty");

        do_write(8'h11);
        do_write(8'h22);
        check_count(2, "Setup for simultaneous test: count == 2");
        @(negedge clk);
        wr_en = 1; rd_en = 1; din = 8'h33;
        @(negedge clk);
        wr_en = 0; rd_en = 0;
        check_count(2, "Simultaneous wr+rd: count net-unchanged");

        do_write(8'h44);
        @(negedge clk);
        rst_n = 0;
        @(negedge clk);
        rst_n = 1;
        @(negedge clk);
        check_count(0, "Mid-operation reset: count clears to 0");

        $display("\n==================================================");
        $display("  TOTAL: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0) $display("  RESULT: ALL TESTS PASSED");
        else                 $display("  RESULT: %0d TEST(S) FAILED", fail_count);
        $display("==================================================\n");

        #20 $finish;
    end

endmodule
