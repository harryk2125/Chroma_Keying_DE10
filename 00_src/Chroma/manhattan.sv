// Data delay 1 cycle with rd_cam_fifo signal
module manhattan 
(
	// System
	input logic clk_i,
	input logic rst_ni,
	// Chroma key
	input logic [23:0] rgb888,
	input logic rd_cam_fifo,
	input logic cam_frame_id,
	input logic frame_error,
	input logic fix_frame_done,
	// RAM 2 Ports
	output logic wr_en,
	output logic [19:0] wr_addr_chroma_o,
	output logic chroma_key_o			// 0 -> green (get background) | 1 -> not green (get foreground)
);

logic [7:0] red8, green8, blue8;

logic [7:0] dl_red, dl_blue, dl_green;

//logic signed [8:0] green_acc;

//logic [8:0] green_abs;

//logic [8:0] distance;

logic [9:0] hor_o, hor;
logic [8:0] ver_o, ver;
logic ram_bank_o, ram_bank;
logic chroma;

logic [8:0] red_margin, blue_margin;

logic dl_en0;
logic dl_en1;
logic dl_en2;
logic dl_en3;

// Manhattan

//always @(posedge clk_i or negedge rst_ni) begin
//	if (!rst_ni) begin
//		red8 <= 8'h0;
//		green8 <= 8'h0;
//		blue8 <= 8'h0;
//		dl_red <= 8'h0;
//		dl_blue <= 8'h0;
//		green_acc <= 9'h0;
//		distance <= 9'h0;
//		dl_en0 <= 1'b0;
//		dl_en1 <= 1'b0;
//		dl_en2 <= 1'b0;
//		dl_en3 <= 1'b0;
//	end
//	else begin
//		// En shifting
//		dl_en0 <= rd_cam_fifo;
//		// Stage 1
//		red8 <= rgb888[23:16];
//		green8 <= rgb888[15:8];
//		blue8 <= rgb888[7:0];
//		// Stage 2
//		dl_red <= red8;
//		dl_blue <= blue8;
//		green_acc <= green8 - 9'd255;
//		dl_en1 <= dl_en0;
//		// Stage 3
//		dl_en2 <= dl_en1;
//		distance <= dl_red + green_abs + dl_blue;
//		// Stage 4
//		dl_en3 <= dl_en2;
//	end
//end

// Color distance advance

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		red8 <= 8'h0;
		green8 <= 8'h0;
		blue8 <= 8'h0;
		red_margin <= 9'h0;
		blue_margin <= 9'h0;
		dl_green <= 8'h0;
		dl_en0 <= 1'b0;
		dl_en1 <= 1'b0;
		dl_en2 <= 1'b0;
		dl_en3 <= 1'b0;
	end
	else begin
		if (frame_error && rd_cam_fifo) begin
			// En shifting
			dl_en0 <= 0;
			// Stage 1 (Color)
			red8 <= 0;
			green8 <= 0;
			blue8 <= 0;
		end
		else begin
			// En shifting
			dl_en0 <= rd_cam_fifo;
			// Stage 1 (Color)
			red8 <= rgb888[23:16];
			green8 <= rgb888[15:8];
			blue8 <= rgb888[7:0];
		end
		// Stage 2 (Margin)
		dl_en1 <= dl_en0;
		red_margin <= red8 + 8'd30;
		blue_margin <= blue8 + 8'd30;
		dl_green <= green8;
		// Stage 3
		chroma <= !((dl_green > 8'd100) && (dl_green > red_margin) && (dl_green > blue_margin));
		dl_en2 <= dl_en1;
		// Stage 4
		dl_en3 <= dl_en2;
	end
end

always @(posedge clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		hor_o <= 0;
		ver_o <= 0;
		ram_bank_o <= 0;
	end
	else begin
		if (fix_frame_done) begin
			hor_o <= 0;
			ver_o <= 0;
			ram_bank_o <= cam_frame_id;
		end
		if (dl_en2) begin
			if (hor_o < 10'd639) begin
				hor_o <= hor_o + 10'd1;
			end
			else begin
				hor_o <= 10'd0;
				ver_o <= (ver_o < 9'd479) ? ver_o + 9'd1 : 9'd0;
				ram_bank_o <= (ver_o < 9'd479) ? ram_bank_o : ram_bank + 1'b1;
			end
		end
		hor <= hor_o;
		ver <= ver_o;
		ram_bank <= ram_bank_o;
	end
end

//assign green_abs = (green_acc[8]) ? (~green_acc + 1'b1) : green_acc;

//assign chroma_key_o = (distance < 9'd75) ? 1'b0 : 1'b1;

assign chroma_key_o = chroma;

assign wr_addr_chroma_o = {ram_bank, ver, hor};

// Because the delay 1 cycle of rd_cam_fifo with data
// Color => 3 (fix, default 2) | Distance => 3
assign wr_en = dl_en3;

endmodule: manhattan