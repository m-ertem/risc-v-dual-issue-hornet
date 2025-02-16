module core_1(input reset_i, //active-low reset

    input clk_i,

    input  [31:0] data_i,       //data memory input
    output [3:0]  data_wmask_o, //data memory mask output
    output        data_wen_o,   //data memory write enable output
    output [31:0] data_addr_o,  //data memory address output
    output [31:0] data_o,       //data memory data output
    output        data_req_o,   //data memory access request output. driven high when a store/load is carried out
    input         data_stall_i, //data memory stall input. pipeline is stalled when a memory access request is answered with a stall.

    input  [31:0] instr_i,              //instruction input
    output [31:0] instr_addr_o,         //instruction address output

    ////////register outputs/////////
    output rf_wen_WB,
    output reg [31:0] mux_o_WB,
    output csr_id_flush,
    output stall_EX,
    output stall_ID,
    output [4:0] rd_WB,
    output misaligned_access, //driven high when the first part of a misaligned access is being executed.
    output reg [4:0] IDEX_preg_rs1,
    output reg [4:0] IDEX_preg_rs2,
    output [4:0] rs1_ID,
    output [4:0] rs2_ID,   
    input [31:0] IDEX_preg_data1,
    input [31:0] IDEX_preg_data2,  
    
    input  issue_stall_1,  /*comes from issue unit */ 
    output stall_IF,  /*goes to issue unit*/ 
    input muldiv_stall_EX, 

    // dual hazard unit signals
    input dual_hazard_stall_1,
    output [4:0] opcode_1, 
    output funct3_1,  
    output [4:0] rd_ID,
    output L_ID,
    output L,
    output [4:0] rd_EX,
    
    // pc_logic
    // output reg [31:0] pc_o,
    input [31:0] pc_i,

    // dual forwarding unit
    output [4:0] rs1_EX, rs2_EX,
    output [4:0] rd_MEM,
    // output [4:0] rd_WB, // already declared
    output [6:0] wb_MEM,
    // output       rf_wen_WB, // already declared
    output [31:0]aluout_MEM,
    input [31:0] aluout_MEM_0,
    input [2:0]  mux2_ctrl_EX,
    input [2:0]  mux4_ctrl_EX,    
    input [31:0] mux_o_WB_0,

    output [31:0] pc_ID,
    output [31:0] pc_EX,
    output [31:0] pc_MEM,
    output [31:0] pc_WB,
    input priority_flag,

    // take_branch signal from core_0    
    input        take_branch,

    // csr signals
    input         csr_if_flush,
    input         csr_ex_flush,
    input         csr_mem_flush,
    output reg    IDEX_preg_misaligned, //driven high when the second part of a misaligned access is being executed in EX stage.
    output [2:0]  mem_MEM,
    output reg    IDEX_preg_dummy, //indicates if the instruction in the EX stage is dummy, i.e. a flushed instruction, nop.
    output reg    EXMEM_preg_dummy, //indicates if the instruction in MEM stage is dummy, i.e. a flushed instruction, nop.
    output reg [31:0] csr_pc_input
    ); //interrupt acknowledge signal. driven high for one cycle when an external interrupt is handled.

parameter reset_vector = 32'h0; //pc is set to this address when a reset occurs.

//IF SIGNALS--------IF SIGNALS--------IF SIGNALS--------IF SIGNALS--------IF SIGNALS--------IF SIGNALS--------IF SIGNALS
//mux signals
wire        mux2_ctrl_IF, mux3_ctrl_IF; //mux control signals
wire [31:0] mux1_o_IF, mux2_o_IF, mux3_o_IF, mux4_o_IF; //mux outputs
//PC
//wire [31:0] pc_i; //pc input
reg  [31:0] pc_o; //pc output

//pipeline registers
reg [31:0] IFID_preg_instr;
reg [31:0] IFID_preg_pc;
reg        IFID_preg_dummy; //indicates if the instruction in the ID stage is dummy, i.e. a flushed instruction, nop.
//END IF SIGNALS--------END IF SIGNALS--------END IF SIGNALS--------END IF SIGNALS--------END IF SIGNALS--------END IF SIGNALS

//ID SIGNALS--------ID SIGNALS--------ID SIGNALS--------ID SIGNALS--------ID SIGNALS--------ID SIGNALS--------ID SIGNALS
wire [31:0] data1_ID, data2_ID;
wire [11:0] csr_addr_ID; //CSR register address
wire        csr_wen_ID;
//control unit outputs
wire ctrl_unit_muldiv_start;
wire ctrl_unit_muldiv_sel;

