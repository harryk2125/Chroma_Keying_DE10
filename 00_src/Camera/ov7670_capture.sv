// OV7670 RGB565 format
// FSM style
module ov7670_capture 
(
	// Sys
	input logic pclk_i,
	input logic rst_ni,
	// Cam
	input logic vsync_i,
	input logic href_i,
	input logic [7:0] data_i,
	// Cam controller
	input logic done_config_i,
	// SDRAM dataflow
	input logic [16:0] color_addr_i,
	input logic fix_frame_done,
	output logic frame_error,
	// Cam FIFO - wclk is pclk
	output logic wr_en,
	output logic [15:0] data_o
);

// FSM
localparam IDLE = 2'b00;				// Wait config complete => IDLE
localparam CAPTURE = 2'b01;			// 
localparam CHECK = 2'b10;				// CHECK if not error => CAPTURE
// Error => Send signal to SDRAM control and wait to fix it
// => Receive fix => CAPTURE

logic [1:0] state;

// Variables
logic pre_vsync;
logic pre_frame_id;
logic f_error;

logic [15:0] d_latch, pixel_bf;
logic [1:0] wr_hold;
logic wr_fifo;

// Address checking
logic [16:0] expect_addr;
localparam FRAME0 = 17'd0;
localparam FRAME1 = 17'd1200;

// Sampling at middle of pixel data by posedge PCLK (datasheet)
always @(posedge pclk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		state <= IDLE;
		pre_vsync <= 0;
		pre_frame_id <= 1;
		f_error <= 0;
		expect_addr <= 0;
		d_latch <= 0;
		wr_fifo <= 0;
		wr_hold <= 0;
		pixel_bf <= 0;
	end
	else begin
		pre_vsync <= vsync_i;
		case (state)
			IDLE: begin
				state <= (done_config_i) ? CAPTURE : IDLE;
			end
			CAPTURE: begin
				state <= (!pre_vsync && vsync_i) ? CHECK : CAPTURE;
				f_error <= 0;
				expect_addr <= (pre_frame_id) ? FRAME0 : FRAME1;
				
				wr_hold <= {wr_hold[0], (href_i && (!wr_hold[0]))};
				d_latch <= {d_latch[7:0], data_i};
				
				wr_fifo <= wr_hold[1];
				pixel_bf <= d_latch;
			end
			CHECK: begin	
				if (!frame_error) begin
					if (color_addr_i == expect_addr) begin
						pre_frame_id <= ~pre_frame_id;
						f_error <= 0;
						state <= CAPTURE;
					end
					else begin
						pre_frame_id <= pre_frame_id;
						f_error <= 1;
						state <= CHECK;
					end
				end
				else if (fix_frame_done) begin
					state <= CAPTURE;
					f_error <= 0;
				end
			end
			default: state <= IDLE;
		endcase
	end
end

assign frame_error = f_error;
assign wr_en = wr_fifo;
assign data_o = pixel_bf;

endmodule: ov7670_capture