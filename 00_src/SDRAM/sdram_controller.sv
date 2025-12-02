// Author: Harry Nguyen
// Date: 28/07/2025
// Using for IS42S16320F-7TL (DE10 Standard)
// Operates as 256 (full-page bursting likely 16400F version in DE2)
// Apply WRITE to WRITE and READ to READ operation
// Final Version
module sdram_controller 
#(
	parameter DATA_WD = 16,
	parameter ROW_WD = 13,
	parameter BANK_WD = 2
)
(
	// System
	input logic sd_clk,
	input logic rst_ni,
	// SDRAM dataflow
	input logic rw_i,
	input logic rw_en_i,
	input logic [BANK_WD+ROW_WD+1:0] addr_i,				// {row, col[9:8], bank, col[7:0]} - eliminate col[7:0]
	input logic [DATA_WD-1:0] data_i,
	output logic ready,
	output logic sd_data_valid,
	output logic fpga_data_valid,
	output logic [DATA_WD-1:0] data_o,
	// SDRAM
	output logic sdram_clk,
	output logic sdram_cke,
	output logic sdram_cs_n,
	output logic sdram_ras_n,
	output logic sdram_cas_n,
	output logic sdram_we_n,
	output logic [ROW_WD-1:0] sdram_addr,
	output logic [BANK_WD-1:0] sdram_bank,
	output logic [1:0] sdram_dqm,
	inout [15:0] sdram_dq
);

// FSM
logic [3:0] state_d, state_q;
logic [3:0] nxt_state_d, nxt_state_q;
// Initial phase
localparam START = 4'd0;
localparam PRECHARGE_INIT = 4'd1;
localparam AUTO_REFRESH1 = 4'd2;
localparam AUTO_REFRESH2 = 4'd3;
localparam LOAD_MODE_REG = 4'd4;
// WRITE + READ
localparam IDLE = 4'd5;									
localparam READ = 4'd6;
localparam READ_DATA = 4'd7;
localparam READ_BURST = 4'd8;
localparam WRITE = 4'd9;
localparam WRITE_DATA = 4'd10;
localparam WRITE_BURST = 4'd11;
localparam WAIT_WRITE = 4'd12;
// Refresh every 7.8us
localparam REFRESH = 4'd13;
// COUNTDOWN
localparam COUNTDOWN = 4'd14;

// Timing (PC133 - CL2 - burst length 8 (burst length 256 version))
// Scale for 1 cycle = 7.52ns
localparam t_PW = 15'd26_596;									// Power up (Before first PRE)	
localparam t_RP = 15'd2;										// Precharge (15ns) -> 2
localparam t_RC = 15'd8;										// Refresh (60) -> 8
localparam t_MDR = 15'd2;										// Mode set reg (14) -> 2
localparam t_RCD = 15'd2;										// ACT -> WR/RD (15) -> 2
localparam t_CL = 15'd2;										// CAS Latency (3 cycles)
localparam t_DPL = 15'd2;										// Data (in) to Precharge (14) -> 2
localparam t_FPRE = 15'd1_000;								// Forced refresh every 7.8us (get the lower value for stable reason)

logic [14:0] cnt_d, cnt_q;
logic [10:0] ref_cnt_d, ref_cnt_q;
logic ref_flag_d, ref_flag_q;

// Command
// Not using AUTO PRECHARGE
localparam cmd_NOP = 4'b0111;									// NOP
localparam cmd_READ = 4'b0101;								// READ
localparam cmd_WRITE = 4'b0100;								// WRITE
localparam cmd_ACT = 4'b0011;									// ACTIVE
localparam cmd_PRE = 4'b0010;									// PRECHARGE
localparam cmd_REF = 4'b0001;									// REFRESH
localparam cmd_MSR = 4'b0000;									// MODE SET REGISTER

logic [3:0] cmd_d, cmd_q;

