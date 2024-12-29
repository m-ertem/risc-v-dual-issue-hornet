`timescale 1ns / 1ps
// aykut//
module reg_bank(input clk_i,
                input reset_i,
                
                input rf_wen_WB_0,
                input rf_wen_WB_1,
                
                input [4:0] rd_WB_0,
                input [4:0] rd_WB_1,
                
                input [31:0] mux_o_WB_0,
                input [31:0] mux_o_WB_1,
                input take_branch_0,
                input csr_id_flush_0,
                input csr_id_flush_1,
                
                input stall_EX_0,
                input stall_EX_1,
                
                input misaligned_access_0,
                input misaligned_access_1,
                
                input [4:0] IDEX_preg_rs1_0,
                input [4:0] IDEX_preg_rs2_0,
                
                input [4:0] IDEX_preg_rs1_1,
                input [4:0] IDEX_preg_rs2_1,
                
                input stall_ID_0,
                input stall_ID_1,
                
                input [4:0] rs1_ID_0,
                input [4:0] rs2_ID_0,
                
                input [4:0] rs1_ID_1,
                input [4:0] rs2_ID_1,
                
                output  [31:0] IDEX_preg_data_1_out_0,
                output  [31:0] IDEX_preg_data_1_out_1,
                output  [31:0] IDEX_preg_data_2_out_0,
                output  [31:0] IDEX_preg_data_2_out_1);
                
reg [31:0] IDEX_preg_data2_0, IDEX_preg_data1_0;     
reg [31:0] IDEX_preg_data2_1, IDEX_preg_data1_1;             
reg [31:0] register_bank [31:0];   

assign   IDEX_preg_data_1_out_0  = IDEX_preg_data1_0;
assign   IDEX_preg_data_2_out_0  = IDEX_preg_data2_0; 

assign   IDEX_preg_data_1_out_1  = IDEX_preg_data1_1;
assign   IDEX_preg_data_2_out_1  = IDEX_preg_data2_1;  


// write to register file
integer i;
always @(negedge clk_i or negedge reset_i)
begin
	if(!reset_i)
	begin
		for(i=0; i < 32; i = i+1)
			register_bank[i] <= 32'b0; //reset all registers to 0.
	end

	else
	begin
        if(!rf_wen_WB_0)
		    register_bank[rd_WB_0] <= mux_o_WB_0;
        if(!rf_wen_WB_1)
		    register_bank[rd_WB_1] <= mux_o_WB_1;
    end
end

 //core0 read  
always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
	begin
		{IDEX_preg_data1_0, IDEX_preg_data2_0} <= 64'b0;
	end

	else if(take_branch_0 || csr_id_flush_0) //flush the pipe
	begin
		{IDEX_preg_data1_0, IDEX_preg_data2_0} <= 64'b0;
	end

    else if(stall_EX_0 || misaligned_access_0)
    begin
        if(IDEX_preg_rs1_0 == 5'b0)
			IDEX_preg_data1_0 <= 32'b0;
		else
			IDEX_preg_data1_0 <= register_bank[IDEX_preg_rs1_0];

		if(IDEX_preg_rs2_0 == 5'b0)
			IDEX_preg_data2_0 <= 32'b0;
		else
			IDEX_preg_data2_0 <= register_bank[IDEX_preg_rs2_0];
    end

    else
    begin
        if(!stall_ID_0)
        begin
            
            if(rs1_ID_0 == 5'b0)
                IDEX_preg_data1_0 <= 32'b0;
            else
                IDEX_preg_data1_0 <= register_bank[rs1_ID_0];

            if(rs2_ID_0 == 5'b0)
                IDEX_preg_data2_0 <= 32'b0;
            else
                IDEX_preg_data2_0 <= register_bank[rs2_ID_0];
        end
    end
end

 //core1 read  
always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
	begin
		{IDEX_preg_data1_1, IDEX_preg_data2_1} <= 64'b0;
	end

	else if(csr_id_flush_1) //flush the pipe
	begin
		{IDEX_preg_data1_1, IDEX_preg_data2_1} <= 64'b0;
	end

    else if(stall_EX_1 || misaligned_access_1)
    begin
        if(IDEX_preg_rs1_1 == 5'b0)
			IDEX_preg_data1_1 <= 32'b0;
		else
			IDEX_preg_data1_1 <= register_bank[IDEX_preg_rs1_1];

		if(IDEX_preg_rs2_1 == 5'b0)
			IDEX_preg_data2_1 <= 32'b0;
		else
			IDEX_preg_data2_1 <= register_bank[IDEX_preg_rs2_1];
    end

    else
    begin
        if(!stall_ID_1)
        begin
            
            if(rs1_ID_1 == 5'b0)
                IDEX_preg_data1_1 <= 32'b0;
            else
                IDEX_preg_data1_1 <= register_bank[rs1_ID_1];

            if(rs2_ID_1 == 5'b0)
                IDEX_preg_data2_1 <= 32'b0;
            else
                IDEX_preg_data2_1 <= register_bank[rs2_ID_1];
        end
    end
end
      
    
endmodule

