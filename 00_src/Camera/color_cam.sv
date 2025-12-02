// This module will operate as a Camera in the ideal situation
// Using the switch to change color_cam
// Use for test the VGA and SDRAM operation
// Just generate the HREF and VSYNC signal
// Also the camera data (8bit per PCLK)
module color_cam 
(
	// System
	input logic clk_i,
	input logic rst_ni,
	input logic [1:0] sel_i,
	// Camera
	input logic cam_done_config,
	input logic pwdw,
	input logic cam_rst,
	input logic sioc,
	inout siod,
	output logic cam_pclk,
	output logic href,
	output logic vsync,
	output logic [7:0] cam_data_o
);

// 8 basic colors
localparam BLACK = 16'h0000;
localparam WHITE = 16'hffff;
localparam RED = 16'hf800;
localparam GREEN = 16'h07e0;
localparam BLUE = 16'h001f;
localparam YELLOW = 16'hffe0;
localparam PURPLE = 16'hf81f;
localparam CYAN = 16'h07ff;

logic [15:0] cam_rgb;
logic pixel_id;

// Camera timing parameters
// Timing control
localparam t_p = 40;								// T_PCK = CLK_40
localparam t_pxl = 80;							// Double because RGB format			= 2 t_p
localparam t_line = 62_720;					// 784 * t_xpl								
// Timing flow
localparam t_rise_vsync = 188_160;
localparam t_vsync_href = 1_066_240;
localparam t_rise_href = 51_200;
localparam t_low_href = 11_520;
localparam t_end = 627_200;

// Just can use the counter of t_p: 40ns = 25MHz
// Max 15 bit
localparam cnt_pxl = 16'd2;
localparam cnt_line = 16'd1_568;
localparam cnt_rise_vsync = 16'd4_704;
localparam cnt_vsync_href = 16'd26_656;
localparam cnt_rise_href = 16'd1_280;
localparam cnt_low_href = 16'd288;
localparam cnt_end = 16'd15_680;

logic [15:0] counter;
logic [8:0] href_cnt;

logic href_dl, vsync_dl;

// Using Finite State Machine to generate these signals
// System STATES
localparam IDLE = 0;												// Wait for the done_config signal
localparam CNT_DWN = 1;											// Count down (25MHz ref clock)
// VGA Signals states
// 1. High of Vync
localparam HIGH_VSYNC = 2;
// 2. Low of Vync
localparam LOW_VSYNC = 3;
// From this Repeat for 479 times
// 3. High of Href -> 5 (< 479) | -> 6 (= 479)			// Start from 0
localparam HIGH_HREF = 4;
// 4. Low of Href
localparam LOW_HREF = 5;
// 5. After last frame
localparam AFT_FRAME = 6;
// 6. Final before next frame									// End count down => HIGH_VSYNC

logic [2:0] CUR_STATE;
logic [2:0] DES_STATE;


always @(posedge clk_i) begin
	case (CUR_STATE)
		IDLE: begin
			if (cam_done_config & rst_ni) begin
				CUR_STATE <= HIGH_VSYNC;
			end
			else begin 
				CUR_STATE <= IDLE;
			end
			href_dl <= 1'b0;
			vsync_dl <= 1'b0;
			counter <= 16'd0;
		end
		CNT_DWN: begin
			CUR_STATE <= (counter == 0) ? DES_STATE : CNT_DWN;
			counter <= (counter == 0) ? 16'd0 : counter - 16'd1;
		end
		HIGH_VSYNC: begin
			CUR_STATE <= CNT_DWN;
			DES_STATE <= LOW_VSYNC;
			counter <= cnt_rise_vsync - 16'd2;
			vsync_dl <= 1'b1;
		end
		LOW_VSYNC: begin
			CUR_STATE <= CNT_DWN;
			DES_STATE <= HIGH_HREF;
			vsync_dl <= 1'b0;
			counter <= cnt_vsync_href - 16'd2;
			href_cnt <= 9'd0;
		end
		HIGH_HREF: begin
			CUR_STATE <= CNT_DWN;
			DES_STATE <= (href_cnt < 9'd479) ? LOW_HREF : AFT_FRAME;
			counter <= cnt_rise_href - 16'd2;
			href_dl <= 1'b1;
		end
		LOW_HREF: begin
			CUR_STATE <= CNT_DWN;
			DES_STATE <= HIGH_HREF;
			counter <= cnt_low_href - 16'd2;
			href_cnt <= href_cnt + 9'd1;
			href_dl <= 1'b0;
		end
		AFT_FRAME: begin
			CUR_STATE <= CNT_DWN;
			DES_STATE <= HIGH_VSYNC;
			counter <= cnt_end - 16'd2;
			href_dl <= 1'b0;
		end
		default: CUR_STATE <= IDLE;
	endcase
end

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		cam_rgb = BLACK;
		pixel_id <= 0;
	end
	else if (href_dl == 1) begin
		pixel_id <= pixel_id + 1'b1;
		case (sel_i)
			2'b00: cam_rgb = (href_cnt < 9'd240) ? BLACK : WHITE;
			2'b01: cam_rgb = (href_cnt < 9'd240) ? RED : YELLOW;
			2'b10: cam_rgb = (href_cnt < 9'd240) ? GREEN : BLUE;
			2'b11: cam_rgb = (href_cnt < 9'd240) ? PURPLE : CYAN;
			default: cam_rgb = WHITE;
		endcase
	end
	else cam_rgb = WHITE;
end

oddr2 delay180
(
	.d0		(1'b0),
	.d1		(1'b1),
	.c0		(clk_i),
	.c1		(~clk_i),
	.ce		(1'b1),
	.r			(1'b0),
	.s			(1'b0),
	.q			(cam_pclk)
);

always @(posedge clk_i) begin
	href <= href_dl;
	vsync <= vsync_dl;
end

assign cam_data_o = (pixel_id) ? cam_rgb[15:8] : cam_rgb[7:0];

endmodule: color_cam