// Asynchronous FIFO
module async_fifo 
#(
	parameter DATA_WD = 16,
	parameter DEPTH = 16_384,
	parameter PTR_WD = $clog2(DEPTH)
)
(
	// Input
	input logic wclk_i, wrst_ni,
	input logic rclk_i, rrst_ni,
	input logic w_en_i, r_en_i,
	input logic [DATA_WD-1:0] data_i,
	// Test
	//output logic [PTR_WD:0] b_wptr, b_rptr,
	// Output
	output logic [PTR_WD-1:0] data_cnt_w, data_cnt_r,
	output logic [DATA_WD-1:0] data_o,
	output logic full_o, empty_o
);

// Variables
logic [PTR_WD:0] b_wptr_sync, b_rptr_sync;
logic [PTR_WD:0] g_wptr_sync, g_rptr_sync;
logic [PTR_WD:0] b_wptr, b_rptr;
logic [PTR_WD:0] g_wptr, g_rptr;

// Address
logic [PTR_WD:0] w_addr, r_addr;

// Sync write pointer with read clock
// Binary
ff_sync
#(
	.WIDTH			(PTR_WD)
)
bwptr_sync
(
	.clk_i			(rclk_i),
	.rst_ni			(rrst_ni),
	.d_i				(b_wptr),
	.d_o				(b_wptr_sync)
);
// Gray
ff_sync
#(
	.WIDTH			(PTR_WD)
)
gwptr_sync
(
	.clk_i			(rclk_i),
	.rst_ni			(rrst_ni),
	.d_i				(g_wptr),
	.d_o				(g_wptr_sync)
);

// Sync read pointer with write clock
// Binary
ff_sync
#(
	.WIDTH			(PTR_WD)
)
brptr_sync
(
	.clk_i			(wclk_i),
	.rst_ni			(wrst_ni),
	.d_i				(b_rptr),
	.d_o				(b_rptr_sync)
);
// Gray
ff_sync
#(
	.WIDTH			(PTR_WD)
)
grptr_sync
(
	.clk_i			(wclk_i),
	.rst_ni			(wrst_ni),
	.d_i				(g_rptr),
	.d_o				(g_rptr_sync)
);

// Write pointer handler
wptr_handler 
#(
	.PTR_WD		(PTR_WD),
	.DEPTH		(DEPTH)
)
wptr_handler_synt
(
	.w_clk_i			(wclk_i),
	.w_en_i			(w_en_i),
	.w_rst_ni		(wrst_ni),
	.b_rptr_sync_i	(b_rptr_sync),
	.g_rptr_sync_i	(g_rptr_sync),
	.b_wptr_o		(b_wptr),
	.g_wptr_o		(g_wptr),
	.data_cnt_w		(data_cnt_w),
	.full_o			(full_o)
);

// Read pointer handler
rptr_handler 
#(
	.PTR_WD		(PTR_WD),
	.DEPTH		(DEPTH)
)
rptr_handler_synt
(
	.r_clk_i			(rclk_i),
	.r_en_i			(r_en_i),
	.r_rst_ni		(rrst_ni),
	.b_wptr_sync_i	(b_wptr_sync),
	.g_wptr_sync_i	(g_wptr_sync),
	.b_rptr_o		(b_rptr),
	.g_rptr_o		(g_rptr),
	.data_cnt_r		(data_cnt_r),
	.empty_o			(empty_o)
);

// FIFO Memory

logic wen_i, ren_i;
logic [PTR_WD-1:0] waddr_i, raddr_i;

assign wen_i = w_en_i & (~full_o);
assign ren_i = r_en_i & (~empty_o);
assign waddr_i = b_wptr[PTR_WD-1:0];
assign raddr_i = b_rptr[PTR_WD-1:0];

// FIFO Memory
async_mem
#(
	.DEPTH			(DEPTH),
	.DATA_WD			(DATA_WD),
	.PTR_WD			(PTR_WD)
)
mem_synt
(
	.wclk_i			(wclk_i),
	.rclk_i			(rclk_i),
	.wen_i			(wen_i),
	.ren_i			(ren_i),
	.waddr_i			(waddr_i),
	.raddr_i			(raddr_i),
	.wdata_i			(data_i),
	.rdata_o			(data_o)
);

//// Old version - Timing errors
//fifo_mem
//#(
//	.DEPTH			(DEPTH),
//	.DATA_WD			(DATA_WD),
//	.PTR_WD			(PTR_WD)
//)
//mem_synt
//(
//	.w_clk_i			(wclk_i),
//	.w_en_i			(w_en_i),
//	.r_clk_i			(rclk_i),
//	.r_en_i			(r_en_i),
//	.b_wptr_i		(b_wptr),
//	.b_rptr_i		(b_rptr),
//	.data_i			(data_i),
//	.full_i			(full_o),
//	.empty_i			(empty_o),
//	.data_o			(data_o)
//);

endmodule: async_fifo