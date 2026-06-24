module hazard_detection_unit (
    input  logic [2:0] dm_read_ex,
    input  logic [4:0] rs1_id,
    input  logic [4:0] rs2_id,
    input  logic [4:0] rd_ex,
    input  logic [4:0] rd_mem,
    input  logic       is_jalr,

    output logic       mux3_ctr_id,
    output logic       flop_ctr_if
);

    logic mem_hazard;
    logic jalr_hazard;

    //--------------------------------------------------------------------------
    // Hazard detection
    //--------------------------------------------------------------------------

    assign mem_hazard =
        (dm_read_ex != 3'b000) &&
        ((rd_ex == rs1_id) || (rd_ex == rs2_id));

    assign jalr_hazard =
        is_jalr &&
        ((rd_ex == rs1_id) || (rd_mem == rs1_id));

    //--------------------------------------------------------------------------
    // Output control
    //--------------------------------------------------------------------------

    always_comb begin
        if (mem_hazard || jalr_hazard) begin
            flop_ctr_if = 1'b0;
            mux3_ctr_id = 1'b1;
        end
        else begin
            flop_ctr_if = 1'b1;
            mux3_ctr_id = 1'b0;
        end
    end

endmodule