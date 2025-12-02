module sel_data_o
(
	input logic clk_i,
	input logic [3:0] in_sel,
	input logic r_en,
	output logic [3:0] sel_o
);

logic [3:0] tmp0, tmp1;

always @(posedge clk_i) begin
	if (!r_en) begin
		tmp0 <= 4'h0;
	end
	else begin
		tmp0 <= in_sel;
	end
	tmp1 <= tmp0;
	sel_o <= tmp1;
end

endmodule: sel_data_o