module uart_fake_back
(
	input logic clk_i,
	input logic rst_ni,
	input logic back_i,
	output logic done_uart,
	output logic wr_en,
	output logic [15:0] data_o
);

// 8 basic colors
localparam BLACK = 16'h0000;
localparam WHITE = 16'hffff;
localparam RED = 16'hf800;
localparam GREEN = 16'h07e0;
localparam BLUE = 16'h001f;
localparam YELLOW = 16'hffe0;
localparam PURPLE = 16'hf81f;
localparam CYAN = 16'h07ff;

localparam MAX_ADDR = 19'd307_200;

logic [18:0] counter;

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		counter <= 19'd0;
		wr_en <= 1'b0;
		data_o <= BLACK;
		done_uart <= 1'b0;
	end
	else if (back_i) begin
		if (counter < MAX_ADDR) begin
			counter <= counter + 19'd1;
			wr_en <= 1'b1;
			data_o <= WHITE;
			done_uart <= 1'b0;
		end
		else begin
			wr_en <= 1'b0;
			data_o <= BLACK;
			done_uart <= 1'b1;
		end
	end
	else begin
		counter <= 19'd0;
		wr_en <= 1'b0;
		data_o <= BLACK;
		done_uart <= 1'b0;
	end
end

endmodule: uart_fake_back