// Write section
module rptr_handler 
#(
	parameter PTR_WD = 10,
	parameter DEPTH = 1024
)
(
	// Input
	input logic r_clk_i, r_en_i,
	input logic r_rst_ni,
	input logic [PTR_WD:0] b_wptr_sync_i,
	input logic [PTR_WD:0] g_wptr_sync_i,
	// Output
	output logic [PTR_WD:0] b_rptr_o, g_rptr_o,
	output logic [PTR_WD-1:0] data_cnt_r,
	output logic empty_o
);

localparam FULL_DEPTH = 2*DEPTH;

// Binary pointer next
logic [PTR_WD:0] b_rptr_nxt;
// Gray pointer next
logic [PTR_WD:0] g_rptr_nxt;

// Generate binary write counter
// Pointer increases when ENABLE Write and the FIFO is NOT FULL
assign b_rptr_nxt = b_rptr_o + (r_en_i & (!empty_o));

// Convert from bin to gray
assign g_rptr_nxt = b_rptr_nxt ^ (b_rptr_nxt >> 1);

// FULL
logic rempty;
assign rempty = (g_rptr_nxt == g_wptr_sync_i);

// Write data count
logic [PTR_WD:0] data_cnt_rd;
assign data_cnt_rd = (b_rptr_o >= b_wptr_sync_i) ? (b_rptr_o - b_wptr_sync_i) : (FULL_DEPTH + b_rptr_o - b_wptr_sync_i);
assign data_cnt_r = data_cnt_rd[PTR_WD-1:0];

// Binary + Gray write pointer
always @(posedge r_clk_i or negedge r_rst_ni) begin
	if (!r_rst_ni) begin
		b_rptr_o <= 0;
		g_rptr_o <= 0;
	end
	else begin
		b_rptr_o <= b_rptr_nxt;
		g_rptr_o <= g_rptr_nxt;
	end
end

// Full condition
always @(posedge r_clk_i or negedge r_rst_ni) begin
	if (!r_rst_ni) begin
		empty_o <= 0;
	end
	else begin
		empty_o <= rempty;
	end
end

endmodule: rptr_handler