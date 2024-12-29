module pc_logic(
	input reset_i,
	// from core
	input take_branch_0,
	input stall_IF_0,
	input stall_IF_1,
	input dual_hazard_stall_0,
	input dual_hazard_stall_1,
	input [31:0] branch_target_addr_0,
	input [31:0] pc_o, // comes from core 0

	// from issue unit, determines increment amount of pc
	input [31:0] pc_increment,

	// output to the core
	output [31:0] pc_i, // goes to core 0

	// input from csr
	input [31:0] mepc,
    input [31:0] irq_addr,
    input mux1_ctrl_IF,
    input mux4_ctrl_IF
);

parameter reset_vector = 32'h0; //pc is set to this address when a reset occurs.

wire [31:0] pc_ID; //pc value
wire mux2_ctrl_IF, mux3_ctrl_IF; // mux control signals
wire [31:0] mux1_o_IF, mux2_o_IF, mux3_o_IF, mux4_o_IF;

assign mux2_ctrl_IF = 1'b0; // stall_IF_0 || stall_IF_1 || dual_hazard_stall;
assign mux3_ctrl_IF = take_branch_0;

assign mux1_o_IF = mux1_ctrl_IF ? mepc : irq_addr;
assign mux2_o_IF = mux2_ctrl_IF ? pc_o : pc_o + pc_increment; //this mux is responsible for stalling the IF stage.
assign mux3_o_IF = mux3_ctrl_IF ? branch_target_addr_0 : mux2_o_IF; //branch mux
// assign mux4_o_IF = mux3_o_IF; // csr cannot work in here
assign mux4_o_IF = mux4_ctrl_IF ? mux3_o_IF : mux1_o_IF;

assign pc_i = reset_i ? mux4_o_IF : reset_vector;

endmodule