//`timescale 1ns/1ns
//module top_color_cam_tb ();
//
//// IOs ports of main module
//// System
//logic clk_i;
//logic rst_ni;
//// Test
//logic [1:0] sel_i;
////logic sobel_i;
//logic led_o;
//logic locked;
//// SDRAM
//logic sdram_clk;
//logic sdram_cke;
//logic sdram_cs_n;
//logic sdram_ras_n;
//logic sdram_cas_n;
//logic sdram_we_n;
//logic [12:0] sdram_addr;
//logic [1:0] sdram_bank;
//logic [1:0] sdram_dqm;
//wire [15:0] sdram_dq;
//// VGA
//logic vga_clk;
//logic [7:0] vga_red;
//logic [7:0] vga_green;
//logic [7:0] vga_blue;
//logic vga_hsync;
//logic vga_vsync;
//logic vga_blank_n;
//logic vga_sync_n;
//
//// Output testing
//logic [15:0] vga_fifo_o;
//
//// DUT
//// Main program
//top top_dut
//(
//	// System
//	.clk_i									(clk_i),
//	.rst_ni									(rst_ni),
//	.sel_i									(sel_i),
//	//.sobel_i									(sobel_i),
//	.led_o									(led_o),
//	.locked									(locked),
//	// SDRAM
//	.sdram_clk								(sdram_clk),
//	.sdram_cke								(sdram_cke),
//	.sdram_cs_n								(sdram_cs_n),
//	.sdram_ras_n							(sdram_ras_n),
//	.sdram_cas_n							(sdram_cas_n),
//	.sdram_we_n								(sdram_we_n),
//	.sdram_addr								(sdram_addr),
//	.sdram_bank								(sdram_bank),
//	.sdram_dqm								(sdram_dqm),
//	.sdram_dq								(sdram_dq),
//	// Output testing
//	.vga_fifo_o								(vga_fifo_o),
//	// VGA
//	.vga_clk									(vga_clk),
//	.vga_red									(vga_red),
//	.vga_green								(vga_green),
//	.vga_blue								(vga_blue),
//	.vga_hsync								(vga_hsync),
//	.vga_vsync								(vga_vsync),
//	.vga_blank_n							(vga_blank_n),
//	.vga_sync_n								(vga_sync_n)
//);
//
//IS42S16320F sdram_model
//(
//	.Dq										(sdram_dq),
//	.Addr										(sdram_addr),
//	.Ba										(sdram_bank),
//	.Clk										(sdram_clk),
//	.Cke										(sdram_cke),
//	.Cs_n										(sdram_cs_n),
//	.Ras_n									(sdram_ras_n),
//	.Cas_n									(sdram_cas_n),
//	.We_n										(sdram_we_n),
//	.Dqm										(sdram_dqm)
//);
//
//// Generate the 50MHz clock
//localparam HCLK_50 = 10;
//always #HCLK_50 clk_i = ~clk_i;
//
//initial begin
//	#0 clk_i = 0;
//	rst_ni = 1;
//	sel_i = 2'b00;
//	#100 rst_ni = 0;
//	#100 rst_ni = 1;
//	#57_000_000 sel_i = 2'b01;
//	#32_000_000 sel_i = 2'b10;
//	#32_000_000 sel_i = 2'b11;
//	#32_000_000 $finish;
//end
//
//endmodule: top_color_cam_tb