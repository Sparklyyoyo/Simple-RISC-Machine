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


module cpu(clk,reset,s,load,in,out,N,V,Z,w);
    input clk, reset, s, load;
    input [15:0] in;
    output [15:0] out;
    output N, V, Z, w;

    wire [15:0] iout, sximm5, sximm8, mdata;
    wire [7:0] PC;
    wire [3:0] vsel;
    wire [2:0] nsel, opcode, readnum, writenum, Z_out;
    wire [1:0] op, ALUop, shift;
    wire asel, bsel, loada, loadb, loadc, write, loads, N, V, Z;

    assign Z = Z_out[2];
    assign N = Z_out[1];
    assign V = Z_out[0];

    register i_register(.clk(clk), .load(load), .in(in), .out(iout));

    instruction_decoder i_decoder(.in(iout),.nsel(nsel),.sximm5(sximm5),.sximm8(sximm8),.shift(shift),.PC(PC),.mdata(mdata),.ALUop(ALUop),.readnum(readnum),.writenum(writenum),.opcode(opcode),.op(op));

    FSM d_FSM(.clk(clk),.opcode(opcode),.op(op),.s(s),.reset(reset),.asel(asel),.bsel(bsel),.nsel(nsel),.w(w),
    .loada(loada),.loadb(loadb),.loadc(loadc),.loads(loads),.vsel(vsel),.write(write));

    datapath d_datapath(.mdata(mdata),.sximm5(sximm5),.sximm8(sximm8),.PC(PC),.writenum(writenum),.write(write),.readnum(readnum),.clk(clk),
    .loada(loada),.loadb(loadb),.shift(shift),.asel(asel),.bsel(bsel),.vsel(vsel),.ALUop(ALUop),.loadc(loadc),.loads(loads),.Z_out(Z_out),.datapath_out(out));

endmodule

module datapath(mdata,sximm5,sximm8,PC,writenum,write,readnum,clk,loada,loadb,shift,asel,bsel,vsel,ALUop,loadc,loads,Z_out,datapath_out);

    input [15:0] mdata, sximm8, sximm5; //Initializing variables
    input [7:0] PC;
    input [2:0] writenum, readnum;
    input [1:0] shift,ALUop;
    input [3:0] vsel;
    input write,clk,asel,bsel,loada,loadb,loadc,loads;
    output [15:0] datapath_out;
    output [2:0] Z_out;

    wire [15:0] data_out,Aout,Bout,sout,Ain,Bin,out;
    reg [15:0] data_in;
    wire [2:0] Z;


    always_comb begin
        case(vsel)

        4'b0001: data_in = mdata;
        4'b0010: data_in = sximm8;
        4'b0100: data_in = {8'b00000000, PC};
        4'b1000: data_in = datapath_out;
        endcase
    end

    

    regfile REGFILE(.data_in(data_in),.writenum(writenum),.write(write),.readnum(readnum),.clk(clk),.data_out(data_out)); //Instantiating regfile for data out

    register A(.clk(clk),.load(loada),.in(data_out),.out(Aout)); //Instantiating register A

    assign Ain = asel ? 16'b0 : Aout; //Left multiplexer with asel select

    register B(.clk(clk),.load(loadb),.in(data_out),.out(Bout)); //Instantiating register B

    shifter U1(.in(Bout),.shift(shift),.sout(sout)); //Instantiating shifter

    assign Bin = bsel ? sximm5 : sout; //Right multiplexer with bsel select
 
    ALU U2(.Ain(Ain),.Bin(Bin),.ALUop(ALUop),.out(out),.Z(Z)); //Instantiating ALU

    register01 status(.clk(clk),.load(loads),.in(Z),.out(Z_out)); //Instantiating status register

    register C(.clk(clk),.load(loadc),.in(out),.out(datapath_out)); //Instantiating register C
endmodule

