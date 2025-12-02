module ram2port_addr16bit
#(
	parameter DATA_WD = 1,
	parameter ADDR_WD = 16
)
(
	// Input
	input logic wclk_i,
	input logic rclk_i,
	// To RAM
	input logic [DATA_WD-1:0] data_i,
	input logic [ADDR_WD-1:0] waddr_i,
	input logic [ADDR_WD-1:0] raddr_i,
	input logic w_en_i,
	input logic r_en_i,
	// Output
	output logic [DATA_WD-1:0] data_o
);

localparam ADDR_ID = 16'd65_535;

(* ramstyle = "M10K" *) reg [ADDR_ID:0] buffer;

always @(posedge wclk_i) begin
	if (w_en_i) begin
		buffer[waddr_i] <= data_i;
	end
end

always @(posedge rclk_i) begin
	if (r_en_i) begin
		data_o <= buffer[raddr_i];
	end
end


endmodule: ram2port_addr16bit