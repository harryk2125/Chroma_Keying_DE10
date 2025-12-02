module camera_interface 
(
	// System
	input logic sys_clk_i,										// Clock 24MHz
	input logic rst_ni,
	output logic led_o,
	output logic frame_error,
	input logic fix_frame_done,
	input logic [16:0] color_addr_i,
	// Camera
		// Capture
	input logic cam_clk,											// Pixel clock
	input logic cam_vsync,										// Vertical sync
	input logic cam_href,										// Horizontal Ref
	input logic [7:0] cam_data_i,								// Data in
	output logic cam_fifo_empty,
		// Controller
	inout siod_io,													// SIOD
	output logic pwdw_o,											// Power down
	output logic sioc_o,											// Data clock out (SCCB)
	output logic reset_o,										// Reset out
	output logic xclk_o,											// Master clock
	// FIFO
	input logic sdram_clk,										// Read clock from SDRAM
	input logic rd_cam_fifo,									// Read camera FIFO 
	output logic [15:0] data_o,								// Output data from FIFO to SDRAM
	output logic [12:0] cam_fifo_data_cnt					// Data read count FIFO to SDRAM
);

// SCCB Interface - Configure the camera parameters
ov7670_controller cam_controller
(
	.clk_24mhz												(sys_clk_i),
	.rst_ni													(rst_ni),
	.siod_io													(siod_io),
	.conf_led_o												(led_o),
	.pwdw_o													(pwdw_o),
	.sioc_o													(sioc_o),
	.reset_o													(reset_o),
	.xclk_o													(xclk_o)
);

logic [15:0] cam_data_o;
logic wr_fifo_cam;

// Capture the camera frames
ov7670_capture frame_cap
(
	.pclk_i													(cam_clk),
	.rst_ni													(rst_ni),
	.fix_frame_done										(fix_frame_done),
	.vsync_i													(cam_vsync),
	.href_i													(cam_href),
	.data_i													(cam_data_i),
	.done_config_i											(led_o),
	.data_o													(cam_data_o),
	.color_addr_i											(color_addr_i),
	.wr_en													(wr_fifo_cam),
	.frame_error											(frame_error)
);

// FIFO: From Camera to SDRAM
async_fifo
#(
	.DATA_WD													(16),
	.DEPTH													(8_192)
)
camera_fifo
(
	// Write section
	.wclk_i													(cam_clk),
	.wrst_ni													(rst_ni),
	.w_en_i													(wr_fifo_cam),
	.data_i													(cam_data_o),
	// Read section
	.rclk_i													(sdram_clk),
	.rrst_ni													(rst_ni),
	.r_en_i													(rd_cam_fifo),
	.data_o													(data_o),
	// FIFO parameter
	.data_cnt_w												(cam_fifo_data_cnt),
	.data_cnt_r												(),
	.full_o													(),
	.empty_o													(cam_fifo_empty)
);

endmodule: camera_interface