module regfile(data_in,writenum,write,readnum,clk,data_out);

    input [15:0] data_in;
    input [2:0] writenum, readnum;
    input write, clk;
    output [15:0] data_out;

    reg [15:0] data_out;
    wire [7:0] wregchoice;
    wire [7:0] rregchoice;
    reg load0, load1, load2, load3, load4, load5, load6, load7;
    wire [15:0] dataR0, dataR1, dataR2, dataR3, dataR4, dataR5, dataR6, dataR7;
    wire [15:0] R0, R1, R2, R3, R4, R5, R6, R7;

    mydecoder wdecoder(.in(writenum), .out(wregchoice));
    mydecoder rdecoder(.in(readnum), .out(rregchoice));

    register I0(.clk(clk),.load(load0),.in(data_in),.out(dataR0));
    register I1(.clk(clk),.load(load1),.in(data_in),.out(dataR1));
    register I2(.clk(clk),.load(load2),.in(data_in),.out(dataR2));
    register I3(.clk(clk),.load(load3),.in(data_in),.out(dataR3));
    register I4(.clk(clk),.load(load4),.in(data_in),.out(dataR4));
    register I5(.clk(clk),.load(load5),.in(data_in),.out(dataR5));
    register I6(.clk(clk),.load(load6),.in(data_in),.out(dataR6));
    register I7(.clk(clk),.load(load7),.in(data_in),.out(dataR7));

    assign R0 = dataR0;
    assign R1 = dataR1;
    assign R2 = dataR2;
    assign R3 = dataR3;
    assign R4 = dataR4;
    assign R5 = dataR5;
    assign R6 = dataR6;
    assign R7 = dataR7;


    always_comb begin

        load0 = (wregchoice[0] & write) ? 1'b1 : 1'b0; 
        load1 = (wregchoice[1] & write) ? 1'b1 : 1'b0; 
        load2 = (wregchoice[2] & write) ? 1'b1 : 1'b0; 
        load3 = (wregchoice[3] & write) ? 1'b1 : 1'b0; 
        load4 = (wregchoice[4] & write) ? 1'b1 : 1'b0; 
        load5 = (wregchoice[5] & write) ? 1'b1 : 1'b0; 
        load6 = (wregchoice[6] & write) ? 1'b1 : 1'b0; 
        load7 = (wregchoice[7] & write) ? 1'b1 : 1'b0; 

        case(rregchoice)

            8'b00000001: data_out = R0;
            8'b00000010: data_out = R1;
            8'b00000100: data_out = R2;
            8'b00001000: data_out = R3;
            8'b00010000: data_out = R4;
            8'b00100000: data_out = R5;
            8'b01000000: data_out = R6;
            8'b10000000: data_out = R7;
            default: data_out = 16'bxxxxxxxxxxxxxxxx;
        endcase
    end
endmodule

