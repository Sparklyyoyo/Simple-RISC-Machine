/*
--- File:    cpu_system.sv
--- Module:  mydecoder
--- Brief:   3-to-8 one-hot decoder for register indexing.
---
--- Interfaces:
---   Inputs  : in[2:0]
---   Outputs : out[7:0] (one-hot)
---
--- Author: Joey Negm
*/

module mydecoder(
    input  logic [2:0] in,
    output logic [7:0] out
    );
    logic [7:0] out = 8'd1 << in;
endmodule