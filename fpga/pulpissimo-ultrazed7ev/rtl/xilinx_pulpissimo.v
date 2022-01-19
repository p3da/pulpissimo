//-----------------------------------------------------------------------------
// Title         : PULPissimo Verilog Wrapper
//-----------------------------------------------------------------------------
// File          : xilinx_pulpissimo.v
// Author        : Manuel Eggimann  <meggimann@iis.ee.ethz.ch>
// Created       : 21.05.2019
//-----------------------------------------------------------------------------
// Description :
// Verilog Wrapper of PULPissimo to use the module within Xilinx IP integrator.
//-----------------------------------------------------------------------------
// Copyright (C) 2013-2019 ETH Zurich, University of Bologna
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//-----------------------------------------------------------------------------

module xilinx_pulpissimo (
		input wire  ref_clk_p,
		input wire  ref_clk_n,

		inout wire  pad_uart_rx,
		inout wire  pad_uart_tx,
		inout wire  pad_uart_rts, //Mapped to spim_csn0
		inout wire  pad_uart_cts, //Mapped to spim_sck

		// original led usage for some unused peripherals
		inout wire  led0_o, //Mapped to spim_csn1
		inout wire  led1_o, //Mapped to cam_pclk
		inout wire  led2_o, //Mapped to cam_hsync
		inout wire  led3_o, //Mapped to cam_data0

		// on ultrazed 7ev we use the leds for ethernet mac status
		//output wire [7:0] led,

		inout wire  switch0_i, //Mapped to cam_data1
		inout wire  switch1_i, //Mapped to cam_data2
		inout wire  switch2_i, //Mapped to cam_data7
		inout wire  switch3_i, //Mapped to cam_vsync

		inout wire  btn0_i, //Mapped to cam_data3
		inout wire  btn1_i, //Mapped to cam_data4
		inout wire  btn2_i, //Mapped to cam_data5
		inout wire  btn3_i, //Mapped to cam_data6

		inout wire  pad_i2c0_sda,
		inout wire  pad_i2c0_scl,

		inout wire  pad_pmod0_4, //Mapped to spim_sdio0
		inout wire  pad_pmod0_5, //Mapped to spim_sdio1
		inout wire  pad_pmod0_6, //Mapped to spim_sdio2
		inout wire  pad_pmod0_7, //Mapped to spim_sdio3

		// inout wire  pad_pmod1_0, //Mapped to sdio_data0
		// inout wire  pad_pmod1_1, //Mapped to sdio_data1
		// inout wire  pad_pmod1_2, //Mapped to sdio_data2
		// inout wire  pad_pmod1_3, //Mapped to sdio_data3
		// inout wire  pad_pmod1_4, //Mapped to i2s0_sck
		// inout wire  pad_pmod1_5, //Mapped to i2s0_ws
		// inout wire  pad_pmod1_6, //Mapped to i2s0_sdi
		// inout wire  pad_pmod1_7, //Mapped to i2s1_sdi

		inout wire  pad_hdmi_scl, //Mapped to sdio_clk
		inout wire  pad_hdmi_sda, //Mapped to sdio_cmd

		input wire  pad_reset,

		input wire  pad_jtag_tck,
		input wire  pad_jtag_tdi,
		output wire pad_jtag_tdo,
		input wire  pad_jtag_tms,

		input  wire       phy_rx_clk,
		input  wire [3:0] phy_rxd,
		input  wire       phy_rx_ctl,
		output wire       phy_tx_clk,
		output wire [3:0] phy_txd,
		output wire       phy_tx_ctl,
		output wire       phy_reset_n
);

localparam CORE_TYPE = 0; // 0 for RISCY, 1 for IBEX RV32IMC (formerly ZERORISCY), 2 for IBEX RV32EC (formerly MICRORISCY)
localparam USE_FPU   = 1;
localparam USE_HWPE = 0;

wire sys_clk_ibufg;	// differential clock to single clock
wire clk_125mhz_mmcm_out; // mmcm output for soc clock
wire ref_clk; // bufg output for soc clock

wire clk_eth_125mhz_mmcm_out; // mmcm output for ethernet mac clock
wire clk_eth_125mhz90_mmcm_out; // mmcm output for ethernet mac clock (90 deg phase)
wire clk_eth; // bufg output for ethernet mac clock
wire clk_eth90; // bufg output for ethernet mac clock (90 degree phase)
wire rst_eth; // ethernet MAC reset