wire [3:0] ctrl_unit_alu_func;
wire [1:0] ctrl_unit_csr_alu_func;
wire       ctrl_unit_ex_mux1, ctrl_unit_ex_mux3, ctrl_unit_ex_mux5, ctrl_unit_ex_mux7, ctrl_unit_ex_mux8;
wire [1:0] ctrl_unit_ex_mux6;
wire       ctrl_unit_B, ctrl_unit_J;
wire [1:0] ctrl_unit_mem_len;
wire       ctrl_unit_mem_wen, ctrl_unit_wb_rf_wen, ctrl_unit_wb_csr_wen;
wire [1:0] ctrl_unit_wb_mux;
wire       ctrl_unit_wb_sign;
//mux signals
wire        mux_ctrl_ID; //control signal for all three muxes
wire [6:0]  mux1_o_ID; //WB field
wire [2:0]  mux2_o_ID; //MEM field
wire [12:0] mux3_o_ID; //EX field

wire [29:0] imm_dec_i; //immediate decoder input
wire [31:0] imm_dec_o; //immediate decoder output
// wire [31:0] pc_ID; //pc value

// dual hazard unit signals
wire [6:0] wb_ID;

//pipeline registers
reg [31:0] IDEX_preg_imm;
reg [4:0]  IDEX_preg_rd;
reg [31:0] IDEX_preg_pc;
reg [12:0] IDEX_preg_ex;
reg [2:0]  IDEX_preg_mem;
reg [6:0]  IDEX_preg_wb;
reg [11:0] IDEX_preg_csr_addr;

//reg [31:0] register_bank [31:0]; //32x32 register file
//END ID SIGNALS--------END ID SIGNALS--------END ID SIGNALS--------END ID SIGNALS--------END ID SIGNALS--------END ID SIGNALS

//EX SIGNALS--------EX SIGNALS--------EX SIGNALS--------EX SIGNALS--------EX SIGNALS--------EX SIGNALS--------EX SIGNALS

//signals from previous stage
wire [6:0]  wb_EX;
wire [2:0]  mem_EX;
wire [12:0] ex_EX;
wire [31:0] data1_EX, data2_EX, imm_EX;
// wire [4:0]  rs1_EX, rs2_EX, rd_EX;
// wire [4:0]  rd_EX;
wire [11:0] csr_addr_EX;
wire        csr_wen_EX;
//mux signals
// wire [1:0]  mux2_ctrl_EX,  mux4_ctrl_EX, mux6_ctrl_EX;
wire [1:0]  mux6_ctrl_EX;
wire        mux1_ctrl_EX, mux3_ctrl_EX, mux5_ctrl_EX, mux7_ctrl_EX, mux8_ctrl_EX;
wire [31:0] mux1_o_EX, mux2_o_EX, mux3_o_EX, mux4_o_EX, mux5_o_EX, mux6_o_EX, mux7_o_EX, mux8_o_EX;
//ALU signals
wire [3:0]  alu_func;
wire [1:0]  csr_alu_func;
wire [31:0] aluout_EX;

wire        mem_wen_EX;
wire [1:0]  mem_length_EX;
wire        instr_addr_misaligned; //driven high when the calculated instruction address is misaligned, which causes an exception.
wire        hazard_stall; //output of the hazard detection unit.

//pipeline registers
reg [31:0] EXMEM_preg_imm;
reg [4:0]  EXMEM_preg_rd;
reg [31:0] EXMEM_preg_data2;
reg [31:0] EXMEM_preg_aluout;
reg [31:0] EXMEM_preg_pc;
reg [11:0] EXMEM_preg_csr_addr;
reg [2:0]  EXMEM_preg_mem;
reg [6:0]  EXMEM_preg_wb;
reg        EXMEM_preg_misaligned; //driven high when the instruction in MEM stage is a misaligned access.
reg [1:0]  EXMEM_preg_addr_bits; //two least-significant bits of data address.
//END EX SIGNALS--------END EX SIGNALS--------END EX SIGNALS--------END EX SIGNALS--------END EX SIGNALS--------END EX SIGNALS

