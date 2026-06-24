import arcabuco_core_pack::*;
module arcabuco_control_decoder (
t_instruction          cmd         ,       
input  logic           IF_ID_stall ,
input  logic           ifNoStall   ,
input  logic           BPU_out     ,     
output logic           BPU_req_event, 
output logic           jump        ,   
output logic           muldiv      , 
output logic           preaccess   ,   
output logic           jalr        ,
output logic           IF_mux1     ,
output logic           ID_mux2     ,
output logic           ID_mux4     ,
output logic           ID_mux5     ,
output logic           WB_reg_write,
output logic [1:0]     ID_mux1     ,
output t_alu_opcode    EX_ALU      ,
output t_muldiv_opcode EX_MUL      ,
output logic           EX_MUL_en   ,
output logic           EX_mux3     ,
output logic [2:0]     MEM_DM_read ,
output logic [1:0]     MEM_DM_write,
output logic [1:0]     WB_mux1     
);

always_comb begin
//Default values 
    //instruction fetch outputs
    IF_mux1      = 1'd0;    
    ID_mux1      = 2'd0;  // these two are 0 so when flush is sent, the flushed address is not lost.
    ID_mux2      = 1'd0;   
    ID_mux4      = 1'd1;   // this is 1 unless adder output in ID sends to ALU
    ID_mux5      = 1'd1;   // this is 1 unless PC+4 is saved
    //execution outputs
    EX_mux3      = 1'd0; 
    EX_ALU       = alu_nop2;
    EX_MUL       = mul;
    EX_MUL_en    = 1'd0;
    //Memory outputs
    MEM_DM_read  = 3'd0;
    MEM_DM_write = 2'd0;
    //WB outputs
    WB_mux1      = 2'd0;
    WB_reg_write = 1'd0; 
    //Special outputs 
    BPU_req_event= 1'd0;  // event is basically comparing guess/answer, and correction if necessary. happens 1 cycle after branch, so branch causes BPU_req_event.
    jump         = 1'd0;
    muldiv       = 1'd0;
    preaccess    = 1'd0;  // access is basically memory operation.
    jalr         = 1'd0; 
  
  
    case (cmd)
        inst_lb : begin
                EX_ALU       = alu_add;
                MEM_DM_read  = 3'd1;  // read byte signed                
                WB_mux1      = 2'd1;      
                WB_reg_write = 1'd1;
                preaccess    = ~IF_ID_stall;
        end
        inst_lh : begin
                EX_ALU       = alu_add;
                MEM_DM_read  = 3'd2;  // read halfword signed
                WB_mux1      = 2'd1;      
                WB_reg_write = 1'd1;                
                preaccess    = ~IF_ID_stall;
         end
          
        inst_lw : begin
                EX_ALU       = alu_add;
                MEM_DM_read  = 3'd3;  // read word
                WB_mux1      = 2'd1;      
                WB_reg_write = 1'd1;
                preaccess    = ~IF_ID_stall;
         end

        inst_lbu : begin
                EX_ALU       = alu_add;
                MEM_DM_read  = 3'd4;  // read byte unsigned                
                WB_mux1      = 2'd1;     
                WB_reg_write = 1'd1;                
                preaccess    = ~IF_ID_stall;
         end

        inst_lhu : begin
                EX_ALU       = alu_add;
                MEM_DM_read  = 3'd5;  // read halfword unsigned                
                WB_mux1      = 2'd1;      
                WB_reg_write = 1'd1;               
                preaccess    = ~IF_ID_stall;
         end

    ////////////////////  STORE  ////////////////////
          
        inst_sb : begin
                EX_ALU       = alu_add;               
                MEM_DM_write = 2'd1;  // write byte                
                preaccess    = ~IF_ID_stall;
         end

        inst_sh : begin
                EX_ALU       = alu_add;
                MEM_DM_write = 2'd2; // write halfword                
                preaccess    = ~IF_ID_stall;
         end
          
        inst_sw : begin
                EX_ALU       = alu_add;               
                MEM_DM_write = 2'd3;  // write word
                preaccess    = ~IF_ID_stall;
         end

    ////////////////////  SHIFT  ////////////////////
          
        inst_sll : begin
                EX_ALU       = alu_sll;          
                EX_mux3      = 1'd1;          //ALUSrc = reg2
                WB_reg_write = 1'd1;
         end

        inst_slli : begin
                EX_ALU       = alu_sll; 
                WB_reg_write = 1'd1;
         end
          
        inst_srl : begin
                EX_ALU       = alu_srl;                 
                EX_mux3      = 1'd1;          //ALUSrc = reg2
                WB_reg_write = 1'd1;
         end

        inst_srli : begin
                EX_ALU       = alu_srl;
                WB_reg_write = 1'd1;
         end
         
        inst_sra : begin         
                EX_ALU       = alu_sra;
                EX_mux3      = 1'd1;          //ALUSrc
                WB_reg_write = 1'd1;
         end

        inst_srai : begin
                EX_ALU       = alu_sra;  
                WB_reg_write = 1'd1;
         end

    //////////////////  ARITHMETIC  //////////////////
          
        inst_add : begin                 
                EX_mux3      = 1'd1;          //ALUSrc
                EX_ALU       = alu_add;
                WB_reg_write = 1'd1;
         end

        inst_addi : begin
                EX_ALU  = alu_add;
                WB_reg_write = 1'd1;
         end

        inst_sub : begin 
                EX_ALU       = alu_sub;        
                EX_mux3      = 1'd1;           // ALUSrc (reg2 vs imm)
                WB_reg_write = 1'd1;
         end

        inst_lui : begin
                WB_reg_write = 1'd1;
         end

        inst_auipc : begin
                EX_ALU  = alu_nop1;
                ID_mux4 = 1'd0;
                WB_reg_write = 1'd1;
         end

    ////////////////////  LOGICAL  ////////////////////

        inst_xor_ : begin
                EX_ALU       = alu_xor;         
                EX_mux3      = 1'd1;          //ALUSrc
                WB_reg_write = 1'd1;
         end

        inst_xori : begin
                EX_ALU       = alu_xor;
                WB_reg_write = 1'd1;
         end

        inst_or_ : begin 
                EX_ALU       = alu_or;          
                EX_mux3      = 1'd1;          //ALUSrc
                WB_reg_write = 1'd1;
         end

        inst_ori : begin
                EX_ALU       = alu_or;   
                WB_reg_write = 1'd1;
         end

        inst_and_ : begin  
                EX_ALU       = alu_and;        
                EX_mux3      = 1'd1;          //ALUSrc
                WB_reg_write = 1'd1;
         end

        inst_andi : begin
                EX_ALU       = alu_and;
                WB_reg_write = 1'd1;
         end

    //////////////////  COMPARE  //////////////////

        inst_slt : begin 
                EX_ALU       = alu_slt;            
                EX_mux3      = 1'd1;          // reg2 vs imm
                WB_reg_write = 1'd1;
         end

        inst_slti : begin
                EX_ALU       = alu_slt; 
                WB_reg_write = 1'd1;
         end

        inst_sltu : begin   
                EX_ALU       = alu_sltu;                
                EX_mux3      = 1'd1;          // reg2 vs imm
                WB_reg_write = 1'd1;
         end

        inst_sltiu : begin
                EX_ALU       = alu_sltu;  
                WB_reg_write = 1'd1;
         end

    ///////////////////  BRANCH  /////////////////// (all same except ALU operation)
                                                    // 
                                                    // if fail = 1, flush and correct adress

        inst_beq : begin    
                EX_ALU   = alu_eq;             
                IF_mux1  = BPU_out;            
                EX_mux3  = 1'd1;                   
                BPU_req_event = ifNoStall; // event only if no stall
         end

        inst_bne : begin         
                EX_ALU   = alu_neq;
                IF_mux1  = BPU_out;               
                EX_mux3  = 1'd1;                     
                BPU_req_event = ifNoStall;     // event only if no stall
         end

        inst_blt : begin          
                EX_ALU   = alu_slt;
                IF_mux1  = BPU_out;               
                EX_mux3  = 1'd1;                 
                BPU_req_event = ~IF_ID_stall;    // event only if no stall
         end

        inst_bge : begin 
                EX_ALU  = alu_grt;        
                IF_mux1 = BPU_out;                
                EX_mux3 = 1'd1;                  
                BPU_req_event = ~IF_ID_stall;    // event only if no stall
         end

        inst_bltu : begin         
                EX_ALU   = alu_sltu ;
                IF_mux1  = BPU_out  ;              
                EX_mux3  = 1'd1;                 
                BPU_req_event = ~IF_ID_stall;    // event only if no stall
         end
         
        inst_bgeu : begin         
                EX_ALU   = alu_grtu ; 
                IF_mux1  = BPU_out  ;              
                EX_mux3  = 1'd1;                   
                BPU_req_event = ~IF_ID_stall;    // event only if no stall
         end
    ////////////////////  jump  ////////////////////

        inst_jal : begin         
                IF_mux1      = 1'd0; // sum -> PC
                ID_mux4      = 1'd0;  
                ID_mux5      = 1'd0;  // PC + 4 -> ALU                
                EX_mux3      = 1'd1;  
                WB_reg_write = 1'd1;
                
        //      jump = ifNoStall
                jump = 1'b1;
         end

        inst_jalr : begin         
                IF_mux1      = 1'd1;  // sum -> PC
                ID_mux1      = 2'd1;  //
                ID_mux2      = 1'd1;  // rs1 + imm(shifted) calculated 
                ID_mux4      = 1'd0;  
                ID_mux5      = 1'd0;  // PC + 4 -> ALU                
                EX_mux3      = 1'd1; 
                WB_reg_write = 1'd1;                
                jump         = ifNoStall;
                jalr         = 1'd1;
         end

    //////////////////  MUL/DIV  //////////////////
        inst_mul : begin
                EX_MUL       = mul;         
                EX_mux3      = 1'd1;  //Data Src
                EX_MUL_en    = 1'd1;                
                WB_mux1      = 2'd2;          // these are delayed to match data in muldiv
                WB_reg_write = 1'd1;                
                muldiv       = ~IF_ID_stall;
         end

        inst_mulh : begin       
                EX_MUL       = mulh;
                EX_mux3      = 1'd1;  
                EX_MUL_en    = 1'd1;                
                WB_mux1      = 2'd2;      
                WB_reg_write = 1'd1;                
                muldiv       = ~IF_ID_stall;
         end

        inst_mulhsu : begin            
                EX_MUL       = mulhsu;              
                EX_mux3      = 1'd1;  
                EX_MUL_en    = 1'd1;
                WB_mux1      = 2'd2;      
                WB_reg_write = 1'd1;                
                muldiv       = ~IF_ID_stall;
         end

        inst_mulhu : begin           
                EX_MUL       = mulhu;            
                EX_mux3      = 1'd1;  
                EX_MUL_en    = 1'd1;                
                WB_mux1      = 2'd2;      
                WB_reg_write = 1'd1;                
                muldiv       = ~IF_ID_stall;
         end

        inst_div : begin        
                EX_MUL       = div;     
                EX_mux3      = 1'd1;  
                EX_MUL_en    = 1'd1;
                WB_mux1      = 2'd2;      
                WB_reg_write = 1'd1;                
                muldiv       = ~IF_ID_stall;
         end

        inst_divu : begin 
                EX_MUL       = divu;                   
                EX_mux3      = 1'd1;  
                EX_MUL_en    = 1'd1;
                WB_mux1      = 2'd2;      
                WB_reg_write = 1'd1;                
                muldiv       = ~IF_ID_stall;
         end

        inst_rem : begin
                EX_MUL       = rem;                   
                EX_mux3      = 1'd1;  
                EX_MUL_en    = 1'd1;
                WB_mux1      = 2'd2;      
                WB_reg_write = 1'd1;                
                muldiv       = ~IF_ID_stall;
         end

        inst_remu : begin 
                EX_MUL       = remu;                   
                EX_mux3      = 1'd1;  
                EX_MUL_en    = 1'd1;
                WB_mux1      = 2'd2;      
                WB_reg_write = 1'd1;                
                muldiv       = ~IF_ID_stall;
         end
     endcase
end
endmodule
