#######################################
#  _______ _           _              #
# |__   __(_)         (_)             #
#    | |   _ _ __ ___  _ _ __   __ _  #
#    | |  | | '_ ` _ \| | '_ \ / _` | #
#    | |  | | | | | | | | | | | (_| | #
#    |_|  |_|_| |_| |_|_|_| |_|\__, | #
#                               __/ | #
#                              |___/  #
#######################################


#Create constraint for the clock input of the ultrazed7ev board
#create_clock -period 8.000 -name ref_clk [get_ports ref_clk_p]
create_clock -period 3.333 -name ref_clk [get_ports ref_clk_p]

#I2S and CAM interface are not used in this FPGA port. Set constraints to
#disable the clock
set_case_analysis 0 i_pulpissimo/safe_domain_i/cam_pclk_o
set_case_analysis 0 i_pulpissimo/safe_domain_i/i2s_slave_sck_o
#set_input_jitter tck 1.000

## JTAG
create_clock -period 100.000 -name tck -waveform {0.000 50.000} [get_ports pad_jtag_tck]
set_input_jitter tck 1.000
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets pad_jtag_tck_IBUF_inst/O]


# minimize routing delay
set_input_delay -clock tck -clock_fall 5.000 [get_ports pad_jtag_tdi]
set_input_delay -clock tck -clock_fall 5.000 [get_ports pad_jtag_tms]
set_output_delay -clock tck 5.000 [get_ports pad_jtag_tdo]

set_max_delay -to [get_ports pad_jtag_tdo] 20.000
set_max_delay -from [get_ports pad_jtag_tms] 20.000
set_max_delay -from [get_ports pad_jtag_tdi] 20.000

set_max_delay -datapath_only -from [get_pins i_pulpissimo/soc_domain_i/pulp_soc_i/i_dmi_jtag/i_dmi_cdc/i_cdc_resp/i_src/data_src_q_reg*/C] -to [get_pins i_pulpissimo/soc_domain_i/pulp_soc_i/i_dmi_jtag/i_dmi_cdc/i_cdc_resp/i_dst/data_dst_q_reg*/D] 20.000
set_max_delay -datapath_only -from [get_pins i_pulpissimo/soc_domain_i/pulp_soc_i/i_dmi_jtag/i_dmi_cdc/i_cdc_resp/i_src/req_src_q_reg/C] -to [get_pins i_pulpissimo/soc_domain_i/pulp_soc_i/i_dmi_jtag/i_dmi_cdc/i_cdc_resp/i_dst/req_dst_q_reg/D] 20.000
set_max_delay -datapath_only -from [get_pins i_pulpissimo/soc_domain_i/pulp_soc_i/i_dmi_jtag/i_dmi_cdc/i_cdc_req/i_dst/ack_dst_q_reg/C] -to [get_pins i_pulpissimo/soc_domain_i/pulp_soc_i/i_dmi_jtag/i_dmi_cdc/i_cdc_req/i_src/ack_src_q_reg/D] 20.000


# reset signal
set_false_path -from [get_ports pad_reset]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets pad_reset_IBUF_inst/O]

# Set ASYNC_REG attribute for ff synchronizers to place them closer together and
# increase MTBF
set_property ASYNC_REG true [get_cells i_pulpissimo/soc_domain_i/pulp_soc_i/soc_peripherals_i/i_apb_adv_timer/u_tim0/u_in_stage/r_ls_clk_sync_reg*]
set_property ASYNC_REG true [get_cells i_pulpissimo/soc_domain_i/pulp_soc_i/soc_peripherals_i/i_apb_adv_timer/u_tim1/u_in_stage/r_ls_clk_sync_reg*]
set_property ASYNC_REG true [get_cells i_pulpissimo/soc_domain_i/pulp_soc_i/soc_peripherals_i/i_apb_adv_timer/u_tim2/u_in_stage/r_ls_clk_sync_reg*]
set_property ASYNC_REG true [get_cells i_pulpissimo/soc_domain_i/pulp_soc_i/soc_peripherals_i/i_apb_adv_timer/u_tim3/u_in_stage/r_ls_clk_sync_reg*]
set_property ASYNC_REG true [get_cells i_pulpissimo/soc_domain_i/pulp_soc_i/soc_peripherals_i/i_apb_timer_unit/s_ref_clk*]
set_property ASYNC_REG true [get_cells i_pulpissimo/soc_domain_i/pulp_soc_i/soc_peripherals_i/i_ref_clk_sync/i_pulp_sync/r_reg_reg*]
set_property ASYNC_REG true [get_cells i_pulpissimo/soc_domain_i/pulp_soc_i/soc_peripherals_i/u_evnt_gen/r_ls_sync_reg*]

