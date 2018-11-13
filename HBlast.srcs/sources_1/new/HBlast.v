
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.07.2018 10:59:35
// Design Name: 
// Module Name: HBlast
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module HBlast #(
//***************************************************************************
   // The following parameters refer to width of various ports
   //***************************************************************************
   parameter CK_WIDTH              = 1,
                                     // # of CK/CK# outputs to memory.
   parameter nCS_PER_RANK          = 1,
                                     // # of unique CS outputs per rank for phy
   parameter CKE_WIDTH             = 1,
                                     // # of CKE outputs to memory.
   parameter DM_WIDTH              = 1,
                                     // # of DM (data mask)
   parameter ODT_WIDTH             = 1,
                                     // # of ODT outputs to memory.
   parameter BANK_WIDTH            = 3,
                                     // # of memory Bank Address bits.
   parameter COL_WIDTH             = 10,
                                     // # of memory Column Address bits.
   parameter CS_WIDTH              = 1,
                                     // # of unique CS outputs to memory.
   parameter DQ_WIDTH              = 8,
                                     // # of DQ (data)
   parameter DQS_WIDTH             = 1,
   parameter DQS_CNT_WIDTH         = 1,
                                     // = ceil(log2(DQS_WIDTH))
   parameter DRAM_WIDTH            = 8,
                                     // # of DQ per DQS
   parameter ECC                   = "OFF",
   parameter ECC_TEST              = "OFF",
   //parameter nBANK_MACHS           = 4,
   parameter nBANK_MACHS           = 4,
   parameter RANKS                 = 1,
                                     // # of Ranks.
   parameter ROW_WIDTH             = 14,
                                     // # of memory Row Address bits.
   parameter ADDR_WIDTH            = 28,
                                     // # = RANK_WIDTH + BANK_WIDTH
                                     //     + ROW_WIDTH + COL_WIDTH;
                                     // Chip Select is always tied to low for
                                     // single rank devices

   //***************************************************************************
   // The following parameters are mode register settings
   //***************************************************************************
   parameter BURST_MODE            = "8",
                                     // DDR3 SDRAM:
                                     // Burst Length (Mode Register 0).
                                     // # = "8", "4", "OTF".
                                     // DDR2 SDRAM:
                                     // Burst Length (Mode Register).
                                     // # = "8", "4".

   
   //***************************************************************************
   // The following parameters are multiplier and divisor factors for PLLE2.
   // Based on the selected design frequency these parameters vary.
   //***************************************************************************
   parameter CLKIN_PERIOD          = 2188,
                                     // Input Clock Period
   parameter CLKFBOUT_MULT         = 7,
                                     // write PLL VCO multiplier
   parameter DIVCLK_DIVIDE         = 2,
                                     // write PLL VCO divisor
   parameter CLKOUT0_PHASE         = 337.5,
                                     // Phase for PLL output clock (CLKOUT0)
   parameter CLKOUT0_DIVIDE        = 2,
                                     // VCO output divisor for PLL output clock (CLKOUT0)
   parameter CLKOUT1_DIVIDE        = 2,
                                     // VCO output divisor for PLL output clock (CLKOUT1)
   parameter CLKOUT2_DIVIDE        = 32,
                                     // VCO output divisor for PLL output clock (CLKOUT2)
   parameter CLKOUT3_DIVIDE        = 8,
                                     // VCO output divisor for PLL output clock (CLKOUT3)
   parameter MMCM_VCO              = 800,
                                     // Max Freq (MHz) of MMCM VCO
   parameter MMCM_MULT_F           = 4,
                                     // write MMCM VCO multiplier
   parameter MMCM_DIVCLK_DIVIDE    = 1,
                                     // write MMCM VCO divisor

   //***************************************************************************
   // Simulation parameters
   //***************************************************************************
   parameter SIMULATION            = "FALSE",
                                     // Should be TRUE during design simulations and
                                     // FALSE during implementations

   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   parameter TCQ                   = 100,
   
   parameter DRAM_TYPE             = "DDR3",

   
   //***************************************************************************
   // System clock frequency parameters
   //***************************************************************************
   parameter nCK_PER_CLK           = 4,
                                     // # of memory CKs per fabric CLK

   

   //***************************************************************************
   // Debug parameters
   //***************************************************************************
   parameter DEBUG_PORT            = "OFF",
                                     // # = "ON" Enable debug signals/controls.
                                     //   = "OFF" Disable debug signals/controls.
      
   parameter RST_ACT_LOW           = 1
                                     // =1 for active low reset,
                                     // =0 for active high.
               )(
input rst, //sys_rst_n?
input [31:0] data,
input [31:0] address,
input dataValid,
input readData,
output [31:0] o_data,
output read_data_valid,
output processEnd,
//input [511:0] rdata,
//input arready,
//input rvalid,
//output [31:0] araddres,
//output arvalid,
//output after expansion
   // Inouts
   inout [7:0]                         ddr3_dq,
   inout [0:0]                        ddr3_dqs_n,
   inout [0:0]                        ddr3_dqs_p,

   // Outputs
   output [13:0]                       ddr3_addr,
   output [2:0]                      ddr3_ba,
   output                                       ddr3_ras_n,
   output                                       ddr3_cas_n,
   output                                       ddr3_we_n,
   output                                       ddr3_reset_n,
   output [0:0]                        ddr3_ck_p,
   output [0:0]                        ddr3_ck_n,
   output [0:0]                       ddr3_cke,
   
   output [0:0]           ddr3_cs_n,
   
   output [0:0]                        ddr3_dm,
   
   output [0:0]                       ddr3_odt,
   

   // Inputs
   
   // Differential system clocks
   input                                        sys_clk_p,
   input                                        sys_clk_n,
   
   // Single-ended iodelayctrl clk (reference clock)
   input                                        clk_ref_i,
   output                                       init_calib_complete,
   // System reset - Default polarity of sys_rst pin is Active Low.
   // System reset polarity will change based on the option 
   // selected in GUI.
   input                                        sys_rst,
   output                                       ddr_user_clk
 );
 
