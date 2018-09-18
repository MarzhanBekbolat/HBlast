`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.07.2018 11:24:29
// Design Name: 
// Module Name: axi4_brdige
// Project Name: 
// Target Devices: 
// Tool Versions: 0
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module axi4_brdige(
input clk,
input rst,
//slave
input s_arvalid,
input [31:0] s_araddr,
input [7:0] s_arlen,
output reg s_rvalid,
output reg s_arready,
output reg [511:0] s_rdata,

input ddrWr,
input [31:0] ddrWrAddress,
input ddrWrEn,
input [511:0] ddrWrData,
input ddrWrDataValid,

input [31:0] ddrRdAddr,
input ddrRd,
output ddrRdAddrDone,
output [511:0] ddrRdData,
output ddrRdDataValid,
//master
output reg m_arvalid,
output reg [31:0] m_araddr,
output reg [7:0] m_arlen,
input m_arready,
input m_rvalid,
input [511:0] m_rdata
    );
 localparam IDLE =1'b0,
            WAIT =1'b1; 
 reg state;  
 always @(posedge clk) 
 begin
 if(rst)
    begin
    s_arready <= 1'b0;
    m_arvalid <=1'b0;
    s_rvalid <= 1'b0;
    state <=IDLE;
    end
 else 
    begin
    case(state)
    IDLE: begin
    s_rvalid <= 1'b0;
    m_arvalid <=1'b0;
    s_arready <=1'b0;
    if(s_arvalid)
        begin
        m_arvalid <=1'b1;
        m_araddr <= s_araddr;
        m_arlen <= s_arlen;
        state <= WAIT;
        end
    end
    WAIT:begin
    s_arready <=1'b0;
    if(m_arready)
        begin
        s_arready <=1'b1;
        m_arvalid <=1'b0;
        end
    if(m_rvalid)
        begin
        s_rdata <=m_rdata;
        s_rvalid <= 1'b1;
        state <=IDLE;
        end
    end
    endcase
    end
 end
endmodule
