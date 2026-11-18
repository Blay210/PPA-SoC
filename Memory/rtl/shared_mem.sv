`timescale 1ns/1ps

module shared_mem #(
    parameter int ADDR_WIDTH = 6
) (
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  req_valid,
    output logic                  req_ready,
    input  logic                  req_write,
    input  logic [ADDR_WIDTH-1:0] req_word_addr,
    input  logic [31:0]           req_wdata,
    input  logic [3:0]            req_wstrb,
    output logic                  rsp_valid,
    output logic [31:0]           rsp_rdata
);
    logic [31:0] words [0:(2**ADDR_WIDTH)-1];
    logic        req_fire;

    assign req_ready = !rst;
    assign req_fire = req_valid && req_ready;

    always_ff @(posedge clk) begin
        if (req_fire) begin
            if (req_write) begin
                for (int byte_lane = 0; byte_lane < 4; byte_lane++) begin
                    if (req_wstrb[byte_lane])
                        words[req_word_addr][8*byte_lane +: 8] <= req_wdata[8*byte_lane +: 8];
                end
            end else begin
                rsp_rdata <= words[req_word_addr];
            end
        end
    end

    always_ff @(posedge clk) begin
        rsp_valid <= req_fire && !req_write;
    end
endmodule
