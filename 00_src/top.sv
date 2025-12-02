module top 
(
	// System
	input logic clk_i,										// Clock50MHz
	input logic rst_ni,										// Negative reset - SW[0]
	input logic back_i,										// Load background image - SW[1]
	input logic sobel_i,										// 0 => Normal | 1 => Sobel - SW[2]
	input logic chroma_i,									// Enable Chroma Keying - SW[3]
	input logic [1:0] sel_i,
	output logic led_o,										// Led out - Confirm done configuration (SCCB)
	output logic done_uart,									// Finish loading the background image
	output logic locked,										// PLL Locked
	// Camera
	input logic cam_pclk,									// Camera pixel clock
	input logic cam_vsync,									// Camera VSYCN
	input logic cam_href,									// Camera HREF
	input logic [7:0] cam_data,							// Camera data
	inout cam_siod,											// Camera SIOD
	output logic cam_pwdw,									// Camera power down
	output logic cam_sioc,									// Camera SIOC
	output logic cam_reset,									// Camera reset
	output logic cam_xclk,									// Camera master clock
	// SDRAM
	output logic sdram_clk,									// SDRAM clock
	output logic sdram_cke,									// SDRAM clock enable
	output logic sdram_cs_n,								// SDRAM CS_n
	output logic sdram_ras_n,								// SDRAM RAS_n
	output logic sdram_cas_n,								// SDRAM CAS_n
	output logic sdram_we_n,								// SDRAM WE_n
	output logic [12:0] sdram_addr,						// SDRAM address
	output logic [1:0] sdram_bank,						// SDRAM bank
	output logic [1:0] sdram_dqm,							// SDRAM DQM
	inout [15:0] sdram_dq,									// SDRAM DQ
	// Test (output testing from VGA FIFO)
	output logic [15:0] data_i,							// VGA Output
	output logic first_frame,								
	// VGA
	output logic vga_clk,									// VGA Clock
	output logic [7:0] vga_red,							// VGA Red
	output logic [7:0] vga_green,							// VGA Green
	output logic [7:0] vga_blue,							// VGA Blue
	output logic vga_hsync,									// VGA HSync
	output logic vga_vsync,									// VGA VSync	
	output logic vga_blank_n,								// VGA Blank_n
	output logic vga_sync_n									// VGA Sync_n
);

logic sd_clk;
logic clk_cam;
//logic locked;
logic clk_vga;
logic clk_sampl;

// Test
//logic cam_pclk;
//logic cam_vsync;
//logic cam_href;
//logic [7:0] cam_data;
//wire cam_siod;
//logic cam_sioc;
//logic cam_pwdw;
//logic cam_reset;
//logic cam_xclk;

// Clock
logic clk_24, clk_25, clk_133, clk_150;
assign clk_24 = clk_cam & locked;
assign clk_25 = clk_vga & locked;
// Clk_133 
assign clk_133 = sd_clk & locked;						
assign clk_150 = clk_sampl & locked;

// PLL
pll pll_inst
(
	.refclk														(clk_i),
	.rst															(0),
	.outclk_0													(sd_clk),
	.outclk_1													(clk_vga),
	.outclk_2													(clk_cam),
	.outclk_3													(clk_sampl),
	.locked 														(locked)
);

wire sys_reset_n = rst_ni & locked;

//color_cam color_cam_synt 
//(
//	.clk_i														(cam_xclk),
//	.rst_ni														(sys_reset_n),
//	.sel_i														(sel_i),
//	.cam_done_config											(led_o),
//	.pwdw															(cam_pwdw),
//	.cam_rst														(cam_reset),
//	.sioc															(cam_sioc),
//	.siod															(cam_siod),
//	.cam_pclk													(cam_pclk),
//	.href															(cam_href),
//	.vsync														(cam_vsync),
//	.cam_data_o													(cam_data)
//);

logic rd_cam_fifo;
logic [15:0] cam_data_fifo;
logic [12:0] cam_fifo_data_cnt;
logic frame_error;
logic fix_frame_done;
logic cam_fifo_empty;
logic [16:0] color_addr;

// Clock 25 MHz
camera_interface camera_interface_synt
(
	.sys_clk_i													(clk_24),		// Clock 25MHz
	.rst_ni														(sys_reset_n),
	.led_o														(led_o),
	.frame_error												(frame_error),
	.fix_frame_done											(fix_frame_done),
	.color_addr_i												(color_addr),
	.cam_clk														(cam_pclk),		// PIXEL CLOCK: 25MHz (Simulate), cam_pclk
	.cam_vsync													(cam_vsync),
	.cam_href													(cam_href),
	.cam_data_i													(cam_data),
	.cam_fifo_empty											(cam_fifo_empty),
	.siod_io														(cam_siod),
	.pwdw_o														(cam_pwdw),
	.sioc_o														(cam_sioc),
	.reset_o														(cam_reset),
	.xclk_o														(cam_xclk),		// Clock 25MHz
	.sdram_clk													(clk_133),		// Clock 100MHz
	.rd_cam_fifo												(rd_cam_fifo),
	.data_o														(cam_data_fifo),
	.cam_fifo_data_cnt										(cam_fifo_data_cnt)
);

