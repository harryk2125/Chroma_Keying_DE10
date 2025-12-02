// Write section
module wptr_handler 
#(
	parameter PTR_WD = 10,
	parameter DEPTH = 1024
)
(
	// Input
	input logic w_clk_i, w_en_i,
	input logic w_rst_ni,
	input logic [PTR_WD:0] b_rptr_sync_i,
	input logic [PTR_WD:0] g_rptr_sync_i,
	// Output
	output logic [PTR_WD:0] b_wptr_o, g_wptr_o,
	output logic [PTR_WD-1:0] data_cnt_w,
	output logic full_o
);

localparam FULL_DEPTH = 2*DEPTH;

// Binary pointer next
logic [PTR_WD:0] b_wptr_nxt;
// Gray pointer next
logic [PTR_WD:0] g_wptr_nxt;

// Generate binary write counter
// Pointer increases when ENABLE Write and the FIFO is NOT FULL
assign b_wptr_nxt = b_wptr_o + (w_en_i & (!full_o));

// Convert from bin to gray
assign g_wptr_nxt = b_wptr_nxt ^ (b_wptr_nxt >> 1);

// FULL
logic wfull;
assign wfull = (g_wptr_nxt == {~g_rptr_sync_i[PTR_WD:PTR_WD-1], g_rptr_sync_i[PTR_WD-2:0]});

// Write data count
logic [PTR_WD:0] data_cnt_wr;
assign data_cnt_wr = (b_wptr_o >= b_rptr_sync_i) ? (b_wptr_o - b_rptr_sync_i) : (FULL_DEPTH + b_wptr_o - b_rptr_sync_i);
assign data_cnt_w = data_cnt_wr[PTR_WD-1:0];

// Binary + Gray write pointer
always @(posedge w_clk_i or negedge w_rst_ni) begin
	if (!w_rst_ni) begin
		b_wptr_o <= 0;
		g_wptr_o <= 0;
	end
	else begin
		b_wptr_o <= b_wptr_nxt;
		g_wptr_o <= g_wptr_nxt;
	end
end

// Full condition
always @(posedge w_clk_i or negedge w_rst_ni) begin
	if (!w_rst_ni) begin
		full_o <= 0;
	end
	else begin
		full_o <= wfull;
	end
end

endmodule: wptr_handler