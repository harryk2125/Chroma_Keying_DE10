// Add frame error feature => Denying the error frame
// Force reading but not getting the data from Cam FIFO
// Just when Cam FIFO's empty => Reset the current address of SDRAM (current frame)

// Modified data: 07/09/2025
// This module controls the dataflow between of FPGA and SDRAM
// Bonus feature: Fix the frame error and synchronizing with VGA signals 
module sdram_dataflow
#(
	parameter IDATA_WD = 16,
	parameter ODATA_WD = 8
)
(
	// System
	input logic sdram_clk,
	input logic rst_ni,
	input logic sobel_i,
	input logic chroma_i,
	input logic frame_error,
	output logic fix_frame_done,
	// Back FIFO
	input logic done_uart,
	input logic [IDATA_WD-1:0] back_fifo_i,
	input logic [11:0] data_cnt_back_fifo,
	output logic rd_back_fifo,
	// Cam FIFO
	input logic [IDATA_WD-1:0] cam_fifo_i,
	input logic [12:0] data_cnt_cam_fifo,
	input logic cam_fifo_empty,
	output logic rd_cam_fifo,
//	// Sobel FIFO
//	input logic [ODATA_WD-1:0] sobel_o,
//	input logic [12:0] data_cnt_sobel_fifo,
//	output logic rd_sobel_fifo,
	// VGA FIFO
	input logic [11:0] data_cnt_vga_fifo,
	input logic vga_fifo_empty,
	output logic wr_vga_fifo,
	output logic vga_sel,
	// Flag
	output logic start_of_cam,
	output logic end_of_cam,
//	output logic start_of_sobel,
//	output logic end_of_sobel,
	output logic start_of_vga,
	output logic end_of_vga,
	output logic cam_frame_id,
//	output logic sobel_frame_id,
	output logic vga_frame_id,
	output logic first_frame,
	// VGA
	output logic [16:0] color_addr,
	output logic [16:0] vga_addr,
	input logic vga_error,
	input logic vga_fix_id,
	output logic vga_fix_flag,
	// SDRAM Controller
	input logic ready,
	input logic fpga_data_valid,
	input logic sd_data_valid,
	output logic rw,
	output logic rw_en,
	output logic [16:0] sd_wr_addr,
	output logic [IDATA_WD-1:0] sd_data_i
);

// FSM States
logic [2:0] state_q, state_d;
localparam IDLE = 3'd0;
localparam BURST = 3'd1;
localparam CHROMA = 3'd2;
localparam F_ERROR = 3'd3;
localparam VGA_ERROR = 3'd4;

// Variable
logic back_sel_q, back_sel_d;												// 0: Normal | 1: Back_fifo_i
logic idata_sel_q, idata_sel_d;											// 0: Cam_fifo_i | 1: Sobel_fifo
logic odata_sel_q, odata_sel_d;											// 0: Cam_fifo_i | 1: Sobel_fifo
// Structure : {row, bank} - SDRAM
logic [16:0] back_addr_q, back_addr_d;									// Color addr
logic [16:0] color_addr_q, color_addr_d;								// Color addr
logic [16:0] sobel_addr_q, sobel_addr_d;								// Sobel address
logic [16:0] sd_rd_addr_q, sd_rd_addr_d;								// Read address (for VGA)
logic [16:0] chroma_addr_q, chroma_addr_d;								// Color addr

logic dl_wr;
logic force_rd_cam_d, force_rd_cam_q;
logic vga_fix_flag_d, vga_fix_flag_q;

// Flag for enable reading VGA
// Change the method of system
// Just allow to do the VGA since the first frame is loaded into SDRAM

// SDRAM address allocating:
// 0 -> 299: Color frame 0 (Foreground 0)
// 300 -> 599: Color frame 1 (Foreground 1)
// 600 -> 899: Sobel frame 0 (Sobel)
// 900 -> 1199: Sobel frame 1 (Sobel)
// 1200 -> 1499: Background frame (Chroma Key)

