package arcabuco_core_pack;
//Execution 
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


//Instruction decode
typedef enum logic [5:0] {
    inst_invalid = 6'd0,

    // U Type
    inst_lui     = 6'd1,
    inst_auipc   = 6'd2,

    // J Type
    inst_jal     = 6'd3,

    // B Type
    inst_beq     = 6'd4,
    inst_bne     = 6'd5,
    inst_blt     = 6'd6,
    inst_bge     = 6'd7,
    inst_bltu    = 6'd8,
    inst_bgeu    = 6'd9,

    // S Type
    inst_sb      = 6'd10,
    inst_sh      = 6'd11,
    inst_sw      = 6'd12,

    // I Type
    inst_jalr    = 6'd13,
    inst_lb      = 6'd14,
    inst_lh      = 6'd15,
    inst_lw      = 6'd16,
    inst_lbu     = 6'd17,
    inst_lhu     = 6'd18,
    inst_addi    = 6'd19,
    inst_slti    = 6'd20,
    inst_sltiu   = 6'd21,
    inst_xori    = 6'd22,
    inst_ori     = 6'd23,
    inst_andi    = 6'd24,
    inst_slli    = 6'd25,
    inst_srli    = 6'd26,
    inst_srai    = 6'd27,
    inst_ebreak  = 6'd28,
    inst_csrrw   = 6'd29,
    inst_csrrs   = 6'd30,
    inst_csrrc   = 6'd31,
    inst_csrrwi  = 6'd32,
    inst_csrrsi  = 6'd33,
    inst_csrrci  = 6'd34,

    // R Type
    inst_add     = 6'd35,
    inst_mul     = 6'd36,
    inst_sub     = 6'd37,
    inst_sll     = 6'd38,
    inst_mulh    = 6'd39,
    inst_slt     = 6'd40,
    inst_mulhsu  = 6'd41,
    inst_sltu    = 6'd42,
    inst_mulhu   = 6'd43,
    inst_xor_    = 6'd44,
    inst_div     = 6'd45,
    inst_srl     = 6'd46,
    inst_divu    = 6'd47,
    inst_sra     = 6'd48,
    inst_or_     = 6'd49,
    inst_rem     = 6'd50,
    inst_and_    = 6'd51,
    inst_remu    = 6'd52

} t_instruction;

typedef struct packed {
    logic        mux1_select;   // 1-bit
    logic [1:0]  mux2_select;   // 2-bit
    logic        jump;          // asserted when JAL or JALR
    logic        en;
} if_ctrl_t;


endpackage

interface reg_access #(parameter DATA_W=32,
                       parameter ADDR_W=32) ();
    logic [DATA_W-1:0] data_w,data_r;
    logic [ADDR_W-1:0] addr;
    logic              ren, wen;
    modport master(
    input data_r,
    output addr,data_w,wen,ren
    );
    modport slave(
    output data_r,
    input addr,data_w,wen,ren
    );
endinterface