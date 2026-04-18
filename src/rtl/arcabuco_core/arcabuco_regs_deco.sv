import arcabuco_core_pack::*;
module arcabuco_regs_deco(
	input   logic clock,
	input   logic rst_n,
	//control interface
	input    	 ctrl_wen        ,
	input  [1:0] ctrl_mux1_select,
	input  		 ctrl_mux2_select,
	input   	 ctrl_mux4_select,
	input   	 ctrl_mux5_select,
	output [5:0] ctrl_cmd        ,

	//registers IO
	input  [4:0]  rd_waddr    ,//waddr
	input  [31:0] rd_data_in  ,//rd
	output [31:0] rs1_data_out,//rs1
	output [31:0] rs2_data_out,//rs1

	//Decoder path
    input  [31:0] instruction_raw,//instruction
    output [4:0]  rd_addr_out,
    output [4:0]  rs1_addr_out,
    output [4:0]  rs2_addr_out,
    output [31:0] imm_data_out,
    input  [31:0] in_pc,
    output [31:0] out_pc,
	reg_access.slave debug_regac
);

	//Instruction decoder
    riscv_decoder instruction_decoder (
        .instruction_raw(instruction_raw),
        .rd 			(rd_addr_out),
        .rs1			(rs1_addr_out),
        .rs2			(rs2_addr_out),
        .imm			(imm_data_out),
        .instruction_out(ctrl_cmd)
    );
	
    //Register file

	logic 		 rd_wen;
	logic [31:0] rd_data;
	logic [4:0]  addr_rd;
	logic [4:0]  addr_rs2;
	logic [31:0] rs1_data_r;
	logic [31:0] rs2_data_r;

	regfile regfile(
		//in
		.clock     (clock	  ),
		.rst_n     (rst_n	  ),
		.rd_wen    (rd_wen    ),
		.rd_data   (rd_data   ),
		.addr_rd   (addr_rd   ),
		.addr_rs2  (addr_rs2  ),
		.addr_rs1  (rs1_addr_out),
		//out
		.rs1_data_r(rs1_data_r),
		.rs2_data_r(rs2_data_r)
	);
        
	wire debug_active = (debug_regac.addr[15:0] != 16'h1000) && debug_regac.addr[12] &&  !(|debug_regac.addr[31:13]); //arbitrary condition defined by debug module designer
	//Debug access muxes
	logic [31:0] rs2_dbg_mux;
	always_comb begin
		if(debug_active) begin
			rd_wen             = debug_regac.wen;
			rd_data            = debug_regac.data_w;
			addr_rd            = debug_regac.addr[4:0];
			addr_rs2           = debug_regac.addr[4:0];
			rs2_dbg_mux        = 32'd0;	// TODO optimize this mux might not be needed
			debug_regac.data_r = rs2_data_r;		
		end else begin
			rd_wen             = ctrl_wen;
			rd_data            = rd_data_in;
			addr_rd            = rd_waddr;
			addr_rs2           = rs2_addr_out;
			rs2_dbg_mux        = rs2_data_r;
			debug_regac.data_r = 32'd0;									
		end	
	end
	
	// Early jump or branch target address calculation
	wire [31:0] op1;
	wire [31:0] op2;
	assign op1 = ctrl_mux1_select == 2'd1 ? {imm_data_out[31:1],1'b0} : imm_data_out;
	assign op2 = ctrl_mux2_select == 1'd1 ? {rs1_data_r[31:1],1'b0} : in_pc		;
	assign out_pc = op1 + op2;
	
	// Output operands	logic
	assign rs1_data_out = ctrl_mux4_select ? rs1_data_r  : out_pc;
	assign rs2_data_out = ctrl_mux5_select ? rs2_dbg_mux : in_pc + 32'd4;

endmodule
//Removed feedforward paths
/*
	io.ctrl.rs1:=rs1_addr_out
	io.ctrl.rs2:=rs2_addr_out
	io.A:=io.in_pc 
*/
// 	val fw1 			= Input(UInt(nbits.W))//unused