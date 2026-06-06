module regfile(
	input		   clk,rst_n,
	input  		   rd_wen    ,
	input  [31:0]  rd_data   ,
	input  [4:0]   addr_rd   ,
	input  [4:0]   addr_rs1  ,
	input  [4:0]   addr_rs2  ,
	output [31:0]  rs1_data_r,
	output [31:0]  rs2_data_r
);


	logic [31:0] regfile [31:1];
	//registers write logic
	always_ff @(posedge clk or negedge rst_n) begin
		if(rd_wen &&  (addr_rd!=5'd0) )begin
			regfile[addr_rd] <= rd_data;
		end
	end	
		
	//read  logic and bypass multiplexers	
	assign rs1_data_r =       addr_rs1 == 5'd0 			?  32'd0  : 
		 				((addr_rs1==addr_rd) && rd_wen) ? rd_data : regfile[addr_rs1];

	assign rs2_data_r =       addr_rs2 == 5'd0 			?  32'd0  : 
					    ((addr_rs2==addr_rd) && rd_wen) ? rd_data : regfile[addr_rs2];
	
endmodule