import arcabuco_core_pack::*;
module arcabuco_controlpath (
input  logic         clk,
input  logic         rst_n,
output pipe_ctrl_t   pipe_ctrl,
output if_ctrl_t     if_ctrl,
output id_ctrl_t     id_ctrl,
input  t_instruction id_ctrl_cmd,
input  rf_addrs_t    id_addrs_out,
input  rf_addrs_t    ex_addrs_out,
output ex_ctrl_cmd_t ex_ctrl_cmd,
input  ex_ctrl_rsp_t ex_ctrl_rsp,
output mem_ctrl_t    mem_ctrl,
input  logic         mem_ctrl_done,
input  logic [4:0]   mem_addr_rd,
input  logic [4:0]   wb_addr_rd,
output logic [1:0]   wb_mux_ctrl
// val formal  = new control_formal TODO add formal 
);

logic BPU_jump, BPU_req_event;
logic IF_ID_stall,IF_no_stall;
logic is_jalr;
typedef struct packed {
    logic           EX_mux3     ;
    t_alu_opcode    EX_ALU      ;
    t_muldiv_opcode EX_MUL      ;
    logic           EX_MUL_en   ;
    mem_ctrl_t      mem_dm      ;
    logic [1:0]     WB_mux1     ;
    logic           WB_reg_write;
} id_ex_ctrl_pipe_t;
id_ex_ctrl_pipe_t id_ex_ctrl,ex_ctrl;
logic is_muldiv,deco_preaccess;
arcabuco_control_decoder inst_ctrl_deco(
.cmd          (id_ctrl_cmd),       
.IF_ID_stall  (IF_ID_stall),
.ifNoStall    (IF_no_stall),
.BPU_out      (BPU_jump),     
.BPU_req_event(BPU_req_event), 
.muldiv       (is_muldiv), 
.preaccess    (deco_preaccess),   
.jalr         (is_jalr),
.jump         (if_ctrl.jump),   
.IF_mux1      (if_ctrl.mux1_select),
.ID_mux1      (id_ctrl.mux1_select),
.ID_mux2      (id_ctrl.mux2_select),
.ID_mux4      (id_ctrl.mux4_select),
.ID_mux5      (id_ctrl.mux5_select),
.WB_reg_write (id_ex_ctrl.WB_reg_write),
.EX_ALU       (id_ex_ctrl.EX_ALU      ),
.EX_MUL       (id_ex_ctrl.EX_MUL      ),
.EX_MUL_en    (id_ex_ctrl.EX_MUL_en   ),
.EX_mux3      (id_ex_ctrl.EX_mux3     ),
.MEM_DM_read  (id_ex_ctrl.mem_dm.read ),
.MEM_DM_write (id_ex_ctrl.mem_dm.write),
.WB_mux1      (id_ex_ctrl.WB_mux1     )
);

