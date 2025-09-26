/*
--- File:    cpu_system.sv
--- Module:  regfile
--- Brief:   8×16 register file with one write and one read port.
---
--- Description:
---   Decodes writenum/readnum to one-hot enables. Write controlled by 'write'.
---   Read is combinational through a one-hot mux.
---
--- Interfaces:
---   Inputs  : data_in[15:0], writenum[2:0], readnum[2:0], write, clk
---   Outputs : data_out[15:0]
---
--- Author: Joey Negm
*/

module regfile(
    input  logic [15:0] data_in,
    input  logic [2:0]  writenum, 
    input  logic [2:0]  readnum,
    input  logic        write, 
    input  logic        clk,
    output logic [15:0] data_out
    );

    // --- Internal signals ---
    logic [15:0] data_out;
    logic [7:0] wregchoice;
    logic [7:0] rregchoice;

    // --- load signals ---
    logic load0, 
    logic load1, 
    logic load2, 
    logic load3, 
    logic load4, 
    logic load5, 
    logic load6, 
    logic load7;

    // --- Register data signals ---
    logic [15:0] dataR0, 
    logic [15:0] dataR1, 
    logic [15:0] dataR2, 
    logic [15:0] dataR3, 
    logic [15:0] dataR4, 
    logic [15:0] dataR5, 
    logic [15:0] dataR6, 
    logic [15:0] dataR7;

    // --- Register outputs ---
    logic [15:0] R0, 
    logic [15:0] R1, 
    logic [15:0] R2, 
    logic [15:0] R3, 
    logic [15:0] R4, 
    logic [15:0] R5, 
    logic [15:0] R6, 
    logic [15:0] R7;

    // --- Decoder instantiations ---
    mydecoder wdecoder(.in(writenum), .out(wregchoice));
    mydecoder rdecoder(.in(readnum), .out(rregchoice));

    // --- Register instantiations ---
    register I0(.clk(clk),.load(load0),.in(data_in),.out(dataR0));
    register I1(.clk(clk),.load(load1),.in(data_in),.out(dataR1));
    register I2(.clk(clk),.load(load2),.in(data_in),.out(dataR2));
    register I3(.clk(clk),.load(load3),.in(data_in),.out(dataR3));
    register I4(.clk(clk),.load(load4),.in(data_in),.out(dataR4));
    register I5(.clk(clk),.load(load5),.in(data_in),.out(dataR5));
    register I6(.clk(clk),.load(load6),.in(data_in),.out(dataR6));
    register I7(.clk(clk),.load(load7),.in(data_in),.out(dataR7));

    // --- Register output assignments ---
    assign R0 = dataR0;
    assign R1 = dataR1;
    assign R2 = dataR2;
    assign R3 = dataR3;
    assign R4 = dataR4;
    assign R5 = dataR5;
    assign R6 = dataR6;
    assign R7 = dataR7;

    always_comb begin
        // --- Load signal assignments ---
        load0 = (wregchoice[0] & write) ? 1'b1 : 1'b0; 
        load1 = (wregchoice[1] & write) ? 1'b1 : 1'b0; 
        load2 = (wregchoice[2] & write) ? 1'b1 : 1'b0; 
        load3 = (wregchoice[3] & write) ? 1'b1 : 1'b0; 
        load4 = (wregchoice[4] & write) ? 1'b1 : 1'b0; 
        load5 = (wregchoice[5] & write) ? 1'b1 : 1'b0; 
        load6 = (wregchoice[6] & write) ? 1'b1 : 1'b0; 
        load7 = (wregchoice[7] & write) ? 1'b1 : 1'b0; 

        case(rregchoice)
            // --- Read mux ---
            8'b00000001: data_out = R0;
            8'b00000010: data_out = R1;
            8'b00000100: data_out = R2;
            8'b00001000: data_out = R3;
            8'b00010000: data_out = R4;
            8'b00100000: data_out = R5;
            8'b01000000: data_out = R6;
            8'b10000000: data_out = R7;
            default:     data_out = 16'bxxxxxxxxxxxxxxxx;
        endcase
    end
endmodule