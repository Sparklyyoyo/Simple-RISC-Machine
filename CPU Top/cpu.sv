`define WAIT 4'b0000
`define loadA 4'b0001
`define loadB 4'b0010
`define ADD 4'b0100
`define WriteToReg 4'b0011
`define DECODE 4'b0110
`define WriteNum 4'b0101
`define MoveNum 4'b0111
`define AND 4'b1000
`define MVN 4'b1001
`define CMP 4'b1010

/*
--- File:    cpu_system.sv
--- Module:  cpu
--- Brief:   Top-level CPU wrapper wiring FSM, instruction decoder, and datapath.
---
--- Description:
---   Latches an input instruction, decodes fields, drives control via FSM,
---   and executes through the datapath. Exposes processor result and flags.
---
--- Interfaces:
---   Clocks/Reset :
---     clk, reset
---   Inputs       :
---     s           : start/step signal
---     load        : instruction register load
---     in[15:0]    : instruction word
---   Outputs      :
---     out[15:0]   : datapath result
---     N,V,Z,w     : condition flags + ready
---
--- Author: Joey Negm
*/

module cpu(
    input  logic        clk,
    input  logic        reset,
    input  logic        s,
    input  logic        load,
    input  logic [15:0] in,
    output logic [15:0] out,
    output logic        N,
    output logic        V,
    output logic        Z,
    output logic        w
    );

    // --- Wires for inter-module connections ---
    logic [15:0] iout, 
    logic [15:0] sximm5, 
    logic [15:0] sximm8, 
    logic [15:0] mdata;

    logic [7:0]  PC;
    logic [3:0]  vsel;

    logic [2:0]  nsel, 
    logic [2:0]  opcode,
    logic [2:0]  readnum, 
    logic [2:0]  writenum, 
    logic [2:0]  Z_out;

    logic [1:0]  op, 
    logic [1:0]  ALUop, 
    logic [1:0]  shift;

    logic       asel, 
    logic       bsel, 
    logic       loada, 
    logic       loadb, 
    logic       loadc, 
    logic       write, 
    logic       loads, 
    logic       N, 
    logic       V, 
    logic       Z;

    // --- Ongoing assignments ---
    assign Z = Z_out[2];
    assign N = Z_out[1];
    assign V = Z_out[0];

    // --- Module instantiations ---
    register i_register(.clk(clk), .load(load), .in(in), .out(iout));

    instruction_decoder i_decoder(.in(iout),.nsel(nsel),.sximm5(sximm5),.sximm8(sximm8),.shift(shift),.PC(PC),.mdata(mdata),.ALUop(ALUop),.readnum(readnum),.writenum(writenum),.opcode(opcode),.op(op));

    FSM d_FSM(.clk(clk),.opcode(opcode),.op(op),.s(s),.reset(reset),.asel(asel),.bsel(bsel),.nsel(nsel),.w(w),
    .loada(loada),.loadb(loadb),.loadc(loadc),.loads(loads),.vsel(vsel),.write(write));

    datapath d_datapath(.mdata(mdata),.sximm5(sximm5),.sximm8(sximm8),.PC(PC),.writenum(writenum),.write(write),.readnum(readnum),.clk(clk),
    .loada(loada),.loadb(loadb),.shift(shift),.asel(asel),.bsel(bsel),.vsel(vsel),.ALUop(ALUop),.loadc(loadc),.loads(loads),.Z_out(Z_out),.datapath_out(out));
endmodule