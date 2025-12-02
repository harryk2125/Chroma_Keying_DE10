module d_ff
(
	input logic clk,
	input logic rst,
	input logic set,
	input logic d,
	output logic q
);

always @(posedge clk or negedge rst) begin
	if (!rst) begin
		q <= 0;
	end
	else begin
		if (set) begin
			q <= 1;
		end
		else begin
			q <= d;
		end
	end
end

endmodule: d_ff