/*
--- File:    cpu_system.sv
--- Module:  instruction_decoder
--- Brief:   Field extraction and sign-extension for instruction word.
---
--- Description:
---   Parses opcode/op, register indices (Rn/Rd/Rm), shift, imm5/imm8. nsel
---   selects which register index drives readnum/writenum. mdata/PC are
---   hardwired (lab scaffold behavior preserved).
---
--- Interfaces:
---   Inputs  : in[15:0], nsel[2:0]
---   Outputs : sximm5[15:0], sximm8[15:0], mdata[15:0], PC[7:0],
---             op[1:0], shift[1:0], ALUop[1:0], opcode[2:0],
---             readnum[2:0], writenum[2:0]
---
--- Author: Joey Negm
*/

module instruction_decoder(
    input logic  [15:0] in,
    input logic  [2:0]  nsel,
    output logic [15:0] sximm5,
    output logic [15:0] sximm8,
    output logic [1:0]  shift,
    output logic [7:0]  PC,
    output logic [15:0] mdata,
    output logic [1:0]  ALUop,
    output logic [2:0]  readnum,
    output logic [2:0]  writenum,
    output logic [2:0]  opcode,
    output logic [1:0]  op
    );

    // --- Internal signals ---
    logic [4:0] imm5;
    logic [7:0] imm8;
    logic [2:0] Rn, 
    logic [2:0] Rd, 
    logic [2:0] Rm;

    // --- Ongoing instructionassignments ---
    assign sximm8 = imm8[7] ?  {8'b1111111,imm8} : {8'b00000000,imm8};
    assign sximm5 = imm5[4] ?  {11'b11111111111,imm5} : {11'b00000000000,imm5};
    assign mdata  = 16'd0;

    assign PC     = 8'b0;

    assign op     = in[12:11];
    assign ALUop  = in[12:11];
    assign shift  = in[4:3];
    assign opcode = in[15:13];

    assign imm5   = in[4:0];
    assign imm8   = in[7:0];

    assign Rn     = in[10:8];
    assign Rd     = in[7:5];
    assign Rm     = in[2:0];

    // --- Read/Write num logic --- 
    always_comb begin
        case(nsel)
        3'b001: begin
            readnum  = Rn;
            writenum = Rn;
        end

        3'b010: begin
            readnum  = Rm;
            writenum = Rm;
        end

        3'b100: begin
            readnum  = Rd;
            writenum = Rd;
        end

        default: begin
            readnum  = 3'bxxx;
            writenum = 3'bxxx;
        end
        endcase
    end
endmodule