// Variables
logic [16:0] addr_d, addr_q;
logic rw_en_d, rw_en_q;
logic rw_id, rw_iq;
logic [12:0] sd_addr_d, sd_addr_q;
logic [1:0] sd_bank_d, sd_bank_q;
logic sd_data_valid_q, sd_data_valid_d;
logic fpga_data_valid_q, fpga_data_valid_d;
logic [2:0] bit_cnt_d, bit_cnt_q;
logic [5:0] burst_cnt_d, burst_cnt_q;
logic [DATA_WD-1:0] data_id, data_iq;
logic [DATA_WD-1:0] data_od, data_odl, data_oq;
logic end_burst_d, end_burst_q;
logic tri_state_d, tri_state_q;

// Generate the delay 180 degree from the system clock (timing clock purpose)
oddr2 delay180
(
	.d0		(1'b0),
	.d1		(1'b1),
	.c0		(sd_clk),
	.c1		(~sd_clk),
	.ce		(1'b1),
	.r			(1'b0),
	.s			(1'b0),
	.q			(sdram_clk)
);

// D-FF operation for signals

always @(posedge sd_clk or negedge rst_ni) begin
	if (!rst_ni) begin
		state_q <= START;
		nxt_state_q <= START;
		cnt_q <= '0;
		cmd_q <= cmd_NOP;
		ref_cnt_q <= '0;
		addr_q <= '0;
		rw_en_q <= '0;
		rw_iq <= '0;
		sd_addr_q <= '0;
		sd_bank_q <= '0;
		sd_data_valid_q <= 0;
		fpga_data_valid_q <= 0;
		end_burst_q <= 0;
		tri_state_q <= 0;
		ref_flag_q <= 0;
		bit_cnt_q <= 0;
		burst_cnt_q <= 0;
		data_iq <= 0;
		data_oq <= 0;
	end
	else begin
		state_q <= state_d;
		nxt_state_q <= nxt_state_d;
		cnt_q <= cnt_d;
		cmd_q <= cmd_d;
		ref_cnt_q <= ref_cnt_d;
		addr_q <= addr_d;
		rw_en_q <= rw_en_d;
		rw_iq <= rw_id;
		sd_addr_q <= sd_addr_d;
		sd_bank_q <= sd_bank_d;
		sd_data_valid_q <= sd_data_valid_d;
		fpga_data_valid_q <= fpga_data_valid_d;
		end_burst_q <= end_burst_d;
		tri_state_q <= tri_state_d;
		ref_flag_q <= ref_flag_d;
		bit_cnt_q <= bit_cnt_d;
		burst_cnt_q <= burst_cnt_d;
		data_iq <= data_id;
		data_oq <= data_odl;
	end
end

always @(posedge sdram_clk or negedge rst_ni) begin
	if (!rst_ni) begin
		data_odl <= 0;
	end
	else begin
		data_odl <= data_od;
	end
end

// SDRAM operatio FSM
always @* begin
	state_d = state_q;
	nxt_state_d = nxt_state_q;
	cnt_d = cnt_q;
	cmd_d = cmd_NOP;										// Always NOP (default)
	ready = 0;
	addr_d = addr_q;
	rw_en_d = rw_en_q;
	rw_id = rw_iq;
	sd_addr_d = sd_addr_q;
	sd_bank_d = sd_bank_q;
	fpga_data_valid_d = fpga_data_valid_q;
	sd_data_valid_d = sd_data_valid_q;
	end_burst_d = end_burst_q;
	tri_state_d = tri_state_q;
	ref_flag_d = ref_flag_q;
	bit_cnt_d = bit_cnt_q;
	burst_cnt_d = burst_cnt_q;
	data_id = data_iq;
	data_od = data_oq;
	
	// Auto refresh COUNTER
	ref_cnt_d = ref_cnt_q + 11'd1;
	if (ref_cnt_q == t_FPRE - 11'd1) begin
		ref_flag_d = 1;
	end
	
	// FSM
	case (state_q)
		// COUNTDOWN
		COUNTDOWN: begin
			cnt_d = (cnt_q == 0) ? 15'd0 : cnt_q - 15'd1;
			state_d = (cnt_q == 0) ? nxt_state_q : COUNTDOWN;
			if (nxt_state_q == WRITE) begin
				tri_state_d = 1;
			end
		end
		// Initial SDRAM
		// Start: wait about 100-200us after power up
		START: begin
			state_d = COUNTDOWN;
			nxt_state_d = PRECHARGE_INIT;
			cnt_d = t_PW - 15'd2;
		end
		// Prechage INITIAL
		PRECHARGE_INIT: begin
			state_d = COUNTDOWN;
			nxt_state_d = AUTO_REFRESH1;
			cnt_d = t_RP - 15'd2;
			sd_addr_d[10] = 1;
			cmd_d = cmd_PRE;
		end
		// AUTO REFRESH 1
		AUTO_REFRESH1: begin
			state_d = COUNTDOWN;
			nxt_state_d = AUTO_REFRESH2;
			cnt_d = t_RC - 15'd2;
			cmd_d = cmd_REF;
		end
		// AUTO REFRESH 2
		AUTO_REFRESH2: begin
			state_d = COUNTDOWN;
			nxt_state_d = LOAD_MODE_REG;
			cnt_d = t_RC - 15'd2;
			cmd_d = cmd_REF;
		end
		// LOAD MODE REGISTER
		LOAD_MODE_REG: begin
			state_d = COUNTDOWN;
			nxt_state_d = IDLE;
			cnt_d = t_MDR - 15'd2;
			cmd_d = cmd_MSR;
			sd_addr_d = 13'b000_0_00_010_0_011;
			// Reserved_ProgrammedBurstLength_Standard_CL2_Sequenced_BurstLength8
			sd_bank_d = 2'd0; 											// Reserved
		end
		// MAIN OPERATION
		// IDLE (WRITE/READ/AUTO_REFRESH)
		IDLE: begin
			ready = (rw_en_q) ? 1'b0 : 1'b1;
			if (rw_en_q) begin
				state_d = COUNTDOWN;
				nxt_state_d = (rw_iq) ? READ : WRITE;
				cnt_d = t_RCD - 15'd2;
				rw_en_d = 0;
				cmd_d = cmd_ACT;
				sd_addr_d = addr_d[ROW_WD+BANK_WD+1:BANK_WD+2];				// Row address
				sd_bank_d = addr_d[BANK_WD-1:0];									// Bank address
				bit_cnt_d = '0;
			end
			else if (ref_flag_q | rw_en_i) begin
				state_d = COUNTDOWN;
				nxt_state_d = REFRESH;
				cmd_d = cmd_PRE;
				cnt_d = t_RP - 15'd2;
				ref_flag_d = 0;
				sd_addr_d[10] = 1;
				if (rw_en_i) begin
					rw_en_d = rw_en_i;
					rw_id = rw_i;
					addr_d = addr_i;
				end
			end
		end
		REFRESH: begin
			state_d = COUNTDOWN;
			nxt_state_d = IDLE;
			cmd_d = cmd_REF;
			cnt_d = t_RC - 15'd2;
			ref_cnt_d = '0;
		end
		READ: begin
			state_d = COUNTDOWN;
			nxt_state_d = READ_DATA;
			cmd_d = cmd_READ;
			cnt_d = t_CL - 15'd1;															// CAS Latency = 2
			sd_addr_d = {1'b0, addr_d[BANK_WD+1:BANK_WD], 8'd0};					// Column address (No auto prechage)
			bit_cnt_d = '0;
			burst_cnt_d = '0;
		end
		READ_DATA: begin	// Checking read condition
			state_d = (bit_cnt_q == 3'd4) ? READ_BURST : READ_DATA;
			sd_data_valid_d = 1;
			bit_cnt_d = bit_cnt_q + 1'b1;
			data_od = sdram_dq;
		end
		READ_BURST: begin // Send READ command
			bit_cnt_d = bit_cnt_q + 1'b1;
			data_od = sdram_dq;
			if (burst_cnt_q != 6'd31) begin
				state_d = READ_DATA;
				cmd_d = cmd_READ;
				sd_addr_d = sd_addr_q + 11'd8;
				sd_data_valid_d = 1;
				burst_cnt_d = burst_cnt_q + 6'd1;
			end
			else begin
				state_d = (bit_cnt_q == 3'd0) ? IDLE : READ_BURST;
				cmd_d = (bit_cnt_q == 3'd5) ? cmd_PRE : cmd_NOP;
				sd_addr_d = sd_addr_q;
				sd_data_valid_d = (bit_cnt_q == 3'd0) ? 1'b0 : 1'b1;
				burst_cnt_d = burst_cnt_q;
			end
		end
		WRITE: begin // First write
			state_d = WRITE_DATA;
			cmd_d = cmd_WRITE;
			data_id = data_i;
			sd_addr_d = {1'b0, addr_d[BANK_WD+1:BANK_WD], 8'd0};
			fpga_data_valid_d = 1;
			tri_state_d = 1;
			bit_cnt_d = bit_cnt_q + 3'd1;
			burst_cnt_d = '0;
		end
		WRITE_DATA: begin // Check write condition
			state_d = (bit_cnt_q == 3'd7) ? WRITE_BURST : WRITE_DATA;
			fpga_data_valid_d = (bit_cnt_q > 3'd6 && burst_cnt_q == 6'd31) ? 1'b0 : 1'b1;
			bit_cnt_d = (bit_cnt_q == 3'd7 && burst_cnt_q == 6'd31) ? bit_cnt_q : bit_cnt_q + 1'b1;
			data_id = data_i;
		end
		WRITE_BURST: begin // Send write command
			data_id = data_i;
			if (burst_cnt_q != 6'd31) begin
				bit_cnt_d = bit_cnt_q + 1'b1;
				state_d = WRITE_DATA;
				cmd_d = cmd_WRITE;
				sd_addr_d = sd_addr_q + 11'd8;
				fpga_data_valid_d = 1;
				burst_cnt_d = burst_cnt_q + 6'd1;
			end
			else begin
				state_d = COUNTDOWN;
				nxt_state_d = WAIT_WRITE;
				sd_addr_d = sd_addr_q;
				fpga_data_valid_d = 1'b0;
				burst_cnt_d = burst_cnt_q;
				cnt_d = t_DPL - 15'd2;
				tri_state_d = 0;
				end_burst_d = 1;
			end
		end
		WAIT_WRITE: begin // Recovery write timing
			state_d = COUNTDOWN;
			nxt_state_d = IDLE;
			cnt_d = t_RP - 15'd2;
			cmd_d = cmd_PRE;
			end_burst_d = 0;
		end
	endcase
end

logic [1:0] dqm_cnt;

always @(posedge sd_clk) begin
	if (end_burst_d == 1) begin
		dqm_cnt = 0;
	end
	if (dqm_cnt <= 2'b10) begin
		sdram_dqm = 2'b11;
		dqm_cnt = dqm_cnt + 2'b1;
	end
	else begin
		sdram_dqm = 2'b00;
	end
end

assign {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} = cmd_q;
assign sdram_cke = 1'b1;
assign sdram_addr = sd_addr_q;
assign sdram_bank = sd_bank_q;
assign sdram_dq = tri_state_q ? data_iq : 16'hzzzz;
assign data_o = data_oq;
assign sd_data_valid = sd_data_valid_q;
assign fpga_data_valid = fpga_data_valid_d;					// 1 cycle before data from FIFO - Change to q just for visualize

endmodule: sdram_controller