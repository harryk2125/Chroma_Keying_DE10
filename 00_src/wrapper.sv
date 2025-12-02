module wrapper 
(
	// System
	input logic CLOCK_50,
	input logic [5:0] SW,
	output logic [2:0] LEDR,
	// Camera
	inout [25:10] GPIO,
//	input logic cam_pclk,									// Camera pixel clock			B20
//	input logic cam_vsync,									// Camera VSYCN					B22
//	input logic cam_href,									// Camera HREF						B23
//	input logic [7:0] cam_data,							// Camera data						B19 - B12
//	inout cam_siod,											// Camera SIOD						B25
//	output logic cam_pwdw,									// Camera power down				B11
//	output logic cam_sioc,									// Camera SIOC						B24
//	output logic cam_reset,									// Camera reset					B10
//	output logic cam_xclk,									// Camera master clock			B21
	// SDRAM
	output logic DRAM_CLK,									// SDRAM clock
	output logic DRAM_CKE,									// SDRAM clock enable
	output logic DRAM_CS_N,									// SDRAM CS_n
	output logic DRAM_RAS_N,								// SDRAM RAS_n
	output logic DRAM_CAS_N,								// SDRAM CAS_n
	output logic DRAM_WE_N,									// SDRAM WE_n
	output logic [12:0] DRAM_ADDR,						// SDRAM address
	output logic [1:0] DRAM_BA,							// SDRAM bank
	output logic DRAM_LDQM,									// SDRAM DQM 0
	output logic DRAM_UDQM,									// SDRAM DQM 1
	inout [15:0] DRAM_DQ,									// SDRAM DQ
	// VGA
	output logic VGA_CLK,									// VGA Clock
	output logic [7:0] VGA_R,								// VGA Red
	output logic [7:0] VGA_G,								// VGA Green
	output logic [7:0] VGA_B,								// VGA Blue
	output logic VGA_HS,										// VGA HSync
	output logic VGA_VS,										// VGA VSync	
	output logic VGA_BLANK_N,								// VGA Blank_n
	output logic VGA_SYNC_N									// VGA Sync_n
);

logic [7:0] data_cam;
assign data_cam = {GPIO[18], GPIO[19], GPIO[16], GPIO[17], GPIO[14], GPIO[15], GPIO[12], GPIO[13]};

//assign data_cam = GPIO[19:12];

top top_synt
(
	// System
	.clk_i									(CLOCK_50),
	.rst_ni									(SW[0]),
	.back_i									(SW[1]),
	.sobel_i									(SW[2]),
	.chroma_i								(SW[3]),
	.sel_i									(SW[5:4]),
	.led_o									(LEDR[0]),
	.locked									(LEDR[1]),
	.done_uart								(LEDR[2]),
	// Camera
	.cam_pclk								(GPIO[20]),
	.cam_vsync								(GPIO[22]),
	.cam_href								(GPIO[23]),
	.cam_data								(data_cam),
	.cam_siod								(GPIO[25]),
	.cam_pwdw								(GPIO[11]),
	.cam_sioc								(GPIO[24]),
	.cam_reset								(GPIO[10]),
	.cam_xclk								(GPIO[21]),
	// SDRAM
	.sdram_clk								(DRAM_CLK),
	.sdram_cke								(DRAM_CKE),
	.sdram_cs_n								(DRAM_CS_N),
	.sdram_ras_n							(DRAM_RAS_N),
	.sdram_cas_n							(DRAM_CAS_N),
	.sdram_we_n								(DRAM_WE_N),
	.sdram_addr								(DRAM_ADDR[12:0]),
	.sdram_bank								(DRAM_BA[1:0]),
	.sdram_dqm								({DRAM_UDQM, DRAM_LDQM}),
	.sdram_dq								(DRAM_DQ[15:0]),
	// VGA
	.vga_clk									(VGA_CLK),
	.vga_red									(VGA_R),
	.vga_green								(VGA_G),
	.vga_blue								(VGA_B),
	.vga_hsync								(VGA_HS),
	.vga_vsync								(VGA_VS),
	.vga_blank_n							(VGA_BLANK_N),
	.vga_sync_n								(VGA_SYNC_N)
);

endmodule: wrapper