wire clk_ptp_250mhz_mmcm_out; // mmcm output for ptp clock
wire clk_ptp; // bufg output for ptp clock
wire rst_ptp; // ptp clock reset

// mmcm signals
wire mmcm_clkfb;
wire mmcm_locked;
wire rst_125mhz_int;
wire mmcm_rst = pad_reset;

// wire led0_o;
// wire led1_o;
// wire led2_o;
// wire led3_o;

/* the following signals are unused and not externally connected */
wire [7:0] led;
/* pmods are usually (on other boards) for sdio and i2s; on avnet ultarazed we use pmods for jtag and uart */
wire  pad_pmod1_0; //Mapped to sdio_data0
wire  pad_pmod1_1; //Mapped to sdio_data1
wire  pad_pmod1_2; //Mapped to sdio_data2
wire  pad_pmod1_3; //Mapped to sdio_data3
wire  pad_pmod1_4; //Mapped to i2s0_sck
wire  pad_pmod1_5; //Mapped to i2s0_ws
wire  pad_pmod1_6; //Mapped to i2s0_sdi
wire  pad_pmod1_7; //Mapped to i2s1_sdi

//Differential to single ended clock conversion
IBUFGDS #(
		.IOSTANDARD("LVDS"),
    .DIFF_TERM("FALSE"),
    .IBUF_LOW_PWR("FALSE"))
i_sysclk_iobuf (
		.I(ref_clk_p),
		.IB(ref_clk_n),
		.O(sys_clk_ibufg)
 );

/* MMCM instance
 *
 * sys_clk_ibufg = 300MHz in
 * clk_125mhz_mmcm_out = 125MHz out (used for xilinx clk manager which
 *                       generates 20MHz clk for SoC and 10MHz for peripherals;
 *                       frequencies are configured in pulpissimo/fpga/pulpissimo-ultrazed7ev/fpga-settings.mk)
 * clk_eth_125mhz_mmcm_out = 125MHz out (used in ethernet MAC; see pulp_soc.sv)
 * clk_eth_125mhz90_mmcm_out = 125MHz out (phase shifted by 90deg; used in ethernet MAC)
 * clk_ptp_250mhz_mmcm_out = 250MHz out (used in ptp clk; see pulp_soc.sv)
 */
MMCM_BASE #(
		.BANDWIDTH("OPTIMIZED"),

		.CLKOUT0_DIVIDE_F(12),
		.CLKOUT0_DUTY_CYCLE(0.5),
		.CLKOUT0_PHASE(0),

		.CLKOUT1_DIVIDE(12),
		.CLKOUT1_DUTY_CYCLE(0.5),
		.CLKOUT1_PHASE(90),

		.CLKOUT2_DIVIDE(12),
		.CLKOUT2_DUTY_CYCLE(0.5),
		.CLKOUT2_PHASE(0),

		.CLKOUT3_DIVIDE(6),
		.CLKOUT3_DUTY_CYCLE(0.5),
		.CLKOUT3_PHASE(0),

		.CLKOUT4_DIVIDE(1),
		.CLKOUT4_DUTY_CYCLE(0.5),
		.CLKOUT4_PHASE(0),

		.CLKOUT5_DIVIDE(1),
		.CLKOUT5_DUTY_CYCLE(0.5),
		.CLKOUT5_PHASE(0),

		.CLKOUT6_DIVIDE(1),
		.CLKOUT6_DUTY_CYCLE(0.5),
		.CLKOUT6_PHASE(0),

		.CLKFBOUT_MULT_F(5),
		.CLKFBOUT_PHASE(0),
		.DIVCLK_DIVIDE(1),
		.REF_JITTER1(0.010),
		.CLKIN1_PERIOD(3.333),
		.STARTUP_WAIT("FALSE"),
		.CLKOUT4_CASCADE("FALSE")
) clk_mmcm_inst (
		.CLKIN1(sys_clk_ibufg),
		.CLKFBIN(mmcm_clkfb),
		.RST(mmcm_rst),
		.PWRDWN(1'b0),
		.CLKOUT0(clk_125mhz_mmcm_out),
		.CLKOUT0B(),
		.CLKOUT1(clk_eth_125mhz90_mmcm_out),
		.CLKOUT1B(),
		.CLKOUT2(clk_eth_125mhz_mmcm_out),
		.CLKOUT2B(),
		.CLKOUT3(clk_ptp_250mhz_mmcm_out),
		.CLKOUT3B(),
		.CLKOUT4(),
		.CLKOUT5(),
		.CLKOUT6(),
		.CLKFBOUT(mmcm_clkfb),
		.CLKFBOUTB(),
		.LOCKED(mmcm_locked)
);

/* soc clock */
BUFG clk_125mhz_bufg_inst (
   .I(clk_125mhz_mmcm_out),
   .O(ref_clk)
);

/* ethernet clock 125 MHz */
BUFG clk_eth_125mhz_bufg_inst (
   .I(clk_eth_125mhz_mmcm_out),
   .O(clk_eth)
);

/* ethernet clock 125 MHz */
BUFG clk_eth_125mhz90_bufg_inst (
   .I(clk_eth_125mhz90_mmcm_out),
   .O(clk_eth90)
);

/* clock for ptp clock 250 MHz */
BUFG clk_ptp_250mhz_bufg_inst (
   .I(clk_ptp_250mhz_mmcm_out),
   .O(clk_ptp)
);

/* Synchronous reset for ethernet mac */
sync_reset #(
		.N(4)
) sync_reset_125mhz_inst (
		.clk(clk_eth),
    .rst(mmcm_locked),
    .out(rst_eth)
);

