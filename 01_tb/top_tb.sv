`timescale 1ns/1ns
module top_tb ();

// Samples - In-Out sources
localparam IN_PATH = "C:/intelFPGA_lite/Graduation/New_Cam_Chroma_133/20_sample/young_man_greenback.hex";
localparam LOG_PATH = "C:/intelFPGA_lite/Graduation/New_Cam_Chroma_133/22_outlog/output_log.txt";
//localparam OUT_PATH = "C:/intelFPGA_lite/Graduation/New_Cam_Chroma_133/21_outsample/young_man_greenback_chroma.hex";
integer file, outfile, status, logfile;
logic [3:0] frame_index;
string out_name;

// IOs ports of main module
// System
logic clk_i;
logic rst_ni;
logic sobel_i;
logic back_i;
logic chroma_i;
logic led_o;
logic locked;
logic done_uart;
logic [1:0] sel_i;
// Camera
logic cam_pclk;
logic cam_vsync;
logic cam_href;
logic [7:0] cam_data;
wire cam_siod;
logic cam_pwdw;
logic cam_sioc;
logic cam_reset;
logic cam_xclk;
// SDRAM
logic sdram_clk;
logic sdram_cke;
logic sdram_cs_n;
logic sdram_ras_n;
logic sdram_cas_n;
logic sdram_we_n;
logic [12:0] sdram_addr;
logic [1:0] sdram_bank;
logic [1:0] sdram_dqm;
wire [15:0] sdram_dq;
// VGA
logic vga_clk;
logic [7:0] vga_red;
logic [7:0] vga_green;
logic [7:0] vga_blue;
logic vga_hsync;
logic vga_vsync;
logic vga_blank_n;
logic vga_sync_n;

// Output testing
logic [15:0] data_i;

// Clock generator
// System clock
localparam CLK_50 = 20;
localparam HALF_CLK50 = 10;
always #HALF_CLK50 clk_i = ~clk_i;
// Pixel clock
localparam CLK24 = 42;
localparam HALF_CLK25 = 21;
always #HALF_CLK25 cam_pclk = ~cam_pclk;

// Sample generator
// Timing control
localparam t_p = CLK24;								// T_PCK = CLK_40
localparam t_pxl = t_p * 2;							// Double because RGB format
localparam t_line = t_pxl * 784;					// 784 * t_xpl
localparam t_rise_vsync = t_line * 3;
localparam t_vsync_href = t_line * 17;
localparam t_rise_href = t_pxl * 640;
localparam t_low_href = t_pxl * 144;
localparam t_end = t_line * 10;

// Generate random input value for camera
//always #t_p cam_data = $random & (32'h000000ff);

// Variables
int i, j;

logic [15:0] hex_data;

logic pixel_byte;

logic [8:0] vga_byte;
logic pre_blank;
logic first_frame;
logic dl_href, dl_vsync;

// DUT
// Main program
top top_dut
(
	// System
	.clk_i									(clk_i),
	.rst_ni									(rst_ni),
	.sobel_i									(sobel_i),
	.back_i									(back_i),
	.chroma_i								(chroma_i),
	.sel_i									(sel_i),
	.led_o									(led_o),
	.locked									(locked),
	.done_uart								(done_uart),
	// Camera
	.cam_pclk								(cam_pclk),
	.cam_vsync								(dl_vsync),
	.cam_href								(dl_href),
	.cam_data								(cam_data),
	.cam_siod								(cam_siod),
	.cam_pwdw								(cam_pwdw),
	.cam_sioc								(cam_sioc),
	.cam_reset								(cam_reset),
	.cam_xclk								(cam_xclk),
	// SDRAM
	.sdram_clk								(sdram_clk),
	.sdram_cke								(sdram_cke),
	.sdram_cs_n								(sdram_cs_n),
	.sdram_ras_n							(sdram_ras_n),
	.sdram_cas_n							(sdram_cas_n),
	.sdram_we_n								(sdram_we_n),
	.sdram_addr								(sdram_addr),
	.sdram_bank								(sdram_bank),
	.sdram_dqm								(sdram_dqm),
	.sdram_dq								(sdram_dq),
	// Output testing
	.data_i									(data_i),
	.first_frame							(first_frame),
	// VGA
	.vga_clk									(vga_clk),
	.vga_red									(vga_red),
	.vga_green								(vga_green),
	.vga_blue								(vga_blue),
	.vga_hsync								(vga_hsync),
	.vga_vsync								(vga_vsync),
	.vga_blank_n							(vga_blank_n),
	.vga_sync_n								(vga_sync_n)
);

// SDRAM Simulation model
// Old SDRAM (Datasheet)
// Rename new SDRAM

mt48lc32m16a2 sdram_simulation_model
(
	.Dq										(sdram_dq),
	.Addr										(sdram_addr),
	.Ba										(sdram_bank),
	.Clk										(sdram_clk),
	.Cke										(sdram_cke),
	.Cs_n										(sdram_cs_n),
	.Ras_n									(sdram_ras_n),
	.Cas_n									(sdram_cas_n),
	.We_n										(sdram_we_n),
	.Dqm										(sdram_dqm)
);

// Top design under testing
initial begin
	// Setting up the variables
	#0 clk_i = 0;
	cam_pclk = 0;
	rst_ni = 1;
	cam_href = 0;
	cam_vsync = 0;
	sobel_i = 0;
	// Trigger the initialization of camera if PLL is locked
	#200 if (locked) begin
		rst_ni = 0;
		#100 rst_ni = 1;
	end
	// If finishing the initialization of camera => Start read process of the camera
	// Generate href + vsync + Read image sample from hex file
	#27_500_000 if (led_o) begin
		for (i = 0; i < 100; i++) begin
			@(negedge cam_pclk);
			sel_i = i[1:0];
			cam_vsync = 1;
			#t_rise_vsync cam_vsync = 0;
			#t_vsync_href
			if (i == 0 || i == 3) begin
				for (j = 0; j < 478; j++) begin
					cam_href = 1;
					#t_rise_href cam_href = 0;
					#t_low_href;
				end
			end
			else begin
				for (j = 0; j < 479; j++) begin
					cam_href = 1;
					#t_rise_href cam_href = 0;
					#t_low_href;
				end
			end
			cam_href = 1;
			#t_rise_href cam_href = 0;
			#t_end;
			if (i == 4) begin
				$finish;
			end
		end
	end
//	#27_500_000 sel_i = 2'b00;
//	#32_000_000 sel_i = 2'b01;
//	#32_000_000 sel_i = 2'b10;
//	#32_000_000 sel_i = 2'b11;
//	#32_000_000 $finish;
end

initial begin
	#0 back_i = 0;
	chroma_i = 0;
	#30_000_000 back_i = 1;
	chroma_i = 1;
end

always @(posedge vga_clk) begin
	pre_blank <= vga_blank_n;
	vga_byte <= (vga_byte != 480) ? ((pre_blank & (~vga_blank_n)) + vga_byte) : 0;
end

always @(negedge cam_pclk) begin
	dl_href <= cam_href;
	dl_vsync <= cam_vsync;
end


// Infinity read the hex image
// RGB565 format image (convert from Python)
// Write 1 frame of image from VGA fifo
// Finish writing => stop the write hex file (output file)
// Compare between 2 pictures (2 hex file must be the same value)
// RGB565 in = RGB565 out at VGA output file
// Check the image in - out
initial begin
	// Open source file
	file = $fopen(IN_PATH, "r");
	if (file == 0) $error("Hex file not open");
	
	// Start load source file
	#28_000_000;
	pixel_byte = 1'b0;
	// Read HIGH -> LOW byte pixel data
	do begin
		@(negedge cam_pclk);
			if (cam_href) begin
				if (pixel_byte == 1'b0) begin
					status = $fscanf(file, "%h", hex_data);
					if (status == -1) begin
						$fseek(file, 0, 0);
						status = $fscanf(file, "%h", hex_data);
					end
					cam_data = hex_data[15:8];
					//cam_data = hex_data[15:8];
				end
				else begin
					cam_data = hex_data[7:0];
					//cam_data = hex_data[7:0];
				end
				pixel_byte <= pixel_byte + 1'b1;
			end
			else begin
				cam_data = 8'hzz;
			end
	end while (1);
end

initial begin
	logfile = $fopen(LOG_PATH, "w");
	if (logfile == 0) $error("Log file not open");
	
	// Open output file + Generate output file
	frame_index = 0;
	out_name = $sformatf("C:/intelFPGA_lite/Graduation/New_Cam_Chroma_133/21_outsample/young_man_%0d.hex", frame_index);
	outfile = $fopen(out_name, "w");
	if (outfile == 0) $error("Output file not open");
	
	#28_000_000;
	vga_byte = 9'b0;
	do begin			
		// Write output file from vga
		@(posedge vga_clk);
			if ((vga_byte < 9'd480) && first_frame) begin
				if (vga_blank_n) begin
					$fdisplay(outfile, "%h", data_i);
					$fdisplay(logfile, "Time = %0t | Frame = %0d | Pixel = %0d | Data = %h", $time, frame_index, vga_byte, data_i);
				end	 
			end
			else if (vga_byte > 9'd479) begin
				// Close files
				// Reset the counters
				vga_byte = 0;
				$fclose(outfile);
				frame_index = frame_index + 1;
				out_name = $sformatf("C:/intelFPGA_lite/Graduation/New_Cam_Chroma_133/21_outsample/young_man_%0d.hex", frame_index);
				outfile = $fopen(out_name, "w");
				if (outfile == 0) begin
					$error("Output file not open");
				end
			end
	end while (1);
end

endmodule: top_tb