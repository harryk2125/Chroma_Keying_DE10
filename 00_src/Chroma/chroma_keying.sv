module chroma_keying 
#(
	parameter DATA_WD = 16
)
(
	// System
	input logic sys_clk_i,								// Clock 100MHz
	input logic rst_ni,									// Negative reset
	// Chroma keying inputs
	input logic [DATA_WD-1:0] rgb565_i,
	input logic rd_cam_fifo,
	input logic cam_frame_id,
	input logic frame_error,
	input logic fix_frame_done,
	// RAM 2 ports (Final)
	input logic vga_clk,									// VGA read clock
	input logic rd_ram,									// Read the mask (1 cycle after)
	input logic [19:0] addr_final,					// Read address for Final RAM 2 ports
	output logic mask_final								// 0 => background		| 1 => foreground
);

// Convert to RGB888 format

logic [23:0] rgb888;

RGB565toRGB888 rgb_extend_synt
(
	.rgb565_i									(rgb565_i),
	.rgb888_o									(rgb888)
);

// Manhattan algorithm
// Calculate this color distance
// Consider it if whether the green or not
// 0 => background				|			1 => foreground

logic wr_mask_chroma;						// Write enable (Mask chroma)
logic [19:0] wr_addr_chroma_o;			// {verticle, horizon}
logic mask_chroma_i;

manhattan manhattan_synt
(
	.clk_i										(sys_clk_i),
	.rst_ni										(rst_ni),
	.rgb888										(rgb888),
	.rd_cam_fifo								(rd_cam_fifo),
	.cam_frame_id								(cam_frame_id),
	.frame_error								(frame_error),
	.fix_frame_done							(fix_frame_done),
	.wr_en										(wr_mask_chroma),
	.wr_addr_chroma_o							(wr_addr_chroma_o),
	.chroma_key_o								(mask_chroma_i)
);

// 2 RAM 2 Port (Final)			-- Without Sobel
// Replace with RAM 2 port (Chroma) when using Soble
ram2port_final
#(
	.DATA_WD										(1),
	.ADDR_WD										(20)
)
ram2port_final_synt
(
	.wclk_i										(sys_clk_i),
	.rclk_i										(vga_clk),
	.data_i										(mask_chroma_i),
	.waddr_i										(wr_addr_chroma_o),
	.raddr_i										(addr_final),
	.w_en_i										(wr_mask_chroma),
	.r_en_i										(rd_ram),
	.data_o										(mask_final)
);

endmodule: chroma_keying