// Interlanced frame scan
// Camera
// 0 -> 1 -> 0 -> 1 -> ...
// Solve the problem of VGA will read the old frame if the new frame is not finishing reading
// VGA
// 0 -> 0 -> 1 -> 1 -> 0 -> 0 -> ...

// State changing operation
always @(posedge sdram_clk or negedge rst_ni) begin
	if (!rst_ni) begin
		state_q <= 0;
		back_addr_q <= 0;
		color_addr_q <= 0;
		sobel_addr_q <= 0;
		chroma_addr_q <= 0;
		sd_rd_addr_q <= 0;
		back_sel_q <= 0;
		idata_sel_q <= 0;
		odata_sel_q <= 0;
		force_rd_cam_q <= 0;
		vga_fix_flag_q <= 0;
	end
	else begin
		state_q <= state_d;
		back_addr_q <= back_addr_d;
		color_addr_q <= color_addr_d;
		sobel_addr_q <= sobel_addr_d;
		chroma_addr_q <= chroma_addr_d;
		sd_rd_addr_q <= sd_rd_addr_d;
		back_sel_q <= back_sel_d;
		idata_sel_q <= idata_sel_d;
		odata_sel_q <= odata_sel_d;
		force_rd_cam_q <= force_rd_cam_d;
		vga_fix_flag_q <= vga_fix_flag_d;
	end
end

