module uart_interface 
(
	// System
	input logic clk_i,
	input logic rst_ni,
	input logic back_i,
	output logic done_uart,
	// Background FIFO
	input logic sdram_clk,
	input logic rd_back_fifo,
	output logic empty_back_fifo,
	output logic [15:0] back_fifo_o,
	output logic [11:0] data_cnt_back_fifo
);

logic wr_en;
logic [15:0] data_o;


// Fake background
uart_fake_back uart_back_synt
(
	.clk_i									(clk_i),
	.rst_ni									(rst_ni),
	.back_i									(back_i),
	.done_uart								(done_uart),
	.wr_en									(wr_en),
	.data_o									(data_o)
);

// Background FIFO
// Very slow FIFO, takes about 6s to full load the picture
// 640 x 480 16bit RGB565
async_fifo
#(
	.DATA_WD									(16),
	.DEPTH									(4_096),
	.PTR_WD									(12)
)
back_fifo_synt
(
	// Write section
	.wclk_i									(clk_i),
	.wrst_ni									(rst_ni),
	.w_en_i									(wr_en),
	.data_i									(data_o),
	// Read section
	.rclk_i									(sdram_clk),
	.rrst_ni									(rst_ni),
	.r_en_i									(rd_back_fifo),
	.data_o									(back_fifo_o),
	// Flags + counters
	.data_cnt_w								(data_cnt_back_fifo),
	.data_cnt_r								(),
	.empty_o									(empty_back_fifo),
	.full_o									()
);

endmodule: uart_interface