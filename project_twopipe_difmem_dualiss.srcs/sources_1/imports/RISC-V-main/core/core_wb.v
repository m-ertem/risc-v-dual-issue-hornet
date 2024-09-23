`timescale 1ns/1ps

module core_wb(input reset_i, //active-low reset
               input clk_i,

               //Wishbone interface for data memory
               output        data_wb_cyc_o,
               output        data_wb_stb_o,
               output        data_wb_we_o,
               output [31:0] data_wb_adr_o,
               output [31:0] data_wb_dat_o,
               output [3:0]  data_wb_sel_o,
               input         data_wb_stall_i,
               input         data_wb_ack_i,
               input [31:0]  data_wb_dat_i,
               input         data_wb_err_i,
               input         data_wb_rst_i,
               input         data_wb_clk_i,

               //Wishbone interface for instruction memory
               output        inst_wb_cyc_o,
               output        inst_wb_stb_o,
               output        inst_wb_we_o,
               output [31:0] inst_wb_adr_o,
               output [31:0] inst_wb_dat_o,
               output [3:0]  inst_wb_sel_o,
               input         inst_wb_stall_i,
               input         inst_wb_ack_i,
               input [31:0]  inst_wb_dat_i,
               input [31:0]  inst_wb_dat_i_1,
               input         inst_wb_err_i,
               input         inst_wb_rst_i,
               input         inst_wb_clk_i,

               //Interrupts
               input meip_i,
               input mtip_i,
               input msip_i,
               input [15:0] fast_irq_i,
               output irq_ack_o); //Interrupt acknowledge signal. driven high for one cycle when an external interrupt is handled.

parameter reset_vector = 32'h0;

wire [31:0] data_addr_o;
wire [31:0] data_i;
wire [31:0] data_o;
wire [3:0]  data_wmask_o;
wire        data_wen_o;
wire        data_req_o;
wire        data_stall_i;
wire        data_err_i;

wire [31:0] instr_addr_o;
wire [31:0] instr_i;
wire [31:0] instr_i_tmp;
wire [31:0] instr_i_1;
wire [31:0] instr_i_1_tmp;
wire        instr_access_fault_i;

wire [31:0] mux_o_WB_0;
wire [31:0] mux_o_WB_1;
wire rf_wen_WB_0;
wire rf_wen_WB_1;
wire [4:0] rd_WB;
wire stall_EX;
wire misaligned_access_0;
wire misaligned_access_1;
wire [4:0] IDEX_preg_rs1_0;
wire [4:0] IDEX_preg_rs2_0;
wire [4:0] IDEX_preg_rs1_1;
wire [4:0] IDEX_preg_rs2_1;
wire stall_ID;
//wire [4:0] rs1_ID;
//wire [4:0] rs2_ID;
//wire take_branch;
wire csr_id_flush;
wire [31:0]IDEX_preg_data_1_out_0;
wire [31:0]IDEX_preg_data_2_out_0;
wire [31:0]IDEX_preg_data_1_out_1;
wire [31:0]IDEX_preg_data_2_out_1;
//
wire [31:0] pc_o;
wire [31:0] pc_i;
wire [31:0] pc_increment;
wire [31:0] branch_target_addr;
wire stall_IF_dual, stall_IF_0, stall_IF_1, take_branch_0;
wire priority_out;
wire funct3_0, funct3_1;
wire [4:0] opcode_0, opcode_1, rd_ID_1, rd_ID_0, rs1_ID_0, rs1_ID_1, rs2_ID_0, rs2_ID_1;
wire [4:0] rd_WB_0, rd_WB_1;
core_0    #(.reset_vector(reset_vector))
        core0(
        //Clock and reset signals.
        .clk_i(clk_i),
        .reset_i(reset_i), //active-low, asynchronous reset

        //Data memory interface
        //.data_addr_o(data_addr_o),
        //.data_i(data_i),
        //.data_o(data_o),
        //.data_wmask_o(data_wmask_o),
        //.data_wen_o(data_wen_o), //active-low
        //.data_req_o(data_req_o),
        //.data_stall_i(data_stall_i),
        //.data_err_i(data_err_i), 

        //Instruction memory interface
        .instr_addr_o(instr_addr_o),
        .instr_i(instr_i),
        .instr_access_fault_i(instr_access_fault_i),

        //Interrupts
        .meip_i(meip_i),
        .mtip_i(mtip_i),
        .msip_i(msip_i),
        .fast_irq_i(fast_irq_i),
        .irq_ack_o(irq_ack_o),
        
        ////////register bank/////////
       .rf_wen_WB (rf_wen_WB_0),
       .rd_WB (rd_WB_0),
       .mux_o_WB (mux_o_WB_0),
       .take_branch (take_branch_0),
       .csr_id_flush (csr_id_flush),
       .stall_EX (stall_EX_0),
       .misaligned_access (misaligned_access_0),
       .IDEX_preg_rs1 (IDEX_preg_rs1_0),
       .IDEX_preg_rs2 (IDEX_preg_rs2_0),
       .stall_ID (stall_ID_0),
       .rs1_ID (rs1_ID_0),
       .rs2_ID (rs2_ID_0),
       .IDEX_preg_data1 (IDEX_preg_data_1_out_0),
       .IDEX_preg_data2 (IDEX_preg_data_2_out_0),
       
       //issue unit//
       .issue_stall_0(issue_stall_0),
       .stall_IF(stall_IF_0),
      
       // dual hazard
       .priority_out(priority_out),
       .rd_ID(rd_ID_0),
       .funct3_0(funct3_0),
       .opcode_0(opcode_0),
       
       // pc_logic
       .branch_target_addr(branch_target_addr),
       .pc_i(pc_i),
       .pc_o(pc_o)
       );
 


core_1    #(.reset_vector(reset_vector))
        core1(
        //Clock and reset signals.
        .clk_i(clk_i),
        .reset_i(reset_i), //active-low, asynchronous reset

        //Data memory interface
        .data_addr_o(data_addr_o),
        .data_i(data_i),
        .data_o(data_o),
        .data_wmask_o(data_wmask_o),
        .data_wen_o(data_wen_o), //active-low
        .data_req_o(data_req_o),
        .data_stall_i(data_stall_i),
        .data_err_i(data_err_i),

        //Instruction memory interface
        //.instr_addr_o(instr_addr_o),
        .instr_i(instr_i_1),
        .instr_access_fault_i(instr_access_fault_i),

        //Interrupts
        .meip_i(meip_i),
        .mtip_i(mtip_i),
        .msip_i(msip_i),
        .fast_irq_i(fast_irq_i),
        .irq_ack_o(irq_ack_o),
        
        ////////register bank/////////
       .rf_wen_WB (rf_wen_WB_1),
       .rd_WB (rd_WB_1),
       .mux_o_WB (mux_o_WB_1),
       .take_branch (take_branch_1),
       .csr_id_flush (csr_id_flush),
       .stall_EX (stall_EX_1),
       .misaligned_access (misaligned_access_1),
       .IDEX_preg_rs1 (IDEX_preg_rs1_1),
       .IDEX_preg_rs2 (IDEX_preg_rs2_1),
       .stall_ID (stall_ID_1),
       .rs1_ID (rs1_ID_1),
       .rs2_ID (rs2_ID_1),
       .IDEX_preg_data1 (IDEX_preg_data_1_out_1),
       .IDEX_preg_data2 (IDEX_preg_data_2_out_1),
        
        //issue unit//
       .issue_stall_1(issue_stall_1),
       .stall_IF(stall_IF_1),
       
       //dual hazard
       .rd_ID(rd_ID_1),
       .funct3_1(funct3_1),
       .opcode_1(opcode_1)
        );
 
reg_bank REG_BANK( 
                 .clk_i(clk_i),
                 .reset_i(reset_i),
                 
                 .rf_wen_WB_0(rf_wen_WB_0),
                 .rf_wen_WB_1(rf_wen_WB_1),
                 
                 .rd_WB_0(rd_WB_0),
                 .rd_WB_1(rd_WB_1),
                 
                 .mux_o_WB_0(mux_o_WB_0),
                 .mux_o_WB_1(mux_o_WB_1),
                 .take_branch_0(take_branch_0),
                 .csr_id_flush(csr_id_flush),
                 
                 .stall_EX_0(stall_EX_0),
                 .stall_EX_1(stall_EX_1),
                 
                 .misaligned_access_0(misaligned_access_0),
                 .misaligned_access_1(misaligned_access_1),
                 .IDEX_preg_rs1_0(IDEX_preg_rs1_0),
                 .IDEX_preg_rs2_0(IDEX_preg_rs2_0),
                 
                 .IDEX_preg_rs1_1(IDEX_preg_rs1_1),
                 .IDEX_preg_rs2_1(IDEX_preg_rs2_1),
                 
                 .stall_ID_0(stall_ID_0),
                 .stall_ID_1(stall_ID_1),
                 
                 .rs1_ID_0(rs1_ID_0),
                 .rs2_ID_0(rs2_ID_1),
                 
                 .rs1_ID_1(rs1_ID_1),
                 .rs2_ID_1(rs2_ID_1),
                 
                 .IDEX_preg_data_1_out_0(IDEX_preg_data_1_out_0),
                 .IDEX_preg_data_1_out_1(IDEX_preg_data_1_out_1),
                 .IDEX_preg_data_2_out_0(IDEX_preg_data_2_out_0),
                 .IDEX_preg_data_2_out_1(IDEX_preg_data_2_out_1)
                 );

reg data_cyc;
always @(posedge data_wb_clk_i or posedge data_wb_rst_i)
begin
    if(data_wb_rst_i)
        data_cyc <= 1'b0;
    else if(data_req_o)
        data_cyc <= 1'b1;
    else if(data_wb_ack_i || data_wb_err_i)
        data_cyc <= 1'b0;
end

assign data_wb_cyc_o = data_req_o | data_cyc;
assign data_wb_stb_o = data_req_o;
assign data_wb_we_o  = ~data_wen_o;
assign data_wb_adr_o = data_addr_o;
assign data_wb_dat_o = data_o;
assign data_wb_sel_o = data_wmask_o;
assign data_i       = data_wb_dat_i;
assign data_stall_i = data_wb_stall_i;
assign data_err_i   = data_wb_err_i;

assign inst_wb_cyc_o = 1'b1;
assign inst_wb_stb_o = 1'b1;
assign inst_wb_we_o  = 1'b0;
assign inst_wb_adr_o = instr_addr_o;
assign inst_wb_dat_o = 32'b0;
assign inst_wb_sel_o = 4'hf;
assign instr_i_tmp = inst_wb_dat_i;
assign instr_i_1_tmp = inst_wb_dat_i_1;
assign instr_access_fault_i = inst_wb_err_i;

issue_unit ISSUE_UNIT(
     .instr_i_tmp(instr_i_tmp),
     .instr_i_1_tmp(instr_i_1_tmp),
     .stall_IF_0(stall_IF_0),
     .stall_IF_1(stall_IF_1),
     .stall_IF_dual(stall_IF_dual),
     .issue_stall_0(issue_stall_0),
     .issue_stall_1(issue_stall_1),
     .instr_i(instr_i),
     .instr_i_1(instr_i_1),
     .priority(priority_out),
     .pc_increment(pc_increment) // goes to pc logic
    );
dual_hazard_unit DUAL_HAZARD_UNIT(
     .priority(priority_out),
     .rs1_ID_0(rs1_ID_0),
     .rs2_ID_0(rs2_ID_0),
     .rd_ID_0(rd_ID_0),
     .opcode_0(opcode_0),
     .funct3_0(funct3_0),
     .rs1_ID_1(rs1_ID_1),
     .rs2_ID_1(rs2_ID_1),
     .rd_ID_1(rd_ID_1),
     .opcode_1(opcode_1),
     .funct3_1(funct3_1),
     .stall_IF_dual(stall_IF_dual)
);
pc_logic PC_LOGIC ( 
         .reset_i(reset_i),
	     .take_branch_0(take_branch_0),
	     .stall_IF_0(stall_IF_0),
	     .stall_IF_1(stall_IF_1),
	     .stall_IF_dual(stall_IF_dual),
	     .branch_target_addr_0(branch_target_addr),
	     .pc_o(pc_o), // comes from core 0
	     .pc_increment(pc_increment),
	     .pc_i(pc_i) // goes to core 0
);
endmodule
