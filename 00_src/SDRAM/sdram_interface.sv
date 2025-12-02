module sdram_interface 
#(
	parameter IDATA_WD = 16,
	parameter ODATA_WD = 8
)
(
	// System
	input logic sd_clk,
	input logic rst_ni,
	input logic back_i,
	input logic sobel_i,									// 0: Normal - 1 Sobel
	input logic chroma_i,
	output logic first_frame,							// First frame flag => enable VGA
	input logic frame_error,							// Frame error (from capture)
	output logic fix_frame_done,						// Done fixing error (camera)
	// Back FIFO
	input logic done_uart,
	input logic [11:0] data_cnt_back_fifo,
	input logic [IDATA_WD-1:0] back_fifo_i,
	output logic rd_back_fifo,
	// Camera FIFO
	input logic [12:0] data_cnt_cam_fifo,			// Data counter of camera FIFO
	input logic [IDATA_WD-1:0] cam_fifo_i,			// Data of cam FIFO
	input logic cam_fifo_empty,						// Camera empty
	output logic rd_cam_fifo,							// Write cam FIFO enable
	// VGA FIFO
	input logic vga_clk,									// Clock of VGA
	input logic rd_vga_fifo,							// Read VGA FIFO enable
	output logic vga_fifo_empty,
	// Foreground FIFO
	output logic [IDATA_WD-1:0] fore_vga_o,		// VGA FIFO data out
	// Background FIFO
	output logic [IDATA_WD-1:0] back_vga_o,		// VGA FIFO data out
	// RAM Chroma Final
	input logic [19:0] chroma_final_addr,			// RAM Chroma final addr
	input logic rd_ram,
 	output logic vga_frame_id,							// Choosing approriate back RAM
	output logic mask_final,
	// VGA
	output logic [16:0] color_addr,
	output logic [16:0] vga_addr,
	output logic vga_fix_flag,
	input logic vga_error,
	input logic vga_fix_id,
	// Controller of SDRAM
	output logic sdram_clk,								// SDRAM Clock
	output logic sdram_cke,								// Clock enable
	output logic sdram_cs_n,
	output logic sdram_ras_n,
	output logic sdram_cas_n,
	output logic sdram_we_n,
	output logic [12:0] sdram_addr,
	output logic [1:0] sdram_bank,
	output logic [1:0] sdram_dqm,
	inout [IDATA_WD-1:0] sdram_dq
);

// Variable
logic ready;
logic rw, rw_en;
logic fpga_data_valid, sd_data_valid;
logic [IDATA_WD-1:0] sd_data_i, sd_data_o;
logic rd_sobel_fifo;
logic [11:0] data_cnt_sobel_fifo, data_cnt_vga_fifo;
logic [12:0] data_cnt_cam_o;
logic [11:0] data_cnt_back_o, data_cnt_vga_o;
logic [ODATA_WD-1:0] sobel_o;
// Structure : {row, bank} - SDRAM
logic [16:0] sd_wr_addr;													// SDRAM address
logic wr_vga_fifo;
logic vga_sel;
logic cam_frame_id;

// Pipeline stage for input flags of sdram_dataflow (The cause of timing violation)
dl_input_dataflow inp_dataflow
(
	.clk_i													(sd_clk),
	.rst_ni													(rst_ni),
	.data_cnt_back_i										(data_cnt_back_fifo),
	.data_cnt_back_o										(data_cnt_back_o),
	.data_cnt_cam_i										(data_cnt_cam_fifo),
	.data_cnt_cam_o										(data_cnt_cam_o),
	.data_cnt_vga_i										(data_cnt_vga_fifo),
	.data_cnt_vga_o										(data_cnt_vga_o)
);

// SDRAM dataflow (Control the dataflow of the system - send signals to controller)
sdram_dataflow 
#(
	.IDATA_WD												(IDATA_WD),
	.ODATA_WD												(ODATA_WD)
)
sdram_dataflow_synt
(
	// System
	.sdram_clk												(sd_clk),
	.rst_ni													(rst_ni),
	.sobel_i													(sobel_i),
	.chroma_i												(chroma_i),
	.frame_error											(frame_error),
	.fix_frame_done										(fix_frame_done),
	// FIFO Back
	.done_uart												(done_uart),
	.data_cnt_back_fifo									(data_cnt_back_o),
	.back_fifo_i											(back_fifo_i),
	.rd_back_fifo											(rd_back_fifo),
	// FIFO Camera
	.data_cnt_cam_fifo									(data_cnt_cam_o),
	.cam_fifo_i												(cam_fifo_i),
	.cam_fifo_empty										(cam_fifo_empty),
	.rd_cam_fifo											(rd_cam_fifo),
	// FIFO VGA
	.vga_sel													(vga_sel),
	.data_cnt_vga_fifo									(data_cnt_vga_o),
	.vga_fifo_empty										(vga_fifo_empty),
	.wr_vga_fifo											(wr_vga_fifo),
//	// FIFO Sobel
//	.data_cnt_sobel_fifo									(data_cnt_sobel_fifo),
//	.sobel_o													(sobel_o),
//	.rd_sobel_fifo											(rd_sobel_fifo),
	.color_addr												(color_addr),
	.vga_addr												(vga_addr),
	.vga_error												(vga_error),
	.vga_fix_id												(vga_fix_id),
	.vga_fix_flag											(vga_fix_flag),
	// Flags
	.start_of_cam											(),
	.end_of_cam												(),
	.start_of_vga											(),
	.end_of_vga												(),
	.cam_frame_id											(cam_frame_id),
	.vga_frame_id											(vga_frame_id),
	.first_frame											(first_frame),
	// SDRAM Controller
	.ready													(ready),
	.fpga_data_valid										(fpga_data_valid),
	.sd_data_valid											(sd_data_valid),
	.rw														(rw),
	.rw_en													(rw_en),
	.sd_wr_addr												(sd_wr_addr),
	.sd_data_i												(sd_data_i)
);

