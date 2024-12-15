package arcabuco_core_pack;
typedef enum logic [3:0]{ alu_sll, alu_srl,  alu_sra, alu_add, alu_sub, alu_xor,  alu_or,   alu_and, alu_slt,
                          alu_sltu, alu_eq,  alu_neq, alu_grt, alu_grtu, alu_nop1, alu_nop2} t_alu_opcode;

typedef enum logic [3:0]{ mul, mulh, mulhsu, mulhu, div, divu, rem, remu} t_muldiv_opcode;

localparam [0:0] MEM_SKIP=1'b1;
localparam [0:0] HAVE_MUL=1'b1;
localparam [0:0] MUL_BUFF=1'b1;
localparam int 	 MUL_STAGES=2;
//decided to support a maximum of 256 base addr in the system
//most significant byte is destinated for base addr
localparam [7:0] TCM_BASE=8'h01;//Scratchpad base addr 32'h01_000000
localparam [7:0] DPB_BASE=8'h02;//Debug program buffer base addr

endpackage
