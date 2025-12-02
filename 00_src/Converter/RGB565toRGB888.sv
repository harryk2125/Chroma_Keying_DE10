module RGB565toRGB888 
(
	// Input
	input logic [15:0] rgb565_i,
	// Output
	output logic [23:0] rgb888_o
);

// Estimate the rgb value
// RGB = [R5, R5[2:0], G6, G6[1:0], B5, B5[2:0]]
assign rgb888_o = {rgb565_i[15:11], rgb565_i[13:11], rgb565_i[10:5], rgb565_i[6:5], rgb565_i[4:0], rgb565_i[2:0]};

endmodule: RGB565toRGB888