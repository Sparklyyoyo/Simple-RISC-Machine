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