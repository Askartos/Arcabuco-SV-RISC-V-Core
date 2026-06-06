import arcabuco_core_pack::*;
module arcabuco_datapath (
input  logic         clk,
input  logic         rst_n,
input  pipe_ctrl_t   pipe_ctrl,
input  if_ctrl_t     if_ctrl,
input  id_ctrl_t     id_ctrl,
output t_instruction id_ctrl_cmd,
output rf_addrs_t    id_addrs_out,
output rf_addrs_t    ex_addrs_out,
input  ex_ctrl_cmd_t ex_ctrl_in,
output ex_ctrl_rsp_t ex_ctrl_out,
input  mem_ctrl_t    mem_ctrl,
output logic         mem_ctrl_done,
output logic [4:0]   mem_addr_rd,
output logic [4:0]   wb_addr_rd,
input  logic [1:0]   wb_mux_ctrl,
mem_if.master        imem,
mem_if.master        dmem  
//val debug      = new debugInterfacenPB(nbits)  
//val formal     = new datapath_formal(nbits)
);



//--------------- Instruction Fetch Stage ---------------//
   logic [31:0] if_out_pc, if_to_id_pc, id_out_pc,ex_in_pc;
   logic [31:0] if_instruction, if_to_id_instruction;
   arcabuco_ifetch ifetch_inst (
      .clk        (clk), 
      .rst_n      (rst_n),
      .ctrl       (if_ctrl),
      .instruction(if_instruction),
      .out_pc     (if_out_pc),
      .in_pc      (id_out_pc),  //feedback from id output to IF
      .A          (if_to_id_pc),//feedback from id input  to IF
      .B          (ex_in_pc),   //feedback from ex input  to IF   
      //TODO add support for debug   
      .dbg_halt   ('0), //(debug.halt),
      .dbg_rst    ('0), //(debug.rst),
      .mtvec      ('0),//(CSR.OUT_CSR(Implement_CSR.index("mtvec"))),
      .jtomtvec   ('0),//(CSR.jtomtvec),
      .imem       (imem)
   );
   //PIPE IF TO ID
   always_ff @(posedge clk or negedge rst_n) begin
     if(!rst_n)begin
       if_to_id_instruction <= 32'h13;
       if_to_id_pc          <= INIT_PC;
     end else if(pipe_ctrl.if_en) begin
       if_to_id_pc <= if_out_pc;
       if(pipe_ctrl.if_flush)//TODO debug || CSR.instertbubble)
         if_to_id_instruction <= 32'h13;
       else
         if_to_id_instruction <= if_instruction;          
     end
   end

//--------------- Instruction Decoding Stage ---------------//
   //registers IO
   logic [31:0] wb_data_rd  ;// write back data 
   id_ex_pipe_t id_ex_pipe_in,id_ex_pipe_out;  
   reg_if id_dbg_regac ();
   assign id_dbg_regac.addr   = '0;
   assign id_dbg_regac.data_w = '0;
   assign id_dbg_regac.wen    = '0;
   assign id_dbg_regac.ren    = '0;
   arcabuco_regs_deco inst_deco (
      .clk            (clk),
      .rst_n          (rst_n),
      .instruction_raw(if_to_id_instruction),
      .ctrl_in        (id_ctrl),
      .ctrl_cmd       (id_ctrl_cmd),
      .rd_waddr       (wb_addr_rd),
      .rd_data_in     (wb_data_rd),
      .id_ex_outs     (id_ex_pipe_in),
      .in_pc          (if_to_id_pc),
      .out_pc         (id_out_pc),
      .debug_regac    (id_dbg_regac)
   );

   assign id_addrs_out =  id_ex_pipe_in.id_ctrl_out; 
   //PIPE ID TO EX
   always_ff @(posedge clk or negedge rst_n) begin
     if(!rst_n)begin
       id_ex_pipe_out <= '0;
       ex_in_pc       <= '0;
     end else if(pipe_ctrl.if_en) begin 
       id_ex_pipe_out <= id_ex_pipe_in;   
       ex_in_pc       <= id_out_pc; //not merged since it goes to IF   
     end else begin// insert bubble  while pipline is disabled
       id_ex_pipe_out <= '0;    
       // ex_in_pc       <= '0;    //why do we need to clear it ?
     end
   end
   assign ex_addrs_out =  id_ex_pipe_out.id_ctrl_out; 

//--------------- Excecution Stage ---------------//

   logic [31:0] ex_mem_rd,ex_wr_data,ex_rd,ex_mul_res;
   arcabuco_execution inst_ex(
      .clk     (clk),
      .rst_n   (rst_n),
      .ctrl_in (ex_ctrl_in),
      .ctrl_out(ex_ctrl_out),
      .rs1     (id_ex_pipe_out.rs1_data_out),    //register operand 1
      .rs2     (id_ex_pipe_out.rs2_data_out),    //register operand 2
      .imm     (id_ex_pipe_out.imm_data_out),    //immidiate value
      .fw1     (ex_mem_rd), //fw_mem
      .fw2     (wb_data_rd), //fw_wb
      .wr_data (ex_wr_data),
      .rd      (ex_rd),//result of alu
      .mul_res (ex_mul_res)//result of muldiv
   ); 


  //PIPE EX TO MEM
   logic [31:0] ex_mem_wr_data;
   logic [4:0]  ex_mem_addr_rd;
   //PIPE ID TO EX
   always_ff @(posedge clk or negedge rst_n) begin
     if(!rst_n)begin
       ex_mem_addr_rd <= '0;
       ex_mem_wr_data <= '0;
       ex_mem_rd      <= '0;
     end else if(!pipe_ctrl.ex_mem_stall) begin 
       ex_mem_addr_rd <= id_ex_pipe_out.id_ctrl_out.rd_addr_out;   
       ex_mem_wr_data <= ex_wr_data;  
       ex_mem_rd      <= ex_rd; 
      end
   end
//-------------- Memory Stage ---------------//
   logic [31:0] mem_out_data;
   arcabuco_mem inst_mem(
      .clk       (clk  ),
      .rst_n     (rst_n),
      .ctrl      (mem_ctrl),
      .ctrl_done (mem_ctrl_done),
      .in_ALUdata(ex_mem_rd),
      .in_data   (ex_mem_wr_data),
      .out_data  (mem_out_data),
      .dmem      (dmem)
   );
   //PIPE MEM TO WB 
   logic [31:0] mem_wb_alu_data,mem_out_data_reg,ex_wb_mul_res;
   always_ff @(posedge clk or negedge rst_n) begin
      if(!rst_n)begin
         wb_addr_rd      <= '0;
         mem_wb_alu_data <= '0;
         mem_out_data_reg<= '0;
         ex_wb_mul_res   <= '0;
      end else begin
         ex_wb_mul_res   <= ex_mul_res;
         mem_out_data_reg<= mem_out_data;
         mem_wb_alu_data <= ex_mem_rd;
         if(!pipe_ctrl.mem_wb_stall) begin 
            wb_addr_rd <= ex_mem_addr_rd; 
         end
      end
   end
   assign mem_addr_rd   = ex_mem_addr_rd;

   //avoids unnecesary bubble for memory transactions with known latency
   wire [31:0] mem_wb_out_data = MEM_SKIP ? mem_out_data : mem_out_data_reg;

  
//--------------- Write Back Stage ---------------//
arcabuco_write_back inst_wb (
    .mem_out(mem_out_data),
    .alu_out(mem_wb_alu_data),
    .mul_out(ex_wb_mul_res),
    .mux1_select(wb_mux_ctrl),
    .out(wb_data_rd)
);

endmodule
/* 
// TODO add debuger and CSR support
reg_if csr_dbg_regac;
ID.RegsAc.we       := debug.RegsAc.we
ID.RegsAc.reg_addr := debug.RegsAc.reg_addr
ID.RegsAc.data_w   := debug.RegsAc.data_w
debug.RegsAc.data_r:= Mux( CSR_Debug_cond , CSR.data_r , ID.RegsAc.data_r)
//CSR
val CSR_Debug_cond= ~ (debug.RegsAc.reg_addr(nbits-1, 12).orR )
val CSR= Module(new CSR(nbits,resetV)) 
val breakpointinterruption = WireInit(false.B)
CSR.we      :=  CSR_Debug_cond & debug.RegsAc.we
CSR.addr    :=  debug.RegsAc.reg_addr
CSR.data_w  :=  debug.RegsAc.data_w
CSR.io.PC    :=  if_out_pc
CSR.interruption:=(breakpointinterruption | debug.interruption ) & ~debug.halt
//breakpoint
val breakpoint = Module(new breakpoint(nbits))
breakpoint.mstatus := CSR.OUT_CSR(Implement_CSR.index("mstatus"))
breakpoint.tdata1 := CSR.OUT_CSR(Implement_CSR.index("tdata1"))
breakpoint.tdata2 := CSR.OUT_CSR(Implement_CSR.index("tdata2"))
breakpoint.pc := if_to_id_pc
breakpoint.ea := if_to_id_instruction
breakpointinterruption := breakpoint.bpInterruption
debug.breakpoint := breakpoint.bpHalt


//--------------- TODO riscv-formal Interface ---------------//

  formal.comp_ans          :=  EX.ctrl.alu_ans
  formal.pc_IF            :=  if_out_pc            //----- PC from IF
  formal.pc_ID            :=  if_to_id_pc            //----- PC from ID
  formal.imm_EX            :=  id_ex_pipe_out.imm_data_out.asUInt        //----- Imm data from EX
  formal.instruction_ID    :=   if_to_id_instruction        //----Complete instruction from ID----
  formal.rs1_addr_ID      :=  id_ex_pipe_in.rs1_addr_out            //----RS1 addres from ID----
  formal.rs2_addr_ID      :=  id_ex_pipe_in.rs2_addr_out            //----RS2 addres from ID----
  formal.rd_addr_ID        :=  id_ex_pipe_in.rd_addr_out            //----RD addres from ID----
  formal.rd_wdata_WB      :=  WB.out                //----RD data from WB---
  formal.rs1_rdata_EX      :=  inst_ex.alu.in_1            //----RS1 data from EX----
  formal.rs2_rdata_EX      :=  inst_ex.alu.in_2            //----RS2 data from EX---
  formal.cmd_ID            :=  ID.ctrl.cmd          //----Decoded commant from ID---  
  formal.mem_wdata_EX      :=  EX.out_wr_data
  formal.mem_addr_EX      :=  EX.rd
  formal.mem_rdata_MEM    :=  MEM.out_data  
  formal.ctrl_mux1_IF      :=  IF.ctrl.mux1_select  //----Mux1 sel from IF---
  formal.ctrl_mux2_IF      :=  IF.ctrl.mux2_select  //----Mux2 sel from IF---
  formal.A_IF              :=  IF.A                  //---- from IF/ID---
  formal.B_IF              :=  IF.B
  formal.in_pc_IF          :=  IF.in_pc
//------------------------------------------------------//
class progBuffAcces(val nbits: Int) extends Bundle{
  val we             = Output(Bool())
  val data_w         = Output(UInt(nbits.W))
  val addr_wr        = Output(UInt(nbits.W))
  val data_r         = Input(UInt(nbits.W))

  
  val IF_addr        = Output(UInt(nbits.W))
  val IF_data_r     = Input(UInt(nbits.W))   
}
class debugInterface(val nbits: Int) extends Bundle {//TODO check
  val progBuffAc=new progBuffAcces(nbits)
  val nPB = new  debugInterfacenPB(nbits)
}

class debugInterfacenPB(val nbits: Int) extends Bundle {
  val rst   = Input(Bool())
  val halt  = Input(Bool())
  val RegsAc= new RegAcces(nbits)
  val interruption=Input(Bool())
  val breakpoint = Output(Bool())
}

class datapath_formal(val nbits:Int) extends Bundle{
  val comp_ans        = Output(Bool())
  val rs1_addr_ID     = Output(UInt(log2Ceil(nbits).W))
  val rs2_addr_ID     = Output(UInt(log2Ceil(nbits).W))
  val rd_addr_ID       = Output(UInt(log2Ceil(nbits).W))
  val rs1_rdata_EX     = Output(UInt(nbits.W))
  val rs2_rdata_EX     = Output(UInt(nbits.W))
  val rd_wdata_WB      = Output(UInt(nbits.W))  
  val imm_EX          = Output(UInt(nbits.W))
  val pc_IF           = Output(UInt(nbits.W))
  val pc_ID           = Output(UInt(nbits.W))
  val cmd_ID          = Output(UInt(nbits.W))
  val instruction_ID   = Output(UInt(nbits.W))
  val mem_wdata_EX    = Output(UInt(nbits.W))
  val mem_addr_EX      = Output(UInt(nbits.W))  
  val mem_rdata_MEM    = Output(SInt(nbits.W))  
  val ctrl_mux1_IF    =  Output(UInt(1.W))
  val ctrl_mux2_IF    =  Output(UInt(2.W))
  val A_IF            =  Output(UInt(nbits.W))
  val B_IF            =  Output(UInt(nbits.W))
  val in_pc_IF        =  Output(UInt(nbits.W))
}
*/