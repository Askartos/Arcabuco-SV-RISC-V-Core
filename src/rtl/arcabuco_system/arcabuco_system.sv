import arcabuco_system_config::*;

module arcabuco_system (
input clock,
input reset,
output logic [NPADS-1:0] io_pad
);
always_comb begin
  io_pad[0] = reset && clock ;
end
always_ff @(posedge clock)begin
  if(reset)
    io_pad[1] <=1;
  else
    io_pad[1] <=0;
end
endmodule
