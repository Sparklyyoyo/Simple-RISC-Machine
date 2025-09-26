/*
--- File:    cpu_system.sv
--- Module:  ALU
--- Brief:   16-bit ALU: ADD, SUB, AND, MVN(~B) with Z/N/V flags.
---
--- Description:
---   Computes result per ALUop and derives flags: Z (zero), N (sign),
---   V (add overflow using separate 'add' sum). Original flag timing kept.
---
--- Interfaces:
---   Inputs  : Ain[15:0], Bin[15:0], ALUop[1:0]
---   Outputs : out[15:0], Z[2:0]  (Z[2]=Z, Z[1]=N, Z[0]=V)
---
--- Author: Joey Negm
*/

module ALU(
    input logic [15:0] Ain, 
    input logic [15:0] Bin, 
    input logic [1:0] ALUop, 
    output logic [15:0] out, 
    output logic [2:0] Z
    );

    // --- Internal signals ---
    logic [15:0] add;
    logic        zero, 
    logic        negative, 
    logic        overflow;

    // --- ALU operation and flag logic ---
    always_comb begin
        case (ALUop)
            2'b00: out   = Ain + Bin;
            2'b01: out   = Ain - Bin;
            2'b10: out   = Ain & Bin;
            2'b11: out   = ~Bin;
            default: out = 16'bxxxxxxxxxxxxxxxx;
        endcase

        case (out)
            16'b0000000000000000: zero = 1'b1;
            default:              zero = 1'b0;
        endcase

        case (out[15])
            1'b1 :   negative = 1'b1;
            default: negative = 1'b0;
        endcase

        if((((add[15] == 1'b0) && (Ain[15] == 1'b1) && (Bin[15] == 1'b1))) || (((add[15] == 1'b1) && (Ain[15] == 1'b0) && (Bin[15] == 1'b0))))
            overflow = 1'b1;
        else
            overflow = 1'b0;
    end
    
    // --- Add operation for overflow detection ---
    assign add  = Ain + Bin;
    assign Z[2] = zero;
    assign Z[1] = negative;
    assign Z[0] = overflow;
endmodule