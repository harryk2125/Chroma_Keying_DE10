module ov7670_registers
(	
	// System
	input logic clk_i,
	input logic rst_ni,
	// Flag
	input logic rd_en,
	output logic done_conf,
	// Output
	output logic sccb_trans,
	output logic [15:0] value_o
);

// Regisiter path (load hex file)
// True path = "C:/intelFPGA_lite/Sub_Graduation/Camera/ov7670/reg_data.hex";
localparam hex_path = "C:/intelFPGA_lite/Graduation/New_Cam_Chroma_133/09_ov7670/reg_data.hex";

// Max value of hex file
localparam HEX_DEPTH = 8'd84;
logic [15:0] svalue [HEX_DEPTH-1:0];

localparam HEX_ADDR_WD = $clog2(HEX_DEPTH);				// => 5.xxx => 6
(* romstyle = "logic" *) logic [0:HEX_ADDR_WD] hex_counter;

// Load hex file
//integer file;

initial begin
	// Just for simulation
//	file = $fopen("hex_path", r);
//	if (file == 0) begin
//		$fatal(1, "ERROR: cannot open hex file");
//	end
//	$fclose(file);
	$readmemh(hex_path, svalue);
end

// Read hex file
always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		value_o <= 16'hxxxx;
		hex_counter <= 0;
		done_conf <= 0;
		sccb_trans <= 0;
	end
	else begin
		if (rd_en) begin
			sccb_trans <= 1;
			value_o <= svalue[hex_counter];
			hex_counter <= (hex_counter < HEX_DEPTH) ? hex_counter + 7'd1 : hex_counter;
		end
		else begin
			sccb_trans <= 0;
			value_o <= 16'hxxxx;
			hex_counter <= hex_counter;
		end
		done_conf <= (hex_counter == HEX_DEPTH) ? 1'b1 : 1'b0;
	end
end

endmodule: ov7670_registers