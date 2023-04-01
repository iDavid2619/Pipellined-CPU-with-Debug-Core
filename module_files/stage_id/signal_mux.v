`include "../definitions.v"
`timescale 1ns / 1ps

/*
this is the multiplexers between the id stage and id_ex_reg
 */

module signal_mux (
    input      i_type_instruction,                              // from control_unit (whether it is a I type instruction)
    input      r_type_instruction,                              // from control_unit (whether it is a R type instruction)
    input      j_instruction,                                   // from control_unit (whether it is a jump instruction)
    input      jr_instruction,                                  // from control_unit (whether it is a jr instruction)
    input      jal_instruction,                                 // from control_unit (whether it is a jal insutrction)
    input      branch_instruction,                              // from control_unit (whether it is a branch instruction)
    input      shift_instruction,                               // from control_unit (whether it is a shift instruction) 
    
    input      condition_satisfied,                             // from condition_check (whether the branch condition is met)
    input      id_no_op,                                        // from if_id_reg (whether the current instruction is a gap)
    output     pc_offset,                                       // for (1) if_id_reg (whether the branch is taken thus prediction failed)
                                                                //     (2) instruction_mem (whether the pc should be offsetted)
    output     pc_overload,                                     // for (1) if_id_reg (whether a jump occured thus prediction failed)
                                                                //     (2) instruction_mem (whether the pc should be overloaded)
    
    input      [`ISA_WIDTH - 1:0] id_reg_1,                     // from general_reg (first register's value)
    input      [`ISA_WIDTH - 1:0] id_pc,                        // from if_id_reg (pc)
    input      [`SHIFT_AMOUNT_WIDTH - 1:0] shift_amount,        // from if_id_reg (shift amount)
    output     [`ISA_WIDTH - 1:0] mux_operand_1,                // for id_ex_reg (to pass on to alu)
    
    input      [`ISA_WIDTH - 1:0] id_reg_2,                     // from general_reg (second register's value)
    input      [`ISA_WIDTH - 1:0] id_sign_extend_result,        // from sign_extend (16 bit sign extend result)
    output     [`ISA_WIDTH - 1:0] mux_operand_2,                // for (1) id_ex_reg (to pass on to alu)
                                                                //     (2) instruction_mem (pc_offset_value)
    
    input      [`ISA_WIDTH - 1:0] id_instruction,               // from if_id_reg (the current instruction)
    output     [`ISA_WIDTH - 1:0] pc_overload_value,            // for instruction_mem (the value for pc to overloaded)
    
    input      [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_1_idx,       // from if_id_reg (index of first source register)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_2_idx,       // from if_id_reg (index of second source register)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_dest_idx,    // from if_id_reg (index of destination resgiter)
    output     [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_1_idx,      // for id_ex_reg (to pass on to forwarding_unit)
    output     [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_2_idx,      // for id_ex_reg (to pass on to forwarding_unit)
    output reg [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_dest_idx    // for id_ex_reg
    );

    // wire i_type_abnormal = store_instruction | branch_instruction;
    wire j_type_normal = j_instruction | jal_instruction;

    assign pc_offset         = ~id_no_op & branch_instruction & condition_satisfied;
    assign pc_overload       = ~id_no_op & (j_type_normal | jr_instruction);
    assign pc_overload_value = j_type_normal ? {
                                    id_pc[`ISA_WIDTH - 1:`ADDRESS_WIDTH + 2],
                                    id_instruction[`ADDRESS_WIDTH - 1:0], 
                                    2'b00
                                } : id_reg_1; // for J type instruction address extension 

    assign mux_operand_1 = jal_instruction    ? id_pc                 : (
                           shift_instruction  ? {
                                                    {(`ISA_WIDTH - `SHIFT_AMOUNT_WIDTH){1'b0}}, 
                                                    shift_amount
                                                }                     : id_reg_1);
    assign mux_operand_2 = i_type_instruction ? id_sign_extend_result : (
                           jal_instruction    ? (`ISA_WIDTH / 8)      : id_reg_2);

    assign mux_reg_1_idx = (   ~(j_type_normal | shift_instruction)) ? id_reg_1_idx : 0;
    assign mux_reg_2_idx = (r_type_instruction | branch_instruction) ? id_reg_2_idx : 0;

    always @(*) begin
        case ({i_type_instruction, branch_instruction | jr_instruction, jal_instruction})
            3'b100 : mux_reg_dest_idx <= id_reg_2_idx;       // I type instruction
            3'b010 : mux_reg_dest_idx <= 0;                  // branch or jump register instruction
            3'b001 : mux_reg_dest_idx <= `JAL_REG_IDX;       // jump and link store to 31st register
            default: mux_reg_dest_idx <= id_reg_dest_idx;    // R type instruction
        endcase
    end
    
endmodule