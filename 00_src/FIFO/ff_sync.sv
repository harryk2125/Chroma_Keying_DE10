module ff_sync 
#(
	parameter WIDTH = 10				// Data width
)
(
	// Input
	input logic clk_i,
	input logic rst_ni,
	input logic [WIDTH:0] d_i,
	// Output
	output logic [WIDTH:0] d_o
);

(* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED" *) logic [WIDTH:0] q1, q2;

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		q1 <= 0;
		q2 <= 0;
	end
	else begin
		q1 <= d_i;
		q2 <= q1;
	end
end

assign d_o = q2;

endmodule: ff_sync