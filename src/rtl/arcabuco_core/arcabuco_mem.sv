module arcabuco_mem (
    input  logic clk,
    input  logic rst_n,

    input  mem_ctrl_t ctrl,
    output logic      ctrl_done,

    input  logic [31:0] IM_addr,
    output logic [31:0] IM_data,

    input  logic [31:0] in_ALUdata,
    input  logic [31:0] in_data,

    output logic signed [31:0] out_data,

    input  logic debug_halt,
    output logic IF_halt,

    // Interfaces
    mem_if.master imem,
    mem_if.master dmem
);

    // ----------------------------------------
    // IMEM logic
    // ----------------------------------------

    logic [31:0] im_addr_dly;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            im_addr_dly <= '0;
        else //TODO evaluate latching this addr if(imem.ready) to avoid unwanted aborts 
            im_addr_dly <= IM_addr;
    end

    assign imem.valid  = 1'b1;
    assign imem.abort  = (~imem.ready) & (IM_addr != im_addr_dly);
    assign imem.we     = 1'b0;
    assign imem.addr   = IM_addr;
    assign imem.size   = 2'd2; // 32-bit
    assign imem.data_w = '0;

    assign IF_halt = ~imem.ready;

    assign IM_data = (debug_halt | ~imem.ready) ? 32'h13 : imem.data_r;

    // ----------------------------------------
    // DMEM logic
    // ----------------------------------------

    assign dmem.valid = (ctrl.write != 2'd0) || ((ctrl.read != 3'd0) && (ctrl.read != 3'd6) && (ctrl.read != 3'd7));
    assign dmem.abort  = 1'b0;
    assign dmem.data_w = in_data;
    assign dmem.we     = (ctrl.write != 2'd0);
    assign dmem.addr   = in_ALUdata;
    assign dmem.size   = ctrl.write;
    assign ctrl_done   = dmem.ready;

    // ----------------------------------------
    // READ logic
    // ----------------------------------------

    logic [31:0] readed_d;
    assign readed_d = dmem.data_r;

    logic [2:0] pre_read;
    logic [1:0] addr_LSB_R;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pre_read   <= 3'd0;
            addr_LSB_R <= 2'd0;
        end else begin
            pre_read   <= ctrl.read;
            addr_LSB_R <= in_ALUdata[1:0];
        end
    end

    always_comb begin
        case (pre_read)
            3'd1: // lb
                out_data = $signed((readed_d >> (addr_LSB_R << 3)) & 8'hFF);

            3'd2: // lh
                out_data = $signed((readed_d >> (addr_LSB_R[1] << 4)) & 16'hFFFF);

            3'd4: // lbu
                out_data = {24'b0, (readed_d >> (addr_LSB_R << 3)) & 8'hFF};

            3'd5: // lhu
                out_data = {16'b0, (readed_d >> (addr_LSB_R[1] << 4)) & 16'hFFFF};

            3'd3: // lw
                out_data = $signed(readed_d);

            default:
                out_data = '0;
        endcase
    end

endmodule
/* removed feedforward paths
    io.out_addr_rd  := io.addr_rd
    io.out_ALUdata  := io.in_ALUdata    
    io.out_fwd1     := io.in_ALUdata
    io.ctrl.rd_addr := io.addr_rd
*/