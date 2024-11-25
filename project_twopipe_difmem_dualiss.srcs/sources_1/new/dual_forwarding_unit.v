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

    input [31:0] pc_MEM_0,
    input [31:0] pc_MEM_1,
    input [31:0] pc_WB_0,
    input [31:0] pc_WB_1,
    input [31:0] pc_EX_0,
    input [31:0] pc_EX_1,

    input priority_MEM,
    input priority_WB,

    output reg [2:0] mux1_ctrl_0, //control signal for mux2 in EX
    output reg [2:0] mux2_ctrl_0, //control signal for mux4 in EX
    
    output reg [2:0] mux1_ctrl_1, //control signal for mux2 in EX
    output reg [2:0] mux2_ctrl_1  //control signal for mux4 in EX
);

wire valid_MEM_0;
wire valid_MEM_1;
wire valid_WB_0;
wire valid_WB_1;

assign valid_MEM_1 = (pc_EX_0 > pc_MEM_1) ? 1'b1 : 1'b0; 
assign valid_MEM_0 = (pc_EX_1 > pc_MEM_0) ? 1'b1 : 1'b0; 
assign valid_WB_1  = (pc_EX_0 > pc_WB_1)  ? 1'b1 : 1'b0; 
assign valid_WB_0  = (pc_EX_1 > pc_WB_0)  ? 1'b1 : 1'b0; 

