/*
Register Forwarding Unit
This module is responsible for detecting pipeline data hazards, and generating the controls signals
for the forwarding muxes(2, 4 and 8) in the EX stage.
It can forward data from MEM or the WB stage to EX stage, even between two pipelines when necessary.
It is also responsible for the forwarding of the CSRs.
*/

module dual_forwarding_unit(
    input [4:0] rs1_0,
    input [4:0] rs2_0,
    input [4:0] exmem_rd_0,
    input [4:0] memwb_rd_0,
    input exmem_wb_0, memwb_wb_0,

    input [4:0] rs1_1,
    input [4:0] rs2_1,
    input [4:0] exmem_rd_1,
    input [4:0] memwb_rd_1,
    input exmem_wb_1, memwb_wb_1,

    output reg [1:0] mux1_ctrl_0, //control signal for mux2 in EX
    output reg [1:0] mux2_ctrl_0, //control signal for mux4 in EX
    
    output reg [1:0] mux1_ctrl_1, //control signal for mux2 in EX
    output reg [1:0] mux2_ctrl_1  //control signal for mux4 in EX
);

always @(*)
begin
    if(!exmem_wb_0 || !exmem_wb_1 || !memwb_wb_0 || !memwb_wb_1)
    begin
        if(!exmem_wb_0) //forward from MEM_0 stage
        begin
            //forward rs1_MEM_0 to EX_0 stage
            if(rs1_0 == exmem_rd_0 && rs1_0 != 5'b0)
                mux1_ctrl_0 = 2'b10;
            else if(!memwb_wb_0)
            begin
                if(rs1_0 == memwb_rd_0 && rs1_0 != 5'b0)
                    mux1_ctrl_0 = 2'b1;
                else
                    mux1_ctrl_0 = 2'b0;
            end
            else
                mux1_ctrl_0 = 2'b0;

            //forward rs1_MEM_0 to EX_1 stage
            if(rs1_1 == exmem_rd_0 && rs1_1 != 5'b0)
                mux1_ctrl_1 = 2'b10;
            else if(!memwb_wb_0)
            begin
                if(rs1_1 == memwb_rd_0 && rs1_1 != 5'b0)
                    mux1_ctrl_1 = 2'b1;
                else
                    mux1_ctrl_1 = 2'b0;
            end
            else
                mux1_ctrl_0 = 2'b0;

            //------------------------------------------//

            //forward rs2_MEM_0 to EX_0 stage
            if(rs2_0 == exmem_rd_0 && rs2_0 != 5'b0)
                mux2_ctrl_0 = 2'b0;
            else if(!memwb_wb_0)
            begin
                if(rs2_0 == memwb_rd_0 && rs2_0 != 5'b0)
                    mux2_ctrl_0 = 2'b1;
                else
                    mux2_ctrl_0 = 2'b10;
            end
            else
                mux2_ctrl_0 = 2'b10;

            //forward rs2_MEM_0 to EX_1 stage
            if(rs2_1 == exmem_rd_0 && rs2_1 != 5'b0)
                mux2_ctrl_1 = 2'b0;
            else if(!memwb_wb_0)
            begin
                if(rs2_1 == memwb_rd_0 && rs2_1 != 5'b0)
                    mux2_ctrl_1 = 2'b1;
                else
                    mux2_ctrl_1 = 2'b10;
            end
            else
                mux2_ctrl_1 = 2'b10;
        end

        //------------------------------------------//

        else if(!memwb_wb_0) //forward from WB_0 stage
        begin
            //forward rs1_WB_0 to EX_0 stage
            if(rs1_0 == memwb_rd_0 && rs1_0 != 5'b0)
                mux1_ctrl_0 = 2'b1;
            else
                mux1_ctrl_0 = 2'b0;

            //forward rs2_WB_0 to EX_0 stage
            if(rs2_0 == memwb_rd_0 && rs2_0 != 5'b0)
                mux2_ctrl_0 = 2'b1;
            else
                mux2_ctrl_0 = 2'b10;

            //forward rs1_WB_0 to EX_1 stage
            if(rs1_1 == memwb_rd_0 && rs1_1 != 5'b0)
                mux1_ctrl_1 = 2'b1;
            else
                mux1_ctrl_1 = 2'b0;

            //forward rs2_WB_0 to EX_1 stage
            if(rs2_1 == memwb_rd_0 && rs2_1 != 5'b0)
                mux2_ctrl_1 = 2'b1;
            else
                mux2_ctrl_1 = 2'b10;
        end

        //------------------------------------------//
        //------------------------------------------//

        if(!exmem_wb_1) //forward from MEM_1 stage
        begin
            //forward rs1_MEM_1 to EX_0 stage
            if(rs1_0 == exmem_rd_1 && rs1_0 != 5'b0)
                mux1_ctrl_0 = 2'b10;
            else if(!memwb_wb_1)
            begin
                if(rs1_0 == memwb_rd_1 && rs1_0 != 5'b0)
                    mux1_ctrl_0 = 2'b1;
                else
                    mux1_ctrl_0 = 2'b0;
            end
            else
                mux1_ctrl_0 = 2'b0;

            //forward rs2_MEM_1 to EX_0 stage
            if(rs2_0 == exmem_rd_1 && rs2_0 != 5'b0)
                mux2_ctrl_0 = 2'b10;
            else if(!memwb_wb_1)
            begin
                if(rs2_0 == memwb_rd_1 && rs2_0 != 5'b0)
                    mux2_ctrl_0 = 2'b1;
                else
                    mux2_ctrl_0 = 2'b0;
            end
            else
                mux2_ctrl_0 = 2'b0;

            //------------------------------------------//

            //forward rs1_MEM_1 to EX_1 stage
            if(rs1_1 == exmem_rd_1 && rs1_1 != 5'b0)
                mux1_ctrl_1 = 2'b0;
            else if(!memwb_wb_1)
            begin
                if(rs1_1 == memwb_rd_1 && rs1_1 != 5'b0)
                    mux1_ctrl_1 = 2'b1;
                else
                    mux1_ctrl_1 = 2'b10;
            end
            else
                mux1_ctrl_1 = 2'b10;

            //forward rs2_MEM_1 to EX_1 stage
            if(rs2_1 == exmem_rd_1 && rs2_1 != 5'b0)
                mux2_ctrl_1 = 2'b0;
            else if(!memwb_wb_1)
            begin
                if(rs2_1 == memwb_rd_1 && rs2_1 != 5'b0)
                    mux2_ctrl_1 = 2'b1;
                else
                    mux2_ctrl_1 = 2'b10;
            end
            else
                mux2_ctrl_1 = 2'b10;
        end

        //------------------------------------------//

        else if(!memwb_wb_0) //forward from WB_0 stage
        begin
            //forward rs_0 to EX_0 stage
            if(rs1_0 == memwb_rd_0 && rs1_0 != 5'b0)
                mux1_ctrl_0 = 2'b1;
            else
                mux1_ctrl_0 = 2'b0;

            //forward rs_1 to EX_0 stage
            if(rs2_0 == memwb_rd_0 && rs2_0 != 5'b0)
                mux2_ctrl_0 = 2'b1;
            else
                mux2_ctrl_0 = 2'b10;

            //forward rs_0 to EX_1 stage
            if(rs1_1 == memwb_rd_0 && rs1_1 != 5'b0)
                mux1_ctrl_1 = 2'b1;
            else
                mux1_ctrl_1 = 2'b0;

            //forward rs_1 to EX_1 stage
            if(rs2_1 == memwb_rd_0 && rs2_1 != 5'b0)
                mux2_ctrl_1 = 2'b1;
            else
                mux2_ctrl_1 = 2'b10;
        end
    end

	else //no forwarding needed
	begin
		mux1_ctrl_0 = 2'b0;
		mux2_ctrl_0 = 2'b10;

		mux1_ctrl_1 = 2'b0;
		mux2_ctrl_1 = 2'b10;
	end
end

endmodule
