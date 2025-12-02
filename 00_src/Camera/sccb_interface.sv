// This module use for SCCB interface
// In clock: 24MHz (Standard)
// Desire SIOC: 100 KHz (Stable - Basic setting)
// Fix the timing base on the time of the system clock
// Perfect timing
module sccb_interface 
(
	input logic sys_clk_i,
	input logic rst_ni,
	input logic send_i,
	input logic [7:0] id_i,
	input logic [7:0] reg_i,
	input logic [7:0] value_i,
	output logic busy,											// 1 => current in use, 0 => free
	output logic sioc,
	output logic siod
);

// Timing of interface (use numbers of cycle)
// 100 KHz <=> 10us
localparam t_clock = 8'd240;									// 24_000_000 / 100_000 = 240
localparam t_hclock = 8'd120;									// Half of 100 KMz from 24MHz
localparam t_tran = 8'd60;										// Transition time between SIOC and SIOD

logic [7:0] cnt_d, cnt_q;

// FSM
// 1 basic writing transmission of SCCB includes 3 phases
// ID Address -> Sub Address -> Write value

// Start of transmission
// SIOC = 1 			|				|	1 -> 0
// SIOD = 1				|	1 -> 0	|	

// 8 bit data + 1 don't care bit
// Only change the SIOD value when SIOC is LOW (middle of LOW)
//			____	  ____	 ____
// SIOC:		 ____		____	  ____
//					xxxxxxxx
// SIOD:	              yyyyyyyy

// End of transmission
// SIOC = 0				|	0 -> 1	|
// SIOD = 0				|				|	0 -> 1

// IDLE
localparam IDLE = 4'd0;
// Start of transmission
localparam START_TRANS = 4'd1;
// A PHASE
// Load the needed data for transmission phase
// ID - SubAddr - Value
localparam LOAD_DATA = 4'd2;

// 1 bit processing
// LOW SIOC (middle) => insert 1 bit
localparam BYTE_S1 = 4'd3;
// SIOC 0 -> 1
localparam BYTE_S2 = 4'd4;
// SIOC 1 -> 0
localparam BYTE_S3 = 4'd5;
// Load new bit at middle of next LOW SIOC
// Also check if whether 8 bit + 1 don't care bit have been transmitted
localparam BYTE_S4 = 4'd6;

// End of transmission
// SIOD = ??? -> 0
localparam END_S1 = 4'd7;
// SIOC 0 -> 1
localparam END_S2 = 4'd8;
// SIOD 0 -> 1
localparam END_S3 = 4'd9;

// TIMER
localparam TIMER = 4'd10;

// Operation

// Variable
logic [3:0] state_d, state_q;
logic [3:0] nxt_state_d, nxt_state_q;
logic sioc_oed, sioc_oeq;
logic siod_oed, siod_oeq;

logic [7:0] id_d, id_q;
logic [7:0] reg_d, reg_q;
logic [7:0] value_d, value_q;

logic [1:0] phase_d, phase_q;
logic [7:0] sccb_data_d, sccb_data_q;

logic [3:0] bit_cnt_d, bit_cnt_q;

logic busy_d, busy_q;


always @(posedge sys_clk_i or negedge rst_ni) begin
	if (!rst_ni) begin
		state_q <= IDLE;
		nxt_state_q <= 0;
		cnt_q <= 0;
		sioc_oeq <= 0;
		siod_oeq <= 0;
		id_q <= 0;
		reg_q <= 0;
		value_q <= 0;
		phase_q <= 0;
		sccb_data_q <= 0;
		bit_cnt_q <= 0;
		busy_q <= 1;
	end
	else begin
		state_q <= state_d;
		nxt_state_q <= nxt_state_d;
		cnt_q <= cnt_d;
		sioc_oeq <= sioc_oed;
		siod_oeq <= siod_oed;
		id_q <= id_d;
		reg_q <= reg_d;
		value_q <= value_d;
		phase_q <= phase_d;
		sccb_data_q <= sccb_data_d;
		bit_cnt_q <= bit_cnt_d;
		busy_q <= busy_d;
	end
end

