import arcabuco_core_pack::*;
module arcabuco_decoder (
    input  logic  [31:0] instruction_raw,
    output logic  [4:0]  rd,
    output logic  [4:0]  rs1,
    output logic  [4:0]  rs2,
    output logic  [31:0] imm,
    output t_instruction instruction_out
);



    // --------------------------------------------------
    // Constant Fields
    // --------------------------------------------------

    logic [6:0] opcode;
    assign opcode = instruction_raw[6:0];

    logic [2:0] funct3;
    assign funct3 = instruction_raw[14:12];

    logic [6:0] funct7;
    assign funct7 = instruction_raw[31:25];

    assign rd  = instruction_raw[11:7] ;
    assign rs1 = instruction_raw[19:15];
    assign rs2 = instruction_raw[24:20];

    // --------------------------------------------------
    // Combinational decoder 
    // --------------------------------------------------
    
// verilator lint_off CASEINCOMPLETE 
    always_comb begin
        instruction_out = inst_invalid;
        imm   = 32'sd0;

        case (opcode)

            7'h37: begin // LUI
                instruction_out = inst_lui;
                imm   = {instruction_raw[31:12], 12'b0};
            end

            7'h17: begin // AUIPC
                instruction_out = inst_auipc;
                imm   = {instruction_raw[31:12], 12'b0};
            end

            7'h6F: begin // JAL
                instruction_out = inst_jal;
                imm   = {{11{instruction_raw[31]}},instruction_raw[31], instruction_raw[19:12], instruction_raw[20], instruction_raw[30:21], 1'b0};
            end

            7'h67: begin // JALR
                imm   = {{20{instruction_raw[31]}},instruction_raw[31:20]};
                instruction_out = inst_jalr;
            end

            7'h63: begin // B-Type
                imm = {{19{instruction_raw[31]}},instruction_raw[31], instruction_raw[7], instruction_raw[30:25], instruction_raw[11:8], 1'b0};
                case (funct3)
                    3'h0: instruction_out = inst_beq;
                    3'h1: instruction_out = inst_bne;
                    3'h4: instruction_out = inst_blt;
                    3'h5: instruction_out = inst_bge;
                    3'h6: instruction_out = inst_bltu;
                    3'h7: instruction_out = inst_bgeu;
                endcase
            end

            7'h03: begin // LOAD
                imm   = {{20{instruction_raw[31]}},instruction_raw[31:20]};
                case (funct3)
                    3'h0: instruction_out = inst_lb;
                    3'h1: instruction_out = inst_lh;
                    3'h2: instruction_out = inst_lw;
                    3'h4: instruction_out = inst_lbu;
                    3'h5: instruction_out = inst_lhu;
                endcase
            end

            7'h23: begin // STORE
                imm = {{20{instruction_raw[31]}},instruction_raw[31:25], instruction_raw[11:7]};
                case (funct3)
                    3'h0: instruction_out = inst_sb;
                    3'h1: instruction_out = inst_sh;
                    3'h2: instruction_out = inst_sw;
                endcase
            end

            7'h13: begin // OP-IMM
                imm   = {{20{instruction_raw[31]}},instruction_raw[31:20]};

                case (funct3)
                    3'h0: instruction_out = inst_addi;
                    3'h2: instruction_out = inst_slti;
                    3'h3: instruction_out = inst_sltiu;
                    3'h4: instruction_out = inst_xori;
                    3'h6: instruction_out = inst_ori;
                    3'h7: instruction_out = inst_andi;
                    3'h1: begin
                        imm   = {{27{instruction_raw[24]}},instruction_raw[24:20]};//TODO check this could be optimized
                        instruction_out = inst_slli;
                    end
                    3'h5: begin
                        imm   = {{27{instruction_raw[24]}},instruction_raw[24:20]};//TODO check this could be optimized
                        case (funct7)
                            7'h00: instruction_out = inst_srli;
                            7'h20: instruction_out = inst_srai;
                        endcase
                    end
                endcase
            end

            7'h33: begin // R-Type
                case (funct3)
                    3'h0: case (funct7)
                        7'h00: instruction_out = inst_add;
                        7'h01: instruction_out = (HAVE_MUL) ? inst_mul : inst_invalid;
                        7'h20: instruction_out = inst_sub;
                    endcase

                    3'h1: case (funct7)
                        7'h00: instruction_out = inst_sll;
                        7'h01: instruction_out = (HAVE_MUL) ? inst_mulh : inst_invalid;
                    endcase

                    3'h2: case (funct7)
                        7'h00: instruction_out = inst_slt;
                        7'h01: instruction_out = (HAVE_MUL) ? inst_mulhsu : inst_invalid;
                    endcase

                    3'h3: case (funct7)
                        7'h00: instruction_out = inst_sltu;
                        7'h01: instruction_out = (HAVE_MUL) ? inst_mulhu : inst_invalid;
                    endcase

                    3'h4: case (funct7)
                        7'h00: instruction_out = inst_xor_;
                        7'h01: instruction_out = (HAVE_MUL) ? inst_div : inst_invalid;
                    endcase

                    3'h5: case (funct7)
                        7'h00: instruction_out = inst_srl;
                        7'h01: instruction_out = (HAVE_MUL) ? inst_divu : inst_invalid;
                        7'h20: instruction_out = inst_sra;
                    endcase

                    3'h6: case (funct7)
                        7'h00: instruction_out = inst_or_;
                        7'h01: instruction_out = (HAVE_MUL) ? inst_rem : inst_invalid;
                    endcase

                    3'h7: case (funct7)
                        7'h00: instruction_out = inst_and_;
                        7'h01: instruction_out = (HAVE_MUL) ? inst_remu : inst_invalid;
                    endcase

                endcase
            end

            7'h73: begin // CSR
                imm = {20'b0, instruction_raw[31:20]};
                case (funct3)
                    3'h0: instruction_out = inst_ebreak;
                    3'h1: instruction_out = inst_csrrw;
                    3'h2: instruction_out = inst_csrrs;
                    3'h3: instruction_out = inst_csrrc;
                    3'h5: instruction_out = inst_csrrwi;
                    3'h6: instruction_out = inst_csrrsi;
                    3'h7: instruction_out = inst_csrrci;
                endcase
            end

        endcase
    end
// verilator lint_on CASEINCOMPLETE 
endmodule