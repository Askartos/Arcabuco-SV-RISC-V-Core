`timescale 1ns/1ps

import arcabuco_core_pack::*;

module arcabuco_datapath_tb;

    logic clk;
    logic rst_n;

    // Dummy control signals
    pipe_ctrl_t   pipe_ctrl;
    if_ctrl_t     if_ctrl;
    id_ctrl_t     id_ctrl;
    ex_ctrl_cmd_t ex_ctrl_in;
    mem_ctrl_t    mem_ctrl;
    logic [1:0]   wb_mux_ctrl;

    // DUT outputs
    t_instruction id_ctrl_cmd;
    rf_addrs_t    id_addrs_out;
    rf_addrs_t    ex_addrs_out;
    ex_ctrl_rsp_t ex_ctrl_out;
    logic         mem_ctrl_done;
    logic [4:0]   mem_addr_rd;
    logic [4:0]   wb_addr_rd;

    // Interface instances
    mem_if imem();
    mem_if dmem();

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset
    initial begin
	     $dumpfile("arcabuco_sim.vcd");
	     $dumpvars(0,arcabuco_datapath_tb);
        $display("arcabuco sim starts");
        rst_n = 0;
        pipe_ctrl = '0;
        if_ctrl   = '0;
        id_ctrl   = '0;
        ex_ctrl_in = '0;
        mem_ctrl   = '0;
        wb_mux_ctrl = '0;
        #20;
        rst_n = 1;

        #1000;
        $finish;
    end

    arcabuco_datapath dut (
        .clk(clk),
        .rst_n(rst_n),

        .pipe_ctrl(pipe_ctrl),
        .if_ctrl(if_ctrl),
        .id_ctrl(id_ctrl),

        .id_ctrl_cmd(id_ctrl_cmd),
        .id_addrs_out(id_addrs_out),
        .ex_addrs_out(ex_addrs_out),

        .ex_ctrl_in(ex_ctrl_in),
        .ex_ctrl_out(ex_ctrl_out),

        .mem_ctrl(mem_ctrl),
        .mem_ctrl_done(mem_ctrl_done),

        .mem_addr_rd(mem_addr_rd),
        .wb_addr_rd(wb_addr_rd),

        .wb_mux_ctrl(wb_mux_ctrl),

        .imem(imem),
        .dmem(dmem)
    );

endmodule
