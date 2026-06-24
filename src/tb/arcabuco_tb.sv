module arcabuco_tb;

    logic clk;
    logic rst_n;

    mem_if imem();
    mem_if dmem();

    //------------------------------------------
    // DUT
    //------------------------------------------
    arcabuco_top dut (
        .clk  (clk),
        .rst_n(rst_n),
        .imem (imem),
        .dmem (dmem)
    );

    //------------------------------------------
    // Clock
    //------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //------------------------------------------
    // Reset
    //------------------------------------------
    initial begin
        $dumpfile("arcabuco_sim.vcd");
        $dumpvars(0,arcabuco_datapath_tb);
        $display("arcabuco sim starts");
        rst_n = 0;

        // Default memory responses
        imem.ready = 1'b1;
        dmem.ready = 1'b1;
        dmem.data_r = '0;

        repeat (5) @(posedge clk);
        rst_n = 1;

        repeat (30) @(posedge clk);
        $finish;
    end

    //------------------------------------------
    // Instruction ROM
    //------------------------------------------
    always_comb begin
        imem.data_r = 32'h00000013; // default NOP

        unique case (imem.addr[31:2])

            // Five NOPs
            0: imem.data_r = 32'h00000013;
            1: imem.data_r = 32'h00000013;
            2: imem.data_r = 32'h00000013;
            3: imem.data_r = 32'h00000013;
            4: imem.data_r = 32'h00000013;

            // addi x1,x0,0
            5: imem.data_r = 32'h00000093;

            // addi x1,x1,1
            6: imem.data_r = 32'h00108093;

            // stay here forever
            default: imem.data_r = 32'h00108093;
        endcase
    end

    //------------------------------------------
    // Simple monitor
    //------------------------------------------
    always @(posedge clk) begin
        if (rst_n && imem.valid) begin
            $display("[%0t] PC=%08x INSN=%08x",
                     $time,
                     imem.addr,
                     imem.data_r);
        end
    end

endmodule