wire reset_Intern; 
wire [511:0] querry;
wire querryValid; 
//slave 
wire [31:0] s_aradress;
//reg [7:0] s_arlength;
wire s_arvalid;
wire s_arready;
wire [511:0] s_rdata;
wire s_rvalid;
wire clk;

wire [27:0] app_addr;
wire [2:0]	app_cmd;
wire		app_en;
wire [63:0]	app_wdf_data;
wire		app_wdf_end;
wire		app_wdf_wren;
wire [63:0]	app_rd_data;
wire		app_rd_data_end;
wire		app_rd_data_valid;
wire		app_rdy;
wire		app_wdf_rdy;


wire pcie_ddr__wr;
wire [63:0] pcie_ddr_wr_data;
wire pcie_ddr_wr_ack;
wire meminf_ddr_rd;
wire ddr_meminf_rd_ack;
wire [27:0] meminf_ddr_rd_addr;
wire [511:0] ddr_meminf_rd_data;
wire ddr_meminf_rd_data_valid;
wire [31:0] locationStart1;
wire [31:0] locationEnd1;
wire [10:0] highestScore1;
wire [31:0] locationStart2;
wire [31:0] locationEnd2;
wire [10:0] highestScore2;
wire [31:0] locationStart3;
wire [31:0] locationEnd3;
wire [10:0] highestScore3;
wire [31:0] locationStart4;
wire [31:0] locationEnd4;
wire [10:0] highestScore4;
wire [31:0] locationStart5;
wire [31:0] locationEnd5;
wire [10:0] highestScore5;
assign ddr_user_clk = clk;
assign reset_Intern = ~sys_rst | ~init_calib_complete; // Seems to be ~sys_rst

memInt memoryInt(
.clk(clk),
.rst(reset_Intern),
.ddr_rd_done(ddr_meminf_rd_ack),
.ddr_rd(meminf_ddr_rd),
.readAdd(meminf_ddr_rd_addr),
.ddr_rd_valid(ddr_meminf_rd_data_valid),
.ddr_rd_data(ddr_meminf_rd_data),
.query(querry),                   //Check later
.queryValid(querryValid),
.locationStart1(locationStart1),
.locationEnd1(locationEnd1),
.highestScore1(highestScore1),
.locationStart2(locationStart2),
.locationEnd2(locationEnd2),
.highestScore2(highestScore2),
.locationStart3(locationStart3),
.locationEnd3(locationEnd3),
.highestScore3(highestScore3),
.locationStart4(locationStart4),
.locationEnd4(locationEnd4),
.highestScore4(highestScore4),
.locationStart5(locationStart5),
.locationEnd5(locationEnd5),
.highestScore5(highestScore5),
.processEnd(processEnd)
);