//MEM SIGNALS--------MEM SIGNALS--------MEM SIGNALS--------MEM SIGNALS--------MEM SIGNALS--------MEM SIGNALS--------MEM SIGNALS
//signals from previous stage
// wire [6:0]  wb_MEM;
wire [31:0] data2_MEM;
// wire [4:0]  rd_MEM;
wire [31:0] imm_MEM;
wire [31:0] memout_MEM;
// wire [31:0] pc_MEM;
wire [11:0] csr_addr_MEM;
wire        csr_wen_MEM;
wire [1:0]  addr_bits_MEM; //two least-significant bits of data address, from previous stage.

wire [31:0] memout; //output of load-store unit
//pipeline registers
reg [4:0]  MEMWB_preg_rd;
reg [31:0] MEMWB_preg_memout;
reg [31:0] MEMWB_preg_aluout, MEMWB_preg_imm;
reg [11:0] MEMWB_preg_csr_addr;
reg [6:0]  MEMWB_preg_wb;
reg        MEMWB_preg_misaligned;
reg [31:0] MEMWB_preg_pc;
//END MEM SIGNALS--------END MEM SIGNALS--------END MEM SIGNALS--------END MEM SIGNALS--------END MEM SIGNALS--------END MEM SIGNALS

//WB SIGNALS--------WB SIGNALS--------WB SIGNALS--------WB SIGNALS--------WB SIGNALS--------WB SIGNALS--------WB SIGNALS
//signals from previous stage
wire [6:0]  wb_WB;
wire        load_sign;
wire [1:0]  mem_length_WB;
wire [1:0]  mux_ctrl_WB;
// wire        rf_wen_WB, csr_wen_WB;
wire        csr_wen_WB;
wire [11:0] csr_addr_WB;
wire [31:0] memout_WB, aluout_WB, imm_WB;
//END WB SIGNALS--------END WB SIGNALS--------END WB SIGNALS--------END WB SIGNALS--------END WB SIGNALS--------END WB SIGNALS

//CSR SIGNALS--------CSR SIGNALS--------CSR SIGNALS--------CSR SIGNALS--------CSR SIGNALS--------CSR SIGNALS
wire csr_stall; //stalls IF and ID stages
wire [31:0] csr_pcin_mux1_o, csr_pcin_mux2_o;

//END CSR SIGNALS--------END CSR SIGNALS--------END CSR SIGNALS--------END CSR SIGNALS--------END CSR SIGNALS
assign csr_pcin_mux1_o = csr_ex_flush ? pc_EX : pc_ID;
assign csr_pcin_mux2_o = csr_mem_flush ? pc_MEM : csr_pcin_mux1_o;
assign csr_stall = !csr_wen_ID && 
                  ((csr_addr_ID == csr_addr_EX && !csr_wen_EX) || 
                   (csr_addr_ID == csr_addr_MEM && !csr_wen_MEM) ||
                   (csr_addr_ID == csr_addr_WB && !csr_wen_WB));


assign misaligned_access = 0;

always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
		csr_pc_input <= 32'b0;
	else
		csr_pc_input <= csr_pcin_mux2_o;
end

//IF STAGE---------------------------------------------------------------------------------
assign instr_addr_o = pc_i;

assign stall_IF = hazard_stall | muldiv_stall_EX | misaligned_access | data_stall_i | csr_stall | dual_hazard_stall_1;