always @* begin
	// Initial
	state_d = state_q;
	nxt_state_d = nxt_state_q;
	cnt_d = cnt_q;
	sioc_oed = sioc_oeq;
	siod_oed = siod_oeq;
	id_d = id_q;
	reg_d = reg_q;
	value_d = value_q;
	phase_d = phase_q;
	sccb_data_d = sccb_data_q;
	bit_cnt_d = bit_cnt_q;
	busy_d = busy_q;
	case (state_q)
		// Timer
		TIMER: begin
			cnt_d = (cnt_q == 0) ? 8'd0 : cnt_q - 8'd1;
			state_d = (cnt_q == 0) ? nxt_state_q : TIMER;
		end
		// Wait the send_i signal
		IDLE: begin
			sioc_oed = 1'b0;
			siod_oed = 1'b0;
		// If send_i = 1 => SIOD 1 -> 0
			if (send_i) begin
				state_d = TIMER;
				nxt_state_d = START_TRANS;
				sioc_oed = 1'b0;
				siod_oed = 1'b1;
				cnt_d = t_tran - 8'd2;
				busy_d = 1'b1;
				id_d = id_i;
				reg_d = reg_i;
				value_d = value_i;
			end
			else begin
				state_d = IDLE;
				busy_d = 1'b0;
			end
		end
		// SIOC 1 -> 0 (59 cycles | final for loading data)
		START_TRANS: begin
			state_d = TIMER;
			nxt_state_d = LOAD_DATA;
			sioc_oed = 1'b1;
			siod_oed = 1'b1;
			cnt_d = t_tran - 8'd3;								// For 59 cycles
			phase_d = 1'b0;
		end
		// Load the transmitted data for each phase (final cycle)
		LOAD_DATA: begin
			state_d = BYTE_S1;									// Only return to this if phase 1 - 2
			sccb_data_d = (phase_q[1]) ? (~value_q) : (phase_q[0] ? (~reg_q) : (~id_q));
			bit_cnt_d = 3'd0;
			sioc_oed = 1'b1;										// Not change the SIOD because don't care bit
		end
		// Data transmit (SIOD)
		BYTE_S1: begin
			state_d = TIMER;
			nxt_state_d = BYTE_S2;
			cnt_d = t_tran - 8'd2;
			// Don't care bit => 0
			siod_oed = (bit_cnt_q == 4'd8) ? 1'b1 : sccb_data_q[4'd7-bit_cnt_q];
		end
		// SIOC 0 -> 1
		BYTE_S2: begin
			state_d = TIMER;
			nxt_state_d = BYTE_S3;
			cnt_d = t_hclock - 8'd2;
			sioc_oed = 1'b0;
			bit_cnt_d = bit_cnt_q + 4'd1;
		end
		// SIOC 1 -> 0 (58 cycle)
		BYTE_S3: begin
			state_d = TIMER;
			nxt_state_d = BYTE_S4;
			cnt_d = t_tran - 8'd4;
			sioc_oed = 1'b1;
		end
		// Check the final bit condition to end if needed (CYCLE 59)
		BYTE_S4: begin
			if (bit_cnt_q < 4'd9) begin
				state_d = TIMER;
				nxt_state_d = BYTE_S1;
				cnt_d = 8'd0;
			end
			else begin
				phase_d = phase_q + 2'b1;
				bit_cnt_d = 4'd0;
				state_d = (phase_q == 2'b10) ? END_S1 : LOAD_DATA;
			end
		end
		// End of the transmission
		END_S1: begin
			state_d = TIMER;
			nxt_state_d = END_S2;
			cnt_d = t_tran - 8'd1;													// Not -1 cycle for this !!!
			// SIOC = SIOD = 0;
			sioc_oed = 1'b1;
			siod_oed = 1'b1;
		end
		// SIOC 0 -> 1
		END_S2: begin
			state_d = TIMER;
			nxt_state_d = END_S3;
			cnt_d = t_tran - 8'd2;
			sioc_oed = 1'b0;
		end
		// SIOD 0 > 1
		END_S3: begin
			state_d = TIMER;
			nxt_state_d = IDLE;
			cnt_d = t_clock - 8'd2;
			siod_oed = 1'b0;
		end
	endcase
end

assign sioc = (sioc_oeq) ? 1'b0 : 1'bz;
assign siod = (siod_oeq) ? 1'b0 : 1'bz;
assign busy = busy_q;

endmodule: sccb_interface