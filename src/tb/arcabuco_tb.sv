`timescale 1 ns/1 ps

module arcabuco_system_tb;
  logic clock = 0;
	logic reset = 1;
	wire [1:0] io_pad;
  arcabuco_system arcabuco_system_dut (
    .clock(clock),
    .reset (reset),    
    .io_pad(io_pad)
  );
  import arcabuco_core_pack::*;
  t_alu_opcode selector=alu_add;
  logic [31:0] in_1=32'd1;
  logic [31:0] in_2=32'd10;
  logic [31:0] arith_res;
  logic        arith_ovf;  
  logic        comp_res;
  t_muldiv_opcode  muldiv_selector=mul;  

arcabuco_execution ex_dut(
.clock(clock),
.rst(reset),
//CONTROL IFX TODO convert to a sv interface 
.alu_selector(selector),
.muldiv_selector(muldiv_selector),
.muldiv_en(1'b0),
.mux1_select(2'd1), 
.mux2_select(2'd1),
.mux3_select(1'd1),
//END OF CONTROL IFX 
.rs1(1),    //register operand 1
.rs2(1),    //register operand 2
.imm(1),    //immidiate value
.fw1(1),    //forward value MEM TODO change to descriptive name
.fw2(1)    //forward value WB  TODO change to descriptive name
);

  parameter CLOCK_PERIOD =50;
  always begin
      #(CLOCK_PERIOD/2);
      clock = ~clock;
  end    
  initial    begin
	  $dumpfile("arcabuco_sim.vcd");
	  $dumpvars(0,arcabuco_system_tb);
    $display("arcabuco sim starts");
    #(CLOCK_PERIOD*20);
    reset = 0;
    #(CLOCK_PERIOD*30);
    $finish();
  end
endmodule
