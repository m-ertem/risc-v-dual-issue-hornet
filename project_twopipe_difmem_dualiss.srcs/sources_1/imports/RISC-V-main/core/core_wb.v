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
wire [31:0] aluout_MEM_0;
wire [31:0] aluout_MEM_1;
wire rf_wen_WB_0;
wire rf_wen_WB_1;
wire [4:0] rd_WB;
wire stall_EX;
wire misaligned_access_1;
wire [4:0] IDEX_preg_rs1_0;
wire [4:0] IDEX_preg_rs2_0;
wire [4:0] IDEX_preg_rs1_1;
wire [4:0] IDEX_preg_rs2_1;
wire stall_ID;
//wire [4:0] rs1_ID;
//wire [4:0] rs2_ID;
//wire take_branch;
wire [31:0]IDEX_preg_data_1_out_0;
wire [31:0]IDEX_preg_data_2_out_0;
wire [31:0]IDEX_preg_data_1_out_1;
wire [31:0]IDEX_preg_data_2_out_1;

// reg bank signals
wire stall_EX_0, stall_EX_1;


// pc logic unit signals
wire [31:0] pc_o;
wire [31:0] pc_i;
wire [31:0] pc_increment;
wire [31:0] branch_target_addr;

// issue unit - dual hazard unit signals
wire dual_hazard_stall_0, dual_hazard_stall_1, stall_IF_0, stall_IF_1, take_branch_0;
wire priority_out_to_core_0, priority_overwrite;
wire priority_out_to_dual_hazard_unit;
wire funct3_0, funct3_1;
wire L_ID, L;
wire [4:0] opcode_0, opcode_1, rd_ID_1, rd_ID_0, rs1_ID_0, rs1_ID_1, rs2_ID_0, rs2_ID_1, rd_EX_0, rd_EX_1;
wire [4:0] rd_WB_0, rd_WB_1;
wire issue_stall_0, issue_stall_1;
wire pipe_0_occuppied_w_branch_IF;
wire muldiv_stall_EX;

// dual forwarding unit signals
// -- for core_0
wire [4:0]  rs1_EX_0, rs2_EX_0;
wire [4:0]  rd_MEM_0;
// wire [4:0]  rd_WB_0; // already declared
wire [6:0] wb_MEM_0;
// wire       rf_wen_WB_0; // already declared
wire [2:0] mux2_ctrl_EX_0,  mux4_ctrl_EX_0;
// -- for core_1
wire [4:0]  rs1_EX_1, rs2_EX_1;
wire [4:0]  rd_MEM_1;
// wire [4:0]  rd_WB_1; already declared
wire [6:0] wb_MEM_1;
// wire       rf_wen_WB_1; // already declared
wire [2:0] mux2_ctrl_EX_1,  mux4_ctrl_EX_1;
wire priority_MEM, priority_WB;

wire [31:0] pc_ID_0;
wire [31:0] pc_ID_1;
wire [31:0] pc_EX_0;
wire [31:0] pc_EX_1;
wire [31:0] pc_MEM_0;
wire [31:0] pc_MEM_1;
wire [31:0] pc_WB_0;
wire [31:0] pc_WB_1;
//
wire [31:0] pc_i_1;

// csr signals
wire [31:0] csr_reg_out_0;
reg  [31:0] csr_pc_input;
wire [31:0] csr_pc_input_0;
wire [31:0] csr_pc_input_1;
wire [31:0] IFID_preg_instr_0;
wire [11:0] csr_addr_WB_0;
wire [31:0] imm_WB_0;
wire csr_wen_WB_0;
wire mret_ID_0; 
wire mret_WB_0;
wire mem_wen;
wire IDEX_preg_dummy_0;
wire EXMEM_preg_dummy_0;
wire IDEX_preg_dummy_1;
wire EXMEM_preg_dummy_1;
wire csr_if_flush_0;
wire csr_id_flush_0;
wire csr_ex_flush_0; 
wire csr_mem_flush_0;
wire csr_if_flush_1; 
wire csr_id_flush_1;
wire csr_ex_flush_1; 
wire csr_mem_flush_1;
wire IDEX_preg_misaligned;
wire ctrl_unit_illegal_instr_0; 
wire ctrl_unit_ecall_0; 
wire ctrl_unit_ebreak_0;
wire instr_addr_misaligned_0;
wire [31:0] mepc;
wire [31:0] irq_addr;
wire mux1_ctrl_IF;
wire mux4_ctrl_IF;
//---------------------------------------//

