`timescale 1ns/1ps

module arcabuco_decoder_tb;

    initial begin
        $dumpfile("decoder.vcd");
        $dumpvars(0,arcabuco_decoder_tb);
        $display("decoder sim starts");
    end

    // --------------------------------------------------
    // Clock / Reset
    // --------------------------------------------------
    logic clk;
    logic rst_n;

    always #5 clk = ~clk;

    // --------------------------------------------------
    // DUT signals (TOP LEVEL NOW)
    // --------------------------------------------------
    logic [31:0] instruction_raw;
    logic [4:0]  rd_addr_out;
    logic [4:0]  rs1_addr_out;
    logic [4:0]  rs2_addr_out;
    logic [31:0] imm_data_out;
    logic [5:0]  ctrl_cmd;

    logic [31:0] rs1_data_out;
    logic [31:0] rs2_data_out;

    logic [31:0] rd_data_in;
    logic [4:0]  rd_waddr;
    logic        ctrl_wen;

    logic [1:0] ctrl_mux1_select;
    logic       ctrl_mux2_select;
    logic       ctrl_mux4_select;
    logic       ctrl_mux5_select;

    logic [31:0] in_pc;
    logic [31:0] out_pc;

    // Dummy debug interface (inactive)
    reg_access debug_if();

    // --------------------------------------------------
    // Instantiate DUT (NEW TOP)
    // --------------------------------------------------
    arcabuco_regs_deco dut (
        .clock(clk),
        .rst_n(rst_n),

        .ctrl_wen(ctrl_wen),
        .ctrl_mux1_select(ctrl_mux1_select),
        .ctrl_mux2_select(ctrl_mux2_select),
        .ctrl_mux4_select(ctrl_mux4_select),
        .ctrl_mux5_select(ctrl_mux5_select),
        .ctrl_cmd(ctrl_cmd),

        .rd_waddr(rd_waddr),
        .rd_data_in(rd_data_in),
        .rs1_data_out(rs1_data_out),
        .rs2_data_out(rs2_data_out),

        .instruction_raw(instruction_raw),
        .rd_addr_out(rd_addr_out),
        .rs1_addr_out(rs1_addr_out),
        .rs2_addr_out(rs2_addr_out),
        .imm_data_out(imm_data_out),

        .in_pc(in_pc),
        .out_pc(out_pc),

        .debug_regac(debug_if)
    );

    // --------------------------------------------------
    // Helper task: write register
    // --------------------------------------------------
    task write_reg(input [4:0] addr, input [31:0] data);
    begin
        rd_waddr = addr;
        rd_data_in = data;
        ctrl_wen = 1;
        #10;
        ctrl_wen = 0;
    end
    endtask

    // --------------------------------------------------
    // Helper task: read registers
    // --------------------------------------------------
    task read_regs(input [4:0] rs1, input [4:0] rs2);
    begin
        instruction_raw = {7'h00, rs2, rs1, 3'b000, 5'd0, 7'h33}; // fake ADD
        #1;
    end
    endtask

    // --------------------------------------------------
    // TEST SEQUENCE
    // --------------------------------------------------
    initial begin

        clk = 0;
        rst_n = 0;

        ctrl_mux1_select = 0;
        ctrl_mux2_select = 0;
        ctrl_mux4_select = 1; // usar rs1_data_r
        ctrl_mux5_select = 1; // usar rs2_data_r

        in_pc = 32'h1000;

        #20;
        rst_n = 1;

        $display("==== REGFILE TEST START ====");

        // -----------------------------
        // WRITE TEST
        // -----------------------------
        write_reg(5'd1, 32'hAAAA1111);
        write_reg(5'd2, 32'hBBBB2222);

        // -----------------------------
        // READ TEST
        // -----------------------------
        read_regs(5'd1, 5'd2);

        #1;

        if (rs1_data_out !== 32'hAAAA1111)
            $error("RS1 read failed");

        if (rs2_data_out !== 32'hBBBB2222)
            $error("RS2 read failed");

        else
            $display("REGFILE BASIC PASS");

        // -----------------------------
        // OVERWRITE TEST
        // -----------------------------
        write_reg(5'd1, 32'hDEADBEEF);
        read_regs(5'd1, 5'd0);

        #1;

        if (rs1_data_out !== 32'hDEADBEEF)
            $error("Overwrite failed");
        else
            $display("REGFILE OVERWRITE PASS");

        // --------------------------------------------------
        // Reuse decoder tests (jerarquía arriba)
        // --------------------------------------------------
        $display("==== DECODER TEST (TOP LEVEL) ====");

        instruction_raw = 32'h12345037; // LUI
        #1;
        if (ctrl_cmd !== 6'd1)
            $error("Decoder failed at top level");

        // -----------------------------
        // PC calculation test
        // -----------------------------
        ctrl_mux1_select = 0;
        ctrl_mux2_select = 0;
        instruction_raw = {12'd4, 5'd0, 3'b000, 5'd0, 7'h13}; // ADDI

        #1;
        $display("out_pc = %h", out_pc);

        $display("==== TEST END ====");
        $finish;
    end

endmodule