package arcabuco_core_pack;
typedef enum logic [3:0]{ alu_sll, alu_srl,  alu_sra, alu_add, alu_sub, alu_xor,  alu_or,   alu_and, alu_slt,
                          alu_sltu, alu_eq,  alu_neq, alu_grt, alu_grtu, alu_nop1, alu_nop2} t_alu_opcode;

typedef enum logic [1:0]{ mul, div, nop} t_muldiv_opcode;
endpackage
