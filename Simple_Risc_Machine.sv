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

/*
--- File:    cpu_system.sv
--- Module:  FSM
--- Brief:   Instruction control state machine.
---
--- Description:
---   Sequences register loads, ALU op selection, and writeback timing based on
---   opcode/op fields. Synchronous reset returns to WAIT. Output timing and
---   encodings preserved from original RTL.
---
--- Interfaces:
---   Inputs  : clk, opcode[2:0], op[1:0], s, reset
---   Outputs : asel,bsel,nsel[2:0],w,loada,loadb,loadc,loads,write,vsel[3:0]
---
--- Author: Joey Negm
*/

module FSM(
    input  logic       clk,
    input  logic [2:0] opcode,
    input  logic [1:0] op,
    input  logic       s,
    input  logic       reset,
    output logic       asel,
    output logic       bsel,
    output logic [2:0] nsel,
    output logic       w,
    output logic       loada,
    output logic       loadb,
    output logic       loadc,
    output logic       loads,
    output logic [3:0] vsel,
    output logic       write
    );

    // --- State register ---
    logic [3:0] present_state;

    // --- FSM State Transition & Output Logic ---
    always_ff @(posedge clk) begin
        if(reset) begin
            present_state = `WAIT;

            nsel  = 3'bxxx;
            loada = 1'b0;
            loadb = 1'b0;
            loadc = 1'b0;
            write = 1'b0;
            vsel  = 4'bxxxx;
            asel  = 1'b0;
            bsel  = 1'b0;
        end
        else begin
            case(present_state)
                `WAIT: if(s)
                        present_state = `DECODE;
                    else 
                        present_state = `WAIT;
                
                `DECODE:begin
                    if(opcode == 3'b101)
                            present_state = `loadA;
                    else if((opcode == 3'b110 && op == 2'b00)||(opcode == 3'b101 && op == 2'b11))
                            present_state = `loadB;
                    else
                        present_state = `WriteNum;
                end 

                `WriteNum: present_state = `WAIT;
                `loadA: present_state    = `loadB;

                `loadB: begin
                    if (opcode == 3'b110 && op == 2'b00)
                        present_state = `MoveNum;
                    else if(opcode == 3'b101 && op == 2'b10)
                        present_state = `AND;
                    else if(opcode == 3'b101 && op == 2'b11)
                        present_state = `MVN;
                    else if(opcode == 3'b101 && op == 2'b01)
                        present_state = `CMP;
                    else 
                        present_state = `ADD;
                end

                `ADD: present_state        = `WriteToReg;
                `AND: present_state        = `WriteToReg;
                `MVN: present_state        = `WriteToReg;
                `CMP: present_state        = `WAIT;
                `WriteToReg: present_state = `WAIT;
                `MoveNum: present_state    = `WriteToReg;
                default: present_state     = 3'bxxx;
            endcase

            case(present_state)
                `loadA: begin
                    nsel  = 3'b001;
                    loada = 1'b1;
                    loadb = 1'b0;
                    loadc = 1'b0;
                    loads = 1'b0;
                    write = 1'b0;
                    vsel  = 4'b1000;
                    asel  = 1'b0;
                    bsel  = 1'b0;
                end

                `loadB: begin
                    nsel  = 3'b010;
                    loada = 1'b0;
                    loadb = 1'b1;
                    loadc = 1'b1;
                    loads = 1'b0;
                    write = 1'b0;
                    vsel  = 4'b1000;
                    asel  = 1'b1;
                    bsel  = 1'b0;
                end

                `AND: begin
                    nsel  = 3'b010;
                    loada = 1'b0;
                    loadb = 1'b0;
                    loadc = 1'b1;
                    loads = 1'b0;
                    write = 1'b0;
                    vsel  = 4'b1000;
                    asel  = 1'b0;
                    bsel  = 1'b0;
                end

                `CMP: begin
                    nsel  = 3'b010;
                    loada = 1'b0;
                    loadb = 1'b0;
                    loadc = 1'b1;
                    loads = 1'b1;
                    write = 1'b0;
                    vsel  = 4'b1000;
                    asel  = 1'b0;
                    bsel  = 1'b0;
                end
                    
                `MVN: begin
                    nsel  = 3'b010;
                    loada = 1'b0;
                    loadb = 1'b0;
                    loadc = 1'b1;
                    loads = 1'b0;
                    write = 1'b0;
                    vsel  = 4'b1000;
                    asel  = 1'b0;
                    bsel  = 1'b0;
                end

                `ADD: begin
                    nsel  = 3'b010;
                    loada = 1'b0;
                    loadb = 1'b0;
                    loadc = 1'b1;
                    loads = 1'b0;
                    write = 1'b0;
                    vsel  = 4'b1000;
                    asel  = 1'b0;
                    bsel  = 1'b0;
                end

                `WriteToReg: begin
                    nsel  = 3'b100;
                    loada = 1'b0;
                    loadb = 1'b0;
                    loadc = 1'b1;
                    loads = 1'b0;
                    write = 1'b1;
                    vsel  = 4'b1000;
                    asel  = 1'b1;
                    bsel  = 1'b0;
                end

                `MoveNum: begin
                    nsel  = 3'b001;
                    loada = 1'b0;
                    loadb = 1'b0;
                    loadc = 1'b1;
                    loads = 1'b0;
                    write = 1'b0;
                    vsel  = 4'b0010;
                    asel  = 1'b1;
                    bsel  = 1'b0;
                end

                `WriteNum: begin
                    nsel  = 3'b001;
                    loada = 1'b0;
                    loadb = 1'b0;
                    loadc = 1'b0;
                    loads = 1'b0;
                    write = 1'b1;
                    vsel  = 4'b0010;
                    asel  = 1'b1;
                    bsel  = 1'b0;
                end

                default: begin
                    nsel  = 3'bxxx;
                    loada = 1'b0;
                    loadb = 1'b0;
                    loadc = 1'b1;
                    loads = 1'b0;
                    write = 1'b0;
                    vsel  = 4'bxxxx;
                    asel  = 1'b0;
                    bsel  = 1'b0;
                end
            endcase
        end
    end

    // --- 'w' signal logic ---
    always_comb begin
        if((s == 1'b0) && (present_state == `WAIT))
            w = 1'b1;
        else 
            w = 1'b0;
    end
endmodule

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
