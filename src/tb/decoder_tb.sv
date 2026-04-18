`timescale 1ns/1ps

module riscv_decoder_tb;
    initial    begin
        $dumpfile("decoder.vcd");
        $dumpvars(0,riscv_decoder_tb);
        $display("decoder sim starts");
    end
    // --------------------------------------------------
    // DUT signals
    // --------------------------------------------------
    logic [31:0] instruction_raw;
    logic [4:0]  rd;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic signed [31:0] imm;
    t_instruction  instruction_out;

    // --------------------------------------------------
    // Instantiate DUT
    // --------------------------------------------------
    riscv_decoder dut (
        .instruction_raw(instruction_raw),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .imm(imm),
        .instruction_out(instruction_out)
    );

    // --------------------------------------------------
    // Reference states (must match DUT enum!)
    // --------------------------------------------------
    localparam lui   = 6'd1;
    localparam addi  = 6'd19;
    localparam add   = 6'd35;
    localparam sub   = 6'd37;
    localparam beq   = 6'd4;
    localparam lw    = 6'd16;
    localparam sw    = 6'd12;
    localparam jal   = 6'd3;

    // --------------------------------------------------
    // Helper: check task
    // --------------------------------------------------
    task check(
        input string name,
        input [5:0] exp_state,
        input signed [31:0] exp_imm
    );
    begin
        #1;
        if (instruction_out !== exp_state) begin
            $error("[%s] STATE mismatch: got %0d expected %0d", name, instruction_out, exp_state);
        end
        if (imm !== exp_imm) begin
            $error("[%s] IMM mismatch: got %0d expected %0d", name, imm, exp_imm);
        end
        else begin
            $display("[%s] PASS", name);
        end
    end
    endtask

    // --------------------------------------------------
    // Test sequence
    // --------------------------------------------------
    initial begin

        $display("==== InstDeco Testbench Start ====");

        // -----------------------------
        // LUI test
        // opcode = 0x37
        // -----------------------------
        instruction_raw = 32'h12345037; // imm = 0x12345 << 12
        check("LUI", lui, 32'sh12345000);

        // -----------------------------
        // ADDI test
        // addi x1, x2, 10
        // -----------------------------
        instruction_raw = {12'd10, 5'd2, 3'b000, 5'd1, 7'h13};
        check("ADDI", addi, 10);

        // -----------------------------
        // ADD test
        // add x3, x1, x2
        // -----------------------------
        instruction_raw = {7'h00, 5'd2, 5'd1, 3'b000, 5'd3, 7'h33};
        check("ADD", add, 0);

        // -----------------------------
        // SUB test
        // -----------------------------
        instruction_raw = {7'h20, 5'd2, 5'd1, 3'b000, 5'd3, 7'h33};
        check("SUB", sub, 0);

        // -----------------------------
        // BEQ test
        // -----------------------------
        instruction_raw = {
            1'b0,        // imm[12]
            6'b000001,   // imm[10:5]
            5'd2,
            5'd1,
            3'b000,
            4'b0010,     // imm[4:1]
            1'b0,        // imm[11]
            7'h63
        };
        check("BEQ", beq, 32'sd36);

        // -----------------------------
        // LW test
        // -----------------------------
        instruction_raw = {12'd8, 5'd2, 3'b010, 5'd1, 7'h03};
        check("LW", lw, 8);

        // -----------------------------
        // SW test
        // -----------------------------
        instruction_raw = {7'd0, 5'd1, 5'd2, 3'b010, 5'd8, 7'h23};
        check("SW", sw, 8);

        // -----------------------------
        // JAL test
        // -----------------------------
        instruction_raw = 32'h001000EF; // small jump
        check("JAL", jal, 2048);


        // --------------------------------------------------
        // SIGN-EXTENSION TESTS
        // --------------------------------------------------

        // I-type negative immediate (ADDI x1, x0, -1)
        instruction_raw = {12'hFFF, 5'd0, 3'b000, 5'd1, 7'h13}; // -1
        check("SIGNEXT ADDI", addi, -1);


        // I-type most negative (addi ra, zero, -2048)
        instruction_raw = {12'h800, 5'd0, 3'b000, 5'd1, 7'h13};
        check("SIGNEXT ADDI ", addi, -2048);


        // S-type negative immediate (SW with -8 offset)
        instruction_raw = {7'b1111111, 5'd1, 5'd2, 3'b010, 5'b11000, 7'h23}; // -8
        check("SIGNEXT SW ", sw, -8);


        // B-type negative branch (-4)
        instruction_raw = {
            1'b1,        // imm[12]
            6'b111111,   // imm[10:5]
            5'd2,
            5'd1,
            3'b000,
            4'b1110,     // imm[4:1]
            1'b1,        // imm[11]
            7'h63
        };
        check("SIGNEXT BEQ", beq, -4);


        // J-type negative jump (-4)
        instruction_raw = {
            1'b1,             // imm[20]
            10'b1111111111,   // imm[10:1]
            1'b1,             // imm[11]
            8'b11111110,      // imm[19:12]
            5'd1,
            7'h6F
        };
        check("SIGNEXT JAL", jal, -4098);


        // U-type (should NOT sign-extend lower bits, just shift)
        instruction_raw = 32'hFFF00037; // upper = 0xFFF00
        check("SIGNEXT LUI", lui, 32'shFFF00000);

        // -----------------------------
        // Random tests (optional)
        // -----------------------------
        repeat (10) begin
            instruction_raw = $urandom;
            #1;
            $display("Random instr: %h -> instruction_out=%0d imm=%0d", instruction_raw, instruction_out, imm);
        end

        $display("==== Testbench Finished ====");
        $finish;
    end

endmodule