// Contains 2 modules: ov7670_registers and SCCB_interface
// Function: Init the OV7670 and communicate with the camera module
module ov7670_controller 
(
	// Input
	input logic clk_24mhz,				// System clock 50 MHz
	input logic rst_ni,					// Negative Reset button: KEY[0]
	// Inout
	inout siod_io,							// SCCB: SIOD - Serial data I/O data
	// Output
		// System
	output logic conf_led_o,			// Led: confirm that REGISTER CONFIGURATION DONE 
		// OV7670
	output logic pwdw_o,					// OV7670: PWDW - power down
	output logic sioc_o,					// OV7670: SIOC - Serial clock
	output logic reset_o,				// OV7670: RESET - Reset
	output logic xclk_o					// OV7670: XCLK - Master clock - 25 MHz
);

// Variables
logic send, busy;
logic rd_en, sccb_trans;
logic [15:0] reg_value;
logic [7:0] reg_i, value_i, id_i;

// OV7670 Registers
ov7670_registers regs_synth
(
	.clk_i									(clk_24mhz),
	.rst_ni									(rst_ni),
	.rd_en									(rd_en),
	.done_conf								(conf_led_o),
	.sccb_trans								(sccb_trans),
	.value_o									(reg_value)
);

// Configuration
ov7670_config config_synth
(
	.clk_i									(clk_24mhz),
	.rst_ni									(rst_ni),
	.rd_en									(rd_en),
	.sccb_trans								(sccb_trans),
	.reg_value_i							(reg_value),
	.busy										(busy),
	.send_o									(send),
	.id_o										(id_i),
	.reg_o									(reg_i),
	.value_o									(value_i)
);

sccb_interface sccb_synth
(
	.sys_clk_i								(clk_24mhz),
	.rst_ni									(rst_ni),
	.send_i									(send),
	.id_i										(id_i),
	.reg_i									(reg_i),
	.value_i									(value_i),
	.busy										(busy),
	.sioc										(sioc_o),
	.siod										(siod_io)
);

assign xclk_o = clk_24mhz;

// Initial values
initial begin
	reset_o = 1'b1;
	pwdw_o = 1'b0;
end

endmodule: ov7670_controller