always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
	begin
		//reset pc to reset vector.
		pc_o <= reset_vector;
		{IFID_preg_pc, IFID_preg_instr} <= 64'h13; //nop instruction addi x0,x0,0
		IFID_preg_dummy <= 1'b0;
	end

	else if(take_branch | csr_if_flush) //flush IF
	begin
		{IFID_preg_pc, IFID_preg_instr} <= 64'h13;
		pc_o <= pc_i;
		IFID_preg_dummy <= 1'b1;
	end

	else if(issue_stall_1) //flush IF
	begin
		{IFID_preg_pc, IFID_preg_instr} <= 64'h13;
		pc_o <= pc_i;
	end

	else
	begin
        if(!stall_ID)
        begin
            IFID_preg_instr <= instr_i;
            IFID_preg_pc    <= priority_flag ? pc_o : (pc_o + 32'd4);
            IFID_preg_dummy <= 1'b0;
        end
        pc_o <= pc_i;
	end
end
//END IF STAGE-----------------------------------------------------------------------------

//ID STAGE---------------------------------------------------------------------------------
//assign fields
assign rs1_ID      = IFID_preg_instr[19:15];
assign rs2_ID      = IFID_preg_instr[24:20];
assign rd_ID       = IFID_preg_instr[11:7];
assign pc_ID       = IFID_preg_pc;
assign imm_dec_i   = IFID_preg_instr[31:2];
assign csr_addr_ID = IFID_preg_instr[31:20];
//Dual hazard
assign opcode_1    = IFID_preg_instr[6:2];
assign funct3_1    = IFID_preg_instr[14];
assign wb_ID       = (!reset_i || take_branch || csr_id_flush || stall_ID) ? 7'h0c : mux1_o_ID;
assign L_ID        = (!wb_ID[3] && wb_ID[6:5] == 2'b1) ? 1'b1 : 1'b0; //load
//assign nets
assign stall_ID    = hazard_stall | muldiv_stall_EX | misaligned_access | data_stall_i | csr_stall | dual_hazard_stall_1; //TODO: move csr stall below
assign mux_ctrl_ID = hazard_stall | dual_hazard_stall_1;
assign csr_wen_ID  = ctrl_unit_wb_csr_wen;

assign mux1_o_ID   = mux_ctrl_ID ? 7'h0c : {ctrl_unit_wb_mux,
                                             ctrl_unit_wb_sign,
                                             ctrl_unit_wb_rf_wen,
                                             ctrl_unit_wb_csr_wen,
                                             ctrl_unit_mem_len};

assign mux2_o_ID   = mux_ctrl_ID ? 3'b1 : {ctrl_unit_mem_len, ctrl_unit_mem_wen};

assign mux3_o_ID   = mux_ctrl_ID ? 13'b0 : {ctrl_unit_ex_mux8,
                                             ctrl_unit_ex_mux7,
                                             ctrl_unit_ex_mux6,
                                             ctrl_unit_ex_mux5,
                                             ctrl_unit_ex_mux3,
                                             ctrl_unit_ex_mux1,
                                             ctrl_unit_csr_alu_func,
                                             ctrl_unit_alu_func};

control_unit    CTRL_UNIT   (.muldiv_start(ctrl_unit_muldiv_start),
                             .muldiv_sel(ctrl_unit_muldiv_sel),
                             .op_mul(ctrl_unit_op_mul),
                             .op_div(ctrl_unit_op_div),
                             .instr_i(IFID_preg_instr),
                             .ALU_func(ctrl_unit_alu_func),
                             .CSR_ALU_func(ctrl_unit_csr_alu_func),
                             .EX_mux5(ctrl_unit_ex_mux5),
                             .EX_mux6(ctrl_unit_ex_mux6),
                             .EX_mux7(ctrl_unit_ex_mux7),
                             .EX_mux8(ctrl_unit_ex_mux8),
                             .EX_mux1(ctrl_unit_ex_mux1),
                             .EX_mux3(ctrl_unit_ex_mux3),
                             .B(ctrl_unit_B),
                             .J(ctrl_unit_J),
                             .MEM_len(ctrl_unit_mem_len),
                             .MEM_wen(ctrl_unit_mem_wen),
                             .WB_rf_wen(ctrl_unit_wb_rf_wen),
                             .WB_csr_wen(ctrl_unit_wb_csr_wen),
                             .WB_mux(ctrl_unit_wb_mux),
                             .WB_sign(ctrl_unit_wb_sign)
                             );

imm_decoder     IMM_DEC	    (.instr_in(imm_dec_i), .imm_out(imm_dec_o));

//write to register file
/*integer i;
always @(negedge clk_i or negedge reset_i)
begin
	if(!reset_i)
	begin
		for(i=0; i < 32; i = i+1)
			register_bank[i] <= 32'b0; //reset all registers to 0.
	end

	else if(!rf_wen_WB)
		register_bank[rd_WB] <= mux_o_WB;
end */

