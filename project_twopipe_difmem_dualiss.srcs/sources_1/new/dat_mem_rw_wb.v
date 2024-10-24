module dat_mem_rw_wb(
input         port1_wb_cyc_i,
input         port1_wb_stb_i,
input         port1_wb_we_i,
input [31:0]  port1_wb_adr_i,
input [31:0]  port1_wb_dat_i,
input [3:0]   port1_wb_sel_i,
output        port1_wb_stall_o,
output        port1_wb_ack_o,
output reg [31:0] port1_wb_dat_o,
output        port1_wb_err_o,
input         port1_wb_rst_i,
input         port1_wb_clk_i);


parameter NUM_WMASKS = 4 ;
parameter DATA_WIDTH = 32 ;
parameter ADDR_WIDTH = 9 ;
parameter RAM_DEPTH = 1 << ADDR_WIDTH;


wire clk1; // clock
wire cs1; // active low chip select
wire we1; // active low write control
wire [NUM_WMASKS-1:0] wmask1; // write mask
wire [ADDR_WIDTH-1:0] addr1;
wire [DATA_WIDTH-1:0] din1;
wire [DATA_WIDTH-1:0] dout1;


assign clk1 = port1_wb_clk_i;
assign cs1 = ~port1_wb_stb_i;
assign we1 = ~port1_wb_we_i;
assign wmask1 = port1_wb_sel_i;
assign addr1 = port1_wb_adr_i[ADDR_WIDTH+1 : 2];
assign din1 = port1_wb_dat_i;
assign port1_wb_stall_o = 1'b0;
reg port1_ack;
always @(posedge port1_wb_clk_i or posedge port1_wb_rst_i)
begin
    if(port1_wb_rst_i)
        port1_ack <= 1'b0;
    else if(port1_wb_cyc_i)
        port1_ack <= port1_wb_stb_i;
end
assign port1_wb_ack_o = port1_ack;
assign port1_wb_err_o = 1'b0;

reg [DATA_WIDTH-1:0] mem [0:RAM_DEPTH-1] /*verilator public*/;

`ifdef FPGA_READMEM
initial $readmemh("reset_handler.mem",mem,7424,7487);
initial $readmemh("bootloader.mem",mem,7488,8191);
`endif 

 // Memory Write Block Port 1
  // Write Operation : When we1 = 0, cs1 = 0
always @ (posedge clk1)
begin
    if ( !cs1 && !we1 ) begin
        if (wmask1[0])
            mem[addr1][7:0] = din1[7:0];
        if (wmask1[1])
            mem[addr1][15:8] = din1[15:8];
        if (wmask1[2])
            mem[addr1][23:16] = din1[23:16];
        if (wmask1[3])
            mem[addr1][31:24] = din1[31:24];
    end
end

  // Memory Read Block Port 1
  // Read Operation : When we1 = 1, cs1 = 0
always @ (posedge clk1)
begin : MEM_READ1
    if (!cs1 && we1)
        port1_wb_dat_o <= mem[addr1];
end

endmodule


