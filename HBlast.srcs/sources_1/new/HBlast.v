
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
input rst,
input [31:0] data,
input [31:0] address,
input dataValid,
input [511:0] rdata,
input arready,
input rvalid,
output [31:0] araddres,
output arvalid,
output [7:0] arlength,
//output after expansion
output [31:0] locationStart,
output [31:0] locationEnd,
output [10:0] highestScore,
output processEnd,
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
   
   input i_wr,
   input [63:0] i_wr_data,
   output o_wr_ack,
   input i_rd,
   output o_rd_ack,
   input [27:0] i_rd_addr,
   output [63:0] o_rd_data,
   output o_rd_data_valid,
   output ddr_user_clk
 );
 
 
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

assign arlength = 8'b00001000; // How much should it be?
assign ddr_user_clk = clk;

memInt memoryInt(
.clk(clk),
.rst(rst),
.ddr_rd_done(o_rd_ack), // acceptance for reading the data
.ddr_rd(i_rd), // request to read
.readAdd(i_rd_addr), // address to read from ddr
.ddr_rd_valid(o_rd_data_valid), // indicates ddr's readiness 
.ddr_rd_data(o_rd_data), // data requested from ddr
.query(),
.queryValid(),
//ouput for comparator
//input rdNew,
//. [12:0] maxScoreOut,
//output [31:0] outAddress,
.locationStart(locationStart),
.locationEnd(locationEnd),
.highestScore(highestScore),
.processEnd(processEnd)
/*.clk(clk),
.rst(rst),
.ddr_rd_done(s_arready),
.ddr_rd(s_arvalid),
 .readAdd(s_aradress),
 .ddr_rd_valid(s_rvalid),
 .ddr_rd_data(s_rdata),
 //input for query
 .query(querry),
 .queryValid(querryValid),
 //ouput for comparator
 //input rdNew,
 //output [12:0] maxScoreOut,
 //output [31:0] outAddress,
 .locationStart(locationStart),
 .locationEnd(locationEnd)
 //.hitTEST()*/
     );
 
 blastT queryB(
    .clk(clk),
    .data(data),
    .address(address),
    .dataValid(dataValid),
    .querry(querry),
    .querryValid(querryValid)
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
           .ui_clk_sync_rst                (rst),
          
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
.rst(!init_calib_complete),
.i_wr(i_wr),
.o_wr_done(o_wr_ack),
.i_wr_data(i_wr_data),
.o_ddr_app_en(app_en),
.o_ddr_cmd(app_cmd),
.o_ddr_addr(app_addr),
.i_ddr_app_rdy(app_rdy),
.o_ddr_wr_data(app_wdf_data),
.o_ddr_wr_en(app_wdf_wren),
.i_ddr_wr_rdy(app_wdf_rdy),
.i_rd(i_rd),
.o_rd_ack(o_rd_ack),
.i_rd_addr(i_rd_addr),
.o_rd_data(o_rd_data),
.o_rd_valid(o_rd_data_valid),
.i_ddr_rd_data(app_rd_data),
.i_ddr_rd_data_valid(app_rd_data_valid)
);

endmodule