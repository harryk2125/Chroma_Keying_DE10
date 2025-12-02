// Main module of VGA Section
`timescale 1ns/1ns
module vga_interface 
(
	// System
	input logic clk_i,
	input logic rst_ni,
	input logic sobel_i,
	input logic chroma_i,
	// FIFO from SDRAM
	input logic sdram_fifo_empty,						// Check the FIFO of the SDRAM (empty status)
	input logic [15:0] fore_vga_i,					// Input data (RGB565 or gray8bit)
	input logic [15:0] back_vga_i,					// Input data (RGB565 or gray8bit)
	output logic vga_clk,
	output logic rd_en,
	// SDRAM
	input logic [16:0] vga_addr,
	input logic vga_fix_flag,
	output logic vga_error,
	output logic vga_fix_id,
	// RAM 2 ports (Chroma Final)
	input logic vga_frame_id,
	// {bank, pixel_y_nxt, pixel_x_nxt}				// {0/1, 0 -> 480, 0 -> 640}
	output logic rd_ram,
	output logic [19:0] chroma_final_addr,			// Address for RAM 2 ports
	input logic final_mask,								// Chroma key final mask
	// 0 -> background		| 1 -> foreground
	// Test output
	output logic [15:0] data_i,
	// Output for VGA
	output logic [7:0] vga_red,
	output logic [7:0] vga_green,
	output logic [7:0] vga_blue,
	output logic vga_hsync, vga_vsync,
	output logic blank_n, sync_n
);

// State
localparam IDLE = 2'b00;										// Wait the data from FIFO
localparam FIRST_LINE = 2'b01;
localparam DISPLAY = 2'b10;
localparam VGA_CHECK = 2'b11;

// SDRAM check
localparam FRAME_0 = 17'd3;
localparam FRAME_1 = 17'd1203;
logic [16:0] expect_addr;

logic [1:0] state_q, state_d;							// State
logic [9:0] pixel_x, pixel_y;							// Hor/Ver pixel
logic video_en;
logic ram_bank_o;
logic vga_error_d, vga_error_q;

//logic [15:0] data_i;

logic [23:0] rgb888;

// Expected SDRAM address to compare with
assign vga_fix_id = (vga_addr > 17'd64 && vga_addr < 17'd1265) ? 1'b1 : 1'b0;
assign expect_addr = (vga_fix_id) ? FRAME_1 : FRAME_0;

assign data_i = chroma_i ? (final_mask ? fore_vga_i : back_vga_i) : fore_vga_i;

RGB565toRGB888 cvrt
(
	.rgb565_i									(data_i),
	.rgb888_o									(rgb888)
);

// Change state operation
always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		state_q <= IDLE;
		vga_error_q <= 0;
	end
	else begin
		state_q <= state_d;
		vga_error_q <= vga_error_d;
	end
end

// Check SDRAM address after finishing display 1 frame
logic vga_check;
always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		vga_check <= 0;
	end
	else begin
		if ((pixel_x == 640) && (pixel_y == 480)) begin
			vga_check <= 1;
		end
		else vga_check <= 0;
	end
end

// FSM
always @* begin
	// Initial
	state_d = state_q;
	rd_en = 0;
	vga_red = 0;
	vga_green = 0;
	vga_blue = 0;
	vga_error_d = vga_error_q;
	// FSM
	case(state_q)
		IDLE: begin
			if (pixel_x == 10'd799 && pixel_y == 10'd524 && (!sdram_fifo_empty)) begin
				if (!sobel_i) begin
					vga_red = rgb888[23:16];
					vga_green = rgb888[15:8];
					vga_blue = rgb888[7:0];
				end
				else begin
					vga_red = data_i[7:0];
					vga_green = data_i[7:0];
					vga_blue = data_i[7:0];
				end
				rd_en = 1;
				state_d = FIRST_LINE;
			end
			else begin
				rd_en = 0;
				state_d = IDLE;
			end
		end
		FIRST_LINE: begin
			if (pixel_x < 639) begin
				if (!sobel_i) begin
					vga_red = rgb888[23:16];
					vga_green = rgb888[15:8];
					vga_blue = rgb888[7:0];
				end
				else begin
					vga_red = data_i[7:0];
					vga_green = data_i[7:0];
					vga_blue = data_i[7:0];
				end
				rd_en = 1;
			end
			else begin
				rd_en = 0;
				state_d = DISPLAY;
			end
		end
		DISPLAY: begin
			if (pixel_x < 640 && pixel_y < 480) begin
				if (!sobel_i) begin
					vga_red = rgb888[23:16];
					vga_green = rgb888[15:8];
					vga_blue = rgb888[7:0];
				end
				else begin
					vga_red = data_i[7:0];
					vga_green = data_i[7:0];
					vga_blue = data_i[7:0];
				end
				rd_en = 1;
			end
			else begin // Check VGA error
				// Just check only 1 time and only !!!
				if (vga_check) begin
					// Same id => nearly not error
					// But have to check the correct addr (expect_addr)
					if (vga_addr == expect_addr) begin
						vga_error_d = 0;
						state_d = DISPLAY;
					end
					else begin
						vga_error_d = 1;
						state_d = VGA_CHECK;
					end
				end
			end
		end
		// VGA ERROR detected !!!
		// Flush all VGA FIFO's data
		// Load again with exact address
		VGA_CHECK: begin
			if (!vga_fix_flag) begin
				vga_error_d = 1;
				rd_en = (!sdram_fifo_empty) ? 1'b1 : 1'b0;
			end
			else begin
				if (vga_addr != expect_addr) begin
					vga_error_d = 1;
					state_d = VGA_CHECK;
					rd_en = 0;
				end
				else begin
					vga_error_d = 0;
					rd_en = 0;
					state_d = DISPLAY;
				end
			end
		end
		default: state_d = IDLE;
	endcase	
end

// VGA Controller
// Generate the VGA output
logic [9:0] pixel_x_nxt, pixel_y_nxt;

vga_controller vga_ctrl
(
	.clk_i										(clk_i),
	.rst_ni										(rst_ni),
	.h_sync										(vga_hsync),
	.v_sync										(vga_vsync),
	.video_en									(blank_n),
	.pixel_x_nxt								(pixel_x_nxt),
	.pixel_y_nxt								(pixel_y_nxt),
	.pixel_x										(pixel_x),
	.pixel_y										(pixel_y)
);

logic nxt_id;

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		ram_bank_o <= 1;
		nxt_id <= 0;
	end
	else begin
		nxt_id <= vga_frame_id;
		if ((pixel_x_nxt == 10'd799) && (pixel_y_nxt == 10'd524)) begin
			ram_bank_o <= nxt_id;
		end
		else ram_bank_o <= ram_bank_o;
	end
end

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		rd_ram <= 0;
	end
	else if (chroma_i) begin
		if ((pixel_x_nxt < 10'd639 || pixel_x_nxt == 10'd799) && (pixel_y_nxt < 10'd479)) begin
			rd_ram <= 1;
		end
		else if ((pixel_x_nxt == 10'd799) && (pixel_y_nxt == 10'd524)) begin
			rd_ram <= 1;
		end
		else rd_ram <= 0;
	end
	else rd_ram <= 0;
end

assign sync_n = 1'b0;
assign vga_clk = clk_i;
//assign rd_ram = rd_en & chroma_i;
assign chroma_final_addr = {ram_bank_o, pixel_y_nxt[8:0], pixel_x_nxt};
assign vga_error = vga_error_q;

endmodule: vga_interface