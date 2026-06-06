//should we keep this module as in the original ?
module arcabuco_write_back (
    // -----------------------------
    // Inputs
    // -----------------------------
    input  logic [31:0] mem_out,
    input  logic [31:0] alu_out,
    input  logic [31:0] mul_out,

    // Control
    input  logic [1:0]  mux1_select,

    // -----------------------------
    // Outputs
    // -----------------------------
    output logic [31:0] out
);

    always_comb begin
        if (mux1_select == 2'd0) begin
            out = alu_out;                 // ALU out
        end
        else if (mux1_select == 2'd1) begin
            out = mem_out;                 // MEM out 
        end
        else begin
            out = mul_out;                 // MUL out
        end
    end

endmodule