`include "../definitions.v"
`timescale 1ns / 1ps

/*
this is the stage register between:
    execution (ex) stage
    memory (mem) stage
 */

module id_ex_reg (
    input clk, rst_n,

    input      ex_hold,                                     // from hazard_unit (discard id result and pause ex)
    output reg mem_no_op,                                   // for alu (stop opeartions)

    input      [`ISA_WIDTH - 1:0] ex_pc_4,                  // from instruction_mem (the current program counter)
    output reg [`ISA_WIDTH - 1:0] mem_pc_4,                 // for ex_mem_reg

    input      ex_reg_write_enable,                         // from id_ex_reg (whether it needs to read from memory)
    output reg mem_reg_write_enable,                        // for mem_wb_reg (whether it needs to read from memory)

    input      [1:0] ex_mem_control,                        // from id_ex_reg ([0] write, [1] read)
    output reg [1:0] mem_mem_control,                       // for: (1) data_mem: both read and write
                                                            //      (2) mem_wb_reg: only read

    input      [`ISA_WIDTH - 1:0] ex_alu_result,            // from alu
    output reg [`ISA_WIDTH - 1:0] ex_operand_1,             // for alu (first oprand for alu)

    input      id_immediate_instruction,                    // from control_unit (whether it is a I type instruction)
    input      [`ISA_WIDTH - 1:0] id_reg_2,                 // from general_reg (second register's value)
    input      [`ISA_WIDTH - 1:0] id_sign_extend_result,    // from sign_extend (16 bit sign extend result)
    output reg [`ISA_WIDTH - 1:0] ex_operand_2,             // for alu (second oprand for alu)

    input      [`REGISTER_SIZE - 1:0] id_src_reg_1,         // from if_id_reg (index of first source register)
    input      [`REGISTER_SIZE - 1:0] id_src_reg_2,         // from if_id_reg (index of second source register)
    input      [`REGISTER_SIZE - 1:0] id_dest_reg,          // from if_id_reg (index of destination resgiter)
    output reg [`REGISTER_SIZE - 1:0] ex_src_reg_1,         // for forwarding_unit
    output reg [`REGISTER_SIZE - 1:0] ex_src_reg_2,         // for forwarding_unit
    output reg [`REGISTER_SIZE - 1:0] ex_dest_reg,          // for forwarding_unit and hazrad_unit
    );

    always @(posedge clk) begin
        if (~rst_n) begin
            {
                ex_no_op,
                ex_pc_4,

                pc_offset,
                ex_reg_write_enable,
                ex_mem_control,
                ex_alu_control,
                ex_operand_1,
                ex_operand_2,
                ex_src_reg_1,
                ex_src_reg_2,
                ex_dest_reg
            }                   <= 0;
        end else if (~if_hold) begin
            ex_no_op            <= 0;
            ex_pc_4             <= id_pc_4;

            pc_offset           <= id_condition_satisfied & id_branch_instruction;
            ex_reg_write_enable <= id_reg_write_enable;
            ex_mem_control      <= id_mem_control;
            ex_alu_control      <= id_alu_control;

            ex_operand_1        <= id_reg_1;
            ex_operand_2        <= id_immediate_instruction ? id_sign_extend_result : id_reg_2;

            ex_src_reg_1        <= id_src_reg_1;
            ex_src_reg_2        <= id_immediate_instruction ? 0 : id_src_reg_2;
            ex_dest_reg         <= id_dest_reg;
        end else
            id_no_op            <= 1;
    end
    
endmodule