wire [63:0] dbWrData;
 
 blastT queryB(
    .clk(clk),
    .data(data),
    .address(address),
    .o_data(o_data),
    .readData(readData),
    .readDataValid(read_data_valid),
    .dataValid(dataValid),
    .querry(querry),
    .querryValid(querryValid),
    .dBData(dbWrData),
    .dBDataWrEn(dbWrEn),
    .dBDataWrAck(dbWrAck),
    .locationStart1(locationStart1),
    .locationEnd1(locationEnd1),
    .highestScore1(highestScore1),
    .locationStart2(locationStart2),
    .locationEnd2(locationEnd2),
    .highestScore2(highestScore2),
    .locationStart3(locationStart3),
    .locationEnd3(locationEnd3),
    .highestScore3(highestScore3),
    .locationStart4(locationStart4),
    .locationEnd4(locationEnd4),
    .highestScore4(highestScore4),
    .locationStart5(locationStart5),
    .locationEnd5(locationEnd5),
    .highestScore5(highestScore5),
    .i_processEnd(processEnd)
     ); 
     
     
         
    // Start of User Design top instance
    //***************************************************************************
    // The User design is instantiated below. The memory interface ports are
    // connected to the top-level and the application interface ports are
    // connected to the traffic generator module. This provides a reference
    // for connecting the memory controller to system.
    //***************************************************************************
    
      mig_7series_0 u_mig_7series_0
          (
           
           
    // Memory interface ports
           .ddr3_addr                      (ddr3_addr),
           .ddr3_ba                        (ddr3_ba),
           .ddr3_cas_n                     (ddr3_cas_n),
           .ddr3_ck_n                      (ddr3_ck_n),
           .ddr3_ck_p                      (ddr3_ck_p),
           .ddr3_cke                       (ddr3_cke),
           .ddr3_ras_n                     (ddr3_ras_n),
           .ddr3_we_n                      (ddr3_we_n),
           .ddr3_dq                        (ddr3_dq),
           .ddr3_dqs_n                     (ddr3_dqs_n),
           .ddr3_dqs_p                     (ddr3_dqs_p),
           .ddr3_reset_n                   (ddr3_reset_n),
           .init_calib_complete            (init_calib_complete),
          
           .ddr3_cs_n                      (ddr3_cs_n),
           .ddr3_dm                        (ddr3_dm),
           .ddr3_odt                       (ddr3_odt),
    // Application interface ports
           .app_addr                       (app_addr),
           .app_cmd                        (app_cmd),
           .app_en                         (app_en),
           .app_wdf_data                   (app_wdf_data),
           .app_wdf_end                    (app_wdf_wren),
           .app_wdf_wren                   (app_wdf_wren),
           .app_rd_data                    (app_rd_data),
           .app_rd_data_end                (app_rd_data_end),
           .app_rd_data_valid              (app_rd_data_valid),
           .app_rdy                        (app_rdy),
           .app_wdf_rdy                    (app_wdf_rdy),
           .app_sr_req                     (1'b0),
           .app_ref_req                    (1'b0),
           .app_zq_req                     (1'b0),
           .app_sr_active                  (app_sr_active),
           .app_ref_ack                    (app_ref_ack),
           .app_zq_ack                     (app_zq_ack),
           .ui_clk                         (clk),
           .ui_clk_sync_rst                (),
          
           .app_wdf_mask                   (8'h00),
          
           
    // System Clock Ports
           .sys_clk_p                       (sys_clk_p),
           .sys_clk_n                       (sys_clk_n),
    // Reference Clock Ports
           .clk_ref_i                       (clk_ref_i),
           .device_temp                      (device_temp),
           `ifdef SKIP_CALIB
           .calib_tap_req                    (calib_tap_req),
           .calib_tap_load                   (calib_tap_load),
           .calib_tap_addr                   (calib_tap_addr),
           .calib_tap_val                    (calib_tap_val),
           .calib_tap_load_done              (calib_tap_load_done),
           `endif
          
           .sys_rst                        (sys_rst)
           );
		   
		   
brdige bridge(
.clk(clk),
.rst(reset_Intern),
.i_wr(dbWrEn),
.o_wr_done(dbWrAck),
.i_wr_data(dbWrData),
.o_ddr_app_en(app_en),
.o_ddr_cmd(app_cmd),
.o_ddr_addr(app_addr),
.i_ddr_app_rdy(app_rdy),
.o_ddr_wr_data(app_wdf_data),
.o_ddr_wr_en(app_wdf_wren),
.i_ddr_wr_rdy(app_wdf_rdy),
.i_rd(meminf_ddr_rd),
.o_rd_ack(ddr_meminf_rd_ack),
.i_rd_addr(meminf_ddr_rd_addr),
.o_rd_data(ddr_meminf_rd_data),
.o_rd_valid(ddr_meminf_rd_data_valid),
.i_ddr_rd_data(app_rd_data),
.i_ddr_rd_data_valid(app_rd_data_valid)
);


endmodule