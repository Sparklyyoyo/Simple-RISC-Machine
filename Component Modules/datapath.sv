/*
--- File:    cpu_system.sv
--- Module:  datapath
--- Brief:   Register file + operand latches + shifter + ALU + status + C-reg.
---
--- Description:
---   Implements the execution path. vsel selects writeback source into the
---   register file; A/B latches capture operands; optional shift on B; ALU
---   computes result; Z flags are latched; result written to C.
---
--- Interfaces:
---   Inputs  : mdata,sximm8,sximm5,PC, writenum,readnum,shift,ALUop,vsel,
---             write,clk,asel,bsel,loada,loadb,loadc,loads
---   Outputs : datapath_out[15:0], Z_out[2:0]
---
--- Author: Joey Negm
*/

module datapath(
    input  logic [15:0]  mdata, 
    input  logic [15:0]  sximm5, 
    input  logic [15:0]  sximm8, 
    input  logic [7:0]   PC, 
    input  logic [2:0]   writenum, 
    input  logic         write, 
    input  logic [2:0]   readnum, 
    input  logic         clk, 
    input  logic         loada, 
    input  logic         loadb, 
    input  logic [1:0]   shift, 
    input  logic         asel,
    input  logic         bsel, 
    input  logic [3:0]   vsel, 
    input  logic [1:0]   ALUop, 
    input  logic         loadc, 
    input  logic         loads, 
    output logic [2:0]  Z_out, 
    output logic [15:0] datapath_out
    );

    // --- Internal signals ---
    logic [15:0] data_out,
    logic [15:0] Aout,
    logic [15:0] Bout,
    logic [15:0] sout,
    logic [15:0] Ain,
    logic [15:0] Bin,
    logic [15:0] out;
    logic [15:0] data_in;

    logic [2:0]  Z;

    // --- Ongoing assignments ---
    always_comb begin
        case(vsel)
            4'b0001: data_in = mdata;
            4'b0010: data_in = sximm8;
            4'b0100: data_in = {8'b00000000, PC};
            4'b1000: data_in = datapath_out;
        endcase
    end

    // --- Register instantiations ---
    regfile REGFILE(.data_in(data_in),.writenum(writenum),.write(write),.readnum(readnum),.clk(clk),.data_out(data_out)); //Instantiating regfile for data out

    register A(.clk(clk),.load(loada),.in(data_out),.out(Aout)); 
    register B(.clk(clk),.load(loadb),.in(data_out),.out(Bout)); 
    register C(.clk(clk),.load(loadc),.in(out),.out(datapath_out)); 
    register #(3) status(.clk(clk),.load(loads),.in(Z),.out(Z_out)); 

    // --- Onegoing assignments ---
    assign Ain = asel ? 16'b0 : Aout; 
    assign Bin = bsel ? sximm5 : sout; 

    // --- Operation instantiations ---
    shifter U1(.in(Bout),.shift(shift),.sout(sout)); 
    ALU U2(.Ain(Ain),.Bin(Bin),.ALUop(ALUop),.out(out),.Z(Z)); 
endmodule