// 2 port RAM buffer
// R_en_i == rd_vga_fifo
// Data out of this buffer: final mask (use for mux)
module ram2port_final
#(
	parameter DATA_WD = 1,
	parameter ADDR_WD = 20
)
(
	// Input
	input logic wclk_i,
	input logic rclk_i,
	// To RAM
	input logic [DATA_WD-1:0] data_i,
	input logic [ADDR_WD-1:0] waddr_i,
	input logic [ADDR_WD-1:0] raddr_i,
	input logic w_en_i,
	input logic r_en_i,
	// Output
	output logic [DATA_WD-1:0] data_o
);

// Address assignment: {bank, row, col}
logic [15:0] waddr0, waddr1, waddr2, waddr3;
logic [15:0] waddr4, waddr5, waddr6, waddr7;
logic [15:0] waddr8, waddr9, waddr10, waddr11;
logic [15:0] waddr12, waddr13, waddr14, waddr15;

logic [15:0] raddr0, raddr1, raddr2, raddr3;
logic [15:0] raddr4, raddr5, raddr6, raddr7;
logic [15:0] raddr8, raddr9, raddr10, raddr11;
logic [15:0] raddr12, raddr13, raddr14, raddr15;

logic [DATA_WD-1:0] idata0, idata1, idata2, idata3;
logic [DATA_WD-1:0] idata4, idata5, idata6, idata7;
logic [DATA_WD-1:0] idata8, idata9, idata10, idata11;
logic [DATA_WD-1:0] idata12, idata13, idata14, idata15;

logic [DATA_WD-1:0] odata0, odata1, odata2, odata3;
logic [DATA_WD-1:0] odata4, odata5, odata6, odata7;
logic [DATA_WD-1:0] odata8, odata9, odata10, odata11;
logic [DATA_WD-1:0] odata12, odata13, odata14, odata15;

logic w_en0, w_en1, w_en2, w_en3;
logic w_en4, w_en5, w_en6, w_en7;
logic w_en8, w_en9, w_en10, w_en11;
logic w_en12, w_en13, w_en14, w_en15;

logic r_en0, r_en1, r_en2, r_en3;
logic r_en4, r_en5, r_en6, r_en7;
logic r_en8, r_en9, r_en10, r_en11;
logic r_en12, r_en13, r_en14, r_en15;

demux4to16
#(
	.DATA_WD										(16)
)
waddr_demux 
(
	.clk_i										(wclk_i),
	.sel_i										(waddr_i[19:16]),
	.data_i										(waddr_i[15:0]),
	.out0											(waddr0),
	.out1											(waddr1),
	.out2											(waddr2),
	.out3											(waddr3),
	.out4											(waddr4),
	.out5											(waddr5),
	.out6											(waddr6),
	.out7											(waddr7),
	.out8											(waddr8),
	.out9											(waddr9),
	.out10										(waddr10),
	.out11										(waddr11),
	.out12										(waddr12),
	.out13										(waddr13),
	.out14										(waddr14),
	.out15										(waddr15)
);

demux4to16
#(
	.DATA_WD										(16)
)
raddr_demux 
(
	.clk_i										(rclk_i),
	.sel_i										(raddr_i[19:16]),
	.data_i										(raddr_i[15:0]),
	.out0											(raddr0),
	.out1											(raddr1),
	.out2											(raddr2),
	.out3											(raddr3),
	.out4											(raddr4),
	.out5											(raddr5),
	.out6											(raddr6),
	.out7											(raddr7),
	.out8											(raddr8),
	.out9											(raddr9),
	.out10										(raddr10),
	.out11										(raddr11),
	.out12										(raddr12),
	.out13										(raddr13),
	.out14										(raddr14),
	.out15										(raddr15)
);

demux4to16
#(
	.DATA_WD										(DATA_WD)
)
data_i_demux 
(
	.clk_i										(wclk_i),
	.sel_i										(waddr_i[19:16]),
	.data_i										(data_i),
	.out0											(idata0),
	.out1											(idata1),
	.out2											(idata2),
	.out3											(idata3),
	.out4											(idata4),
	.out5											(idata5),
	.out6											(idata6),
	.out7											(idata7),
	.out8											(idata8),
	.out9											(idata9),
	.out10										(idata10),
	.out11										(idata11),
	.out12										(idata12),
	.out13										(idata13),
	.out14										(idata14),
	.out15										(idata15)
);

