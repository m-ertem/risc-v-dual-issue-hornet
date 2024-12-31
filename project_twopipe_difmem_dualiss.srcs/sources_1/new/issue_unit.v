module issue_unit(
    input [31:0] instr_i_tmp,
    input [31:0] instr_i_1_tmp,
    input stall_IF_0,
    input stall_IF_1,
    input dual_hazard_stall_0,
    input dual_hazard_stall_1,
    input funct3_0,
    input funct3_1,
    input pipe_0_occuppied_w_branch_IF,
    output reg issue_stall_0,
    output reg issue_stall_1,
    output [31:0] instr_i, 
    output [31:0] instr_i_1,
    output reg priority_flag,
    output reg priority_overwrite,
    output reg [31:0] pc_increment // goes to pc logic
    );

    wire [4:0] opcode_0;
    wire [4:0] opcode_1;
    wire       funct7_0;
    wire       funct7_1;
    
    reg priority_flag;

    reg [2:0] instr_0_type;
    reg [2:0] instr_1_type;
    
    reg [31:0] instr_i_reg;
    reg [31:0] instr_i_1_reg;

    parameter ALU = 3'b000;
    parameter mem = 3'b001;
    parameter branch = 3'b010;
    parameter CSR = 3'b011;

    assign opcode_0 = instr_i_tmp[6:2];
    assign opcode_1 = instr_i_1_tmp[6:2];
    assign funct7_0 = instr_i_tmp[25];
    assign funct7_1 = instr_i_1_tmp[25];

    // assign first instruction's type
    always@(*) begin
        if(opcode_0 == 5'b01100 || opcode_0 ==  5'b00100 || opcode_0 == 5'b01101 )
            instr_0_type = ALU;
        else if(opcode_0 == 5'b00000 || opcode_0 ==  5'b01000)
            instr_0_type = mem;
        else if(opcode_0 == 5'b11000 || opcode_0 ==  5'b11011 ||opcode_0 ==  5'b11001 || opcode_0 == 5'b00101)
            instr_0_type = branch;
        else if(opcode_0 == 5'b11100 && funct3_0 == 1'b0)
            instr_0_type = CSR;
    end

    // assign second instruction's type
    always@(*) begin
        if(opcode_1 == 5'b01100 || opcode_1 == 5'b00100 || opcode_1 == 5'b01101)
            instr_1_type = ALU;
        else if(opcode_1 == 5'b00000 ||opcode_1 == 5'b01000)
            instr_1_type = mem;
        else if(opcode_1 == 5'b11000 || opcode_1 ==  5'b11011 ||opcode_1 ==  5'b11001 || opcode_1 == 5'b00101)
            instr_1_type = branch;
        else if(opcode_1 == 5'b11100 && funct3_1 == 1'b0)
            instr_1_type = CSR;
    end

    // assign instructions to pipelines
    always@(*) begin
        if(pipe_0_occuppied_w_branch_IF && stall_IF_0)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;         
            issue_stall_0 = 0; // already stalled     
            issue_stall_1 = 1; // NOP
        end
        // CSR instructions
        else if(instr_0_type == CSR && instr_1_type == CSR && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;         
            issue_stall_0 = 0; 
            issue_stall_1 = 1; // NOP
        end
        else if(instr_0_type == CSR && instr_1_type == CSR && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;         
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 1; // NOP
        end
        else if(instr_0_type == CSR && instr_1_type == CSR && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;         
            issue_stall_0 = 0; 
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == CSR && instr_1_type == CSR && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;         
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled
        end
        /////////////////////////////////////////
        else if(instr_0_type == CSR && instr_1_type != CSR && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;         
            issue_stall_0 = 0; 
            issue_stall_1 = 1; // NOP
        end
        else if(instr_0_type == CSR && instr_1_type != CSR && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;         
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 1; // NOP
        end
        else if(instr_0_type == CSR && instr_1_type != CSR && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;         
            issue_stall_0 = 0; 
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == CSR && instr_1_type != CSR && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;         
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled
        end
        /////////////////////////////////////////
        else if(instr_0_type == branch && instr_1_type == CSR && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;         
            issue_stall_0 = 0; 
            issue_stall_1 = 1; // NOP
        end
        else if(instr_0_type == branch && instr_1_type == CSR && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;         
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 1; // NOP
        end
        else if(instr_0_type == branch && instr_1_type == CSR && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;         
            issue_stall_0 = 0; 
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == branch && instr_1_type == CSR && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;         
            issue_stall_0 = 0; // already stalled 
            issue_stall_1 = 0; // already stalled
        end
        /////////////////////////////////////////
        else if(instr_0_type == mem && instr_1_type == CSR && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_flag  = 1'b1;
            pc_increment  = 4;         
            issue_stall_0 = 1; // NOP
            issue_stall_1 = 0; 
        end
        else if(instr_0_type == mem && instr_1_type == CSR && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_flag  = 1'b1;
            pc_increment  = 4;         
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; 
        end
        else if(instr_0_type == mem && instr_1_type == CSR && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;         
            issue_stall_0 = 1; // NOP
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == mem && instr_1_type == CSR && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;         
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled
        end
        /////////////////////////////////////////
        else if(instr_0_type == ALU && instr_1_type == CSR && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;         
            issue_stall_0 = 0; 
            issue_stall_1 = 1; // NOP 
        end
        else if(instr_0_type == ALU && instr_1_type == CSR && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_flag  = 1'b1;
            pc_increment  = 4;         
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0;
        end
        else if(instr_0_type == ALU && instr_1_type == CSR && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;         
            issue_stall_0 = 0;
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == ALU && instr_1_type == CSR && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;         
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled
        end
        // end of CSR instructions
        else if(instr_0_type == mem && instr_1_type == mem && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_flag  = 1'b1;
            pc_increment  = 4;         
            issue_stall_0 = 1; // NOP     
            issue_stall_1 = 0;
        end
        else if(instr_0_type == mem && instr_1_type == mem && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_flag  = 1'b1;
            pc_increment  = 4;         
            issue_stall_0 = 0; // already stalled    
            issue_stall_1 = 0;
        end
        else if(instr_0_type == mem && instr_1_type == mem && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_flag  = 1'b1;
            pc_increment  = 0;         
            issue_stall_0 = 1; // NOP     
            issue_stall_1 = 0;
        end
        else if(instr_0_type == mem && instr_1_type == mem && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_flag  = 1'b1;
            pc_increment  = 0;         
            issue_stall_0 = 0; // already stalled  
            issue_stall_1 = 0;
        end
        /////////////////////////////////////////
        else if(instr_0_type == mem && instr_1_type == branch && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_flag  = 1'b1;
            pc_increment  = 4;               
            issue_stall_0 = 1;
            issue_stall_1 = 0;            
        end
        else if(instr_0_type == mem && instr_1_type == branch && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_flag  = 1'b1;
            pc_increment  = 4;               
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0;            
        end
        else if(instr_0_type == mem && instr_1_type == branch && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_flag  = 1'b1;
            pc_increment  = 0;               
            issue_stall_0 = 1; 
            issue_stall_1 = 0; // already stalled          
        end
        else if(instr_0_type == mem && instr_1_type == branch && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_flag  = 1'b1;
            pc_increment  = 0;               
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled     
        end
        /////////////////////////////////////////
        else if(instr_0_type == branch && instr_1_type == mem && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;              
            issue_stall_0 = 0;
            issue_stall_1 = 1; // NOP
        end
        else if(instr_0_type == branch && instr_1_type == mem && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;              
            issue_stall_0 = 0;
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == branch && instr_1_type == mem && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;              
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 1;
        end
        else if(instr_0_type == branch && instr_1_type == mem && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;              
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled
        end
        /////////////////////////////////
        else if(instr_0_type == mem && instr_1_type == ALU && !stall_IF_0 && !stall_IF_1)
        begin
            if(funct7_1) // if MULDIV operation
            begin
                instr_i_reg   = instr_i_1_tmp;
                instr_i_1_reg = instr_i_tmp;
                priority_flag  = 1'b1;
                pc_increment  = 4;
                issue_stall_0 = 1; // NOP
                issue_stall_1 = 0;   
            end
            else
            begin
                instr_i_reg   = instr_i_1_tmp;
                instr_i_1_reg = instr_i_tmp;
                priority_flag  = 1'b1;
                pc_increment  = 8;
                issue_stall_0 = 0;
                issue_stall_1 = 0;   
            end
        end
        else if(instr_0_type == mem && instr_1_type == ALU && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_flag  = 1'b1;
            pc_increment  = 4;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0;   
        end
        else if(instr_0_type == mem && instr_1_type == ALU && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_flag  = 1'b1;
            pc_increment  = 0;
            issue_stall_0 = 1; 
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == mem && instr_1_type == ALU && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_flag  = 1'b1;
            pc_increment  = 0;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled
        end
        ////////////////////////////////
        else if(instr_0_type == ALU && instr_1_type == mem && !stall_IF_0 && !stall_IF_1)
        begin
            if(funct7_0) // if MULDIV operation
            begin
                instr_i_reg = instr_i_tmp;
                instr_i_1_reg = instr_i_1_tmp;
                priority_flag = 1'b0;
                pc_increment = 4;
                issue_stall_0 = 0;
                issue_stall_1 = 1; // NOP   
            end   
            else
            begin
                instr_i_reg = instr_i_tmp;
                instr_i_1_reg = instr_i_1_tmp;
                priority_flag = 1'b0;
                pc_increment = 8;
                issue_stall_0 = 0;
                issue_stall_1 = 0;   
            end   
        end
        else if(instr_0_type == ALU && instr_1_type == mem && stall_IF_0 && !stall_IF_1)
        begin
            if(funct7_0) // if MULDIV operation
            begin
                instr_i_reg = instr_i_1_tmp;
                instr_i_1_reg = instr_i_tmp;
                priority_flag = 1'b1;
                pc_increment = 0;
                issue_stall_0 = 0; // already stalled
                issue_stall_1 = 1; // NOP      
            end           
            else
            begin
                instr_i_reg = instr_i_1_tmp;
                instr_i_1_reg = instr_i_tmp;
                priority_flag = 1'b1;
                pc_increment = 4;
                issue_stall_0 = 0; // already stalled
                issue_stall_1 = 0;      
            end
        end
        else if(instr_0_type == ALU && instr_1_type == mem && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag = 1'b0;
            pc_increment = 4;
            issue_stall_0 = 0;
            issue_stall_1 = 0; // already stalled      
        end
        else if(instr_0_type == ALU && instr_1_type == mem && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag = 1'b0;
            pc_increment = 0;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled      
        end
        ///////////////////////////////
        else if(instr_0_type == ALU && instr_1_type == branch && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;
            issue_stall_0 = 0; //
            issue_stall_1 = 1; // NOP  
        end
        else if(instr_0_type == ALU && instr_1_type == branch && stall_IF_0 && !stall_IF_1)
        begin
            if(funct7_0)
            begin
                instr_i_reg   = instr_i_1_tmp;
                instr_i_1_reg = instr_i_tmp;
                priority_flag  = 1'b1;
                pc_increment  = 0;
                issue_stall_0 = 0; // already stalled
                issue_stall_1 = 1; // NOP  
            end
            else
            begin
                instr_i_reg   = instr_i_1_tmp;
                instr_i_1_reg = instr_i_tmp;
                priority_flag  = 1'b1;
                pc_increment  = 4;
                issue_stall_0 = 0; // already stalled
                issue_stall_1 = 0;  
            end
        end
        else if(instr_0_type == ALU && instr_1_type == branch && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;
            issue_stall_0 = 0; 
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == ALU && instr_1_type == branch && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b1;
            pc_increment  = 0;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled
        end
        //////////////////////////////
        else if(instr_0_type == branch && instr_1_type == ALU && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;
            issue_stall_0 = 0;
            issue_stall_1 = 1; // NOP
        end
        else if(instr_0_type == branch && instr_1_type == ALU && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;
            issue_stall_0 = 0;
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == branch && instr_1_type == ALU && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0;
        end
        else if(instr_0_type == branch && instr_1_type == ALU && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled
        end
        //////////////////////////////
        else if(instr_0_type == branch && instr_1_type == branch && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;
            issue_stall_0 = 0;
            issue_stall_1 = 1; // NOP
        end
        else if(instr_0_type == branch && instr_1_type == branch && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;
            issue_stall_0 = 0;
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == branch && instr_1_type == branch && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 1; 
        end
        else if(instr_0_type == branch && instr_1_type == branch && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled
        end
        ///////////////////////////////
        else if(instr_0_type == ALU && instr_1_type == ALU && !stall_IF_0 && !stall_IF_1)
        begin
            if(funct7_0 || funct7_1)
            begin
                instr_i_reg   = instr_i_tmp;
                instr_i_1_reg = instr_i_1_tmp;
                priority_flag  = 1'b0;
                pc_increment  = 4;
                issue_stall_0 = 0;
                issue_stall_1 = 1; // NOP
            end
            else
            begin
                instr_i_reg   = instr_i_tmp;
                instr_i_1_reg = instr_i_1_tmp;
                priority_flag  = 1'b0;
                pc_increment  = 8;
                issue_stall_0 = 0;
                issue_stall_1 = 0;
            end
        end
        else if(instr_0_type == ALU && instr_1_type == ALU && stall_IF_0 && !stall_IF_1)
        begin
            if(funct7_0)
            begin
                instr_i_reg   = instr_i_1_tmp;
                instr_i_1_reg = instr_i_tmp;
                priority_flag  = 1'b1;
                pc_increment  = 0;
                issue_stall_0 = 0; // already stalled
                issue_stall_1 = 1; // NOP
            end
            else
            begin
                instr_i_reg   = instr_i_1_tmp;
                instr_i_1_reg = instr_i_tmp;
                priority_flag  = 1'b1;
                pc_increment  = 4;
                issue_stall_0 = 0; // already stalled
                issue_stall_1 = 0;
            end
        end
        else if(instr_0_type == ALU && instr_1_type == ALU && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 4;
            issue_stall_0 = 0;
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == ALU && instr_1_type == ALU && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_flag  = 1'b0;
            pc_increment  = 0;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled
        end
        ///////////////////////////////
        else 
        begin 
            priority_flag  = 1'b0;
            pc_increment  = 8;
            issue_stall_0 = 0;
            issue_stall_1 = 0;
        end   
    end

    // assign priority_flag = priority_flag;

    assign instr_i = instr_i_reg;
    assign instr_i_1 = instr_i_1_reg;

endmodule
