import arcabuco_core_pack::*;
module alu(
input t_alu_opcode selector,
input  logic [31:0] in_1,
input  logic [31:0] in_2,
output logic [31:0] arith_res,//arithmetical output result
output logic        arith_ovf,  //overflow flag relevant for add and sub
output logic        comp_res      //result of comparators operations
);
logic [32:0] add_res;//32 bits adder       +overflow bit
logic [32:0] sub_res;//32 bits substractor +overflow bit
//if power opt coudl be worth to do some operand gating to these adders
assign add_res=in_1+in_2;
assign sub_res=in_1-in_2;
assign arith_ovf=selector==alu_add ? add_res[32] :
                 selector==alu_sub ? sub_res[32] : 1'b0;
//Arithmetic operations
always_comb begin
  case(selector)
    alu_sll:begin//shift left
      arith_res = in_1<<in_2[4:0];
    end
    alu_srl:begin//shift right
      arith_res = in_1>>in_2[4:0];
    end
    alu_sra:begin//shift right with sign extension
      if(in_1[31]==1'b0)
        arith_res = in_1>>in_2[4:0];
      else
        arith_res = (in_1>>in_2[4:0]) | (32'hFFFF_FFFF << (32'd32-in_2[4:0])) ;
    end
    alu_add:begin //Addition
      arith_res = add_res[31:0];
    end
    alu_sub:begin //Substraction
      arith_res = sub_res[31:0];
    end
    alu_xor:begin //XOR
      arith_res = in_1^in_2;
    end
    alu_or:begin //OR
      arith_res = in_1|in_2;
    end
    alu_and:begin //AND
      arith_res = in_1&in_2;
    end
    alu_nop1:begin// pass the in_1
      arith_res = in_1;
    end
    alu_nop2:begin//pass the in2
      arith_res = in_2;
    end
    default:begin //no arithmetic op
      arith_res = 32'd0;
    end
  endcase
end
//Comparators 
always_comb begin
  case(selector)
    alu_slt:begin //signedl less than
      comp_res = $signed(in_1) < $signed(in_2);
    end
    alu_sltu:begin//un$signed less than
      comp_res =  in_1 < in_2;
    end
    alu_eq:begin//equal
      comp_res =  in_1 == in_2;
    end
    alu_neq:begin//not equal
      comp_res =  in_1 != in_2;
    end
    alu_grt:begin//greather or equal signed
      comp_res = $signed(in_1) >= $signed(in_2);
    end
    alu_grtu:begin//greather or equal un$signed
      comp_res = in_1 >= in_2 ;
    end
    default:begin //no comparator operation
      comp_res =  1'd0;
    end
  endcase
end
endmodule 