demux4to16
#(
	.DATA_WD										(1)
)
wen_demux 
(
	.clk_i										(wclk_i),
	.sel_i										(waddr_i[19:16]),
	.data_i										(w_en_i),
	.out0											(w_en0),
	.out1											(w_en1),
	.out2											(w_en2),
	.out3											(w_en3),
	.out4											(w_en4),
	.out5											(w_en5),
	.out6											(w_en6),
	.out7											(w_en7),
	.out8											(w_en8),
	.out9											(w_en9),
	.out10										(w_en10),
	.out11										(w_en11),
	.out12										(w_en12),
	.out13										(w_en13),
	.out14										(w_en14),
	.out15										(w_en15)
);

demux4to16
#(
	.DATA_WD										(1)
)
ren_demux 
(
	.clk_i										(rclk_i),
	.sel_i										(raddr_i[19:16]),
	.data_i										(r_en_i),
	.out0											(r_en0),
	.out1											(r_en1),
	.out2											(r_en2),
	.out3											(r_en3),
	.out4											(r_en4),
	.out5											(r_en5),
	.out6											(r_en6),
	.out7											(r_en7),
	.out8											(r_en8),
	.out9											(r_en9),
	.out10										(r_en10),
	.out11										(r_en11),
	.out12										(r_en12),
	.out13										(r_en13),
	.out14										(r_en14),
	.out15										(r_en15)
);

ram2port_addr16bit
#(
    .DATA_WD    (DATA_WD),
    .ADDR_WD    (16)
)
ram_sel0
(
    .wclk_i     (wclk_i),
    .rclk_i     (rclk_i),
    .data_i     (idata0),
    .waddr_i    (waddr0),
    .raddr_i    (raddr0),
    .w_en_i     (w_en0),
    .r_en_i     (r_en0),
    .data_o     (odata0)
);

ram2port_addr16bit
#(
    .DATA_WD    (DATA_WD),
    .ADDR_WD    (16)
)
ram_sel1
(
    .wclk_i     (wclk_i),
    .rclk_i     (rclk_i),
    .data_i     (idata1),
    .waddr_i    (waddr1),
    .raddr_i    (raddr1),
    .w_en_i     (w_en1),
    .r_en_i     (r_en1),
    .data_o     (odata1)
);

ram2port_addr16bit
#(
    .DATA_WD    (DATA_WD),
    .ADDR_WD    (16)
)
ram_sel2
(
    .wclk_i     (wclk_i),
    .rclk_i     (rclk_i),
    .data_i     (idata2),
    .waddr_i    (waddr2),
    .raddr_i    (raddr2),
    .w_en_i     (w_en2),
    .r_en_i     (r_en2),
    .data_o     (odata2)
);

ram2port_addr16bit
#(
    .DATA_WD    (DATA_WD),
    .ADDR_WD    (16)
)
ram_sel3
(
    .wclk_i     (wclk_i),
    .rclk_i     (rclk_i),
    .data_i     (idata3),
    .waddr_i    (waddr3),
    .raddr_i    (raddr3),
    .w_en_i     (w_en3),
    .r_en_i     (r_en3),
    .data_o     (odata3)
);

ram2port_addr16bit
#(
    .DATA_WD    (DATA_WD),
    .ADDR_WD    (16)
)
ram_sel4
(
    .wclk_i     (wclk_i),
    .rclk_i     (rclk_i),
    .data_i     (idata4),
    .waddr_i    (waddr4),
    .raddr_i    (raddr4),
    .w_en_i     (w_en4),
    .r_en_i     (r_en4),
    .data_o     (odata4)
);

ram2port_addr16bit
#(
    .DATA_WD    (DATA_WD),
    .ADDR_WD    (16)
)
ram_sel5
(
    .wclk_i     (wclk_i),
    .rclk_i     (rclk_i),
    .data_i     (idata5),
    .waddr_i    (waddr5),
    .raddr_i    (raddr5),
    .w_en_i     (w_en5),
    .r_en_i     (r_en5),
    .data_o     (odata5)
);

ram2port_addr16bit
#(
    .DATA_WD    (DATA_WD),
    .ADDR_WD    (16)
)
ram_sel6
(
    .wclk_i     (wclk_i),
    .rclk_i     (rclk_i),
    .data_i     (idata6),
    .waddr_i    (waddr6),
    .raddr_i    (raddr6),
    .w_en_i     (w_en6),
    .r_en_i     (r_en6),
    .data_o     (odata6)
);

ram2port_addr16bit
#(
    .DATA_WD    (DATA_WD),
    .ADDR_WD    (16)
)
ram_sel7
(
    .wclk_i     (wclk_i),
    .rclk_i     (rclk_i),
    .data_i     (idata7),
    .waddr_i    (waddr7),
    .raddr_i    (raddr7),
    .w_en_i     (w_en7),
    .r_en_i     (r_en7),
    .data_o     (odata7)
);

