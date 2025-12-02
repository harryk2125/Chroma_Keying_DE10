// Fixed version for RAM addr
// Basic version just use hsync_cnt and vsync_cnt
module vga_controller
(
	// Input
	input logic clk_i,										// VGA controll clock (25MHz) - or Pixel clock
	input logic rst_ni,										// Negative reset
	// Output
	output logic h_sync, v_sync,							// Hsync - Vsync
	output logic video_en,									// Blank_n
	output logic [9:0] pixel_x_nxt, pixel_y_nxt,
	output logic [9:0] pixel_x, pixel_y
);

// Horizontal parameters (pixel clock)
localparam HorDis = 10'd640;
localparam HorFront = 10'd16;
localparam HorSync = 10'd96;
localparam HorBack = 10'd48;
localparam HorSum = 10'd800;

// Vertical parameters (pixel clock)
localparam VerDis = 10'd480;
localparam VerFront = 10'd10;
localparam VerSync = 10'd2;
localparam VerBack = 10'd33;
localparam VerSum = 10'd525;

// Counters
logic [9:0] hsync_cnt, hsync_nxt;
logic [9:0] vsync_cnt, vsync_nxt;

// Generate the VGA signals
// Active Zone: 640 | 480
// Hsync (Sync with VGA clock)
always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		hsync_cnt <= HorDis;
		vsync_cnt <= VerDis;
	end
	else begin
		hsync_cnt <= hsync_cnt + 10'd1;
		if (hsync_cnt == HorSum-10'd1) begin
			vsync_cnt <= vsync_cnt + 10'd1;
			hsync_cnt <= 10'd0;
		end
		if ((vsync_cnt == VerSum-10'd1) && (hsync_cnt == HorSum-10'd1)) begin
			hsync_cnt <= 10'd0;
			vsync_cnt <= 10'd0;
		end
	end
end

// Delay 5 cycle (use for VGA)
// Hsync

delayncycle
#(
	.DATA_WD									(10),
	.N_CYCLE									(4)
)
dl_5_hsync
(
	.clk_i									(clk_i),
	.rst_ni									(1),
	.data_i									(hsync_cnt),
	.data_o									(hsync_nxt)
);

// Vsync

delayncycle
#(
	.DATA_WD									(10),
	.N_CYCLE									(4)
)
dl_5_vsync
(
	.clk_i									(clk_i),
	.rst_ni									(1),
	.data_i									(vsync_cnt),
	.data_o									(vsync_nxt)
);

assign pixel_x = hsync_nxt;					// VGA Hsync counter (Delay 5 cycles)
assign pixel_y = vsync_nxt;					// VGA Vsync counter (Delay 5 cycles)
assign pixel_x_nxt = hsync_cnt;				// RAM Hsync counter
assign pixel_y_nxt = vsync_cnt;				// RAM Vsync counter
assign h_sync = ((hsync_nxt < HorDis + HorFront) || (hsync_nxt > HorSum - HorBack - 10'd1)) ? 1'b1 : 1'b0;
assign v_sync = ((vsync_nxt < VerDis + VerFront) || (vsync_nxt > VerSum - VerBack - 10'd1)) ? 1'b1 : 1'b0;
assign video_en = ((hsync_nxt < HorDis) && (vsync_nxt < VerDis)) ? 1'b1 : 1'b0;

endmodule: vga_controller