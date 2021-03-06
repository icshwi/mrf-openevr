-- =============================================================================
--! @file   ess_evr_gtx_z7_pkg.vhd
--! @brief  Common definitions for the ESS openEVR GTX wrapper
--!
--! @author Ross Elliot <ross.elliot@ess.eu>
--! @author Felipe Torres González <felipe.torresgonzalez@ess.eu>
--!
--! @date 20200526
--! @version 0.1
--!
--! @details
--! Company European Spallation Source ERIC
--! Platform: picoZED 7030
--! Carrier board:  Tallinn picoZED carrier board (aka FPGA-based IOC) rev. B
--! Based on the AVNET xdc file for the picozed 7z030 RevC v2
--!
--! @copyright
--!      Copyright (C) 2019- 2020 European Spallation Source ERIC
--!
--!      This program is free software: you can redistribute it and/or modify
--!      it under the terms of the GNU General Public License as published by
--!      the Free Software Foundation, either version 3 of the License, or
--!      (at your option) any later version.
--!
--!      This program is distributed in the hope that it will be useful,
--!      but WITHOUT ANY WARRANTY; without even the implied warranty of
--!      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--!      GNU General Public License for more details.
--!
--!      You should have received a copy of the GNU General Public License
--!      along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- =============================================================================
--! @page TransceiverDocs
--! @see
--!   \li [1]: 7 Series FPGAS GTX/GTH Transceivers User Gude (UG476)
--!   \li [2]: 7 Series FPGAS Transceivers Wizard (PG168)
--!   \li [3]: MRF's event code list (section 1.3.1), http://mrf.fi/fw/DCManual-191127.pdf

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ess_evr_gtx_z7_pkg is

  --!@name gt_ctrl_flags
  --!@brief Record to group all the control flags for the EVR GTX wrapper
  type gt_ctrl_flags is record
  --!@{
    tx_fsm_done   : std_logic; --! Completed full reset for the Tx path
    rx_fsm_done   : std_logic; --! Completed full reset for the Rx path
    pll_locked    : std_logic; --! Internal PLL locked to the external freq.
    fbclk_lost    : std_logic; --! Feedback freq. lost - Don't really know what's this...
    rx_data_valid : std_logic; --! Read data valid flag
    link_up       : std_logic; --! Link-up flag
    event_rcv     : std_logic; --! Event received
  --!@}
  end record gt_ctrl_flags;

  --!@name gt_resets
  --!@brief Record to group all the reset signals for the EVR GTX wrapper
  --!@{
  type gt_resets is record
    tx_async  : std_logic; --! Reset the Tx path - Sync to sys_clk
    rx_async  : std_logic; --! Reset the Rx path - Synt to sys_clk
    gbl_async : std_logic; --! Global reset for Tx&Rx paths
  end record gt_resets;
  --!@}

  --============================================================================

  --! @brief Module to generate a reset signal for the transceiver
  --! @details
  --!   This module ensures the proper signaling to the transceiver's reset
  --!   logic. See p.29 [2].
  component z7_gtx_evr_common_reset is
    generic (
      --! Period of the stable clock driving this state-machine, unit is [ns]
      STABLE_CLOCK_PERIOD      : integer := 8);
    port (
      --! Stable Clock, either a stable clock from the PCB
      STABLE_CLOCK             : in std_logic;
      --! User Reset, can be pulled any time
      SOFT_RESET               : in std_logic;
      --! Reset QPLL
      COMMON_RESET             : out std_logic:= '0');
    end component z7_gtx_evr_common_reset;

  -- GTX wrapper for the openEVR
  component z7_gtx_evr is
    port
    (
      SYSCLK_IN                               : in   std_logic;
      --! Soft reset for the GT Tx FSM
      SOFT_RESET_TX_IN                        : in   std_logic;
      --! Soft reset for the Rx FSM
      SOFT_RESET_RX_IN                        : in   std_logic;
      DONT_RESET_ON_DATA_ERROR_IN             : in   std_logic;
      GT0_TX_FSM_RESET_DONE_OUT               : out  std_logic;
      GT0_RX_FSM_RESET_DONE_OUT               : out  std_logic;
      GT0_DATA_VALID_IN                       : in   std_logic;

      --_________________________________________________________________________
      --GT0  (X0Y0)
      --____________________________CHANNEL PORTS________________________________
      --------------------------------- CPLL Ports -------------------------------
      gt0_cpllfbclklost_out                   : out  std_logic;
      gt0_cplllock_out                        : out  std_logic;
      gt0_cplllockdetclk_in                   : in   std_logic;
      gt0_cpllreset_in                        : in   std_logic;
      -------------------------- Channel - Clocking Ports ------------------------
      gt0_gtrefclk0_in                        : in   std_logic;
      gt0_gtrefclk1_in                        : in   std_logic;
      ---------------------------- Channel - DRP Ports  --------------------------
      gt0_drpaddr_in                          : in   std_logic_vector(8 downto 0);
      gt0_drpclk_in                           : in   std_logic;
      gt0_drpdi_in                            : in   std_logic_vector(15 downto 0);
      gt0_drpdo_out                           : out  std_logic_vector(15 downto 0);
      gt0_drpen_in                            : in   std_logic;
      gt0_drprdy_out                          : out  std_logic;
      gt0_drpwe_in                            : in   std_logic;
      --------------------------- Digital Monitor Ports --------------------------
      gt0_dmonitorout_out                     : out  std_logic_vector(7 downto 0);
      --------------------- RX Initialization and Reset Ports --------------------
      gt0_eyescanreset_in                     : in   std_logic;
      gt0_rxuserrdy_in                        : in   std_logic;
      -------------------------- RX Margin Analysis Ports ------------------------
      gt0_eyescandataerror_out                : out  std_logic;
      gt0_eyescantrigger_in                   : in   std_logic;
      ------------------ Receive Ports - FPGA RX Interface Ports -----------------
      gt0_rxusrclk_in                         : in   std_logic;
      gt0_rxusrclk2_in                        : in   std_logic;
      ------------------ Receive Ports - FPGA RX interface Ports -----------------
      gt0_rxdata_out                          : out  std_logic_vector(15 downto 0);
      ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
      gt0_rxdisperr_out                       : out  std_logic_vector(1 downto 0);
      gt0_rxnotintable_out                    : out  std_logic_vector(1 downto 0);
      --------------------------- Receive Ports - RX AFE -------------------------
      gt0_gtxrxp_in                           : in   std_logic;
      ------------------------ Receive Ports - RX AFE Ports ----------------------
      gt0_gtxrxn_in                           : in   std_logic;
      ------------------- Receive Ports - RX Buffer Bypass Ports -----------------
      gt0_rxphmonitor_out                     : out  std_logic_vector(4 downto 0);
      gt0_rxphslipmonitor_out                 : out  std_logic_vector(4 downto 0);
      --------------------- Receive Ports - RX Equalizer Ports -------------------
      gt0_rxdfelpmreset_in                    : in   std_logic;
      gt0_rxmonitorout_out                    : out  std_logic_vector(6 downto 0);
      gt0_rxmonitorsel_in                     : in   std_logic_vector(1 downto 0);
      --------------- Receive Ports - RX Fabric Output Control Ports -------------
      gt0_rxoutclk_out                        : out  std_logic;
      gt0_rxoutclkfabric_out                  : out  std_logic;
      ------------- Receive Ports - RX Initialization and Reset Ports ------------
      gt0_gtrxreset_in                        : in   std_logic;
      gt0_rxpmareset_in                       : in   std_logic;
      ---------------------- Receive Ports - RX gearbox ports --------------------
      gt0_rxslide_in                          : in   std_logic;
      ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
      gt0_rxcharisk_out                       : out  std_logic_vector(1 downto 0);
      -------------- Receive Ports -RX Initialization and Reset Ports ------------
      gt0_rxresetdone_out                     : out  std_logic;
      --------------------- TX Initialization and Reset Ports --------------------
      gt0_gttxreset_in                        : in   std_logic;
      gt0_txuserrdy_in                        : in   std_logic;
      ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
      gt0_txusrclk_in                         : in   std_logic;
      gt0_txusrclk2_in                        : in   std_logic;
      ------------------ Transmit Ports - TX Data Path interface -----------------
      gt0_txdata_in                           : in   std_logic_vector(15 downto 0);
      ---------------- Transmit Ports - TX Driver and OOB signaling --------------
      gt0_gtxtxn_out                          : out  std_logic;
      gt0_gtxtxp_out                          : out  std_logic;
      ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
      gt0_txoutclk_out                        : out  std_logic;
      -- RXoutCLK * 2 and without Delay alignment - see p.210 [1]
      gt0_txoutclkfabric_out                  : out  std_logic;
      gt0_txoutclkpcs_out                     : out  std_logic;
      --------------------- Transmit Ports - TX Gearbox Ports --------------------
      gt0_txcharisk_in                        : in   std_logic_vector(1 downto 0);
      ------------- Transmit Ports - TX Initialization and Reset Ports -----------
      gt0_txresetdone_out                     : out  std_logic;
      --____________________________COMMON PORTS________________________________
       GT0_QPLLOUTCLK_IN  : in std_logic;
       GT0_QPLLOUTREFCLK_IN : in std_logic);
    end component;

end package;
