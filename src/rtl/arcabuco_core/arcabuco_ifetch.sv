import arcabuco_core_pack::*;
module arcabuco_ifetch #(
    parameter logic [31:0] RESET_VAL = '0
)(
    input  clk, rst_n,
    input  if_ctrl_t ctrl,

    input  logic [31:0] in_pc,
    output logic [31:0] out_pc,

    input  logic [31:0] A,
    input  logic [31:0] B,

    // Instruction memory interface
    output logic [31:0] IM_addr,
    input  logic [31:0] IM_data,


    input  logic halt,

    input  logic [31:0] mtvec,
    input  logic jtomtvec,

    output logic [31:0] instruction
);

    //ff to findout if we are out of reset (workaround for now) 
    //TODO make sure all control signals let IM_addr=RESET_VAL during reset
    logic valid_pc;
    // Current program counter register
    logic [31:0] crnt_pc;
    // Next pc, combinational logic to remove 1 cycle from instrution latency
    logic [31:0] next_pc;


    // ----------------------------------------
    // Next pc combinational logic 
    // ----------------------------------------
    always_comb begin
        if(!valid_pc)begin
            next_pc = RESET_VAL;
        end else if(jtomtvec) begin          // Interrupt handling
            next_pc = mtvec;
        end else if (!ctrl.mux2_select[1]) begin // Branch correction PC (mux2)
            if(!ctrl.mux2_select[0]) begin
                next_pc = A;
            end else begin
                next_pc = B;
            end
        end else if(ctrl.en) begin  // Usual pc behavior enable
            if (ctrl.mux1_select == 1'b0) begin// Jump-controlled PC (mux1)
                next_pc = in_pc;
            end else begin // PC+4 increment logic
                if(!halt) //debuger halt
                    next_pc = crnt_pc + 32'd4; 
                else
                    next_pc = crnt_pc;
            end
        end else begin
            next_pc = crnt_pc;
        end
    end

    // ----------------------------------------
    // Current pc FF 
    // ----------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            crnt_pc <= RESET_VAL;
            valid_pc<= 1'b0;
        end else begin
            valid_pc<= 1'b1;
            crnt_pc <= next_pc;
        end
    end
    // ----------------------------------------
    // Outputs
    // ----------------------------------------
    assign out_pc      = crnt_pc;
    assign IM_addr     = next_pc;
    assign instruction = IM_data;

endmodule