# Create asynchronous clock group between slow-clk and SoC clock. Those clocks
# are considered asynchronously and proper synchronization regs are in place
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins i_pulpissimo/safe_domain_i/i_slow_clk_gen/slow_clk_o]] -group [get_clocks -of_objects [get_pins i_pulpissimo/soc_domain_i/pulp_soc_i/i_clk_rst_gen/i_fpga_clk_gen/soc_clk_o]]

# Create asynchronous clock group between Per Clock  and SoC clock. Those clocks
# are considered asynchronously and proper synchronization regs are in place
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins i_pulpissimo/soc_domain_i/pulp_soc_i/i_clk_rst_gen/clk_per_o]] -group [get_clocks -of_objects [get_pins i_pulpissimo/soc_domain_i/pulp_soc_i/i_clk_rst_gen/clk_soc_o]]

# Create asynchronous clock group between JTAG TCK and SoC clock.
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins i_pulpissimo/pad_jtag_tck]] -group [get_clocks -of_objects [get_pins i_pulpissimo/soc_domain_i/pulp_soc_i/i_clk_rst_gen/clk_soc_o]]

#############################################################
#  _____ ____         _____      _   _   _                  #
# |_   _/ __ \       / ____|    | | | | (_)                 #
#   | || |  | |_____| (___   ___| |_| |_ _ _ __   __ _ ___  #
#   | || |  | |______\___ \ / _ \ __| __| | '_ \ / _` / __| #
#  _| || |__| |      ____) |  __/ |_| |_| | | | | (_| \__ \ #
# |_____\____/      |_____/ \___|\__|\__|_|_| |_|\__, |___/ #
#                                                 __/ |     #
#                                                |___/      #
#############################################################

## Sys clock
set_property -dict {PACKAGE_PIN AC7 IOSTANDARD LVDS} [get_ports ref_clk_n]
set_property -dict {PACKAGE_PIN AC8 IOSTANDARD LVDS} [get_ports ref_clk_p]

## Reset
set_property -dict {LOC AA13 IOSTANDARD LVCMOS18} [get_ports pad_reset]

## Buttons
set_property -dict {PACKAGE_PIN AB13 IOSTANDARD LVCMOS18} [get_ports btn0_i]
set_property -dict {PACKAGE_PIN AA15 IOSTANDARD LVCMOS18} [get_ports btn1_i]
set_property -dict {PACKAGE_PIN AB15 IOSTANDARD LVCMOS18} [get_ports btn2_i]
set_property -dict {PACKAGE_PIN AF13 IOSTANDARD LVCMOS18} [get_ports btn3_i]

## PMOD 0
set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS33} [get_ports pad_jtag_tms]
set_property -dict {PACKAGE_PIN A15 IOSTANDARD LVCMOS33} [get_ports pad_jtag_tdi]
set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS33} [get_ports pad_jtag_tdo]
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS33} [get_ports pad_jtag_tck]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports pad_pmod0_4]
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports pad_pmod0_5]
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS33} [get_ports pad_pmod0_6]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports pad_pmod0_7]

## PMOD 1
set_property -dict {PACKAGE_PIN AH18 IOSTANDARD LVCMOS18} [get_ports pad_pmod1_0]
set_property -dict {PACKAGE_PIN AG18 IOSTANDARD LVCMOS18} [get_ports pad_pmod1_1]
set_property -dict {PACKAGE_PIN AF18 IOSTANDARD LVCMOS18} [get_ports pad_pmod1_2]
set_property -dict {PACKAGE_PIN AE18 IOSTANDARD LVCMOS18} [get_ports pad_pmod1_3]
set_property -dict {PACKAGE_PIN AJ17 IOSTANDARD LVCMOS18} [get_ports pad_pmod1_4]
set_property -dict {PACKAGE_PIN AH17 IOSTANDARD LVCMOS18} [get_ports pad_pmod1_5]
set_property -dict {PACKAGE_PIN AE19 IOSTANDARD LVCMOS18} [get_ports pad_pmod1_6]
set_property -dict {PACKAGE_PIN AD19 IOSTANDARD LVCMOS18} [get_ports pad_pmod1_7]

## UART
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports pad_uart_tx]
set_property -dict {PACKAGE_PIN E15 IOSTANDARD LVCMOS33} [get_ports pad_uart_rx]
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS33} [get_ports pad_uart_rts]
set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS33} [get_ports pad_uart_cts]