module FSM(clk,opcode,op,s,reset,asel,bsel,nsel,w,loada,loadb,loadc,loads,vsel,write);

    input [2:0] opcode;
    input [1:0] op;
    input clk, s, reset;
    output reg w, asel, bsel, loada, loadb, loadc, loads, write;
    output reg [2:0] nsel;
    output reg [3:0] vsel;


    reg [3:0] present_state;

    always_ff @(posedge clk) begin
        
        if(reset) begin

            present_state = `WAIT;

            nsel = 3'bxxx;
            loada = 1'b0;
            loadb = 1'b0;
            loadc = 1'b0;
            write = 1'b0;
            vsel = 4'bxxxx;
            asel = 1'b0;
            bsel = 1'b0;
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

                `loadA: present_state = `loadB;

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

                `ADD: present_state = `WriteToReg;

                `AND: present_state = `WriteToReg;

                `MVN: present_state = `WriteToReg;

                `CMP: present_state = `WAIT;

                `WriteToReg: present_state = `WAIT;

                `MoveNum: present_state = `WriteToReg;

                default: present_state = 3'bxxx;
            endcase

            case(present_state)

                `loadA: begin

                    nsel = 3'b001;
                    loada = 1'b1;
                    loadb = 1'b0;
                    loadc = 1'b0;
                    loads = 1'b0;
                    write = 1'b0;
                    vsel = 4'b1000;
                    asel = 1'b0;
                    bsel = 1'b0;
                end

                `loadB: begin
                    
                    nsel = 3'b010;
                    loada = 1'b0;
                    loadb = 1'b1;
                    loadc = 1'b1;
                    loads = 1'b0;
                    write = 1'b0;
                    vsel = 4'b1000;
                    asel = 1'b1;
                    bsel = 1'b0;
                end

                `AND: begin
                    
                    nsel = 3'b010;
                    loada = 1'b0;
                    loadb = 1'b0;
                    loadc = 1'b1;
                    loads = 1'b0;
                    write = 1'b0;
                    vsel = 4'b1000;
                    asel = 1'b0;
                    bsel = 1'b0;
                end

                `CMP: begin
                    
                    nsel = 3'b010;
                    loada = 1'b0;
                    loadb = 1'b0;
                    loadc = 1'b1;
                    loads = 1'b1;
                    write = 1'b0;
                    vsel = 4'b1000;
                    asel = 1'b0;
                    bsel = 1'b0;
                end
                    
                `MVN: begin
                    
                    nsel = 3'b010;
                    loada = 1'b0;
                    loadb = 1'b0;
                    loadc = 1'b1;
                    loads = 1'b0;
                    write = 1'b0;
                    vsel = 4'b1000;
                    asel = 1'b0;
                    bsel = 1'b0;
                end

                `ADD: begin
                    
                    nsel = 3'b010;
                    loada = 1'b0;
                    loadb = 1'b0;
                    loadc = 1'b1;
                    loads = 1'b0;
                    write = 1'b0;
                    vsel = 4'b1000;
                    asel = 1'b0;
                    bsel = 1'b0;
                end

                `WriteToReg: begin
                    
                    nsel = 3'b100;
                    loada = 1'b0;
                    loadb = 1'b0;
                    loadc = 1'b1;
                    loads = 1'b0;
                    write = 1'b1;
                    vsel = 4'b1000;
                    asel = 1'b1;
                    bsel = 1'b0;
                end

                `MoveNum: begin
                    
                    nsel = 3'b001;
                    loada = 1'b0;
                    loadb = 1'b0;
                    loadc = 1'b1;
                    loads = 1'b0;
                    write = 1'b0;
                    vsel = 4'b0010;
                    asel = 1'b1;
                    bsel = 1'b0;
                end

                `WriteNum: begin
                    
                    nsel = 3'b001;
                    loada = 1'b0;
                    loadb = 1'b0;
                    loadc = 1'b0;
                    loads = 1'b0;
                    write = 1'b1;
                    vsel = 4'b0010;
                    asel = 1'b1;
                    bsel = 1'b0;
                end

                default: begin
                    
                    nsel = 3'bxxx;
                    loada = 1'b0;
                    loadb = 1'b0;
                    loadc = 1'b1;
                    loads = 1'b0;
                    write = 1'b0;
                    vsel = 4'bxxxx;
                    asel = 1'b0;
                    bsel = 1'b0;
                end

            endcase
        end

    end

    always_comb begin

        if((s == 1'b0) && (present_state == `WAIT))
            w = 1'b1;
        
        else 
            w = 1'b0;
    end
endmodule

module instruction_decoder(in,nsel,sximm5,sximm8,shift,PC,mdata,ALUop,readnum,writenum,opcode,op);

    input [15:0] in;
    input [2:0] nsel;
    output [15:0] sximm5, sximm8, mdata;
    output [7:0] PC;
    output [1:0] op, shift, ALUop;
    output reg [2:0] opcode, readnum, writenum;

    reg [4:0] imm5;
    reg [7:0] imm8, PC;
    reg [2:0] Rn, Rd, Rm;

    assign sximm8 = imm8[7] ?  {8'b1111111,imm8} : {8'b00000000,imm8};
    assign sximm5 = imm5[4] ?  {11'b11111111111,imm5} : {11'b00000000000,imm5};
    assign mdata = 16'd0;

    assign PC = 8'b0;

    assign op = in[12:11];
    assign ALUop = in[12:11];
    assign shift = in[4:3];

    assign opcode = in[15:13];
    
    assign imm5 = in[4:0];
    assign imm8 = in[7:0];
    
    assign Rn = in[10:8];
    assign Rd = in[7:5];
    assign Rm = in[2:0];
   

    always_comb begin

        case(nsel)

        3'b001: begin
            readnum = Rn;
            writenum = Rn;
        end

        3'b010: begin
            readnum = Rm;
            writenum = Rm;
        end

        3'b100: begin
            readnum = Rd;
            writenum = Rd;
        end

        default: begin
            readnum = 3'bxxx;
            writenum = 3'bxxx;
        end
        endcase
    end
endmodule

module register(clk,load,in,out);

    parameter n = 16;
    input clk, load;
    input [n-1:0] in;
    output [n-1:0] out;

    reg [n-1:0] out;
    wire [n-1:0] next_out;

    assign next_out = load ? in : out;

    always_ff @(posedge clk)
        out = next_out;
endmodule

module mydecoder(in,out);

    input [2:0] in;
    output [7:0] out;

    wire [7:0] out = 1 << in;
endmodule

module ALU(Ain, Bin, ALUop, out, Z);

    input [15:0] Ain, Bin;
    input [1:0] ALUop;
    output [15:0] out;
    output [2:0] Z;

    reg [15:0] out;
    reg [15:0] add;
    reg zero, negative, overflow;

    always_comb begin
        
        case (ALUop)

            2'b00: out = Ain + Bin;
            2'b01: out = Ain - Bin;
            2'b10: out = Ain & Bin;
            2'b11: out = ~Bin;
            default: out = 16'bxxxxxxxxxxxxxxxx;
        endcase

        case (out)

            16'b0000000000000000: zero = 1'b1;
            default: zero = 1'b0;
        endcase

        case (out[15])

            1'b1 : negative = 1'b1;
            default: negative = 1'b0;
        endcase

        if((((add[15] == 1'b0) && (Ain[15] == 1'b1) && (Bin[15] == 1'b1))) || (((add[15] == 1'b1) && (Ain[15] == 1'b0) && (Bin[15] == 1'b0))))
            overflow = 1'b1;

        else
            overflow = 1'b0;
    end
    
    assign add = Ain + Bin;
    assign Z[2] = zero;
    assign Z[1] = negative;
    assign Z[0] = overflow;
       
endmodule

module shifter(in,shift,sout);

    input [15:0] in;
    input [1:0] shift;
    output [15:0] sout;

    reg [15:0] sout;
    reg hold;

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
                    hold = in[15];
                    sout = in >> 1;
                    sout[15] = hold;
            end
            
            default: begin
                sout = 16'bxxxxxxxxxxxxxxxx;
                hold = 1'bx;
            end
        endcase
    end
endmodule

module register01(clk,load,in,out);

    parameter n = 3;
    input clk, load;
    input [n-1:0] in;
    output [n-1:0] out;

    reg [n-1:0] out;
    wire [n-1:0] next_out;

    assign next_out = load ? in : out;

    always_ff @(posedge clk)
        out = next_out;
endmodule
