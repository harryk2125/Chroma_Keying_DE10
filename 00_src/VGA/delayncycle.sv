module delayncycle 
#(
	parameter DATA_WD = 16,
	parameter N_CYCLE = 3
)
(
	input logic clk_i,
	input logic rst_ni,
	input logic [DATA_WD-1:0] data_i,
	output logic [DATA_WD-1:0] data_o
);

logic [DATA_WD-1:0] buffer [0:N_CYCLE-1];

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		data_o <= '0;
	end
	else begin
		buffer[0] <= data_i;
		for (int i = 1; i < N_CYCLE; i++) begin
			buffer[i] <= buffer[i-1];
		end
		data_o <= buffer[N_CYCLE-1];
	end
end

endmodule: delayncycle