always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
	begin
		IDEX_preg_wb <= 7'h0c;
		IDEX_preg_mem <= 3'b1;
		IDEX_preg_csr_addr <= 12'b0;
		IDEX_preg_ex <= 13'b0;
		IDEX_preg_pc <= 32'b0;
		{IDEX_preg_rs1, IDEX_preg_rs2, IDEX_preg_rd} <= 15'b0;
		IDEX_preg_imm  <= 32'b0;
		IDEX_preg_dummy <= 1'b0;
		IDEX_preg_misaligned <= 1'b0;
	end

	else if(take_branch || csr_id_flush) //flush the pipe
	begin
		IDEX_preg_wb <= 7'h0c;
		IDEX_preg_mem <= 3'b1;
		IDEX_preg_csr_addr <= 12'b0;
		IDEX_preg_ex <= 13'b0;
		IDEX_preg_pc <= 32'b0;
		{IDEX_preg_rs1, IDEX_preg_rs2, IDEX_preg_rd} <= 15'b0;
		IDEX_preg_imm  <= 32'b0;
		IDEX_preg_dummy <= 1'b1;
		IDEX_preg_misaligned <= 1'b0;
	end

    else if(stall_EX || misaligned_access)
    begin
        
        if(misaligned_access)
            IDEX_preg_misaligned <= 1'b1;
    end

    else
    begin
        if(stall_ID)
        begin
            IDEX_preg_wb <= 7'h0c;
            IDEX_preg_mem <= 3'b1;
            IDEX_preg_misaligned <= 1'b0;
            IDEX_preg_dummy <= 1'b1;
            IDEX_preg_rd <= 5'b0;
        end

        else
        begin
            IDEX_preg_imm <= imm_dec_o;
            IDEX_preg_rd  <= rd_ID;
            IDEX_preg_rs2 <= rs2_ID;
            IDEX_preg_rs1 <= rs1_ID;
            IDEX_preg_pc  <= pc_ID;
            IDEX_preg_ex  <= mux3_o_ID;
            IDEX_preg_mem <= mux2_o_ID;
            IDEX_preg_wb  <= mux1_o_ID;
            IDEX_preg_csr_addr <= csr_addr_ID;
            IDEX_preg_misaligned <= 1'b0;
            IDEX_preg_dummy <= IFID_preg_dummy;
        end
    end
end

//END ID STAGE-----------------------------------------------------------------------------

//EX STAGE---------------------------------------------------------------------------------

hazard_detection_unit HZRD_DET_UNIT (.rs1(rs1_ID),
                                     .rs2(rs2_ID),
                                     .opcode(IFID_preg_instr[6:2]),
                                     .funct3(IFID_preg_instr[14]),
                                     .rd_EX(rd_EX),
                                     .L_EX(L),
                                     .hazard_stall(hazard_stall));
//assign fields
assign wb_EX    = IDEX_preg_wb;
assign mem_EX   = IDEX_preg_mem;
assign ex_EX    = IDEX_preg_ex;
assign pc_EX    = IDEX_preg_pc;
assign data1_EX = IDEX_preg_data1;
assign data2_EX = IDEX_preg_data2;
assign rs1_EX   = IDEX_preg_rs1;
assign rs2_EX   = IDEX_preg_rs2;
assign rd_EX    = IDEX_preg_rd;
assign imm_EX   = IDEX_preg_imm;
assign csr_addr_EX = IDEX_preg_csr_addr;
//assign nets
assign alu_func     = ex_EX[3:0];
assign csr_alu_func = ex_EX[5:4];
assign mux1_ctrl_EX = ex_EX[6];
assign mux3_ctrl_EX = ex_EX[7];
assign mux5_ctrl_EX = ex_EX[8];
assign mux6_ctrl_EX = ex_EX[10:9];
assign mux7_ctrl_EX = ex_EX[11];
assign mux8_ctrl_EX = ex_EX[12];
assign L            = (!wb_EX[3] && wb_EX[6:5] == 2'b1) ? 1'b1 : 1'b0; //load
assign mem_wen_EX   = muldiv_stall_EX ? 1'b1 : (csr_ex_flush ? 1'b1 : mem_EX[0]);
assign mem_length_EX = mem_EX[2:1];
assign csr_wen_EX = wb_EX[2];

//muxes
assign mux1_o_EX = mux1_ctrl_EX ? pc_EX : mux2_o_EX;

assign mux2_o_EX = mux2_ctrl_EX == 3'b100 ? aluout_MEM_0
                 : mux2_ctrl_EX == 3'b011 ? mux_o_WB_0
                 : mux2_ctrl_EX == 3'b010 ? aluout_MEM
                 : mux2_ctrl_EX == 3'b001 ? mux_o_WB
                 : data1_EX;

assign mux3_o_EX =  mux3_ctrl_EX ? imm_EX : mux4_o_EX;