ram2port_addr16bit
#(
    .DATA_WD    (DATA_WD),
    .ADDR_WD    (16)
)
ram_sel8
(
    .wclk_i     (wclk_i),
    .rclk_i     (rclk_i),
    .data_i     (idata8),
    .waddr_i    (waddr8),
    .raddr_i    (raddr8),
    .w_en_i     (w_en8),
    .r_en_i     (r_en8),
    .data_o     (odata8)
);

ram2port_addr16bit
#(
    .DATA_WD    (DATA_WD),
    .ADDR_WD    (16)
)
ram_sel9
(
    .wclk_i     (wclk_i),
    .rclk_i     (rclk_i),
    .data_i     (idata9),
    .waddr_i    (waddr9),
    .raddr_i    (raddr9),
    .w_en_i     (w_en9),
    .r_en_i     (r_en9),
    .data_o     (odata9)
);

ram2port_addr16bit
#(
    .DATA_WD    (DATA_WD),
    .ADDR_WD    (16)
)
ram_sel10
(
    .wclk_i     (wclk_i),
    .rclk_i     (rclk_i),
    .data_i     (idata10),
    .waddr_i    (waddr10),
    .raddr_i    (raddr10),
    .w_en_i     (w_en10),
    .r_en_i     (r_en10),
    .data_o     (odata10)
);

ram2port_addr16bit
#(
    .DATA_WD    (DATA_WD),
    .ADDR_WD    (16)
)
ram_sel11
(
    .wclk_i     (wclk_i),
    .rclk_i     (rclk_i),
    .data_i     (idata11),
    .waddr_i    (waddr11),
    .raddr_i    (raddr11),
    .w_en_i     (w_en11),
    .r_en_i     (r_en11),
    .data_o     (odata11)
);

ram2port_addr16bit
#(
    .DATA_WD    (DATA_WD),
    .ADDR_WD    (16)
)
ram_sel12
(
    .wclk_i     (wclk_i),
    .rclk_i     (rclk_i),
    .data_i     (idata12),
    .waddr_i    (waddr12),
    .raddr_i    (raddr12),
    .w_en_i     (w_en12),
    .r_en_i     (r_en12),
    .data_o     (odata12)
);

ram2port_addr16bit
#(
    .DATA_WD    (DATA_WD),
    .ADDR_WD    (16)
)
ram_sel13
(
    .wclk_i     (wclk_i),
    .rclk_i     (rclk_i),
    .data_i     (idata13),
    .waddr_i    (waddr13),
    .raddr_i    (raddr13),
    .w_en_i     (w_en13),
    .r_en_i     (r_en13),
    .data_o     (odata13)
);

ram2port_addr16bit
#(
    .DATA_WD    (DATA_WD),
    .ADDR_WD    (16)
)
ram_sel14
(
    .wclk_i     (wclk_i),
    .rclk_i     (rclk_i),
    .data_i     (idata14),
    .waddr_i    (waddr14),
    .raddr_i    (raddr14),
    .w_en_i     (w_en14),
    .r_en_i     (r_en14),
    .data_o     (odata14)
);

ram2port_addr16bit
#(
    .DATA_WD    (DATA_WD),
    .ADDR_WD    (16)
)
ram_sel15
(
    .wclk_i     (wclk_i),
    .rclk_i     (rclk_i),
    .data_i     (idata15),
    .waddr_i    (waddr15),
    .raddr_i    (raddr15),
    .w_en_i     (w_en15),
    .r_en_i     (r_en15),
    .data_o     (odata15)
);

logic [3:0] selo;

sel_data_o datao_sel
(
	.clk_i		(rclk_i),
	.r_en			(r_en_i),
	.in_sel		(raddr_i[19:16]),
	.sel_o		(selo)
);

mux16to1
#(
	.DATA_WD		(1)
)
sel_datao
(
	.clk_i		(rclk_i),
	.sel_i		(selo),
	.in0			(odata0),
	.in1			(odata1),
	.in2			(odata2),
	.in3			(odata3),
	.in4			(odata4),
	.in5			(odata5),
	.in6			(odata6),
	.in7			(odata7),
	.in8			(odata8),
	.in9			(odata9),
	.in10			(odata10),
	.in11			(odata11),
	.in12			(odata12),
	.in13			(odata13),
	.in14			(odata14),
	.in15			(odata15),
	.data_o		(data_o)
);

endmodule: ram2port_final