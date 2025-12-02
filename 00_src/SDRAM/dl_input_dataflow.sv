// Just delay flags - not data
module dl_input_dataflow 
(
	// System
	input logic clk_i,
	input logic rst_ni,
	// Back FIFO
	input logic [11:0] data_cnt_back_i,
	output logic [11:0] data_cnt_back_o,
	// Back FIFO
	input logic [12:0] data_cnt_cam_i,
	output logic [12:0] data_cnt_cam_o,
	// Back FIFO
	input logic [11:0] data_cnt_vga_i,
	output logic [11:0] data_cnt_vga_o
);

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		data_cnt_back_o <= '0;
		data_cnt_cam_o <= '0;
		data_cnt_vga_o <= 12'd750;
	end
	else begin
		data_cnt_back_o <= data_cnt_back_i;
		data_cnt_cam_o <= data_cnt_cam_i;
		data_cnt_vga_o <= data_cnt_vga_i;
	end
end

endmodule: dl_input_dataflow