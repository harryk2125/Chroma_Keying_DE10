module async_mem 
#(
	parameter DATA_WD = 16,
	parameter DEPTH = 16_384,
	parameter PTR_WD = 14
)
(
	input logic wclk_i,
	input logic rclk_i,
	input logic wen_i,
	input logic ren_i,
	input logic [PTR_WD-1:0] waddr_i,
	input logic [PTR_WD-1:0] raddr_i,
	input logic [DATA_WD-1:0] wdata_i,
	output logic [DATA_WD-1:0] rdata_o
);

(* ramstyle = "M10K" *) reg [DATA_WD-1:0] ff_mem [DEPTH-1:0];

always @(posedge wclk_i) begin
	if (wen_i) begin
		ff_mem[waddr_i] <= wdata_i;
	end
end

always @(posedge rclk_i) begin
	if (ren_i) begin
		rdata_o <= ff_mem[raddr_i];
	end
end

endmodule: async_mem