// SDRAM Controller
// Address structure: {row, bank} <=> 13 + 2 = 15
sdram_controller
#(
	.DATA_WD													(IDATA_WD),
	.ROW_WD													(13),
	.BANK_WD													(2)
)
sdram_ctrl
(
	// Input
	.sd_clk													(sd_clk),
	.rst_ni													(rst_ni),
	.rw_i														(rw),
	.rw_en_i													(rw_en),
	.addr_i													(sd_wr_addr),
	.data_i													(sd_data_i),
	// Output
	.data_o													(sd_data_o),
	.sd_data_valid											(sd_data_valid),
	.fpga_data_valid										(fpga_data_valid),
	.ready													(ready),
	// SDRAM Controller
	.sdram_clk												(sdram_clk),
	.sdram_cke												(sdram_cke),
	.sdram_cs_n												(sdram_cs_n),
	.sdram_ras_n											(sdram_ras_n),
	.sdram_cas_n											(sdram_cas_n),
	.sdram_we_n												(sdram_we_n),
	.sdram_addr												(sdram_addr),
	.sdram_bank												(sdram_bank),
	.sdram_dqm												(sdram_dqm),
	.sdram_dq												(sdram_dq)
);

// Sobel operation
// Convert the input data RGB565 to RGB888
// Convert to Grayscale
// Store data in 3 line buffer
// Apply sobel operation 
// Write into FIFO inside sobel
//sobel
//#(
//	.IDATA_WD												(IDATA_WD),
//	.ODATA_WD												(ODATA_WD),
//	.FIFO_DEPTH												(8192)
//)
//sb_conv
//(
//	.clk_i													(sd_clk),
//	.rst_ni													(rst_ni),
//	.rgb565_i												(cam_fifo_i),
//	.rd_cam_fifo											(rd_cam_fifo),
//	.sdram_clk												(sd_clk),
//	.rd_sobel_fifo											(rd_sobel_fifo),
//	.data_cnt_sobel_fifo									(data_cnt_sobel_fifo),
//	.sobel_o													(sobel_o)
//);

// Pipeline

logic [15:0] fore_vga_i, back_vga_i;
logic wr_fore_vga, wr_back_vga;

assign fore_vga_i = (!vga_sel) ? sd_data_o : 16'hxx;
assign back_vga_i = (vga_sel) ? sd_data_o : 16'hxx;

assign wr_fore_vga = wr_vga_fifo & (~vga_sel);
assign wr_back_vga = wr_vga_fifo & vga_sel;

// FIFO: From SDRAM to VGA
async_fifo
#(
	.DATA_WD													(IDATA_WD),
	.DEPTH													(4_096)
)
fore_vga_fifo
(
	// Write section
	.wclk_i													(sd_clk),
	.wrst_ni													(rst_ni),
	.w_en_i													(wr_fore_vga),
	.data_i													(fore_vga_i),
	// Read section
	.rclk_i													(vga_clk),
	.rrst_ni													(rst_ni),
	.r_en_i													(rd_vga_fifo),
	.data_o													(fore_vga_o),
	// FIFO parameter
	.data_cnt_w												(data_cnt_vga_fifo),
	.data_cnt_r												(),
	.full_o													(),
	.empty_o													(vga_fifo_empty)
);

// FIFO: From SDRAM to VGA
async_fifo
#(
	.DATA_WD													(IDATA_WD),
	.DEPTH													(4_096)
)
back_vga_fifo
(
	// Write section
	.wclk_i													(sd_clk),
	.wrst_ni													(rst_ni),
	.w_en_i													(wr_back_vga),
	.data_i													(back_vga_i),
	// Read section
	.rclk_i													(vga_clk),
	.rrst_ni													(rst_ni),
	.r_en_i													(rd_vga_fifo),
	.data_o													(back_vga_o),
	// FIFO parameter
	.data_cnt_w												(),
	.data_cnt_r												(),
	.full_o													(),
	.empty_o													()
);

// Chroma keying
chroma_keying chroma_keying_synt
(
	.sys_clk_i												(sd_clk),
	.rst_ni													(rst_ni),
	.rgb565_i												(cam_fifo_i),
	.rd_cam_fifo											(rd_cam_fifo),
	.cam_frame_id											(cam_frame_id),
	.frame_error											(frame_error),
	.fix_frame_done										(fix_frame_done),
	.vga_clk													(vga_clk),
	.rd_ram													(rd_ram),
	.addr_final												(chroma_final_addr),
	.mask_final												(mask_final)
);

endmodule: sdram_interface