always @(*)
begin
    if(!exmem_wb_0 || !exmem_wb_1)
    begin
        if(!priority_MEM && !(rs1_1==32'b0 && rs2_1==32'b0))
        begin
            if(!exmem_wb_1) //forward from MEM_1 stage
            begin
                //--------------------FORWARD-TO-EX_0-STAGE------------------------//
                //--------------------------RS1-----------------------------//
                // forward rd_MEM_1 to rs1_EX_0 stage
                if(rs1_0 == exmem_rd_1 && rs1_0 != 5'b0 && valid_MEM_1)
                    mux1_ctrl_0 = 3'b100;
                // forward rd_MEM_0 to rs1_EX_0 stage
                else if(!exmem_wb_0 && rs1_0 == exmem_rd_0 && rs1_0 != 5'b0)
                    mux1_ctrl_0 = 3'b010;
                else if(!priority_WB)
                begin
                    // forward rd_WB_1 to rs1_EX_0 stage
                    if(!memwb_wb_1 && rs1_0 == memwb_rd_1 && rs1_0 != 5'b0 && valid_WB_1)
                        mux1_ctrl_0 = 3'b11;
                    // forward rd_WB_0 to rs1_EX_0 stage
                    else if(!memwb_wb_0 && rs1_0 == memwb_rd_0 && rs1_0 != 5'b0)
                        mux1_ctrl_0 = 3'b001;
                    else
                        mux1_ctrl_0 = 3'b0;
                end
                else if(priority_WB)
                begin
                    // forward rd_WB_0 to rs1_EX_0 stage
                    if(!memwb_wb_0 && rs1_0 == memwb_rd_0 && rs1_0 != 5'b0)
                        mux1_ctrl_0 = 3'b001;
                    // forward rd_WB_1 to rs1_EX_0 stage
                    else if(!memwb_wb_1 && rs1_0 == memwb_rd_1 && rs1_0 != 5'b0 && valid_WB_1)
                        mux1_ctrl_0 = 3'b11;
                    else
                        mux1_ctrl_0 = 3'b0;
                end
                else
                    mux1_ctrl_0 = 3'b0;

                //---------------------------RS2----------------------------//

                // forward rd_MEM_1 to rs2_EX_0 stage
                if(rs2_0 == exmem_rd_1 && rs2_0 != 5'b0 && valid_MEM_1)
                    mux2_ctrl_0 = 3'b100;
                // forward from rd_MEM_0 to rs2_EX_0
                else if(!exmem_wb_0 && rs2_0 == exmem_rd_0 && rs2_0 != 5'b0)
                    mux2_ctrl_0 = 3'b000;
                else if(!priority_WB)
                begin
                    // forward from rd_WB_1 to rs2_EX_0
                    if(!memwb_wb_1 && rs2_0 == memwb_rd_1 && rs2_0 != 5'b0 && valid_WB_1)
                        mux2_ctrl_0 = 3'b011;
                    // forward from rd_WB_0 to rs2_EX_0
                    else if(!memwb_wb_0 && rs2_0 == memwb_rd_0 && rs2_0 != 5'b0)
                        mux2_ctrl_0 = 3'b001;
                    else
                        mux2_ctrl_0 = 3'b010;
                end
                else if(priority_WB)
                begin
                    // forward from rd_WB_0 to rs2_EX_0
                    if(!memwb_wb_0 && rs2_0 == memwb_rd_0 && rs2_0 != 5'b0)
                        mux2_ctrl_0 = 3'b001;
                    // forward from rd_WB_1 to rs2_EX_0
                    else if(!memwb_wb_1 && rs2_0 == memwb_rd_1 && rs2_0 != 5'b0 && valid_WB_1)
                        mux2_ctrl_0 = 3'b011;
                    else
                        mux2_ctrl_0 = 3'b010;
                end
                else
                    mux2_ctrl_0 = 3'b010;

                //--------------------FORWARD-TO-EX_1-STAGE------------------------//

                //--------------------------RS1-----------------------------//
                // forward rd_MEM_1 to rs1_EX_1 stage
                if(rs1_1 == exmem_rd_1 && rs1_1 != 5'b0)
                    mux1_ctrl_1 = 3'b010;
                // forward rd_MEM_0 to rs1_EX_1 stage
                else if(!exmem_wb_0 && rs1_1 == exmem_rd_0 && rs1_1 != 5'b0 && valid_MEM_0)
                    mux1_ctrl_1 = 3'b100;
                else if(!priority_WB)
                begin
                    // forward rd_WB_1 to rs1_EX_1 stage
                    if(!memwb_wb_1 && rs1_1 == memwb_rd_1 && rs1_1 != 5'b0)
                        mux1_ctrl_1 = 3'b001;
                    // forward rd_WB_0 to rs1_EX_1 stage
                    else if(!memwb_wb_0 && rs1_1 == memwb_rd_0 && rs1_1 != 5'b0 && valid_WB_0)
                        mux1_ctrl_1 = 3'b011;
                    else
                        mux1_ctrl_1 = 3'b0;
                end
                else if(priority_WB)
                begin
                    // forward rd_WB_0 to rs1_EX_1 stage
                    if(!memwb_wb_0 && rs1_1 == memwb_rd_0 && rs1_1 != 5'b0 && valid_WB_0)
                        mux1_ctrl_1 = 3'b011;
                    // forward rd_WB_1 to rs1_EX_1 stage
                    else if(!memwb_wb_1 && rs1_1 == memwb_rd_1 && rs1_1 != 5'b0)
                        mux1_ctrl_1 = 3'b001;
                    else
                        mux1_ctrl_1 = 3'b0;
                end
                else
                    mux1_ctrl_1 = 3'b0;

                //---------------------------RS2----------------------------//

                // forward rd_MEM_1 to rs2_EX_1 stage
                if(rs2_1 == exmem_rd_1 && rs2_1 != 5'b0)
                    mux2_ctrl_1 = 3'b000;
                // forward from rd_MEM_0 to rs2_EX_1
                else if(!exmem_wb_0 && rs2_1 == exmem_rd_0 && rs2_1 != 5'b0 && valid_MEM_0)
                    mux2_ctrl_1 = 3'b100;
                else if(!priority_WB)
                begin
                    // forward from rd_WB_1 to rs2_EX_1
                    if(!memwb_wb_1 && rs2_1 == memwb_rd_1 && rs2_1 != 5'b0)
                        mux2_ctrl_1 = 3'b001;
                    // forward from rd_WB_0 to rs2_EX_1
                    else if(!memwb_wb_0 && rs2_1 == memwb_rd_0 && rs2_1 != 5'b0 && valid_WB_0)
                        mux2_ctrl_1 = 3'b011;
                    else
                        mux2_ctrl_1 = 3'b010;
                end
                else if(priority_WB)
                begin
                    // forward from rd_WB_0 to rs2_EX_1
                    if(!memwb_wb_0 && rs2_1 == memwb_rd_0 && rs2_1 != 5'b0 && valid_MEM_0)
                        mux2_ctrl_1 = 3'b011;
                    // forward from rd_WB_1 to rs2_EX_1
                    else if(!memwb_wb_1 && rs2_1 == memwb_rd_1 && rs2_1 != 5'b0)
                        mux2_ctrl_1 = 3'b001;
                    else
                        mux2_ctrl_1 = 3'b010;
                end
                else
                    mux2_ctrl_1 = 3'b010;
            end

            //-------------------------------------------------------//

            else if(!exmem_wb_0) //forward from MEM_0 stage
            begin
                //--------------------FORWARD-TO-EX_0-STAGE------------------------//
                //--------------------------RS1-----------------------------//
                // forward rd_MEM_0 to rs1_EX_0 stage
                if(rs1_0 == exmem_rd_0 && rs1_0 != 5'b0)
                    mux1_ctrl_0 = 3'b010;
                // forward rd_MEM_1 to rs1_EX_0 stage
                else if(!exmem_wb_1 && rs1_0 == exmem_rd_1 && rs1_0 != 5'b0 && valid_MEM_1)
                    mux1_ctrl_0 = 3'b100;
                else if(!priority_WB)
                begin
                    // forward rd_WB_1 to rs1_EX_0 stage
                    if(!memwb_wb_1 && rs1_0 == memwb_rd_1 && rs1_0 != 5'b0 && valid_WB_1)
                        mux1_ctrl_0 = 3'b11;
                    // forward rd_WB_0 to rs1_EX_0 stage
                    else if(!memwb_wb_0 && rs1_0 == memwb_rd_0 && rs1_0 != 5'b0)
                        mux1_ctrl_0 = 3'b001;
                    else
                        mux1_ctrl_0 = 3'b0;
                end
                else if(priority_WB)
                begin
                    // forward rd_WB_0 to rs1_EX_0 stage
                    if(!memwb_wb_0 && rs1_0 == memwb_rd_0 && rs1_0 != 5'b0)
                        mux1_ctrl_0 = 3'b001;
                    // forward rd_WB_1 to rs1_EX_0 stage
                    else if(!memwb_wb_1 && rs1_0 == memwb_rd_1 && rs1_0 != 5'b0 && valid_WB_1)
                        mux1_ctrl_0 = 3'b11;
                    else
                        mux1_ctrl_0 = 3'b0;
                end
                else
                    mux1_ctrl_0 = 3'b0;

                //---------------------------RS2----------------------------//
                // forward from rd_MEM_0 to rs2_EX_0
                if(rs2_0 == exmem_rd_0 && rs2_0 != 5'b0)
                    mux2_ctrl_0 = 3'b000;
                // forward rd_MEM_1 to rs2_EX_0 stage
                else if(!exmem_wb_1 && rs2_0 == exmem_rd_1 && rs2_0 != 5'b0 && valid_MEM_1)
                    mux2_ctrl_0 = 3'b100;
                else if(!priority_WB)
                begin
                    // forward from rd_WB_1 to rs2_EX_0
                    if(!memwb_wb_1 && rs2_0 == memwb_rd_1 && rs2_0 != 5'b0 && valid_WB_1)
                        mux2_ctrl_0 = 3'b011;
                    // forward from rd_WB_0 to rs2_EX_0
                    else if(!memwb_wb_0 && rs2_0 == memwb_rd_0 && rs2_0 != 5'b0)
                        mux2_ctrl_0 = 3'b001;
                    else
                        mux2_ctrl_0 = 3'b010;
                end
                else if(priority_WB)
                begin
                    // forward from rd_WB_0 to rs2_EX_0
                    if(!memwb_wb_0 && rs2_0 == memwb_rd_0 && rs2_0 != 5'b0)
                        mux2_ctrl_0 = 3'b001;
                    // forward from rd_WB_1 to rs2_EX_0
                    else if(!memwb_wb_1 && rs2_0 == memwb_rd_1 && rs2_0 != 5'b0 && valid_WB_1)
                        mux2_ctrl_0 = 3'b011;
                    else
                        mux2_ctrl_0 = 3'b010;
                end
                else
                    mux2_ctrl_0 = 3'b010;

                //--------------------FORWARD-TO-EX_1-STAGE------------------------//

                //--------------------------RS1-----------------------------//
                // forward rd_MEM_0 to rs1_EX_1 stage
                if(rs1_1 == exmem_rd_0 && rs1_1 != 5'b0 && valid_MEM_0)
                    mux1_ctrl_1 = 3'b100;
                // forward rd_MEM_1 to rs1_EX_1 stage
                else if(!exmem_wb_1 && rs1_1 == exmem_rd_1 && rs1_1 != 5'b0)
                    mux1_ctrl_1 = 3'b010;
                else if(!priority_WB)
                begin
                    // forward rd_WB_1 to rs1_EX_1 stage
                    if(!memwb_wb_1 && rs1_1 == memwb_rd_1 && rs1_1 != 5'b0)
                        mux1_ctrl_1 = 3'b001;
                    // forward rd_WB_0 to rs1_EX_1 stage
                    else if(!memwb_wb_0 && rs1_1 == memwb_rd_0 && rs1_1 != 5'b0 && valid_WB_0)
                        mux1_ctrl_1 = 3'b011;
                    else
                        mux1_ctrl_1 = 3'b0;
                end
                else if(priority_WB)
                begin
                    // forward rd_WB_0 to rs1_EX_1 stage
                    if(!memwb_wb_0 && rs1_1 == memwb_rd_0 && rs1_1 != 5'b0 && valid_WB_0)
                        mux1_ctrl_1 = 3'b011;
                    // forward rd_WB_1 to rs1_EX_1 stage
                    else if(!memwb_wb_1 && rs1_1 == memwb_rd_1 && rs1_1 != 5'b0)
                        mux1_ctrl_1 = 3'b001;
                    else
                        mux1_ctrl_1 = 3'b0;
                end
                else
                    mux1_ctrl_1 = 3'b0;

                //---------------------------RS2----------------------------//
                // forward from rd_MEM_0 to rs2_EX_1
                if(rs2_1 == exmem_rd_0 && rs2_1 != 5'b0 && valid_MEM_0)
                    mux2_ctrl_1 = 3'b100;
                // forward rd_MEM_1 to rs2_EX_1 stage
                else if(!exmem_wb_1 && rs2_1 == exmem_rd_1 && rs2_1 != 5'b0)
                    mux2_ctrl_1 = 3'b000;
                else if(!priority_WB)
                begin
                    // forward from rd_WB_1 to rs2_EX_1
                    if(!memwb_wb_1 && rs2_1 == memwb_rd_1 && rs2_1 != 5'b0)
                        mux2_ctrl_1 = 3'b001;
                    // forward from rd_WB_0 to rs2_EX_1
                    else if(!memwb_wb_0 && rs2_1 == memwb_rd_0 && rs2_1 != 5'b0 && valid_WB_0)
                        mux2_ctrl_1 = 3'b011;
                    else
                        mux2_ctrl_1 = 3'b010;
                end
                else if(priority_WB)
                begin
                    // forward from rd_WB_0 to rs2_EX_1
                    if(!memwb_wb_0 && rs2_1 == memwb_rd_0 && rs2_1 != 5'b0 && valid_MEM_0)
                        mux2_ctrl_1 = 3'b011;
                    // forward from rd_WB_1 to rs2_EX_1
                    else if(!memwb_wb_1 && rs2_1 == memwb_rd_1 && rs2_1 != 5'b0)
                        mux2_ctrl_1 = 3'b001;
                    else
                        mux2_ctrl_1 = 3'b010;
                end
                else
                    mux2_ctrl_1 = 3'b010;
            end
        end
        //------------------------------------------//
        else // priority_MEM == 1
        begin
            if(!exmem_wb_0) //forward from MEM_0 stage
            begin
                //--------------------FORWARD-TO-EX_0-STAGE------------------------//
                //--------------------------RS1-----------------------------//
                //forward rd_MEM_0 to rs1_EX_0 stage
                if(rs1_0 == exmem_rd_0 && rs1_0 != 5'b0)
                    mux1_ctrl_0 = 3'b010;
                // forward rd_MEM_1 to rs1_EX_0 stage
                else if(!exmem_wb_1 && rs1_0 == exmem_rd_1 && rs1_0 != 5'b0 && valid_MEM_1)
                    mux1_ctrl_0 = 3'b100;
                else if(!priority_WB)
                begin
                    // forward rd_WB_1 to rs1_EX_0 stage
                    if(!memwb_wb_1 && rs1_0 == memwb_rd_1 && rs1_0 != 5'b0 && valid_WB_1)
                        mux1_ctrl_0 = 3'b11;
                    // forward rd_WB_0 to rs1_EX_0 stage
                    else if(!memwb_wb_0 && rs1_0 == memwb_rd_0 && rs1_0 != 5'b0)
                        mux1_ctrl_0 = 3'b001;
                    else
                        mux1_ctrl_0 = 3'b0;
                end
                else if(priority_WB)
                begin
                    // forward rd_WB_0 to rs1_EX_0 stage
                    if(!memwb_wb_0 && rs1_0 == memwb_rd_0 && rs1_0 != 5'b0)
                        mux1_ctrl_0 = 3'b001;
                    // forward rd_WB_1 to rs1_EX_0 stage
                    else if(!memwb_wb_1 && rs1_0 == memwb_rd_1 && rs1_0 != 5'b0 && valid_WB_1)
                        mux1_ctrl_0 = 3'b11;
                    else
                        mux1_ctrl_0 = 3'b0;
                end
                else
                    mux1_ctrl_0 = 3'b0;

                //---------------------------RS2----------------------------//

                //forward rd_MEM_0 to rs2_EX_0 stage
                if(rs2_0 == exmem_rd_0 && rs2_0 != 5'b0)
                    mux2_ctrl_0 = 3'b000;
                // forward rd_MEM_1 to rs2_EX_0 stage
                else if(!exmem_wb_1 && rs2_0 == exmem_rd_1 && rs2_0 != 5'b0 && valid_MEM_1)
                    mux2_ctrl_0 = 3'b100;
                else if(!priority_WB)
                begin
                    // forward from rd_WB_1 to rs2_EX_0 stage
                    if(!memwb_wb_1 && rs2_0 == memwb_rd_1 && rs2_0 != 5'b0 && valid_WB_1)
                        mux2_ctrl_0 = 3'b011;
                    // forward from rd_WB_0 to rs2_EX_0 stage
                    else if(!memwb_wb_0 && rs2_0 == memwb_rd_0 && rs2_0 != 5'b0)
                        mux2_ctrl_0 = 3'b001;
                    else
                        mux2_ctrl_0 = 3'b010;
                end
                else if(priority_WB)
                begin
                    // forward from rd_WB_0 to rs2_EX_0 stage
                    if(!memwb_wb_0 && rs2_0 == memwb_rd_0 && rs2_0 != 5'b0)
                        mux2_ctrl_0 = 3'b001;
                    // forward from rd_WB_1 to rs2_EX_0 stage
                    else if(!memwb_wb_1 && rs2_0 == memwb_rd_1 && rs2_0 != 5'b0 && valid_WB_1)
                        mux2_ctrl_0 = 3'b011;
                    else
                        mux2_ctrl_0 = 3'b010;
                end
                else
                    mux2_ctrl_0 = 3'b010;

                //--------------------FORWARD-TO-EX_1-STAGE------------------------//

                //--------------------------RS1-----------------------------//
                // forward rd_MEM_0 to rs1_EX_1 stage
                if(rs1_1 == exmem_rd_0 && rs1_1 != 5'b0 && valid_MEM_0)
                    mux1_ctrl_1 = 3'b100;
                // forward rd_MEM_1 to rs1_EX_1 stage
                else if(!exmem_wb_1 && rs1_1 == exmem_rd_1 && rs1_1 != 5'b0)
                    mux1_ctrl_1 = 3'b010;
                else if(!priority_WB)
                begin
                    // forward rd_WB_1 to rs1_EX_1 stage
                    if(!memwb_wb_1 && rs1_1 == memwb_rd_1 && rs1_1 != 5'b0)
                        mux1_ctrl_1 = 3'b001;
                    // forward rd_WB_0 to rs1_EX_1 stage
                    else if(!memwb_wb_0 && rs1_1 == memwb_rd_0 && rs1_1 != 5'b0 && valid_WB_0)
                        mux1_ctrl_1 = 3'b011;
                    else
                        mux1_ctrl_1 = 3'b0;
                end
                else if(priority_WB)
                begin
                    // forward rd_WB_0 to rs1_EX_1 stage
                    if(!memwb_wb_0 && rs1_1 == memwb_rd_0 && rs1_1 != 5'b0 && valid_WB_0)
                        mux1_ctrl_1 = 3'b011;
                    // forward rd_WB_1 to rs1_EX_1 stage
                    else if(!memwb_wb_1 && rs1_1 == memwb_rd_1 && rs1_1 != 5'b0)
                        mux1_ctrl_1 = 3'b001;
                    else
                        mux1_ctrl_1 = 3'b0;
                end
                else
                    mux1_ctrl_1 = 3'b0;

                //---------------------------RS2----------------------------//
                // forward from rd_MEM_0 to rs2_EX_1
                if(rs2_1 == exmem_rd_0 && rs2_1 != 5'b0 && valid_MEM_0)
                    mux2_ctrl_1 = 3'b100;
                // forward rd_MEM_1 to rs2_EX_1 stage
                else if(!exmem_wb_1 && rs2_1 == exmem_rd_1 && rs2_1 != 5'b0)
                    mux2_ctrl_1 = 3'b000;
                else if(!priority_WB)
                begin
                    // forward from rd_WB_1 to rs2_EX_1
                    if(!memwb_wb_1 && rs2_1 == memwb_rd_1 && rs2_1 != 5'b0)
                        mux2_ctrl_1 = 3'b001;
                    // forward from rd_WB_0 to rs2_EX_1
                    else if(!memwb_wb_0 && rs2_1 == memwb_rd_0 && rs2_1 != 5'b0 && valid_WB_0)
                        mux2_ctrl_1 = 3'b011;
                    else
                        mux2_ctrl_1 = 3'b010;
                end
                else if(priority_WB)
                begin
                    // forward from rd_WB_0 to rs2_EX_1
                    if(!memwb_wb_0 && rs2_1 == memwb_rd_0 && rs2_1 != 5'b0 && valid_MEM_0)
                        mux2_ctrl_1 = 3'b011;
                    // forward from rd_WB_1 to rs2_EX_1
                    else if(!memwb_wb_1 && rs2_1 == memwb_rd_1 && rs2_1 != 5'b0)
                        mux2_ctrl_1 = 3'b001;
                    else
                        mux2_ctrl_1 = 3'b010;
                end
                else
                    mux2_ctrl_1 = 3'b010;
            end
            else if(!exmem_wb_1) //forward from MEM_1 stage
            begin
                //--------------------FORWARD-TO-EX_0-STAGE------------------------//
                //--------------------------RS1-----------------------------//
                // forward rd_MEM_1 to rs1_EX_0 stage
                if(rs1_0 == exmem_rd_1 && rs1_0 != 5'b0 && valid_MEM_1)
                    mux1_ctrl_0 = 3'b100;
                //forward rd_MEM_0 to rs1_EX_0 stage
                else if(!exmem_wb_0 && rs1_0 == exmem_rd_0 && rs1_0 != 5'b0)
                    mux1_ctrl_0 = 3'b010;
                else if(!priority_WB)
                begin
                    // forward rd_WB_1 to rs1_EX_0 stage
                    if(!memwb_wb_1 && rs1_0 == memwb_rd_1 && rs1_0 != 5'b0 && valid_WB_1)
                        mux1_ctrl_0 = 3'b11;
                    // forward rd_WB_0 to rs1_EX_0 stage
                    else if(!memwb_wb_0 && rs1_0 == memwb_rd_0 && rs1_0 != 5'b0)
                        mux1_ctrl_0 = 3'b001;
                    else
                        mux1_ctrl_0 = 3'b0;
                end
                else if(priority_WB)
                begin
                    // forward rd_WB_0 to rs1_EX_0 stage
                    if(!memwb_wb_0 && rs1_0 == memwb_rd_0 && rs1_0 != 5'b0)
                        mux1_ctrl_0 = 3'b001;
                    // forward rd_WB_1 to rs1_EX_0 stage
                    else if(!memwb_wb_1 && rs1_0 == memwb_rd_1 && rs1_0 != 5'b0 && valid_WB_1)
                        mux1_ctrl_0 = 3'b11;
                    else
                        mux1_ctrl_0 = 3'b0;
                end
                else
                    mux1_ctrl_0 = 3'b0;

                //---------------------------RS2----------------------------//

                // forward rd_MEM_1 to rs2_EX_0 stage
                if(rs2_0 == exmem_rd_1 && rs2_0 != 5'b0 && valid_MEM_1)
                    mux2_ctrl_0 = 3'b100;
                //forward rd_MEM_0 to rs2_EX_0 stage
                else if(!exmem_wb_0 && rs2_0 == exmem_rd_0 && rs2_0 != 5'b0)
                    mux2_ctrl_0 = 3'b000;
                else if(!priority_WB)
                begin
                    // forward from rd_WB_1 to rs2_EX_0 stage
                    if(!memwb_wb_1 && rs2_0 == memwb_rd_1 && rs2_0 != 5'b0 && valid_WB_1)
                        mux2_ctrl_0 = 3'b011;
                    // forward from rd_WB_0 to rs2_EX_0 stage
                    else if(!memwb_wb_0 && rs2_0 == memwb_rd_0 && rs2_0 != 5'b0)
                        mux2_ctrl_0 = 3'b001;
                    else
                        mux2_ctrl_0 = 3'b010;
                end
                else if(priority_WB)
                begin
                    // forward from rd_WB_0 to rs2_EX_0 stage
                    if(!memwb_wb_0 && rs2_0 == memwb_rd_0 && rs2_0 != 5'b0)
                        mux2_ctrl_0 = 3'b001;
                    // forward from rd_WB_1 to rs2_EX_0 stage
                    else if(!memwb_wb_1 && rs2_0 == memwb_rd_1 && rs2_0 != 5'b0 && valid_WB_1)
                        mux2_ctrl_0 = 3'b011;
                    else
                        mux2_ctrl_0 = 3'b010;
                end
                else
                    mux2_ctrl_0 = 3'b010;
                //--------------------FORWARD-TO-EX_1-STAGE------------------------//

                //--------------------------RS1-----------------------------//
                // forward rd_MEM_1 to rs1_EX_1 stage
                if(rs1_1 == exmem_rd_1 && rs1_1 != 5'b0)
                    mux1_ctrl_1 = 3'b010;
                // forward rd_MEM_0 to rs1_EX_1 stage
                else if(!exmem_wb_0 && rs1_1 == exmem_rd_0 && rs1_1 != 5'b0 && valid_MEM_0)
                    mux1_ctrl_1 = 3'b100;
                else if(!priority_WB)
                begin
                    // forward rd_WB_1 to rs1_EX_1 stage
                    if(!memwb_wb_1 && rs1_1 == memwb_rd_1 && rs1_1 != 5'b0)
                        mux1_ctrl_1 = 3'b001;
                    // forward rd_WB_0 to rs1_EX_1 stage
                    else if(!memwb_wb_0 && rs1_1 == memwb_rd_0 && rs1_1 != 5'b0 && valid_WB_0)
                        mux1_ctrl_1 = 3'b011;
                    else
                        mux1_ctrl_1 = 3'b0;
                end
                else if(priority_WB)
                begin
                    // forward rd_WB_0 to rs1_EX_1 stage
                    if(!memwb_wb_0 && rs1_1 == memwb_rd_0 && rs1_1 != 5'b0 && valid_WB_0)
                        mux1_ctrl_1 = 3'b011;
                    // forward rd_WB_1 to rs1_EX_1 stage
                    else if(!memwb_wb_1 && rs1_1 == memwb_rd_1 && rs1_1 != 5'b0)
                        mux1_ctrl_1 = 3'b001;
                    else
                        mux1_ctrl_1 = 3'b0;
                end
                else
                    mux1_ctrl_1 = 3'b0;

                //---------------------------RS2----------------------------//

                // forward rd_MEM_1 to rs2_EX_1 stage
                if(rs2_1 == exmem_rd_1 && rs2_1 != 5'b0)
                    mux2_ctrl_1 = 3'b000;
                // forward from rd_MEM_0 to rs2_EX_1
                else if(!exmem_wb_0 && rs2_1 == exmem_rd_0 && rs2_1 != 5'b0 && valid_MEM_0)
                    mux2_ctrl_1 = 3'b100;
                else if(!priority_WB)
                begin
                    // forward from rd_WB_1 to rs2_EX_1
                    if(!memwb_wb_1 && rs2_1 == memwb_rd_1 && rs2_1 != 5'b0)
                        mux2_ctrl_1 = 3'b001;
                    // forward from rd_WB_0 to rs2_EX_1
                    else if(!memwb_wb_0 && rs2_1 == memwb_rd_0 && rs2_1 != 5'b0 && valid_WB_0)
                        mux2_ctrl_1 = 3'b011;
                    else
                        mux2_ctrl_1 = 3'b010;
                end
                else if(priority_WB)
                begin
                    // forward from rd_WB_0 to rs2_EX_1
                    if(!memwb_wb_0 && rs2_1 == memwb_rd_0 && rs2_1 != 5'b0 && valid_MEM_0)
                        mux2_ctrl_1 = 3'b011;
                    // forward from rd_WB_1 to rs2_EX_1
                    else if(!memwb_wb_1 && rs2_1 == memwb_rd_1 && rs2_1 != 5'b0)
                        mux2_ctrl_1 = 3'b001;
                    else
                        mux2_ctrl_1 = 3'b010;
                end
                else
                    mux2_ctrl_1 = 3'b010;
            end
        end
    end
        
    //------------------FORWARD-FROM-WB-STAGE-----------------------//

    else if(!memwb_wb_0 || !memwb_wb_1)
    begin
        if(!priority_WB && !(rs1_1==32'b0 && rs2_1==32'b0)) 
        begin
            if(!memwb_wb_1) //forward from WB_1 stage
            begin
                //forward rd_WB_1 to rs1_EX_0 stage
                if(rs1_0 == memwb_rd_1 && rs1_0 != 5'b0 && valid_WB_1)
                    mux1_ctrl_0 = 3'b011;
                else
                    mux1_ctrl_0 = 3'b000;

                //forward rd_WB_1 to rs2_EX_0 stage
                if(rs2_0 == memwb_rd_1 && rs2_0 != 5'b0 && valid_WB_1)
                    mux2_ctrl_0 = 3'b011;
                else
                    mux2_ctrl_0 = 3'b010;

                //forward rd_WB_1 to rs1_EX_1 stage
                if(rs1_1 == memwb_rd_1 && rs1_1 != 5'b0)
                    mux1_ctrl_1 = 3'b001;
                else
                    mux1_ctrl_1 = 3'b000;

                //forward rd_WB_1 to rs2_EX_1 stage
                if(rs2_1 == memwb_rd_1 && rs2_1 != 5'b0)
                    mux2_ctrl_1 = 3'b001;
                else
                    mux2_ctrl_1 = 3'b010;
            end
            
            else if(!memwb_wb_0) //forward from WB_0 stage
            begin
                //forward rd_WB_0 to rs1_EX_0 stage
                if(rs1_0 == memwb_rd_0 && rs1_0 != 5'b0)
                    mux1_ctrl_0 = 3'b001;
                else
                    mux1_ctrl_0 = 3'b000;

                //forward rd_WB_0 to rs2_EX_0 stage
                if(rs2_0 == memwb_rd_0 && rs2_0 != 5'b0)
                    mux2_ctrl_0 = 3'b001;
                else
                    mux2_ctrl_0 = 3'b010;

                //forward rd_WB_0 to rs1_EX_1 stage
                if(rs1_1 == memwb_rd_0 && rs1_1 != 5'b0 && valid_WB_0)
                    mux1_ctrl_1 = 3'b011;
                else
                    mux1_ctrl_1 = 3'b000;

                //forward rd_WB_0 to rs2_EX_1 stage
                if(rs2_1 == memwb_rd_0 && rs2_1 != 5'b0 && valid_WB_0)
                    mux2_ctrl_1 = 3'b011;
                else
                    mux2_ctrl_1 = 3'b010;
            end
        end

        //------------------------------------------//

        else // priority_WB == 1
        begin
            if(!memwb_wb_0) //forward from WB_0 stage
            begin
                //forward rd_WB_0 to rs1_EX_0 stage
                if(rs1_0 == memwb_rd_0 && rs1_0 != 5'b0)
                    mux1_ctrl_0 = 3'b001;
                else
                    mux1_ctrl_0 = 3'b000;

                //forward rd_WB_0 to rs2_EX_0 stage
                if(rs2_0 == memwb_rd_0 && rs2_0 != 5'b0)
                    mux2_ctrl_0 = 3'b001;
                else
                    mux2_ctrl_0 = 3'b010;

                //forward rd_WB_0 to rs1_EX_1 stage
                if(rs1_1 == memwb_rd_0 && rs1_1 != 5'b0 && valid_WB_0)
                    mux1_ctrl_1 = 3'b011;
                else
                    mux1_ctrl_1 = 3'b000;

                //forward rd_WB_0 to rs2_EX_1 stage
                if(rs2_1 == memwb_rd_0 && rs2_1 != 5'b0 && valid_WB_0)
                    mux2_ctrl_1 = 3'b011;
                else
                    mux2_ctrl_1 = 3'b010;
            end
            else if(!memwb_wb_1) //forward from WB_1 stage
            begin
                //forward rd_WB_1 to rs1_EX_0 stage
                if(rs1_0 == memwb_rd_1 && rs1_0 != 5'b0 && valid_WB_1)
                    mux1_ctrl_0 = 3'b011;
                else
                    mux1_ctrl_0 = 3'b000;

                //forward rd_WB_1 to rs2_EX_0 stage
                if(rs2_0 == memwb_rd_1 && rs2_0 != 5'b0 && valid_WB_1)
                    mux2_ctrl_0 = 3'b011;
                else
                    mux2_ctrl_0 = 3'b010;

                //forward rd_WB_1 to rs1_EX_1 stage
                if(rs1_1 == memwb_rd_1 && rs1_1 != 5'b0)
                    mux1_ctrl_1 = 3'b001;
                else
                    mux1_ctrl_1 = 3'b000;

                //forward rd_WB_1 to rs2_EX_1 stage
                if(rs2_1 == memwb_rd_1 && rs2_1 != 5'b0)
                    mux2_ctrl_1 = 3'b001;
                else
                    mux2_ctrl_1 = 3'b010;
            end
        end
    end

	else //no forwarding needed
	begin
		mux1_ctrl_0 = 3'b0;
		mux2_ctrl_0 = 3'b10;

		mux1_ctrl_1 = 3'b0;
		mux2_ctrl_1 = 3'b10;
	end
end

endmodule
