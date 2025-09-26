/*
--- File:    cpu_system.sv
--- Module:  register
--- Brief:   Generic positive-edge register (parameterized width).
---
--- Description:
---   Loads input when 'load' is asserted; otherwise holds value. Assignment
---   style is preserved from original RTL.
---
--- Interfaces:
---   Inputs  : clk, load, in[n-1:0]
---   Outputs : out[n-1:0]
---
--- Author: Joey Negm
*/

module register #(parameter n = 16) (
    input  logic  clk,
    input  logic  load,
    input  logic  [n-1:0] in,
    output logic  [n-1:0] out
    );

    logic [n-1:0] next_out;

    // --- Next state logic ---
    assign next_out = load ? in : out;

    always_ff @(posedge clk)
        out = next_out;
endmodule
