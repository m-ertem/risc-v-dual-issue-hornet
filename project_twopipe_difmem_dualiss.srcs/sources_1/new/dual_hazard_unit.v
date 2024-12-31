module dual_hazard_unit (
    input clk_i,
    input reset_i,
    input priority_flag,
    input[4:0] rs1_ID_0,
    input[4:0] rs2_ID_0,
    input[4:0] rd_ID_0,
    input[4:0] rd_EX_0,
    input[4:0] opcode_0,
    input funct3_0,
    input[4:0] rs1_ID_1,
    input[4:0] rs2_ID_1,
    input[4:0] rd_ID_1,
    input[4:0] rd_EX_1,
    input[4:0] opcode_1,
    input funct3_1,
    input L_ID_1,
    input L_EX_1,

    input[31:0] pc_ID_0,
    input[31:0] pc_ID_1,
    input[31:0] pc_EX_0,
    input[31:0] pc_EX_1,

    output pipe_0_occuppied_w_branch_IF,
    
    output dual_hazard_stall_0,
    output dual_hazard_stall_1
);

// e�e priority_flag 1 ise rs1_ID_0, rs2_ID_0, rd_ID_1 kar��la�t�r�lacak
// e�e priority_flag 0 ise rs1_ID_1, rs2_ID_1, rd_ID_0 kar��la�t�r�lacak

wire uses_rs1_0, uses_rs2_0;
wire valid_EX_0, valid_EX_1;
reg stall_flag_0, stall_trigger_0, stall_once_0;
reg stall_flag_1, stall_trigger_1, stall_once_1;

assign pipe_0_occuppied_w_branch_IF = opcode_0[4:1] == 4'b1100 ? 1'b1 : 1'b0;

assign uses_rs1_0 = opcode_0[4:1] == 4'b1100 || //JALR and branch instructions
                    opcode_0[4:0] == 5'b00100 || //register-immediate arithmetic
                    opcode_0[4:0] == 5'b01100 || //register-register arithmetic
                    (opcode_0[4:0] == 5'b11100 && funct3_0 == 1'b0); //CSR instructions

assign uses_rs2_0 = opcode_0[4:0] == 5'b11000 || //branch instructions
                    opcode_0[4:0] == 5'b01100; //register-register arithmetic

wire uses_rs1_1, uses_rs2_1;

assign uses_rs1_1 = opcode_1[4:0] == 5'b00000 || //load instructions
                    opcode_1[4:0] == 5'b01000 || //store instructions
                    opcode_1[4:0] == 5'b00100 || //register-immediate arithmetic
                    opcode_1[4:0] == 5'b01100 || //register-register arithmetic
                    (opcode_1[4:0] == 5'b11100 && funct3_1 == 1'b0); //CSR instructions

assign uses_rs2_1 = opcode_1[4:0] == 5'b01000 || //store instructions
                    opcode_1[4:0] == 5'b01100; //register-register arithmetic

assign valid_EX_1 = (pc_ID_0 > pc_EX_1) ? 1'b1 : 1'b0; 
assign valid_EX_0 = (pc_ID_1 > pc_EX_0) ? 1'b1 : 1'b0; 

always @(*)
begin
    if(!rs1_ID_0 && !rs2_ID_0 && !rs1_ID_1 && !rs2_ID_1 && !rd_ID_0 && !rd_ID_1)
    begin
        stall_trigger_0 = 1'b0;
        stall_once_0    = 1'b0;
        stall_trigger_1 = 1'b0;
        stall_once_1    = 1'b0;
    end
    else
    begin
        if(priority_flag==1)
        begin
            stall_once_1 = 1'b0;
            stall_trigger_1 = 1'b0;

            if(L_ID_1)
            begin
                if(((rs1_ID_0 == rd_ID_1) && uses_rs1_0 && (rs1_ID_0 != 5'b0)) || ((rs2_ID_0 == rd_ID_1) && uses_rs2_0 && (rs2_ID_0 != 5'b0)))
                    stall_trigger_0 = 1'b1;

                else
                    stall_trigger_0 = 1'b0;
            end
            else
            begin
                stall_trigger_0 = 1'b0;

                if(((rs1_ID_0 == rd_ID_1) && uses_rs1_0 && (rs1_ID_0 != 5'b0)) || ((rs2_ID_0 == rd_ID_1) && uses_rs2_0 && (rs2_ID_0 != 5'b0)))
                    stall_once_0 = 1'b1;

                else
                    stall_once_0 = 1'b0;
            end
        end
        else if(priority_flag==0)
        begin
            stall_once_0 = 1'b0;
            stall_trigger_0 = 1'b0;

            if((((rs1_ID_1 == rd_ID_0) && uses_rs1_1 && (rs1_ID_1 != 5'b0))) || ((rs2_ID_1 == rd_ID_0) && uses_rs2_1 && (rs2_ID_1 != 5'b0)))
                stall_once_1 = 1'b1;
            else
                stall_once_1 = 1'b0;
        end
        else    
        begin
            stall_trigger_0 = 1'b0;
            stall_once_0    = 1'b0;
            stall_trigger_1 = 1'b0;
            stall_once_1    = 1'b0;
        end
        
        // detecs cross-dependencies in the case of a load operation
        if(valid_EX_1 && L_EX_1 && (((rs1_ID_0 == rd_EX_1) && uses_rs1_0 && (rs1_ID_0 != 5'b0)) || ((rs2_ID_0 == rd_EX_1) && uses_rs2_0 && (rs2_ID_0 != 5'b0))))
        begin
            stall_once_0 = 1'b1;
        end

    end
end

always @(posedge clk_i or negedge reset_i)
begin
    if(!reset_i)
    begin
        stall_flag_0 <= 0;
        stall_flag_1 <= 0;
    end
    else 
    begin
        if(stall_trigger_0)
            stall_flag_0 <= 1;
        else
            stall_flag_0 <= 0;
        if(stall_trigger_1)
            stall_flag_1 <= 1;
        else
            stall_flag_1 <= 0;
    end
end

assign dual_hazard_stall_0 = stall_flag_0 || stall_trigger_0 || stall_once_0;
assign dual_hazard_stall_1 = stall_flag_1 || stall_trigger_1 || stall_once_1;

endmodule
