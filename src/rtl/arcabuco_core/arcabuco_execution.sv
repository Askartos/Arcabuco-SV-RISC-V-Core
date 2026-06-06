import arcabuco_core_pack::*;
module arcabuco_execution(
input   logic clk,
input   logic rst_n,
//CONTROL IFX 
input  ex_ctrl_cmd_t    ctrl_in,
output ex_ctrl_rsp_t    ctrl_out,
//DATAPATH SIGNALS
input  logic [31:0] rs1,    //register operand 1
input  logic [31:0] rs2,    //register operand 2
input  logic [31:0] imm,    //immidiate value
input  logic [31:0] fw1,    //forward value MEM TODO change to descriptive name
input  logic [31:0] fw2,    //forward value WB  TODO change to descriptive name
output logic [31:0] wr_data,//Data to be writen by MEM
output logic [31:0] rd,     //result of alu
output logic [31:0] mul_res//result of muldiv
);
logic [31:0] mux1;
logic [31:0] mux2;
logic [31:0] mux3;
//operand 1 selection
assign mux1 = ctrl_in.mux1_select==2'd3 ? fw1 :
              ctrl_in.mux1_select==2'd2 ? fw2 : rs1;
//operand 2 selection
assign mux2 = ctrl_in.mux2_select==2'd3 ? fw1 :
              ctrl_in.mux2_select==2'd2 ? fw2 : rs2;
//immidiate selector
assign mux3 = ctrl_in.mux3_select==1'd1 ? mux2: imm;

riscv_alu alu(
  .selector (ctrl_in.alu_selector),
  .in_1     (mux1),
  .in_2     (mux3),
  .arith_res(rd),
  .arith_ovf(),  //TODO check if not used ?
  .comp_res (ctrl_out.comp_res)      
);

//muldiv
generate 
  if(HAVE_MUL)begin
    muldiv muldiv(
      .clk      (clk),
      .rst_n    (rst_n),
      .selector (ctrl_in.muldiv_selector),
      .in_1     (mux1),
      .in_2     (mux2),
      .enable   (ctrl_in.muldiv_en),
      .result   (mul_res),
      .busy     (ctrl_out.mul_busy)   
    );
  end else begin
    assign mul_res =32'd0;
    assign ctrl_out.mul_busy=1'b0;
  end
endgenerate

generate 
  if(MEM_SKIP)begin
    //avoids unnecesary bubble for memory transactions with known latency
    assign ctrl_out.memory_access  =  rd[31:24] ==TCM_BASE ? 1'b0  :
                                      rd[31:24] ==DPB_BASE ? 1'b0  : 1'b1;
  end else begin
    assign ctrl_out.memory_access = 1'b1;
  end
endgenerate

//EX TO MEM OUTPUTS
assign wr_data =mux2;
endmodule