// State detail - Controller the addr and read/write signals
// 1 full frame: 256 burst x 1200 times = 640 col * 480 row
// Double frame buffer
// Address allocate
localparam COLOR_END0 = 15'd1200;
localparam COLOR_END1 = 15'd2400;
localparam SOBEL_END0 = 15'd3600;
localparam SOBEL_END1 = 15'd4800;
localparam BACKGROUND = 15'd6000;
always @* begin
	// Initial parameter
	state_d = state_q;
	rw = 0;
	rw_en = 0;
	back_addr_d = back_addr_q;
	color_addr_d = color_addr_q;
	sobel_addr_d = sobel_addr_q;
	chroma_addr_d = chroma_addr_q;
	sd_rd_addr_d = sd_rd_addr_q;
	sd_wr_addr = 0;
	fix_frame_done = 0;
	idata_sel_d = idata_sel_q;
	odata_sel_d = odata_sel_q;
	back_sel_d = back_sel_q;
	force_rd_cam_d = force_rd_cam_q;
	vga_fix_flag_d = vga_fix_flag_q;
	// State details
	case(state_q)
		IDLE: begin
			// Wait for enough data in Camera FIFO (256 pixel) to burst write into SDRAM
			// First is writing the color data from FIFO camera to SDRAM
			if (data_cnt_cam_fifo > 256 && ready) begin
				rw = 0;															// Write
				rw_en = 1;														// Enable write/read
				color_addr_d = 1;
				back_addr_d = SOBEL_END1;
				sobel_addr_d = COLOR_END1;
				chroma_addr_d = SOBEL_END1;
				sd_wr_addr = color_addr_q;									
				state_d = BURST;
				idata_sel_d = 0;
				back_sel_d = 0;
			end
			if (frame_error && ready) begin
				state_d = F_ERROR;
				fix_frame_done = 0;
				back_addr_d = SOBEL_END1;
				sobel_addr_d = COLOR_END1;
				chroma_addr_d = SOBEL_END1;
			end
		end
		BURST: begin
			// If SDRAM is ready
			// Just process frame error when SDRAM is free
			if (ready) begin
				if (frame_error) begin
					state_d = F_ERROR;
					fix_frame_done = 0;
				end
				if (vga_error) begin
					state_d = (!vga_fix_flag_q) ? VGA_ERROR : BURST;
				end
				else begin
					vga_fix_flag_d = 0;
				end
				if (data_cnt_back_fifo > 255) begin
					rw = 0;
					rw_en = 1;
					back_addr_d = (back_addr_q == BACKGROUND-17'b1) ? SOBEL_END1 : back_addr_q + 17'b1;
					sd_wr_addr = back_addr_q;
					idata_sel_d = 0;
					back_sel_d = 1'b1;
				end
				// Check, keep WRITE the color data from Camera FIFO to SDRAM (If can)
				if (data_cnt_cam_fifo > 255) begin
					rw = 0;
					rw_en = 1;
					color_addr_d = (color_addr_q == COLOR_END1-17'b1) ? '0 : color_addr_q + 17'b1;
					sd_wr_addr = color_addr_q;
					idata_sel_d = 0;
					back_sel_d = 0;
				end
				// If not => Check and LOAD the data from SDRAM to VGA if possible
				// Update: Just start loading the data to VGA FIFO when complete 1 frame (first_frame flag)
				else if ((data_cnt_vga_fifo < 640) && first_frame) begin
					rw = 1;
					rw_en = 1;
					//sd_rd_addr_d = ((sd_rd_addr_q == COLOR_END0-1'b1) || (sd_rd_addr_q == COLOR_END1-1'b1)) ? ((sobel_i ? sobel_frame_id : cam_frame_id) ? 15'd0 : COLOR_END0) : sd_rd_addr_q + 1'b1;
					sd_rd_addr_d = ((sd_rd_addr_q == COLOR_END0-1'b1) || (sd_rd_addr_q == COLOR_END1-1'b1)) ? (cam_frame_id ? '0 : COLOR_END0) : sd_rd_addr_q + 1'b1;
					// If allow sobel operation => Write the sobel data into SDRAM
					//sd_wr_addr = (sobel_i) ? (sd_rd_addr_q + COLOR_END1) : sd_rd_addr_q;
					sd_wr_addr = sd_rd_addr_q;
					odata_sel_d = 0;
					state_d = (chroma_i) ? CHROMA : BURST;
				end
				// If not => Check and WRITE the sobel data from Sobel FIFO to SDRAM
//				else if (data_cnt_sobel_fifo > 1023) begin
//					rw = 0;
//					rw_en = 1;
//					sobel_addr_d = (sobel_addr_q == SOBEL_END1-1'b1) ? COLOR_END1 : sobel_addr_q + 1'b1;
//					sd_wr_addr = sobel_addr_q;
//					idata_sel_d = 1;
//					back_sel_d = 0;
//				end
			end
		end
		CHROMA: begin
			if (ready) begin
				rw = 1;
				rw_en = 1;
				chroma_addr_d = (sd_rd_addr_q < COLOR_END0) ? sd_rd_addr_q + SOBEL_END1 : sd_rd_addr_q + SOBEL_END0;
				sd_wr_addr = chroma_addr_q;
				odata_sel_d = 1;
				state_d = BURST;
			end
		end
		// At this time, SDRAM's been free and frame_error occurs
		// Using dl_wr for read camera fifo condition (Conveinient)
		F_ERROR: begin
			back_sel_d = 0;
			force_rd_cam_d = 1;
			idata_sel_d = 0;
			rw = 0;
			rw_en = 0;
			// Just reset when camera empty
			if (cam_fifo_empty) begin
				state_d = (!frame_error) ? BURST : F_ERROR;
				rw = 0;
				rw_en = 0;														// Disable SDRAM operation !!!
				color_addr_d = cam_frame_id ? COLOR_END0 : 17'd0;
				fix_frame_done = 1;
				force_rd_cam_d = 0;
			end
		end
		VGA_ERROR: begin
			// Wait until VGA FIFO empty
			if (vga_fifo_empty) begin
				vga_fix_flag_d = 1;
				sd_rd_addr_d = (vga_fix_id) ? COLOR_END0 : 17'd0;
				state_d = BURST;
			end
			else begin
				vga_fix_flag_d = 0;
				state_d = VGA_ERROR;
			end
		end
		default: state_d = IDLE;
	endcase
end

assign rd_back_fifo = (((!rw) && rw_en) || dl_wr || fpga_data_valid) && back_sel_d && (!idata_sel_d);

assign rd_cam_fifo = (((!rw) && rw_en) || dl_wr || fpga_data_valid) && (!idata_sel_d) && (!back_sel_d);
//assign rd_sobel_fifo = fpga_data_valid && idata_sel_d; // OLD

//assign rd_sobel_fifo = (((!rw) && rw_en) || dl_wr || fpga_data_valid) && (idata_sel_d) && (!back_sel_d);
//assign sd_data_i = back_sel_d ? back_fifo_i : (!idata_sel_d ? cam_fifo_i : {8'h00, sobel_o});
assign sd_data_i = back_sel_d ? back_fifo_i : (!idata_sel_d ? cam_fifo_i : 16'h0);

assign start_of_cam = (color_addr_q == 17'd0) ? 1'b1 : 1'b0;
assign end_of_cam = (color_addr_q == COLOR_END0-1'b1) ? 1'b1 : 1'b0;
//assign start_of_sobel = (sobel_addr_q == 15'd0) ? 1'b1 : 1'b0;
//assign end_of_sobel = (sobel_addr_q == SOBEL_END0-1'b1) ? 1'b1 : 1'b0;
assign start_of_vga = (sd_rd_addr_q == 17'd0) ? 1'b1 : 1'b0;
assign end_of_vga = (sd_rd_addr_q == COLOR_END0-1'b1) ? 1'b1 : 1'b0;

// Camera - VGA frame ID: 0 -> Frame 0 		|| 1 -> Frame 1

always @(posedge sdram_clk or negedge rst_ni) begin
	if (!rst_ni) begin
		cam_frame_id <= 1'b0;
	end
	else begin
		if (color_addr_q < COLOR_END0 - 1'b1) begin
			cam_frame_id <= 1'b0;
		end
		else begin
			cam_frame_id <= 1'b1;
		end
	end
end

//always @(posedge sdram_clk or negedge rst_ni) begin
//	if (!rst_ni) begin
//		sobel_frame_id <= 1'b0;
//	end
//	else begin
//		if (sobel_addr_q < SOBEL_END0 - 1'b1) begin
//			sobel_frame_id <= 1'b0;
//		end
//		else begin
//			sobel_frame_id <= 1'b1;
//		end
//	end
//end

always @(posedge sdram_clk or negedge rst_ni) begin
	if (!rst_ni) begin
		vga_frame_id <= 1'b0;
	end
	else begin
		if (sd_rd_addr_q < COLOR_END0) begin
			vga_frame_id <= 1'b0;
		end
		else begin
			vga_frame_id <= 1'b1;
		end
	end
end

// VGA will work after finishing reading the first frame of VGA

always @(posedge sdram_clk or negedge rst_ni) begin
	if (!rst_ni) begin
		first_frame <= 1'b0;
	end
	else begin
		if (end_of_cam) begin
			first_frame <= 1'b1;
		end
		else begin
			first_frame <= first_frame;
		end
	end
end

// Read 1 pixel before transmitting to SDRAM (data sync)

logic [11:0] rw_cnt;

always @(posedge sdram_clk) begin
	if ((!rw) && rw_en) begin
		rw_cnt <= 5'd0;
		dl_wr <= 1'b0;
	end
	else if (force_rd_cam_q) begin
		if (!cam_fifo_empty) begin
			dl_wr <= 1'b1;
		end
		else begin
			dl_wr <= 1'b0;
		end
	end
	else begin
		if (rw_cnt < 5'd16) begin
			rw_cnt <= rw_cnt + 4'd1;
		end
		else if (rw_cnt == 5'd16) begin
			dl_wr <= 1'b1;
			rw_cnt <= rw_cnt + 5'd1;
		end
		else begin
			dl_wr <= 1'b0;
		end
	end
end

// Fix the 1 cycle delay and loss signals in the end (Already fix with new sdram controller)
//logic pre_vga;
//
//always @(posedge sdram_clk) begin
//	pre_vga <= sd_data_valid;
//end

assign wr_vga_fifo = sd_data_valid;//| pre_vga;

assign vga_sel = odata_sel_d;

assign vga_addr = sd_rd_addr_q;

assign color_addr = color_addr_q;

assign vga_fix_flag = vga_fix_flag_q;

// END

endmodule: sdram_dataflow