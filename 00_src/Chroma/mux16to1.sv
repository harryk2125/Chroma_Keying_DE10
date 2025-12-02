module mux16to1 
#(
	parameter DATA_WD = 1
)
(
	input logic clk_i,
	input logic [3:0] sel_i,
	input logic in0, in1, in2, in3,
	input logic in4, in5, in6, in7,
	input logic in8, in9, in10, in11,
	input logic in12, in13, in14, in15,
	output logic data_o
);

logic odata0, odata1, odata2, odata3;
logic [1:0] osel;

always @(posedge clk_i) begin
	osel <= sel_i[3:2];
end

mux4to1 
#(
	.DATA_WD									(1)
)
sel0
(
	.clk_i									(clk_i),
	.sel_i									(sel_i[1:0]),
	.in0										(in0),
	.in1										(in1),
	.in2										(in2),
	.in3										(in3),
	.data_o									(odata0)
);

mux4to1 
#(
	.DATA_WD									(1)
)
sel1
(
	.clk_i									(clk_i),
	.sel_i									(sel_i[1:0]),
	.in0										(in4),
	.in1										(in5),
	.in2										(in6),
	.in3										(in7),
	.data_o									(odata1)
);

mux4to1 
#(
	.DATA_WD									(1)
)
sel2
(
	.clk_i									(clk_i),
	.sel_i									(sel_i[1:0]),
	.in0										(in8),
	.in1										(in9),
	.in2										(in10),
	.in3										(in11),
	.data_o									(odata2)
);

mux4to1 
#(
	.DATA_WD									(1)
)
sel3
(
	.clk_i									(clk_i),
	.sel_i									(sel_i[1:0]),
	.in0										(in12),
	.in1										(in13),
	.in2										(in14),
	.in3										(in15),
	.data_o									(odata3)
);

mux4to1 
#(
	.DATA_WD									(1)
)
sel_o
(
	.clk_i									(clk_i),
	.sel_i									(osel),
	.in0										(odata0),
	.in1										(odata1),
	.in2										(odata2),
	.in3										(odata3),
	.data_o									(data_o)
);

endmodule: mux16to1