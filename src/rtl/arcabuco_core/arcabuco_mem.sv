module arcabuco_mem (
    input  logic clk,
    input  logic rst_n,

    input  mem_ctrl_t ctrl,
    output logic      ctrl_done,


    input  logic [31:0] in_ALUdata,
    input  logic [31:0] in_data,

    output logic signed [31:0] out_data,

    mem_if.master dmem
);


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
    //TODO revist these they seem to be not working in sv
    always_comb begin
        case (pre_read)
            3'd1: // lb
                out_data = $signed((readed_d >> (addr_LSB_R << 3)) & 8'hFF);

            3'd2: // lh
                out_data = $signed((readed_d >> (addr_LSB_R[1] << 4)) & 16'hFFFF);

            3'd4: // lbu
                out_data = {24'b0, 8'(readed_d >> (addr_LSB_R << 3)) & 8'hFF};

            3'd5: // lhu
                out_data = {16'b0, 16'(readed_d >> (addr_LSB_R[1] << 4)) & 16'hFFFF};

            3'd3: // lw
                out_data = $signed(readed_d);

            default:
                out_data = '0;
        endcase
    end

endmodule