core_0    #(.reset_vector(reset_vector))
    core0(
    //Clock and reset signals.
    .clk_i(clk_i),
    .reset_i(reset_i), //active-low, asynchronous reset

    //Instruction memory interface
    .instr_addr_o(instr_addr_o),
    .instr_i(instr_i),
    
    ////////register bank/////////
    .rf_wen_WB (rf_wen_WB_0),
    .rd_WB (rd_WB_0),
    .mux_o_WB (mux_o_WB_0),
    .take_branch (take_branch_0),
    .csr_id_flush (csr_id_flush_0),
    .stall_EX (stall_EX_0),
    .IDEX_preg_rs1 (IDEX_preg_rs1_0),
    .IDEX_preg_rs2 (IDEX_preg_rs2_0),
    .stall_ID (stall_ID_0),
    .rs1_ID (rs1_ID_0),
    .rs2_ID (rs2_ID_0),
    .IDEX_preg_data1 (IDEX_preg_data_1_out_0),
    .IDEX_preg_data2 (IDEX_preg_data_2_out_0),
    
    //issue unit//
    .issue_stall_0(issue_stall_0),
    // .priority_overwrite(priority_overwrite),
    .stall_IF(stall_IF_0),
    .priority_flag(priority_out_to_core_0),
    .muldiv_stall_EX(muldiv_stall_EX),
    
    // dual hazard
    .priority_out(priority_out_to_dual_hazard_unit),
    .rd_ID(rd_ID_0),
    .funct3_0(funct3_0),
    .opcode_0(opcode_0),
    .dual_hazard_stall_0(dual_hazard_stall_0),
    .dual_hazard_stall_1(dual_hazard_stall_1),
    .rd_EX(rd_EX_0),

    // pc_logic
    .branch_target_addr(branch_target_addr),
    .pc_i(pc_i),
    .pc_o(pc_o),
    .stall_IF_1(stall_IF_1),

    // dual forwarding unit
    .rs1_EX(rs1_EX_0),
    .rs2_EX(rs2_EX_0),
    .rd_MEM(rd_MEM_0),
    // .rd_WB(rd_WB_0), // already connected
    .wb_MEM(wb_MEM_0),
    // .rf_wen_WB(rf_wen_WB_0), // already connected
    .priority_MEM(priority_MEM),
    .priority_WB(priority_WB),
    .aluout_MEM(aluout_MEM_0),
    .aluout_MEM_1(aluout_MEM_1),
    .mux2_ctrl_EX(mux2_ctrl_EX_0),
    .mux4_ctrl_EX(mux4_ctrl_EX_0),
    .mux_o_WB_1(mux_o_WB_1),

    .pc_ID(pc_ID_0),
    .pc_EX(pc_EX_0),
    .pc_MEM(pc_MEM_0),
    .pc_WB(pc_WB_0),

    // csr signals
    .csr_if_flush(csr_if_flush_0), 
    .csr_ex_flush(csr_ex_flush_0), 
    .csr_mem_flush(csr_mem_flush_0),
    .csr_reg_out(csr_reg_out_0),

    .csr_pc_input(csr_pc_input_0),
    .IFID_preg_instr(IFID_preg_instr_0),
    .csr_addr_WB(csr_addr_WB_0),
    .imm_WB(imm_WB_0),
    .csr_wen_WB(csr_wen_WB_0),
    .mret_ID(mret_ID_0), 
    .mret_WB(mret_WB_0),
    .IDEX_preg_dummy(IDEX_preg_dummy_0),
    .EXMEM_preg_dummy(EXMEM_preg_dummy_0),
    .ctrl_unit_illegal_instr(ctrl_unit_illegal_instr_0), 
    .ctrl_unit_ecall(ctrl_unit_ecall_0), 
    .ctrl_unit_ebreak(ctrl_unit_ebreak_0),
    .instr_addr_misaligned(instr_addr_misaligned_0)  
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

    //Instruction memory interface
    //.instr_addr_o(instr_addr_o),
    .instr_i(instr_i_1),
    
    ////////register bank/////////
    .rf_wen_WB (rf_wen_WB_1),
    // .rd_WB (rd_WB_1), // already connected
    .mux_o_WB (mux_o_WB_1),
    .take_branch (take_branch_0),
    .csr_id_flush (csr_id_flush_1),
    .stall_EX (stall_EX_1),
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
    .muldiv_stall_EX(muldiv_stall_EX),
    
    //dual hazard
    .rd_ID(rd_ID_1),
    .funct3_1(funct3_1),
    .opcode_1(opcode_1),
    .L_ID(L_ID),
    .L(L),
    .dual_hazard_stall_1(dual_hazard_stall_1),
    .rd_EX(rd_EX_1),

    // dual forwarding unit
    .rs1_EX(rs1_EX_1),
    .rs2_EX(rs2_EX_1),
    .rd_MEM(rd_MEM_1),
    .rd_WB(rd_WB_1),
    .wb_MEM(wb_MEM_1),
    // .rf_wen_WB(rf_wen_WB_1), // already connected
    .aluout_MEM(aluout_MEM_1),
    .aluout_MEM_0(aluout_MEM_0),
    .mux2_ctrl_EX(mux2_ctrl_EX_1),
    .mux4_ctrl_EX(mux4_ctrl_EX_1),
    .mux_o_WB_0(mux_o_WB_0),

    .pc_ID(pc_ID_1),
    .pc_EX(pc_EX_1),
    .pc_MEM(pc_MEM_1),
    .pc_WB(pc_WB_1),

    .priority_flag(priority_out_to_core_0),

    //
    .pc_i(pc_i_1),

    // csr signals
    .csr_if_flush(csr_if_flush_1), 
    .csr_ex_flush(csr_ex_flush_1), 
    .csr_mem_flush(csr_mem_flush_1),
    
    .IDEX_preg_misaligned(IDEX_preg_misaligned),
    .mem_MEM(mem_wen),
    .IDEX_preg_dummy(IDEX_preg_dummy_1), 
    .EXMEM_preg_dummy(EXMEM_preg_dummy_1),
    .csr_pc_input(csr_pc_input_1)
    );

