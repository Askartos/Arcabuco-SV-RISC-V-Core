import arcabuco_core_pack::*;
module arcabuco_execution(
input   logic clock,
input   logic rst,
//CONTROL IFX TODO convert to a sv interface 
input  t_alu_opcode     alu_selector,
input  t_muldiv_opcode  muldiv_selector,
input  logic            muldiv_en,
input  logic  [1:0]     mux1_select, 
input  logic  [1:0]     mux2_select,
input  logic            mux3_select,
output logic            comp_res,
output logic            mul_busy,
output logic            memory_access,
//END OF CONTROL IFX 
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
assign mux1 = mux1_select==2'd3 ? fw1 :
              mux1_select==2'd2 ? fw2 : rs1;
//operand 2 selection
assign mux2 = mux2_select==2'd3 ? fw1 :
              mux2_select==2'd2 ? fw2 : rs2;
//immidiate selector
assign mux3 = mux3_select==1'd1 ? mux2: imm;

alu alu(
  .selector (alu_selector),
  .in_1     (mux1),
  .in_2     (mux3),
  .arith_res(rd),
  .arith_ovf(),  //TODO check if not used ?
  .comp_res (comp_res)      
);

//muldiv
generate 
  if(HAVE_MUL)begin
    muldiv muldiv(
      .clock   (clock),
      .rst     (rst),
      .selector (muldiv_selector),
      .in_1     (mux1),
      .in_2     (mux2),
      .enable   (muldiv_en),
      .result   (mul_res),
      .busy     (mul_busy)   
    );
  end else begin
    assign mul_res =32'd0;
    assign mul_busy=1'b0;
  end
endgenerate

generate 
  if(MEM_SKIP)begin
    //avoids unnecesary bubble for memory transactions with known latency
    assign memory_access  = rd[31:24] ==TCM_BASE[31:24] ? 1'b0  :
                            rd[31:24] ==DPB_BASE[31:24] ? 1'b0  : 1'b1;
  end else begin
    assign memory_access = 1'b1;
  end
endgenerate

//EX TO MEM OUTPUTS
assign wr_data =mux2;
/*
List of removed feedfoward paths 
  io.ctrl.rd_addr:=io.in_addr_rd
  io.ctrl.r1_addr:=io.in_addr_r1
  io.ctrl.r2_addr:=io.in_addr_r2
  io.addr_rd     :=io.in_addr_rd
  io.B           :=io.in_pc //sh
  //--------------- riscv-formal rs1 and rs2 Interface Signals ---------------//
  io.ALU_in1 := ALU.io.in1
  io.ALU_in2 := tmp_in2
*/
endmodule