logic rd_back_fifo;
logic [15:0] back_fifo_o;
logic [11:0] data_cnt_back_fifo;

uart_interface uart_interface_synt
(
	.clk_i														(clk_25),
	.rst_ni														(sys_reset_n),
	.back_i														(back_i),
	.done_uart													(done_uart),
	.sdram_clk													(clk_133),
	.rd_back_fifo												(rd_back_fifo),
	.empty_back_fifo											(),
	.back_fifo_o												(back_fifo_o),
	.data_cnt_back_fifo										(data_cnt_back_fifo)
);

logic sdram_fifo_empty;
logic rd_vga_fifo;
//logic [15:0] vga_fifo_o;
//logic first_frame;
logic [15:0] fore_vga_o, back_vga_o;
logic [19:0] chroma_final_addr;
logic vga_frame_id;
logic rd_ram;
logic mask_final;
logic [16:0] vga_addr;
logic vga_fix_flag;
logic vga_error;
logic vga_fix_id;

// Clock 100-166MHz
sdram_interface sdram_interface_synt
(
	.sd_clk														(clk_133),		// Clock 143MHz
	.rst_ni														(sys_reset_n),
	.sobel_i														(sobel_i),
	.back_i														(back_i),
	.chroma_i													(chroma_i),
	.first_frame												(first_frame),
	.frame_error												(frame_error),
	.fix_frame_done											(fix_frame_done),
	// Back FIFO
	.data_cnt_back_fifo										(data_cnt_back_fifo),
	.back_fifo_i												(back_fifo_o),
	.rd_back_fifo												(rd_back_fifo),
	.done_uart													(done_uart),
	// Cam FIFO
	.data_cnt_cam_fifo										(cam_fifo_data_cnt),
	.cam_fifo_i													(cam_data_fifo),
	.cam_fifo_empty											(cam_fifo_empty),
	.rd_cam_fifo												(rd_cam_fifo),
	// VGA FIFO
	.vga_clk														(clk_25),		// Clock 25MHz
	.rd_vga_fifo												(rd_vga_fifo),
	.vga_fifo_empty											(sdram_fifo_empty),
	.fore_vga_o													(fore_vga_o),
	.back_vga_o													(back_vga_o),
	// RAM Chroma Final
	.chroma_final_addr										(chroma_final_addr),
	.rd_ram														(rd_ram),
	.vga_frame_id												(vga_frame_id),
	.mask_final													(mask_final),
	// VGA
	.color_addr													(color_addr),
	.vga_addr													(vga_addr),
	.vga_fix_flag												(vga_fix_flag),
	.vga_error													(vga_error),
	.vga_fix_id													(vga_fix_id),
	// SDRAM ports
	.sdram_clk													(sdram_clk),	// Clock 100MHz - delay 1/2 cycle
	.sdram_cke													(sdram_cke),
	.sdram_cs_n													(sdram_cs_n),
	.sdram_ras_n												(sdram_ras_n),
	.sdram_cas_n												(sdram_cas_n),
	.sdram_we_n													(sdram_we_n),
	.sdram_addr													(sdram_addr),
	.sdram_bank													(sdram_bank),
	.sdram_dqm													(sdram_dqm),
	.sdram_dq													(sdram_dq)
);

// Clock 25MHz
vga_interface vga_interface_synt
(
	.clk_i														(clk_25),				// Clock 25
	.rst_ni														(sys_reset_n),
	.sobel_i														(sobel_i),
	.chroma_i													(chroma_i),
	.sdram_fifo_empty											(sdram_fifo_empty),
	.fore_vga_i													(fore_vga_o),
	.back_vga_i													(back_vga_o),
	.vga_clk														(vga_clk),
	.rd_en														(rd_vga_fifo),
	.vga_addr													(vga_addr),
	.vga_fix_id													(vga_fix_id),
	.vga_error													(vga_error),
	.vga_fix_flag												(vga_fix_flag),
	.vga_frame_id												(vga_frame_id),
	.rd_ram														(rd_ram),
	.chroma_final_addr										(chroma_final_addr),
	.final_mask													(mask_final),
	.data_i														(data_i),
	.vga_red														(vga_red),
	.vga_green													(vga_green),
	.vga_blue													(vga_blue),
	.vga_hsync													(vga_hsync),
	.vga_vsync													(vga_vsync),
	.blank_n														(vga_blank_n),
	.sync_n														(vga_sync_n)
);

reg [7:0] dummy_counter;
always @(posedge clk_150) begin
    dummy_counter <= dummy_counter + 1;
end

endmodule: top