// assign pc_i_1 = priority_out_to_core_0 ? pc_i : (pc_i + 32'd4);
assign pc_i_1 = pc_i;

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
    .csr_id_flush_0(csr_id_flush_0),
    .csr_id_flush_1(csr_id_flush_1),
    
    .stall_EX_0(stall_EX_0),
    .stall_EX_1(stall_EX_1),
    
    .misaligned_access_1(misaligned_access_1),
    .IDEX_preg_rs1_0(IDEX_preg_rs1_0),
    .IDEX_preg_rs2_0(IDEX_preg_rs2_0),
    
    .IDEX_preg_rs1_1(IDEX_preg_rs1_1),
    .IDEX_preg_rs2_1(IDEX_preg_rs2_1),
    
    .stall_ID_0(stall_ID_0),
    .stall_ID_1(stall_ID_1),
                 
    .rs1_ID_0(rs1_ID_0),
    .rs2_ID_0(rs2_ID_0),
    
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
    .dual_hazard_stall_0(dual_hazard_stall_0),
    .dual_hazard_stall_1(dual_hazard_stall_1),
    .funct3_0(funct3_0),
    .funct3_1(funct3_1),
    .pipe_0_occuppied_w_branch_IF(pipe_0_occuppied_w_branch_IF),
    .issue_stall_0(issue_stall_0),
    .issue_stall_1(issue_stall_1),
    .instr_i(instr_i),
    .instr_i_1(instr_i_1),
    .priority_flag(priority_out_to_core_0),
    .priority_overwrite(priority_overwrite),
    .pc_increment(pc_increment) // goes to pc logic
);

dual_hazard_unit DUAL_HAZARD_UNIT(
    .clk_i(clk_i),
    .reset_i(reset_i),
    .priority_flag(priority_out_to_dual_hazard_unit),
    .rs1_ID_0(rs1_ID_0),
    .rs2_ID_0(rs2_ID_0),
    .rd_ID_0(rd_ID_0),
    .rd_EX_0(rd_EX_0),
    .opcode_0(opcode_0),
    .funct3_0(funct3_0),
    .rs1_ID_1(rs1_ID_1),
    .rs2_ID_1(rs2_ID_1),
    .rd_ID_1(rd_ID_1),
    .rd_EX_1(rd_EX_1),
    .opcode_1(opcode_1),
    .funct3_1(funct3_1),
    .L_ID_1(L_ID),
    .L_EX_1(L),

    .pc_ID_0(pc_ID_0),
    .pc_ID_1(pc_ID_1),
    .pc_EX_0(pc_EX_0),
    .pc_EX_1(pc_EX_1),

    .pipe_0_occuppied_w_branch_IF(pipe_0_occuppied_w_branch_IF),

    .dual_hazard_stall_0(dual_hazard_stall_0),
    .dual_hazard_stall_1(dual_hazard_stall_1)
);

pc_logic PC_LOGIC ( 
    .reset_i(reset_i),
	.take_branch_0(take_branch_0),
	.stall_IF_0(stall_IF_0),
	.stall_IF_1(stall_IF_1),
	.dual_hazard_stall_0(dual_hazard_stall_0),
    .dual_hazard_stall_1(dual_hazard_stall_1),
	.branch_target_addr_0(branch_target_addr),
	.pc_o(pc_o), // comes from core 0
	.pc_increment(pc_increment),
	.pc_i(pc_i), // goes to core 0
    .mepc(mepc), 
    .irq_addr(irq_addr), 
    .mux1_ctrl_IF(mux1_ctrl_IF), 
    .mux4_ctrl_IF(mux4_ctrl_IF)
);

