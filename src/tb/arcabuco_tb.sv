`timescale 1 ns/1 ps
import arcabuco_core_pack::t_alu_opcode;
module arcabuco_system_tb;
  logic clock = 0;
	logic reset = 1;
	wire [1:0] io_pad;
  arcabuco_system arcabuco_system_dut (
    .clock(clock),
    .reset (reset),    
    .io_pad(io_pad)
  );
  t_alu_opcode selector=alu_add;
  logic [31:0] in_1=32'd1;
  logic [31:0] in_2=32'd10;
  logic [31:0] arith_res;
  logic        arith_ovf;  
  logic        comp_res;      
  alu alu_dut(
    .selector (selector),
    .in_1     (in_1 & clock),
    .in_2     (in_2),
    .arith_res(arith_res),
    .arith_ovf(arith_ovf),  
    .comp_res (comp_res)      
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
