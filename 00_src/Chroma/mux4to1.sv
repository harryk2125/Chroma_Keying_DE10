module mux4to1 
#(
	parameter DATA_WD = 1
)
(
	input logic clk_i,
	input logic [1:0] sel_i,
	input logic in0, in1, in2, in3,
	output logic data_o
);

always @(posedge clk_i) begin
	case (sel_i)
		2'd0: data_o <= in0;
		2'd1: data_o <= in1;
		2'd2: data_o <= in2;
		2'd3: data_o <= in3;
		default: data_o <= '0;
	endcase
end

endmodule: mux4to1