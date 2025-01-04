`timescale 1ns/1ps

module barebones_top_tb();

reg reset_i, clk_i;
wire irq_ack_o;
reg meip_i;
reg [15:0] fast_irq_i;

barebones_wb_top uut(.reset_i(reset_i), .clk_i(clk_i), .meip_i(meip_i), .fast_irq_i(fast_irq_i), .irq_ack_o(irq_ack_o));

//100 MHz clock
always begin
clk_i = 1'b0; #5; clk_i = 1'b1; #5;
end

initial begin
//uncomment the program you want to simulate
//remove the " ../../test/memory_contents/ " parts if you are using Vivado.
//$readmemh("../../test/memory_contents/bubble_sort_irq.data",uut.memory.mem);
//$readmemh("../../test/memory_contents/bubble_sort.data",uut.memory.mem);
//$readmemh("C:/Users/ayseertem/Desktop/Mustifa/Dual Hornet/my_tests/basic_arithmetic/basic_arithmetic.data",uut.inst_memory.mem);
//$readmemh("C:/Users/ayseertem/Desktop/Mustifa/Dual Hornet/my_tests/basic_arithmetic/basic_arithmetic.data",uut.dat_memory.mem);
//$readmemh("C:/Users/ayseertem/Desktop/Mustifa/Dual Hornet/RISC-V-main/test/bubble_sort_irq/bubble_sort_irq.data",uut.inst_memory.mem);
//$readmemh("C:/Users/ayseertem/Desktop/Mustifa/Dual Hornet/RISC-V-main/test/bubble_sort_irq/bubble_sort_irq.data",uut.dat_memory.mem);
//$readmemh("C:/Users/ayseertem/Desktop/Mustifa/Dual Hornet/RISC-V-main/test/soft_float/soft_float.data",uut.inst_memory.mem);
//$readmemh("C:/Users/ayseertem/Desktop/Mustifa/Dual Hornet/RISC-V-main/test/soft_float/soft_float.data",uut.dat_memory.mem);
$readmemh("C:/Users/ayseertem/Desktop/Mustifa/Dual Hornet/RISC-V-main/test/bubble_sort/bubble_sort_rv32i_zicsr.data",uut.inst_memory.mem);
$readmemh("C:/Users/ayseertem/Desktop/Mustifa/Dual Hornet/RISC-V-main/test/bubble_sort/bubble_sort_rv32i_zicsr.data",uut.dat_memory.mem);
//$readmemh("C:/Users/ayseertem/Desktop/Mustifa/Dual Hornet/RISC-V-main/test/aes/aes_test.data",uut.inst_memory.mem);
//$readmemh("C:/Users/ayseertem/Desktop/Mustifa/Dual Hornet/RISC-V-main/test/aes/aes_test.data",uut.dat_memory.mem);
//$readmemh("C:/Users/ayseertem/Desktop/Mustifa/Dual Hornet/RISC-V-main/test/muldiv/muldiv.data",uut.inst_memory.mem);
//$readmemh("C:/Users/ayseertem/Desktop/Mustifa/Dual Hornet/RISC-V-main/test/muldiv/muldiv.data",uut.dat_memory.mem);
//$readmemh("../../test/memory_contents/soft_float.data",uut.memory.mem);
//$readmemh("C:/Users/ayseertem/Desktop/Mustifa/Dual Hornet/RISC-V-main/test/direct_mode/direct_mode.data",uut.inst_memory.mem);
//$readmemh("C:/Users/ayseertem/Desktop/Mustifa/Dual Hornet/RISC-V-main/test/direct_mode/direct_mode.data",uut.dat_memory.mem);

reset_i = 1'b0; fast_irq_i = 16'b0; meip_i = 1'b0;
#10;
reset_i = 1'b1;
#300;
//interrupt signals, arbitrarily generated. uncomment if you need to.
/*
#2100; meip_i=1'b1; 
#400;  meip_i=1'b1;
#400;  meip_i=1'b1; 
#400;  meip_i=1'b1;
#850;  meip_i=1'b1;
#316;  meip_i=1'b1;
#763;  meip_i=1'b1;
#152;  meip_i=1'b1;
#761;  meip_i=1'b1;
#252;  meip_i=1'b1;*/
end

//this always block imitates an interrupt controller. uncomment if you are using machine external interrupt.
/*
always @(posedge clk_i)
begin
	if(irq_ack_o)
		meip_i = 1'b0;
end*/

endmodule