assign mux4_o_EX = mux4_ctrl_EX == 3'b100 ? aluout_MEM_0
                 : mux4_ctrl_EX == 3'b011 ? mux_o_WB_0
                 : mux4_ctrl_EX == 3'b010 ? data2_EX
                 : mux4_ctrl_EX == 3'b001 ? mux_o_WB
                 : aluout_MEM;

assign mux5_o_EX = mux5_ctrl_EX ? pc_EX	 : mux2_o_EX;
assign mux6_o_EX = aluout_EX;
assign mux7_o_EX = imm_EX;

assign mux8_o_EX = mux8_ctrl_EX ? imm_EX : mux2_o_EX;

// //instantiate the forwarding unit.
// forwarding_unit FWD_UNIT(.rs1(rs1_EX),
//                          .rs2(rs2_EX),
//                          .exmem_rd(rd_MEM),
//                          .memwb_rd(rd_WB),
//                          .exmem_wb(wb_MEM[3]),
//                          .memwb_wb(rf_wen_WB),
//                          .mux1_ctrl(mux2_ctrl_EX),
//                          .mux2_ctrl(mux4_ctrl_EX));

//instantiate the ALU
ALU ALU (.src1(mux1_o_EX), 
         .src2(mux3_o_EX), 
         .func(alu_func), 
         .alu_out(aluout_EX));

assign stall_EX = muldiv_stall_EX | data_stall_i;

always @(posedge clk_i or negedge reset_i) //clock the outputs to the pipeline register
begin
	if(!reset_i)
	begin
		EXMEM_preg_wb <= 7'h0c;
		EXMEM_preg_mem <= 3'b1;
		EXMEM_preg_csr_addr <= 12'b0;
		{EXMEM_preg_pc, EXMEM_preg_aluout, EXMEM_preg_data2} <= 96'b0;
		EXMEM_preg_rd <= 5'b0;
		EXMEM_preg_imm <= 32'b0;
		EXMEM_preg_dummy <= 1'b0;
		EXMEM_preg_misaligned <= 1'b0;
		EXMEM_preg_addr_bits <= 2'b0;
	end

	else if(stall_EX || csr_ex_flush)
	begin
	   EXMEM_preg_wb <= 7'h0c;
	   EXMEM_preg_mem <= 3'b1;
	   EXMEM_preg_csr_addr <= 12'b0;
	   {EXMEM_preg_pc, EXMEM_preg_aluout, EXMEM_preg_data2} <= 96'b0;
	   EXMEM_preg_rd <= 5'b0;
	   EXMEM_preg_imm <= 32'b0;
	   EXMEM_preg_dummy <= 1'b1;
	   EXMEM_preg_misaligned <= 1'b0;
	   EXMEM_preg_addr_bits <= 2'b0;
	end

	else
	begin
		EXMEM_preg_imm <= mux7_o_EX;
		EXMEM_preg_rd <= rd_EX;
		EXMEM_preg_pc <= pc_EX;
		EXMEM_preg_data2 <= mux4_o_EX;
		EXMEM_preg_aluout <= mux6_o_EX;
		EXMEM_preg_mem <= {mem_EX[2:1],mem_wen_EX};
		EXMEM_preg_wb[6:4] <= wb_EX[6:4];
		EXMEM_preg_wb[3] <= misaligned_access ? 1'b1 : wb_EX[3];
		EXMEM_preg_wb[2:0] <= wb_EX[2:0];
		EXMEM_preg_csr_addr <= csr_addr_EX;
		EXMEM_preg_dummy <= IDEX_preg_dummy;
		EXMEM_preg_misaligned <= IDEX_preg_misaligned;
		EXMEM_preg_addr_bits <= aluout_EX[1:0];
	end
end

//END EX STAGE-----------------------------------------------------------------------------

load_store_unit LS_UNIT (.clk_i(clk_i),
                         .reset_i(reset_i),
                         .addr_i(aluout_EX),
                         .data_i(mux4_o_EX),
                         .length_EX_i(mem_length_EX),
                         .load_i(L),
                         .wen_i(mem_wen_EX),
                         .misaligned_EX_i(IDEX_preg_misaligned),
                         .misaligned_MEM_i(EXMEM_preg_misaligned),
                         .read_data_i(data_i),
                         .length_MEM_i(mem_MEM[2:1]),
                         .addr_offset_i(EXMEM_preg_addr_bits),
                         .memout_WB_i(memout_WB[23:0]),
                         .data_o(data_o),
                         .addr_o(data_addr_o),
                         .wmask_o(data_wmask_o),
                         /*.misaligned_access_o(misaligned_access),*/
                         .memout_o(memout));

