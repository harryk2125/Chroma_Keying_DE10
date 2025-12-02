module RGB2Gray 
#(
	parameter DATA_WD = 8
)
(
	// Input
	input logic [DATA_WD-1:0] red, green, blue,
	// Output
	output logic [DATA_WD-1:0] gray
);

// Using the shift bit method 
// Because Green color is more sensitve to human eyes)
// And this method is simplier than average method
// Red >> 2 + Green >> 1 + Blue >> 2
assign gray = (red >> 2) + (green >> 1) + (blue >> 2);

endmodule: RGB2Gray