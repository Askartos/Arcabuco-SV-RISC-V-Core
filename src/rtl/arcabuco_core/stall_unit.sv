import arcabuco_core_pack::*;
module stall_unit (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        preaccess,
    input  logic        transaction,
    input  logic        EX_busy,
    input  logic        HDU_wait,
    input  logic        muldiv,
    input  logic        MEM_done,

    output logic        BUS_trans,
    output logic        IF_ID_stall,
    output logic        MEM_WB_stall,
    output logic        MUL_stall,
    output logic        EX_MEM_stall,
    output logic        MUL_stop,
    output logic        MUL_stb,
    output logic        nWait
);

    //--------------------------------------------------------------------------
    // MEMORY Stall
    //--------------------------------------------------------------------------

    logic late_memwait;
    logic later_memwait;
    logic memstop;
    logic access;
    logic memwait;

    logic memwait_skip;
    logic memwait_noskip;
    logic memwait_final;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            late_memwait  <= 1'b0;
            later_memwait <= 1'b0;
            memstop       <= 1'b0;
            access        <= 1'b0;
        end
        else begin
            late_memwait  <= memwait;
            later_memwait <= late_memwait;
            access        <= preaccess;

            case (memstop)
                1'b0: begin
                    if (BUS_trans)
                        memstop <= 1'b1;
                    else
                        memstop <= 1'b0;
                end

                1'b1: begin
                    if (MEM_done)
                        memstop <= 1'b0;
                    else
                        memstop <= 1'b1;
                end
            endcase
        end
    end

    assign BUS_trans = access ? transaction : 1'b0;

    assign memwait_skip   = BUS_trans | (memstop & ~MEM_done);
    assign memwait_noskip = BUS_trans | memstop;

    generate
        if (MEM_SKIP)
            assign memwait_final = memwait_skip;
        else
            assign memwait_final = memwait_noskip;
    endgenerate

    assign memwait = memwait_final;

    //--------------------------------------------------------------------------
    // MULDIV Stall
    //--------------------------------------------------------------------------

    logic late_mulbusy;
    logic later_mulbusy;
    logic mulstop;
    logic mulwait;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            late_mulbusy  <= 1'b0;
            later_mulbusy <= 1'b0;
            mulstop       <= 1'b0;
        end
        else begin
            late_mulbusy  <= EX_busy;
            later_mulbusy <= late_mulbusy;

            case (mulstop)
                1'b0: begin
                    if (muldiv)
                        mulstop <= 1'b1;
                    else
                        mulstop <= 1'b0;
                end

                1'b1: begin
                    // stay stalled until busy goes low
                    if (!EX_busy)
                        mulstop <= muldiv; // immediately re-enter if another op arrives
                    else
                        mulstop <= 1'b1;
                end
            endcase
        end
    end

    assign mulwait = EX_busy ? mulstop : 1'b0;

    assign MUL_stall = ~(mulwait & late_mulbusy);

    //--------------------------------------------------------------------------
    // Pipeline stall generation
    //--------------------------------------------------------------------------

    assign IF_ID_stall = HDU_wait | mulwait | memwait;

    // Equivalent of:
    // val mem_df = (memwait & ~RegNext(memwait,false.B))
    logic memwait_d1;
    logic mem_df;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            memwait_d1 <= 1'b0;
        else
            memwait_d1 <= memwait;
    end

    assign mem_df = memwait & ~memwait_d1;

    // Equivalent RegNext(mem_df,false.B)
    logic mem_df_d1;
    logic mem_df_d2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_df_d1 <= 1'b0;
            mem_df_d2 <= 1'b0;
        end
        else begin
            mem_df_d1 <= mem_df;
            mem_df_d2 <= mem_df_d1;
        end
    end

    //--------------------------------------------------------------------------
    // EX/MEM stall
    //--------------------------------------------------------------------------

    logic EX_MEM_stall_skip;
    logic EX_MEM_stall_noskip;
    logic EX_MEM_stall_final;

    assign EX_MEM_stall_skip =
        memwait & late_memwait;

    assign EX_MEM_stall_noskip =
        (memwait & late_memwait & ~MEM_done) |
        mem_df_d1;

    generate
        if (MEM_SKIP)
            assign EX_MEM_stall_final = EX_MEM_stall_skip;
        else
            assign EX_MEM_stall_final = EX_MEM_stall_noskip;
    endgenerate

    assign EX_MEM_stall = EX_MEM_stall_final;

    //--------------------------------------------------------------------------
    // MEM/WB stall
    //--------------------------------------------------------------------------

    logic MEM_WB_stall_skip;
    logic MEM_WB_stall_noskip;
    logic MEM_WB_stall_final;

    assign MEM_WB_stall_skip =
        (late_memwait & later_memwait & ~MEM_done) |
        (late_mulbusy & later_mulbusy);

    assign MEM_WB_stall_noskip =
        (memwait & later_memwait) |
        (late_mulbusy & later_mulbusy) |
        mem_df_d2;

    generate
        if (MEM_SKIP)
            assign MEM_WB_stall_final = MEM_WB_stall_skip;
        else
            assign MEM_WB_stall_final = MEM_WB_stall_noskip;
    endgenerate

    assign MEM_WB_stall = MEM_WB_stall_final;

    //--------------------------------------------------------------------------
    // Misc outputs
    //--------------------------------------------------------------------------

    assign MUL_stb  = (mulstop & ~late_mulbusy);
    assign MUL_stop = mulstop;
    assign nWait    = ~mulwait & ~memwait;

endmodule