/* Synchronous reset for ptp clock */
sync_reset #(
    .N(4)
) sync_reset_250MHz_inst (
    .clk(clk_ptp),
    .rst(mmcm_locked),
    .out(rst_ptp)
);

pulpissimo #(
		.CORE_TYPE(CORE_TYPE),
		.USE_FPU(USE_FPU),
		.USE_HWPE(USE_HWPE)
) i_pulpissimo (
		.pad_spim_sdio0(pad_pmod0_4),
		.pad_spim_sdio1(pad_pmod0_5),
		.pad_spim_sdio2(pad_pmod0_6),
		.pad_spim_sdio3(pad_pmod0_7),
		.pad_spim_csn0(pad_uart_rts),
		.pad_spim_csn1(led0_o),
		.pad_spim_sck(pad_uart_cts),
		.pad_uart_rx(pad_uart_rx),
		.pad_uart_tx(pad_uart_tx),
		.pad_cam_pclk(led1_o),
		.pad_cam_hsync(led2_o),
		.pad_cam_data0(led3_o),
		.pad_cam_data1(switch0_i),
		.pad_cam_data2(switch1_i),
		.pad_cam_data3(btn0_i),
		.pad_cam_data4(btn1_i),
		.pad_cam_data5(btn2_i),
		.pad_cam_data6(btn3_i),
		.pad_cam_data7(switch2_i),
		.pad_cam_vsync(switch3_i),
		.pad_sdio_clk(pad_hdmi_scl),
		.pad_sdio_cmd(pad_hdmi_sda),
		.pad_sdio_data0(pad_pmod1_0),
		.pad_sdio_data1(pad_pmod1_1),
		.pad_sdio_data2(pad_pmod1_2),
		.pad_sdio_data3(pad_pmod1_3),
		.pad_i2c0_sda(pad_i2c0_sda),
		.pad_i2c0_scl(pad_i2c0_scl),
		.pad_i2s0_sck(pad_pmod1_4),
		.pad_i2s0_ws(pad_pmod1_5),
		.pad_i2s0_sdi(pad_pmod1_6),
		.pad_i2s1_sdi(pad_pmod1_7),
		.pad_reset_n(~pad_reset),
		.pad_jtag_tck(pad_jtag_tck),
		.pad_jtag_tdi(pad_jtag_tdi),
		.pad_jtag_tdo(pad_jtag_tdo),
		.pad_jtag_tms(pad_jtag_tms),
		.pad_jtag_trst(1'b1),
		.pad_xtal_in(ref_clk),
		.pad_bootsel0(),
		.pad_bootsel1(),

		/* ethernet phy interface */
		.phy_rx_clk(phy_rx_clk),
		.phy_rxd(phy_rxd),
		.phy_rx_ctl(phy_rx_ctl),
		.phy_tx_clk(phy_tx_clk),
		.phy_txd(phy_txd),
		.phy_tx_ctl(phy_tx_ctl),
		.phy_reset_n(phy_reset_n),

		/* clock and reset for ethernet mac */
		.clk_eth(clk_eth),
		.clk_eth90(clk_eth90),
		.rst_eth(rst_eth),
		.led(led),

    .clk_ptp(clk_ptp),
    .rst_ptp(rst_ptp)
);





endmodule
