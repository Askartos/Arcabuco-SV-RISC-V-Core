import arcabuco_core_pack::*;
module arcabuco_decoder (
    input  logic        [31:0] instruc,
    output logic        [4:0]  rd,
    output logic        [4:0]  rs1,
    output logic        [4:0]  rs2,
    output logic signed [31:0] imm,
    output t_instruction       state
);



    // --------------------------------------------------
    // Fields
    // --------------------------------------------------

    logic [6:0] opcode;
    assign opcode = instruc[6:0];

    logic [2:0] funct3;
    assign funct3 = instruc[14:12];

    logic [6:0] funct7;
    assign funct7 = instruc[31:25];

    assign rd  = instruc[11:7] ;//state==inst_invalid ? '0  : instruc[11:7]  ;
    assign rs1 = instruc[19:15];//state==inst_invalid ? '0  : instruc[19:15] ;
    assign rs2 = instruc[24:20];//state==inst_invalid ? '0  : instruc[24:20] ;

    // --------------------------------------------------
    // Combinational decoder
    // --------------------------------------------------
    always_comb begin
        state = inst_invalid;
        imm   = 32'sd0;

        case (opcode)

            7'h37: begin // LUI
                state = inst_lui;
                imm   = {instruc[31:12], 12'b0};
            end

            7'h17: begin // AUIPC
                state = inst_auipc;
                imm   = {instruc[31:12], 12'b0};
            end

            7'h6F: begin // JAL
                state = inst_jal;
                imm   = $signed({instruc[31], instruc[19:12], instruc[20], instruc[30:21], 1'b0});
            end

            7'h67: begin // JALR
                imm   = $signed(instruc[31:20]);
                state = inst_jalr;
            end

            7'h63: begin // B-Type
                imm = $signed({instruc[31], instruc[7], instruc[30:25], instruc[11:8], 1'b0});
                case (funct3)
                    3'h0: state = inst_beq;
                    3'h1: state = inst_bne;
                    3'h4: state = inst_blt;
                    3'h5: state = inst_bge;
                    3'h6: state = inst_bltu;
                    3'h7: state = inst_bgeu;
                endcase
            end

            7'h03: begin // LOAD
                imm = $signed(instruc[31:20]);
                case (funct3)
                    3'h0: state = inst_lb;
                    3'h1: state = inst_lh;
                    3'h2: state = inst_lw;
                    3'h4: state = inst_lbu;
                    3'h5: state = inst_lhu;
                endcase
            end

            7'h23: begin // STORE
                imm = $signed({instruc[31:25], instruc[11:7]});
                case (funct3)
                    3'h0: state = inst_sb;
                    3'h1: state = inst_sh;
                    3'h2: state = inst_sw;
                endcase
            end

            7'h13: begin // OP-IMM
                imm = $signed(instruc[31:20]);

                case (funct3)
                    3'h0: state = inst_addi;
                    3'h2: state = inst_slti;
                    3'h3: state = inst_sltiu;
                    3'h4: state = inst_xori;
                    3'h6: state = inst_ori;
                    3'h7: state = inst_andi;
                    3'h1: begin
                        imm   = $signed(instruc[24:20]);
                        state = inst_slli;
                    end
                    3'h5: begin
                        imm = $signed(instruc[24:20]);
                        case (funct7)
                            7'h00: state = inst_srli;
                            7'h20: state = inst_srai;
                        endcase
                    end
                endcase
            end

            7'h33: begin // R-Type
                case (funct3)
                    3'h0: case (funct7)
                        7'h00: state = inst_add;
                        7'h01: state = (HAVE_MUL) ? inst_mul : inst_invalid;
                        7'h20: state = inst_sub;
                    endcase

                    3'h1: case (funct7)
                        7'h00: state = inst_sll;
                        7'h01: state = (HAVE_MUL) ? inst_mulh : inst_invalid;
                    endcase

                    3'h2: case (funct7)
                        7'h00: state = inst_slt;
                        7'h01: state = (HAVE_MUL) ? inst_mulhsu : inst_invalid;
                    endcase

                    3'h3: case (funct7)
                        7'h00: state = inst_sltu;
                        7'h01: state = (HAVE_MUL) ? inst_mulhu : inst_invalid;
                    endcase

                    3'h4: case (funct7)
                        7'h00: state = inst_xor_;
                        7'h01: state = (HAVE_MUL) ? inst_div : inst_invalid;
                    endcase

                    3'h5: case (funct7)
                        7'h00: state = inst_srl;
                        7'h01: state = (HAVE_MUL) ? inst_divu : inst_invalid;
                        7'h20: state = inst_sra;
                    endcase

                    3'h6: case (funct7)
                        7'h00: state = inst_or_;
                        7'h01: state = (HAVE_MUL) ? inst_rem : inst_invalid;
                    endcase

                    3'h7: case (funct7)
                        7'h00: state = inst_and_;
                        7'h01: state = (HAVE_MUL) ? inst_remu : inst_invalid;
                    endcase

                endcase
            end

            7'h73: begin // CSR
                imm = $signed({20'b0, instruc[31:20]});
                case (funct3)
                    3'h0: state = inst_ebreak;
                    3'h1: state = inst_csrrw;
                    3'h2: state = inst_csrrs;
                    3'h3: state = inst_csrrc;
                    3'h5: state = inst_csrrwi;
                    3'h6: state = inst_csrrsi;
                    3'h7: state = inst_csrrci;
                endcase
            end

        endcase
    end

endmodule