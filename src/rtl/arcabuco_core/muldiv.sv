import arcabuco_core_pack::*;
module muldiv (
input   logic clock,
input   logic rst,
input   t_muldiv_opcode selector,
input   logic           enable,
input   logic [31:0]    in_1,
input   logic [31:0]    in_2,
output  logic [31:0]    result,
output  logic           busy 
);

logic [31:0] in_1_buff,in_2_buff;
generate 
  if(MUL_BUFF)begin
    always_ff @(posedge clock or posedge rst) begin
      if(rst) begin
        in_1_buff <= '0;
        in_2_buff <= '0;
      end else begin
        in_1_buff <= in_1;
        in_2_buff <= in_2;
      end
    end
  end else begin
    assign in_1_buff = in_1;
    assign in_2_buff = in_2;
  end
endgenerate

wire ismulS   = selector==mulh || selector==mulhsu;
wire ismulSU  = selector==mulhsu;
logic signed [32:0] mulin_1_sig,mulin_2_sig;
assign mulin_1_sig= {in_1_buff[31] &(ismulS)           , in_1_buff};
assign mulin_2_sig= {in_2_buff[31] &(ismulS&!ismulSU)  , in_2_buff};

logic signed [63:0] mul_res;

assign mul_res = mulin_1_sig * mulin_2_sig;


wire isdivS       = selector==div;
logic signed [32:0] divin_1_sig,divin_2_sig;
assign divin_1_sig = {(in_1_buff[31]&&isdivS) , in_1_buff};
assign divin_2_sig = {(in_2_buff[31]&&isdivS) , in_2_buff};

wire divOverflow  = (in_1_buff == 32'h7FFF_FFFF) && (in_2_buff==32'hFFFF_FFFF);
wire divZero      = in_2_buff==32'd0;

logic signed [63:0] div_res_unsig,div_res_sig;
assign div_res_unsig = divZero    ? 64'hFFFF_FFFF_FFFF_FFFF : (divin_1_sig/divin_2_sig) ;
assign div_res_sig   = divOverflow? 64'hFFFF_FFFF_8000_0001 : div_res_unsig;

logic signed [63:0] rem_res_unsig,rem_res_sig;
assign rem_res_unsig = divZero    ? {32'hFFFF_FFFF,in_1_buff} : (divin_1_sig%divin_2_sig) ;
assign rem_res_sig   = divOverflow? 64'hFFFF_FFFF_0000_0000 : rem_res_unsig;

logic [31:0] reg_result;
always_comb begin
  case(selector)
    mul:begin 
      reg_result = mul_res[31:0];
    end
    mulh:begin
      reg_result = mul_res[63:32];
    end
    mulhsu:begin
      reg_result = mul_res[63:32];
    end
    mulhu:begin
      reg_result = mul_res[63:32];
    end
    div:begin
      reg_result = div_res_sig[31:0];
    end
    divu:begin
      reg_result = div_res_unsig[31:0];
    end
    rem:begin
      reg_result = rem_res_sig[31:0];
    end
    remu:begin
      reg_result = rem_res_unsig[31:0];
    end
  endcase
end

logic done;
logic [$clog2(MUL_STAGES+2)-1 : 0] counter;
generate 
  if(MUL_BUFF)begin
    assign done = counter == ($bits(counter)'(MUL_STAGES+2));
  end else begin
    assign done = counter == ($bits(counter)'(MUL_STAGES+1));
  end
endgenerate

assign busy = enable && !done;
always_ff @(posedge clock or posedge rst) begin : proc_counter
  if(rst) begin
    counter <= '0;
  end else if(busy) begin
    counter <= counter+1;
  end else begin
    counter <= '0;

  end
end
// Define a shift register array with MUL_STAGES
logic [31:0] pipeline [MUL_STAGES-1:0];

always_ff @(posedge clock or posedge rst) begin
  if (rst) begin
    // Reset all MUL_STAGES of the shift register
    for (int i = 0; i < MUL_STAGES; i++) begin
      pipeline[i] <= 32'd0;
    end
  end else begin
    // Shift data through the MUL_STAGES
    pipeline[0] <= reg_result;
    for (int i = 1; i < MUL_STAGES; i++) begin
      pipeline[i] <= pipeline[i-1];
    end
  end
end
// Output the final stage
assign result = pipeline[MUL_STAGES-1];
endmodule