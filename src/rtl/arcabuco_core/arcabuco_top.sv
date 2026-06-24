import arcabuco_core_pack::*;
module arcabuco_top (
input  logic         clk,
input  logic         rst_n,
mem_if.master        imem,
mem_if.master        dmem  
//val debug      = new debugInterfacenPB(nbits)  
//val formal     = new datapath_formal(nbits)
);

pipe_ctrl_t   pipe_ctrl;
if_ctrl_t     if_ctrl;
id_ctrl_t     id_ctrl;
t_instruction id_ctrl_cmd;
rf_addrs_t    id_addrs_out;
rf_addrs_t    ex_addrs_out;
ex_ctrl_cmd_t ex_ctrl_cmd;
ex_ctrl_rsp_t ex_ctrl_rsp;
mem_ctrl_t    mem_ctrl;
logic         mem_ctrl_done;
logic [4:0]   mem_addr_rd;
logic [4:0]   wb_addr_rd;
logic [1:0]   wb_mux_ctrl;

arcabuco_datapath inst_datapath(
.clk          (clk          ),
.rst_n        (rst_n        ),
.pipe_ctrl    (pipe_ctrl    ),
.if_ctrl      (if_ctrl      ),
.id_ctrl      (id_ctrl      ),
.id_ctrl_cmd  (id_ctrl_cmd  ),
.id_addrs_out (id_addrs_out ),
.ex_addrs_out (ex_addrs_out ),
.ex_ctrl_cmd  (ex_ctrl_cmd  ),
.ex_ctrl_rsp  (ex_ctrl_rsp  ),
.mem_ctrl     (mem_ctrl     ),
.mem_ctrl_done(mem_ctrl_done),
.mem_addr_rd  (mem_addr_rd  ),
.wb_addr_rd   (wb_addr_rd   ),
.wb_mux_ctrl  (wb_mux_ctrl  ),
.imem         (imem         ),
.dmem         (dmem         ));

arcabuco_controlpath inst_controlpath(
.clk          (clk          ),
.rst_n        (rst_n        ),
.pipe_ctrl    (pipe_ctrl    ),
.if_ctrl      (if_ctrl      ),
.id_ctrl      (id_ctrl      ),
.id_ctrl_cmd  (id_ctrl_cmd  ),
.id_addrs_out (id_addrs_out ),
.ex_addrs_out (ex_addrs_out ),
.ex_ctrl_cmd  (ex_ctrl_cmd  ),
.ex_ctrl_rsp  (ex_ctrl_rsp  ),
.mem_ctrl     (mem_ctrl     ),
.mem_ctrl_done(mem_ctrl_done),
.mem_addr_rd  (mem_addr_rd  ),
.wb_addr_rd   (wb_addr_rd   ),
.wb_mux_ctrl  (wb_mux_ctrl  ));
endmodule