logic BPU_fail;
branch_prediction_fsm inst_bpu_fsm(
.clk      (clk),
.rst_n    (rst_n),
.req_event(BPU_req_event),//TODO: check if needs to be flushed
.answer   (ex_ctrl_rsp.comp_res), 
.fail     (BPU_fail),
.jump     (BPU_jump)  
);
assign if_ctrl.mux2_select = BPU_fail ? {1'd0,ex_ctrl_rsp.comp_res} : 2'd2;
assign pipe_ctrl.if_flush  = BPU_fail | (BPU_req_event && !BPU_jump)  | if_ctrl.jump;  //  flush IF when: fail, jump, branch taken by BPU.

forwarding_unit inst_fu(
.clk          (clk),
.rst_n        (rst_n),
.reg_write_mem(mem_wb_ctrl.WB_reg_write),
.reg_write_wb (wb_ctrl.WB_reg_write),
.rs1_ex       (ex_addrs_out.rs1_addr_out),     // rs1 of instruction currently in EX
.rs2_ex       (ex_addrs_out.rs2_addr_out),     // rs2 of instruction currently in EX
.rd_mem       (mem_addr_rd),     // destination register in MEM
.rd_wb        (wb_addr_rd),      // destination register in WB
.ID_cmd       (id_ctrl_cmd),
.mux1_ctr_ex  (ex_ctrl_cmd.mux1_select),
.mux2_ctr_ex  (ex_ctrl_cmd.mux2_select)
);

logic    HDU_mux3_ctr_id,flop_ctr_if;             
hazard_detection_unit inst_hdu (
 .dm_read_ex (ex_ctrl.mem_dm.read),
 .rs1_id     (id_addrs_out.rs1_addr_out),
 .rs2_id     (id_addrs_out.rs2_addr_out),
 .rd_ex      (ex_addrs_out.rd_addr_out),
 .rd_mem     (mem_addr_rd),
 .is_jalr    (is_jalr),
 .mux3_ctr_id(HDU_mux3_ctr_id),
 .flop_ctr_if(flop_ctr_if)
);

logic nWait,preaccess,SU_BUS_trans;
logic MUL_stall,MUL_stb,MUL_stop;
stall_unit inst_su(
.clk          (clk),
.rst_n        (rst_n),
.preaccess    (preaccess),
.transaction  (ex_ctrl_rsp.memory_access),
.EX_busy      (ex_ctrl_rsp.mul_busy),
.HDU_wait     (HDU_mux3_ctr_id),
.muldiv       (is_muldiv),
.MEM_done     (mem_ctrl_done),
.BUS_trans    (SU_BUS_trans),
.IF_ID_stall  (IF_ID_stall),
.MEM_WB_stall (pipe_ctrl.mem_wb_stall),
.EX_MEM_stall (pipe_ctrl.ex_mem_stall),
.MUL_stall    (MUL_stall),
.MUL_stop     (MUL_stop),
.MUL_stb      (MUL_stb),
.nWait        (nWait)
);
assign IF_no_stall     = flop_ctr_if & nWait;
assign if_ctrl.en      = !IF_ID_stall;
assign pipe_ctrl.if_en = !IF_ID_stall;//TODO remove duplicates
wire   ID_flush        = BPU_fail | IF_ID_stall;
assign preaccess       = ID_flush? 1'd0 : deco_preaccess;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ex_ctrl <= 0;
    end else if(!ID_flush) begin
        ex_ctrl <= id_ex_ctrl;
    end else  begin
        ex_ctrl <= 0;
    end
end

t_muldiv_opcode EX_MUL_stalled; 
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        EX_MUL_stalled <= mul;
    end else if(MUL_stall) begin
        EX_MUL_stalled <= ex_ctrl.EX_MUL;
    end
end
assign ex_ctrl_cmd.muldiv_selector = MUL_stb ? ex_ctrl.EX_MUL : EX_MUL_stalled;  // at first cycle, take from pipe. After, take from stall register.
assign ex_ctrl_cmd.mux3_select     = ex_ctrl.EX_mux3;
assign ex_ctrl_cmd.alu_selector    = ex_ctrl.EX_ALU;
assign ex_ctrl_cmd.muldiv_en       = ex_ctrl.EX_MUL_en ||  MUL_stop; //TODO is MUL_stop ever used ?


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mem_ctrl <= '0;
    end else if(!pipe_ctrl.ex_mem_stall) begin
        mem_ctrl <= ex_ctrl.mem_dm;
    end
end

typedef struct packed {
    logic [1:0]     WB_mux1     ;
    logic           WB_reg_write;
} wb_ctrl_pipe_t;
wb_ctrl_pipe_t mem_wb_ctrl,wb_ctrl;
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wb_ctrl      <= '0;
        mem_wb_ctrl  <= '0;
    end else begin
        mem_wb_ctrl.WB_mux1       <= ex_ctrl.WB_mux1;
        mem_wb_ctrl.WB_reg_write  <= ex_ctrl.WB_reg_write;        
        if(!pipe_ctrl.mem_wb_stall)begin
            wb_ctrl      <= mem_wb_ctrl;
        end
    end
end
assign wb_mux_ctrl = wb_ctrl.WB_mux1;
assign id_ctrl.wen = wb_ctrl.WB_reg_write && ((pipe_ctrl.mem_wb_stall &  SU_BUS_trans) | ~pipe_ctrl.mem_wb_stall); // this stops registers from getting written during memory read stall. Change during optimization.

/*

//--------------- TODO riscv-formal Interface ---------------//
//------------------------------------------------------//

//----Write enable signal from ID
    io.formal.wen_ID                :=  DECO.io.out.WB_reg_write

//----PIPE IF enable signal from IF
    io.formal.PIPE_IF_en_ID := ~SU.io.IF_ID_stall

//----Jump signal from ID
    io.formal.jump_ID               :=  if_ctrl.jump

//----IF flush signal from ID

    io.formal.IF_flush_ID       :=  BPU.io.fail | (DECO.io.preevent & ~BPU.io.out)
    
//----Read and Write control signals from MEM
    io.formal.fail:=BPU.io.fail
    io.formal.ctrl_read_MEM := MEM.MEM_DM_read  //io.MEM.read 
    io.formal.ctrl_write_MEM:= MEM.MEM_DM_write //io.MEM.write

*/


endmodule 

 
