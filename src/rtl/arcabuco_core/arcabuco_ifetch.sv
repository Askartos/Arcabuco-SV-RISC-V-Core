import arcabuco_core_pack::*;
module arcabuco_ifetch (
    input  clk, rst_n,
    input  if_ctrl_t ctrl,

    input  logic [31:0] in_pc,

    input  logic [31:0] A,
    input  logic [31:0] B,


    input  logic dbg_halt,
    input  logic dbg_rst,

    input  logic [31:0] mtvec,
    input  logic jtomtvec,

    output logic [31:0] out_pc,
    output logic [31:0] instruction,

    // Instruction memory interface
    mem_if.master imem
);
    
    logic if_halt;

    // Current program counter register
    logic [31:0] crnt_pc;
    // Next pc, combinational logic to remove 1 cycle from instrution latency
    logic [31:0] next_pc;


    // ----------------------------------------
    // Next pc combinational logic 
    // ----------------------------------------

    wire        mux1_select= ctrl.mux1_select;   // 1-bit
    wire [1:0]  mux2_select= ctrl.mux2_select;   // 2-bit
    wire        jump       = ctrl.jump       ;          // asserted when JAL or JALR
    wire        en         = ctrl.en         ;


    always_comb begin
        if(dbg_rst)begin //debug rst
            next_pc = INIT_PC;
        end else if(jtomtvec) begin          // Interrupt handling
            next_pc = mtvec;
        end else if (!ctrl.mux2_select[1]) begin // Branch correction PC (mux2)
            if(!ctrl.mux2_select[0]) begin
                next_pc = A;
            end else begin
                next_pc = B;
            end
        end else if(ctrl.en) begin  // Usual pc behavior enable
            if (ctrl.mux1_select == 1'b1) begin// Jump-controlled PC (mux1)
                next_pc = in_pc;
            end else begin // PC+4 increment logic
                if(!if_halt) //debuger  + mem halt
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
            crnt_pc <= INIT_PC;
        end else begin
            crnt_pc <= next_pc;
        end
    end

    // ----------------------------------------
    // IMEM logic
    // ----------------------------------------
    assign if_halt     =  (dbg_halt | ~imem.ready);
    assign imem.valid  = 1'b1;
    assign imem.abort  = (~imem.ready) & (next_pc != crnt_pc); //evaluate a better approach
    assign imem.we     = 1'b0;
    assign imem.addr   = next_pc;
    assign imem.size   = 2'd2; // 32-bit
    assign imem.data_w =   '0;

    // ----------------------------------------
    // Outputs
    // ----------------------------------------
    assign out_pc      = crnt_pc;
    assign instruction = if_halt ? 32'h13 : imem.data_r;


endmodule