dual_forwarding_unit DUAL_FORWARDING_UNIT (
    // input signals for core_0
    .rs1_0(rs1_EX_0),
    .rs2_0(rs2_EX_0),
    .exmem_rd_0(rd_MEM_0),
    .memwb_rd_0(rd_WB_0),
    .exmem_wb_0(wb_MEM_0[3]), 
    .memwb_wb_0(rf_wen_WB_0),

    // input signals for core_1
    .rs1_1(rs1_EX_1),
    .rs2_1(rs2_EX_1),
    .exmem_rd_1(rd_MEM_1),
    .memwb_rd_1(rd_WB_1),
    .exmem_wb_1(wb_MEM_1[3]), 
    .memwb_wb_1(rf_wen_WB_1),

    .priority_MEM(priority_MEM),
    .priority_WB(priority_WB),

    // output signals for core_0
    .mux1_ctrl_0(mux2_ctrl_EX_0), //control signal for mux2 in EX
    .mux2_ctrl_0(mux4_ctrl_EX_0), //control signal for mux4 in EX

    // output signals for core_1
    .mux1_ctrl_1(mux2_ctrl_EX_1), //control signal for mux2 in EX
    .mux2_ctrl_1(mux4_ctrl_EX_1), //control signal for mux4 in EX

    .pc_MEM_0(pc_MEM_0),
    .pc_MEM_1(pc_MEM_1),
    .pc_WB_0(pc_WB_0),
    .pc_WB_1(pc_WB_1),
    .pc_EX_0(pc_EX_0),
    .pc_EX_1(pc_EX_1)
);

always @*
begin
    // if(csr_pc_input_0 == 32'b0 && csr_pc_input_1 == 32'b0)
    //     csr_pc_input = csr_pc_input;
    if(csr_pc_input_0 == 32'b0)
        csr_pc_input = csr_pc_input_1;
    else if(csr_pc_input_1 == 32'b0)
        csr_pc_input = csr_pc_input_0;        
    else
        csr_pc_input = csr_pc_input_0 < csr_pc_input_1 ? csr_pc_input_0 : csr_pc_input_1;
end

//instantiate CSR Unit
csr_unit CSR_UNIT(
                  // inputs
                  .clk_i(clk_i),
                  .reset_i(reset_i),
                  .pc_i(csr_pc_input),
                  .csr_r_addr_i(IFID_preg_instr_0[31:20]),
                  .csr_w_addr_i(csr_addr_WB_0),
                  .csr_reg_i(imm_WB_0),
                  .csr_wen_i(csr_wen_WB_0),
                  .meip_i(meip_i), // core_wb in
                  .mtip_i(mtip_i), // core_wb in
                  .msip_i(msip_i), // core_wb in
                  .fast_irq_i(fast_irq_i), // core_wb in
                  .take_branch_i(take_branch_0),
                  .mem_wen_i(mem_wen),
                  .ex_dummy_i_0(IDEX_preg_dummy_0),
                  .ex_dummy_i_1(IDEX_preg_dummy_1),
                  .mem_dummy_i_0(EXMEM_preg_dummy_0),
                  .mem_dummy_i_1(EXMEM_preg_dummy_1),
                  .mret_id_i(mret_ID_0),
                  .mret_wb_i(mret_WB_0),
                  .misaligned_ex(IDEX_preg_misaligned),
                  .instr_access_fault_i(instr_access_fault_i), // core_wb_in
                  .illegal_instr_i(ctrl_unit_illegal_instr_0), 
                  .instr_addr_misaligned_i(instr_addr_misaligned_0),
                  .ecall_i(ctrl_unit_ecall_0),
                  .ebreak_i(ctrl_unit_ebreak_0),
                  .data_err_i(data_err_i), // core_wb_in

                  // outputs
                  .csr_reg_o(csr_reg_out_0),
                  .mepc_o(mepc), // to pc_logic
                  .irq_addr_o(irq_addr), // to pc_logic
                  .mux1_ctrl_o(mux1_ctrl_IF), // to pc_logic
                  .mux2_ctrl_o(mux4_ctrl_IF), // to pc_logic
                  .ack_o(irq_ack_o), // core_wb output
                  .csr_if_flush_o_0(csr_if_flush_0),
                  .csr_if_flush_o_1(csr_if_flush_1),
                  .csr_id_flush_o_0(csr_id_flush_0),
                  .csr_id_flush_o_1(csr_id_flush_1),
                  .csr_ex_flush_o_0(csr_ex_flush_0),
                  .csr_ex_flush_o_1(csr_ex_flush_1),
                  .csr_mem_flush_o_0(csr_mem_flush_0),
                  .csr_mem_flush_o_1(csr_mem_flush_1)             
                  );

endmodule
