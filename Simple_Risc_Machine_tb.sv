
module cpu_tb;

    reg clk, reset, s, load, err;
    reg [15:0] in;

    wire [15:0] out;
    wire N, V, Z, w;

    cpu DUT(clk,reset,s,load,in,out,N,V,Z,w);

    initial begin //Clk rises and falls until test bench ends
        clk = 0;
        #5;
        forever begin
            clk = 1;
            #5;

            clk = 0;
            #5;
        end
    end

    task check; //Task which makes sure unit I am testing is the same as expected output.

        input [15:0] test;
        input [15:0] expected_output;

        begin
            if(test !== expected_output) begin
                $display("Error: Output is %b, expected output is %b.", test, expected_output);
                err = 1'b1; //If they are not the same, make err = 1 and display an error.
            end
        end
    endtask

    initial begin

        err = 1'b0; //Initializing variables

        in = 16'b1101000000000111;
        s = 1'b1;
        reset = 1'b1;
        load = 1'b1;

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

        #30

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
            $display("FAILED"); //Displaying "FAILED" if err = 1, otherwise "PASSED"

        else
            $display("PASSED");
        
        $stop;
    end
endmodule