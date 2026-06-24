import arcabuco_core_pack::*;
module forwarding_unit (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        reg_write_mem,
    input  logic        reg_write_wb,
    input  logic [4:0]  rs1_ex,     // rs1 of instruction currently in EX
    input  logic [4:0]  rs2_ex,     // rs2 of instruction currently in EX
    input  logic [4:0]  rd_mem,     // destination register in MEM
    input  logic [4:0]  rd_wb,      // destination register in WB
    input  t_instruction ID_cmd,
    output logic [1:0]  mux1_ctr_ex,
    output logic [1:0]  mux2_ctr_ex
);

    logic ex1, ex2;
    logic mem1, mem2;
    t_instruction EX_cmd;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            EX_cmd <= inst_invalid;
        else
            EX_cmd <= ID_cmd;
    end


    //------------------------------------------------------------
    // MEM -> EX forwarding
    //------------------------------------------------------------

    assign ex1 = reg_write_mem    &&
                 (rd_mem != 5'd0) &&
                 (rd_mem == rs1_ex);

    assign ex2 = reg_write_mem    &&
                 (rd_mem != 5'd0) &&
                 (rd_mem == rs2_ex);


    //------------------------------------------------------------
    // WB -> EX forwarding
    //------------------------------------------------------------

    assign mem1 = reg_write_wb    &&
                  (rd_wb != 5'd0) &&
                  !ex1            &&
                  (rd_wb == rs1_ex);

    assign mem2 = reg_write_wb    &&
                  (rd_wb != 5'd0) &&
                  !ex2            &&
                  (rd_wb == rs2_ex);


    //------------------------------------------------------------
    // Output mux1 control
    //------------------------------------------------------------

    always_comb begin
        if (ex1 && (EX_cmd != inst_auipc))
            mux1_ctr_ex = 2'd3;
        else if (mem1 && (EX_cmd != inst_auipc))
            mux1_ctr_ex = 2'd2;
        else
            mux1_ctr_ex = 2'd1;
    end


    //------------------------------------------------------------
    // Output mux2 control
    //------------------------------------------------------------

    always_comb begin
        if (ex2 && (EX_cmd != inst_jal) && (EX_cmd != inst_jalr))
            mux2_ctr_ex = 2'd3;
        else if (mem2 && (EX_cmd != inst_jal) && (EX_cmd != inst_jalr))
            mux2_ctr_ex = 2'd2;
        else
            mux2_ctr_ex = 2'd1;
    end

endmodule