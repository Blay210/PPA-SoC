`timescale 1ns/1ps

module shared_mem_tb;
    localparam int ADDR_WIDTH = 6;
    localparam logic [ADDR_WIDTH-1:0] FIRST_WORD = '0;
    localparam logic [ADDR_WIDTH-1:0] LAST_WORD = '1;

    logic clk = 0;
    logic rst = 1;
    logic req_valid = 0;
    logic req_ready;
    logic req_write = 0;
    logic [ADDR_WIDTH-1:0] req_word_addr = '0;
    logic [31:0] req_wdata = '0;
    logic [3:0] req_wstrb = '0;
    logic rsp_valid;
    logic [31:0] rsp_rdata;

    shared_mem #(.ADDR_WIDTH(ADDR_WIDTH)) dut (.*);

    always #5 clk = ~clk;

    task automatic write_word(
        input logic [ADDR_WIDTH-1:0] address,
        input logic [31:0] data,
        input logic [3:0] strobe
    );
        @(negedge clk);
        req_valid = 1;
        req_write = 1;
        req_word_addr = address;
        req_wdata = data;
        req_wstrb = strobe;
        @(posedge clk);
        #1;
        if (req_ready !== 1'b1 || rsp_valid !== 1'b0)
            $fatal(1, "Unexpected handshake for write at word %0d", address);
    endtask

    task automatic expect_word(
        input logic [ADDR_WIDTH-1:0] address,
        input logic [31:0] expected
    );
        @(negedge clk);
        req_valid = 1;
        req_write = 0;
        req_word_addr = address;
        @(posedge clk);
        #1;
        if (req_ready !== 1'b1 || rsp_valid !== 1'b1 || rsp_rdata !== expected)
            $fatal(1, "Read at word %0d: expected %08h, got %08h (valid=%b)",
                   address, expected, rsp_rdata, rsp_valid);
    endtask

    initial begin
        if ($test$plusargs("waves")) begin
            $dumpfile("build/shared_mem.vcd");
            $dumpvars(0, shared_mem_tb);
        end

        @(posedge clk);
        #1;
        if (req_ready !== 1'b0 || rsp_valid !== 1'b0)
            $fatal(1, "Reset must suppress requests and read responses");
        @(negedge clk);
        rst = 0;

        write_word(FIRST_WORD, 32'h1122_3344, 4'b1111);
        write_word(LAST_WORD,  32'hDEAD_BEEF, 4'b1111);
        expect_word(FIRST_WORD, 32'h1122_3344);
        write_word(FIRST_WORD, 32'hAABB_CCDD, 4'b0101);
        write_word(FIRST_WORD, 32'hFFFF_FFFF, 4'b0000);
        expect_word(FIRST_WORD, 32'h11BB_33DD);
        expect_word(LAST_WORD,  32'hDEAD_BEEF);

        @(negedge clk);
        req_valid = 0;
        @(posedge clk);
        #1;
        if (rsp_valid !== 1'b0)
            $fatal(1, "Idle cycle must have no read response");

        $display("PASS: shared_mem reset, read/write, byte strobes, boundaries, consecutive reads");
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "Simulation timeout");
    end
endmodule
