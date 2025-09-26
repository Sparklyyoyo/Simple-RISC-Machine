/*
--- File:    cpu_tb.sv
--- Module:  cpu_tb
--- Brief:   Top-level testbench for the simple CPU. Drives clock/reset,
---          loads instructions, and checks architected state via a task.
---
--- Description:
---   Generates a free-running clock, applies a sequence of MOV/ADD/AND/MVN/CMP
---   instructions to the DUT, and validates results by peeking the register
---   file and status flags. A lightweight `check` task flags mismatches and
---   accumulates an `err` bit. The bench intentionally keeps simple time-based
---   delays between stimulus steps to avoid functional alterations.
---
--- Interfaces:
---   DUT ports:
---     clk, reset, s, load : TB-driven control lines
---     in                  : 16-bit instruction input bus
---     out                 : 16-bit datapath observation bus (unused here)
---     N, V, Z, w          : status/handshake lines monitored in checks
---
--- Notes:
---   * No functional changes were made—only formatting, comments, and minor
---     hygiene (e.g., consistent delays terminators).
---   * Accesses like `cpu_tb.DUT.d_datapath.REGFILE.Rx` are kept as-is to
---     mirror your style, even though hierarchical peeks are tool/structure-
---     dependent.
---
--- Author: Joey Negm
*/

module cpu_tb;

    // --- Mirror DUT signals ---
    logic        clk;
    logic        reset;

    logic [15:0] in;
    logic        s;
    logic        load;
    logic        err;
    

    logic [15:0] out;
    logic N;
    logic V;
    logic Z;
    logic w;

    cpu DUT(.*);

    // --- Clock generation ---
    initial begin 
        clk = 0;
        #5;
        forever begin
            clk = 1; #5;
            clk = 0; #5;
        end
    end

    // --- Task to check output correctness ---
    task check;
        input [15:0] test;
        input [15:0] expected_output;
        begin
            if(test !== expected_output) begin
                $display("Error: Output is %b, expected output is %b.", test, expected_output);
                err = 1'b1; //If they are not the same, make err = 1 and display an error.
            end
        end
    endtask

    // --- Test sequence ---
    initial begin
        err   = 1'b0; 

        in    = 16'b1101000000000111;
        s     = 1'b1;
        reset = 1'b1;
        load  = 1'b1;

        #10;
        reset = 1'b0;
        
        #30;
        $display("Testing Mov to R0");
        check(cpu_tb.DUT.d_datapath.REGFILE.R0, 16'd7);

        in = 16'b1101000100000010; //Testing MOV to R1
        #30;
        $display("Testing Mov to R1");
        check(cpu_tb.DUT.d_datapath.REGFILE.R1, 16'd2);

        in = 16'b1010000101001000;
        #60;
        $display("Testing Add of R0 and R1 in R2");
        check(cpu_tb.DUT.d_datapath.REGFILE.R2, 16'd16);

        in = 16'b1101001100000011;
        #30;
        $display("Testing Mov to R3");
        check(cpu_tb.DUT.d_datapath.REGFILE.R3, 16'd3);

        in = 16'b1101010000000101;
        #30;
        $display("Testing Mov to R4");
        check(cpu_tb.DUT.d_datapath.REGFILE.R4, 16'd5);

        in = 16'b1010001110100100;
        #60;
        $display("Testing Add of R3 and R4 to R5");
        check(cpu_tb.DUT.d_datapath.REGFILE.R5, 16'd8);
        
        in = 16'b1100000000100000;
        #60;
        $display("Testing Mov to R1 from R0");
        check(cpu_tb.DUT.d_datapath.REGFILE.R1, 16'd7);
        
        in = 16'b1100000010001011;
        $display("Testing Mov to R4 from R3, shifted by 1");
        s = 1'b0;
        #60;
        check(cpu_tb.DUT.d_datapath.REGFILE.R4, 16'd6);

        in = 16'b1010000101000000;
        $display("Testing Add of R0 and R1 in R2");
        s = 1'b1;
        #60;
        check(cpu_tb.DUT.d_datapath.REGFILE.R2, 16'd14);

        in = 16'b1011001110100100;
        $display("Testing AND of R3 and R4 in R5");
        #60;
        check(cpu_tb.DUT.d_datapath.REGFILE.R5, 16'd2);
        in = 16'b1011100011000101;
        #60;

        $display("Testing MVN of R5 in R6");
        check(cpu_tb.DUT.d_datapath.REGFILE.R6, 16'b1111111111111101);

        in = 16'b1010101100000100;
        #60;
        $display("Testing Z");
        check(cpu_tb.DUT.Z, 1'b0);

        $display("Testing N");
        check(cpu_tb.DUT.N, 1'b1);

        $display("Testing V");
        check(cpu_tb.DUT.V, 1'b0);

         $display("Testing w");

        check(cpu_tb.DUT.w, 1'b0);

        if (err) 
            $display("FAILED"); 

        else
            $display("PASSED");
        
        $stop;
    end
endmodule