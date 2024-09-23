module dual_hazard_unit (
    input priority,
    input[4:0] rs1_ID_0,
    input[4:0] rs2_ID_0,
    input[4:0] rd_ID_0,
    input[4:0] opcode_0,
    input funct3_0,
    input[4:0] rs1_ID_1,
    input[4:0] rs2_ID_1,
    input[4:0] rd_ID_1,
    input[4:0] opcode_1,
    input funct3_1,
    output reg stall_IF_dual
);

// eðe priority 1 ise rs1_ID_0, rs2_ID_0, rd_ID_1 karþýlaþtýrýlacak
// eðe priority 0 ise rs1_ID_1, rs2_ID_1, rd_ID_0 karþýlaþtýrýlacak

wire uses_rs1_0, uses_rs2_0;

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

always @(*)
begin
    if(priority==0)
    begin
//        if(L_EX)
//        begin
            if((rs1_ID_1 == rd_ID_0 && uses_rs1_1) || (rs2_ID_1 == rd_ID_0 && uses_rs2_1))
                stall_IF_dual = 1'b1;

            else
                stall_IF_dual = 1'b0;
//        end
//        else
//        begin
//            stall_IF_dual = 1'b0;
//        end
    end
    else if(priority==1)
    begin
//        if(L_EX)
//        begin
            if((rs1_ID_0 == rd_ID_1 && uses_rs1_0) || (rs2_ID_0 == rd_ID_1 && uses_rs2_0))
                stall_IF_dual = 1'b1;

            else
                stall_IF_dual = 1'b0;
//        end
//        else
//        begin
//            stall_IF_dual = 1'b0;
//        end
    end
    else 
         stall_IF_dual = 1'b0;
    
end


endmodule
