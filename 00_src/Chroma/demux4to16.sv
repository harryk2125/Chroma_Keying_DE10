module demux4to16 
#(
	parameter DATA_WD = 16
)
(
	// System
	input logic clk_i,
	// Data
	input logic [3:0] sel_i,
	input logic [DATA_WD-1:0] data_i,
	// Odata
	output logic [DATA_WD-1:0] out0,
	output logic [DATA_WD-1:0] out1,
	output logic [DATA_WD-1:0] out2,
	output logic [DATA_WD-1:0] out3,
	output logic [DATA_WD-1:0] out4,
	output logic [DATA_WD-1:0] out5,
	output logic [DATA_WD-1:0] out6,
	output logic [DATA_WD-1:0] out7,
	output logic [DATA_WD-1:0] out8,
	output logic [DATA_WD-1:0] out9,
	output logic [DATA_WD-1:0] out10,
	output logic [DATA_WD-1:0] out11,
	output logic [DATA_WD-1:0] out12,
	output logic [DATA_WD-1:0] out13,
	output logic [DATA_WD-1:0] out14,
	output logic [DATA_WD-1:0] out15
);

logic [DATA_WD-1:0] buffer [0:15];

always @(posedge clk_i) begin
	// Stage 1 (Write data)
	buffer[sel_i] <= data_i;
	// Stage 2 (Read data)
	out0 <= buffer[0];
	out1 <= buffer[1];
	out2 <= buffer[2];
	out3 <= buffer[3];
	out4 <= buffer[4];
	out5 <= buffer[5];
	out6 <= buffer[6];
	out7 <= buffer[7];
	out8 <= buffer[8];
	out9 <= buffer[9];
	out10 <= buffer[10];
	out11 <= buffer[11];
	out12 <= buffer[12];
	out13 <= buffer[13];
	out14 <= buffer[14];
	out15 <= buffer[15];
end

endmodule: demux4to16