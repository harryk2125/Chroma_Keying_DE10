module ov7670_config 
(
	// System
	input logic clk_i,
	input logic rst_ni,											// Negative reset <=> Config signal
	// Regs
	output logic rd_en,
	input logic sccb_trans,
	//input logic done_conf,
	input logic [15:0] reg_value_i,
	// SCCB Interface
	input logic busy,
	output logic send_o,
	output logic [7:0] id_o,
	output logic [7:0] reg_o,
	output logic [7:0] value_o
);

// Localparam
localparam ID = 8'h42;
localparam t_1ms = 19'd24_000;

logic [18:0] cnt;

logic dl_1ms;
logic end_transmit;
logic [1:0] trigger;

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		rd_en = 0;
		trigger = 2'b11;
	end
	else begin
		if (!busy) begin
			if (end_transmit || dl_1ms) begin
				rd_en = 0;
				trigger = 2'b11;
			end
			else if (trigger == 2'b11) begin
				rd_en = 1;
				trigger = 2'b00;
			end
			else begin
				rd_en = 0;
				trigger = trigger + 2'b1;
			end
		end
		else rd_en = 0;
	end
end

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		send_o = 0;
		id_o = 0;
		reg_o = 0;
		value_o = 0;
		cnt = t_1ms;
		end_transmit = 0;
	end
	else begin
		if (sccb_trans) begin
			if (end_transmit) begin
				send_o = 0;
				id_o = 0;
				reg_o = 0;
				value_o = 0;
			end
			else if (reg_value_i == 16'hff_f0) begin
				send_o = 0;
				id_o = 0;
				reg_o = 0;
				value_o = 0;
				cnt = 8'd0;
				end_transmit = 0;
			end
			else if (reg_value_i == 16'hff_ff) begin
				send_o = 0;
				id_o = 0;
				reg_o = 0;
				value_o = 0;
				end_transmit = 1;
			end
			else begin
				send_o = 1;
				id_o = ID;
				reg_o = reg_value_i[15:8];
				value_o = reg_value_i[7:0];
				end_transmit = 0;
			end
		end
		else begin
			send_o = 0;
			id_o = 0;
			reg_o = 0;
			value_o = 0;
		end
		if (cnt < t_1ms) begin
			cnt = cnt + 19'd1;
			send_o = 0;
			id_o = 0;
			reg_o = 0;
			value_o = 0;
			end_transmit = 0;
		end
	end
end

assign dl_1ms = (cnt < t_1ms) ? 1'b1 : 1'b0;		// Counting

endmodule: ov7670_config