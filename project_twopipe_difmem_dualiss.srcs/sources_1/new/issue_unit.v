module issue_unit(
    input [31:0] instr_i_tmp,
    input [31:0] instr_i_1_tmp,
    input stall_IF_0,
    input stall_IF_1,
    input dual_hazard_stall_0,
    input dual_hazard_stall_1,
    output reg issue_stall_0,
    output reg issue_stall_1,
    output [31:0] instr_i, 
    output [31:0] instr_i_1,
    output priority,
    output reg priority_overwrite,
    output reg [31:0] pc_increment // goes to pc logic
    );

    wire [4:0] opcode_0;
    wire [4:0] opcode_1;
    
    reg priority_tmp;

    reg [2:0] instr_0_type;
    reg [2:0] instr_1_type;
    
    reg [31:0] instr_i_reg;
    reg [31:0] instr_i_1_reg;

    parameter ALU = 3'b000;
    parameter mem = 3'b001;
    parameter branch = 3'b010;

    assign opcode_0 = instr_i_tmp[6:2];
    assign opcode_1 = instr_i_1_tmp[6:2];

    assign stall_check = 1'b1;

    // assign first instruction's type
    always@(*) begin
        if(opcode_0 == 5'b01100 ||opcode_0 ==  5'b00100 || opcode_0 == 5'b01101 )
            instr_0_type = ALU;
        else if(opcode_0 == 5'b00000 ||opcode_0 ==  5'b01000)
            instr_0_type = mem;
        else if(opcode_0 == 5'b11000 || opcode_0 ==  5'b11011 ||opcode_0 ==  5'b11001 || opcode_0 == 5'b00101)
            instr_0_type = branch;
    end

    // assign second instruction's type
    always@(*) begin
        if(opcode_1 == 5'b01100 || opcode_1 == 5'b00100 || opcode_1 == 5'b01101)
            instr_1_type = ALU;
        else if(opcode_1 == 5'b00000 ||opcode_1 == 5'b01000)
            instr_1_type = mem;
        else if(opcode_1 == 5'b11000 || opcode_1 ==  5'b11011 ||opcode_1 ==  5'b11001 || opcode_1 == 5'b00101)
            instr_1_type = branch;
    end

    // assign instructions to pipelines
    always@(*) begin
        if(instr_0_type == mem && instr_1_type == mem && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_tmp  = 1'b1;
            pc_increment  = 4;         
            issue_stall_0 = 1; // NOP     
            issue_stall_1 = 0;
        end
        else if(instr_0_type == mem && instr_1_type == mem && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_tmp  = 1'b1;
            pc_increment  = 4;         
            issue_stall_0 = 0; // already stalled    
            issue_stall_1 = 0;
        end
        else if(instr_0_type == mem && instr_1_type == mem && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_tmp  = 1'b1;
            pc_increment  = 0;         
            issue_stall_0 = 1; // NOP     
            issue_stall_1 = 0;
        end
        else if(instr_0_type == mem && instr_1_type == mem && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_tmp  = 1'b1;
            pc_increment  = 0;         
            issue_stall_0 = 0; // already stalled  
            issue_stall_1 = 0;
        end
        else if(instr_0_type == mem && instr_1_type == branch && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_tmp  = 1'b1;
            pc_increment  = 4;               
            issue_stall_0 = 1;
            issue_stall_1 = 0;            
        end
        else if(instr_0_type == mem && instr_1_type == branch && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_tmp  = 1'b1;
            pc_increment  = 4;               
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0;            
        end
        else if(instr_0_type == mem && instr_1_type == branch && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_tmp  = 1'b1;
            pc_increment  = 0;               
            issue_stall_0 = 1; 
            issue_stall_1 = 0; // already stalled          
        end
        else if(instr_0_type == mem && instr_1_type == branch && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_tmp  = 1'b1;
            pc_increment  = 0;               
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled     
        end
        else if(instr_0_type == branch && instr_1_type == mem && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b0;
            pc_increment  = 4;              
            issue_stall_0 = 0;
            issue_stall_1 = 1; // NOP
        end
        else if(instr_0_type == branch && instr_1_type == mem && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b0;
            pc_increment  = 4;              
            issue_stall_0 = 0;
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == branch && instr_1_type == mem && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b0;
            pc_increment  = 0;              
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 1;
        end
        else if(instr_0_type == branch && instr_1_type == mem && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b0;
            pc_increment  = 0;              
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled
        end
        /////////////////////////////////
        else if(instr_0_type == mem && instr_1_type == ALU && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_tmp  = 1'b1;
            pc_increment  = 8;
            issue_stall_0 = 0;
            issue_stall_1 = 0;   
        end
        else if(instr_0_type == mem && instr_1_type == ALU && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_tmp  = 1'b1;
            pc_increment  = 4;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0;   
        end
        else if(instr_0_type == mem && instr_1_type == ALU && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_tmp  = 1'b1;
            pc_increment  = 0;
            issue_stall_0 = 1; 
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == mem && instr_1_type == ALU && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_tmp  = 1'b1;
            pc_increment  = 0;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled
        end
        ////////////////////////////////
        else if(instr_0_type == ALU && instr_1_type == mem && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp = 1'b0;
            pc_increment = 8;
            issue_stall_0 = 0;
            issue_stall_1 = 0;      
        end
        else if(instr_0_type == ALU && instr_1_type == mem && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_tmp = 1'b1;
            pc_increment = 4;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0;      
        end
        else if(instr_0_type == ALU && instr_1_type == mem && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp = 1'b0;
            pc_increment = 4;
            issue_stall_0 = 0;
            issue_stall_1 = 0; // already stalled      
        end
        else if(instr_0_type == ALU && instr_1_type == mem && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp = 1'b0;
            pc_increment = 0;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled      
        end
        ///////////////////////////////
        else if(instr_0_type == ALU && instr_1_type == branch && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_tmp  = 1'b1;
            pc_increment  = 4;
            issue_stall_0 = 1; // NOP
            issue_stall_1 = 0;  
        end
        else if(instr_0_type == ALU && instr_1_type == branch && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_tmp  = 1'b1;
            pc_increment  = 4;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0;  
        end
        else if(instr_0_type == ALU && instr_1_type == branch && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b0;
            pc_increment  = 4;
            issue_stall_0 = 0; 
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == ALU && instr_1_type == branch && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b1;
            pc_increment  = 0;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled
        end
        //////////////////////////////
        else if(instr_0_type == branch && instr_1_type == ALU && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b0;
            pc_increment  = 4;
            issue_stall_0 = 0;
            issue_stall_1 = 1; // NOP
        end
        else if(instr_0_type == branch && instr_1_type == ALU && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b0;
            pc_increment  = 4;
            issue_stall_0 = 0;
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == branch && instr_1_type == ALU && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b0;
            pc_increment  = 0;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0;
        end
        else if(instr_0_type == branch && instr_1_type == ALU && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b0;
            pc_increment  = 0;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled
        end
        //////////////////////////////
        else if(instr_0_type == branch && instr_1_type == branch && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b0;
            pc_increment  = 4;
            issue_stall_0 = 0;
            issue_stall_1 = 1; // NOP
        end
        else if(instr_0_type == branch && instr_1_type == branch && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b0;
            pc_increment  = 4;
            issue_stall_0 = 0;
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == branch && instr_1_type == branch && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b0;
            pc_increment  = 0;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 1; 
        end
        else if(instr_0_type == branch && instr_1_type == branch && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b0;
            pc_increment  = 0;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled
        end
        ///////////////////////////////
        else if(instr_0_type == ALU && instr_1_type == ALU && !stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b0;
            pc_increment  = 8;
            issue_stall_0 = 0;
            issue_stall_1 = 0;
        end
        else if(instr_0_type == ALU && instr_1_type == ALU && stall_IF_0 && !stall_IF_1)
        begin
            instr_i_reg   = instr_i_1_tmp;
            instr_i_1_reg = instr_i_tmp;
            priority_tmp  = 1'b1;
            pc_increment  = 4;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0;
        end
        else if(instr_0_type == ALU && instr_1_type == ALU && !stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b0;
            pc_increment  = 4;
            issue_stall_0 = 0;
            issue_stall_1 = 0; // already stalled
        end
        else if(instr_0_type == ALU && instr_1_type == ALU && stall_IF_0 && stall_IF_1)
        begin
            instr_i_reg   = instr_i_tmp;
            instr_i_1_reg = instr_i_1_tmp;
            priority_tmp  = 1'b0;
            pc_increment  = 0;
            issue_stall_0 = 0; // already stalled
            issue_stall_1 = 0; // already stalled
        end
        ///////////////////////////////
        else 
        begin 
            priority_tmp  = 1'b0;
            pc_increment  = 8;
            issue_stall_0 = 0;
            issue_stall_1 = 0;
        end   
    end

    assign priority = priority_tmp;

    assign instr_i = instr_i_reg;
    assign instr_i_1 = instr_i_1_reg;

endmodule
