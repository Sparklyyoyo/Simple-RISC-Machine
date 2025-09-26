/*
--- File:    cpu_system.sv
--- Module:  shifter
--- Brief:   16-bit single-bit shifter (LSL/LSR/ASR).
---
--- Description:
---   shift==00: pass-through
---   shift==01: logical left by 1
---   shift==10: logical right by 1
---   shift==11: arithmetic right by 1 (manual sign extend)
---
--- Interfaces:
---   Inputs  : in[15:0], shift[1:0]
---   Outputs : sout[15:0]
---
--- Author: Joey Negm
*/

module shifter(
    input logic [15:0] in,
    input logic [1:0] shift,
    output logic [15:0] sout
    );
    // --- Internal signals ---
    logic hold;

    // --- Shift operation logic ---
    always_comb begin
        case (shift)
            2'b00: begin
               sout = in;
               hold = 1'bx;
            end

            2'b01: begin
                sout = in << 1;
                hold = 1'bx;
            end

            2'b10: begin
                sout = in >> 1;
                hold = 1'bx;
            end

            2'b11: begin
                    hold     = in[15];
                    sout     = in >> 1;
                    sout[15] = hold;
            end
            
            default: begin
                sout = 16'bxxxxxxxxxxxxxxxx;
                hold = 1'bx;
            end
        endcase
    end
endmodule