## LEDs
set_property -dict {PACKAGE_PIN AC14 IOSTANDARD LVCMOS18} [get_ports led0_o]
set_property -dict {PACKAGE_PIN AD14 IOSTANDARD LVCMOS18} [get_ports led1_o]
set_property -dict {PACKAGE_PIN AE14 IOSTANDARD LVCMOS18} [get_ports led2_o]
set_property -dict {PACKAGE_PIN AE13 IOSTANDARD LVCMOS18} [get_ports led3_o]

#set_property PACKAGE_PIN AG3 [get_ports {led[0]}];	# HP_DP_47_N
#set_property PACKAGE_PIN AC14 [get_ports {led[1]}];	# HP_DP_20_P
#set_property PACKAGE_PIN AD14 [get_ports {led[2]}];	# HP_DP_20_N
#set_property PACKAGE_PIN AE14 [get_ports {led[3]}];	# HP_DP_21_P
#set_property PACKAGE_PIN AE13 [get_ports {led[4]}];	# HP_DP_21_N
#set_property PACKAGE_PIN AA14 [get_ports {led[5]}];	# HP_DP_22_P
#set_property PACKAGE_PIN AB14 [get_ports {led[6]}];	# HP_DP_22_N
#set_property PACKAGE_PIN AG4 [get_ports {led[7]}];	# HP_DP_47_P
#
#set_property IOSTANDARD LVCMOS18 [get_ports {led[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led[1]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led[2]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led[3]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led[4]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led[5]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led[6]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led[7]}]

## Switches
set_property -dict {PACKAGE_PIN AG19 IOSTANDARD LVCMOS18} [get_ports switch0_i]
set_property -dict {PACKAGE_PIN AC13 IOSTANDARD LVCMOS18} [get_ports switch1_i]
set_property -dict {PACKAGE_PIN AC19 IOSTANDARD LVCMOS18} [get_ports switch2_i]
set_property -dict {PACKAGE_PIN AF1 IOSTANDARD LVCMOS18} [get_ports switch3_i]

## I2C Bus
set_property -dict {PACKAGE_PIN AC18 IOSTANDARD LVCMOS18} [get_ports pad_i2c0_scl]
set_property -dict {PACKAGE_PIN AC17 IOSTANDARD LVCMOS18} [get_ports pad_i2c0_sda]

## HDMI CTL
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports pad_hdmi_scl]
set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports pad_hdmi_sda]


# Ethernet PHY
#set_property -dict {PACKAGE_PIN AE19 IOSTANDARD LVCMOS18} [get_ports {phy_reset_n}]

#set_property -dict { PACKAGE_PIN AD19 IOSTANDARD LVCMOS25 } [ get_ports {phy_mdc} ]
#set_property -dict { PACKAGE_PIN AC18 IOSTANDARD LVCMOS25 } [ get_ports {phy_mdio} ]

#RGMII Receive
#set_property -dict {PACKAGE_PIN AF16 IOSTANDARD LVCMOS18} [get_ports {phy_rx_clk}]
#set_property -dict {PACKAGE_PIN AG18 IOSTANDARD LVCMOS18} [get_ports {phy_rxd[0]}]
#set_property -dict {PACKAGE_PIN AH18 IOSTANDARD LVCMOS18} [get_ports {phy_rxd[1]}]
#set_property -dict {PACKAGE_PIN AE18 IOSTANDARD LVCMOS18} [get_ports {phy_rxd[2]}]
#set_property -dict {PACKAGE_PIN AF18 IOSTANDARD LVCMOS18} [get_ports {phy_rxd[3]}]
#set_property -dict {PACKAGE_PIN AF17 IOSTANDARD LVCMOS18} [get_ports {phy_rx_ctl}]

#RGMII Transmit
#set_property -dict {PACKAGE_PIN AJ17 IOSTANDARD LVCMOS18} [get_ports {phy_tx_clk}]
#set_property -dict {PACKAGE_PIN AH17 IOSTANDARD LVCMOS18} [get_ports {phy_txd[0]}]
#set_property -dict {PACKAGE_PIN AJ16 IOSTANDARD LVCMOS18} [get_ports {phy_txd[1]}]
#set_property -dict {PACKAGE_PIN AK16 IOSTANDARD LVCMOS18} [get_ports {phy_txd[2]}]
#set_property -dict {PACKAGE_PIN AA16 IOSTANDARD LVCMOS18} [get_ports {phy_txd[3]}]
#set_property -dict {PACKAGE_PIN AB16 IOSTANDARD LVCMOS18} [get_ports {phy_tx_ctl}]

# PHY generates 125MHz clock
#create_clock -period 8.000 -name phy_rx_clk -waveform {0.000 4.000} [get_ports phy_rx_clk]


set_property BITSTREAM.GENERAL.UNCONSTRAINEDPINS Allow [current_design]