assign data_req_o = L | ~mem_wen_EX; //driven high if there's a load or a store.
assign data_wen_o  = mem_wen_EX;
//MEM STAGE---------------------------------------------------------------------------------
assign wb_MEM 	    = EXMEM_preg_wb;
assign mem_MEM 	    = EXMEM_preg_mem;
assign aluout_MEM   = EXMEM_preg_aluout;
assign data2_MEM    = EXMEM_preg_data2;
assign rd_MEM 	    = EXMEM_preg_rd;
assign pc_MEM       = EXMEM_preg_pc;
assign imm_MEM 	    = EXMEM_preg_imm;
assign csr_addr_MEM = EXMEM_preg_csr_addr;
assign addr_bits_MEM = EXMEM_preg_addr_bits;
assign csr_wen_MEM = wb_MEM[2];

always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
	begin
		MEMWB_preg_wb <= 7'h0c;
		MEMWB_preg_csr_addr <= 12'b0;
		MEMWB_preg_rd <= 5'b0;
		MEMWB_preg_memout <= 32'b0;
		MEMWB_preg_aluout <= 32'b0;
		MEMWB_preg_imm <= 32'b0;
		MEMWB_preg_misaligned <= 1'b0;
        MEMWB_preg_pc <= 32'b0;
	end

	else if(csr_mem_flush)
	begin
		MEMWB_preg_wb <= 7'h0c;
		MEMWB_preg_csr_addr <= 12'b0;
		MEMWB_preg_rd <= 5'b0;
		MEMWB_preg_memout <= 32'b0;
		MEMWB_preg_aluout <= 32'b0;
		MEMWB_preg_imm <= 32'b0;
		MEMWB_preg_misaligned <= 1'b0;
        MEMWB_preg_pc <= 32'b0;
	end

	else
	begin
		MEMWB_preg_wb <= wb_MEM;
		MEMWB_preg_rd <= rd_MEM;
		MEMWB_preg_csr_addr <= csr_addr_MEM;
		MEMWB_preg_imm <= imm_MEM;
		MEMWB_preg_aluout <= aluout_MEM;
		MEMWB_preg_memout <= memout;
		MEMWB_preg_misaligned <= EXMEM_preg_misaligned;
        MEMWB_preg_pc <= pc_MEM;
	end
end
//END MEM STAGE-----------------------------------------------------------------------------

//WB STAGE---------------------------------------------------------------------------------
//assign fields
assign wb_WB 	   = MEMWB_preg_wb;
assign memout_WB   = MEMWB_preg_memout;
assign rd_WB 	   = MEMWB_preg_rd;
assign csr_addr_WB = MEMWB_preg_csr_addr;
assign imm_WB      = MEMWB_preg_imm;
assign aluout_WB   = MEMWB_preg_aluout;
assign pc_WB       = MEMWB_preg_pc;
//assign nets
assign mem_length_WB = wb_WB[1:0];
assign csr_wen_WB  = wb_WB[2];
assign rf_wen_WB   = wb_WB[3];
assign load_sign   = wb_WB[4];
assign mux_ctrl_WB = wb_WB[6:5];

//WB mux
always @(*)
begin
	if(mux_ctrl_WB == 2'b0)
		mux_o_WB = aluout_WB;

	else if(mux_ctrl_WB == 2'b1) //load instruction
	begin
		if(mem_length_WB == 2'b0)
		begin
			if(load_sign == 1'b1) //signed load, perform sign extension
				mux_o_WB = { {24{memout_WB[7]}}, memout_WB[7:0] };
			else
				mux_o_WB = { 24'b0, memout_WB[7:0] };
		end
		else if(mem_length_WB == 2'b1)
		begin
			if(load_sign == 1'b1) //signed load, perform sign extension
				mux_o_WB = { {16{memout_WB[15]}}, memout_WB[15:0] };
			else
				mux_o_WB = { 16'b0, memout_WB[15:0] };
		end
		else
			mux_o_WB = { memout_WB };
		end

	else
		mux_o_WB = imm_WB;
end

//END WB STAGE-----------------------------------------------------------------------------
endmodule