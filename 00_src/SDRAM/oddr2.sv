module oddr2 
(
	// Input
	input logic d0, d1,
	input logic c0, c1,
	input logic ce,
	input logic r, s,
	// Output
	output logic q
);

logic q0, q1;

d_ff ff0
(
	.clk		(c0),
	.rst		(~r),
	.set		(s),
	.d			(d0),
	.q			(q0)
);

d_ff ff1
(
	.clk		(c1),
	.rst		(~r),
	.set		(s),
	.d			(d1),
	.q			(q1)
);

assign q = (ce ? (c0 ? q0 : (c1 ? q1 : 1'bz)) : 1'bz);

endmodule: oddr2