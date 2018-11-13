`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.07.2018 10:30:42
// Design Name: 
// Module Name: blastT
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

module blastT(

input clk,
input rst,
input [31:0] data,
input [31:0] address, //How many bits should it be? 
output reg [31:0] o_data,
input dataValid,
input readData,
output reg readDataValid,
output [511:0] querry,
output reg querryValid,
input [31:0] locationStart1,
input [31:0] locationEnd1,
input [10:0] highestScore1,
input [31:0]locationStart2,
input [31:0]locationEnd2,
input [10:0]highestScore2,
input [31:0]locationStart3,
input [31:0]locationEnd3,
input [10:0]highestScore3,
input [31:0]locationStart4,
input [31:0]locationEnd4,
input [10:0]highestScore4,
input [31:0]locationStart5,
input [31:0]locationEnd5,
input [10:0]highestScore5,
input i_processEnd,
output reg [63:0] dBData,
output reg dBDataWrEn,
input dBDataWrAck
);

reg [511:0] querryReg;

reg [31:0] STAT_REG;

assign querry = querryReg;

always @(posedge clk)
begin
    if(rst)
       STAT_REG <= 0;
    else
    begin
        if(i_processEnd)
            STAT_REG <= 1'b1;
        else if(readData & address==0)
            STAT_REG <= 0;
    end
end

always @(posedge clk)
    readDataValid <= readData;

always @(posedge clk)
begin
    if(readData)
    begin
        case(address)
            'd0:begin
                o_data <= STAT_REG;
            end
            'd4:begin
                o_data <= highestScore1;
            end
            'd8:begin
                o_data <= locationEnd1;
            end
            'd12:begin
               o_data <= locationStart1;
            end
            'd16:begin
               o_data <= highestScore2;
            end
            'd20:begin
                o_data <= locationEnd2;
            end
            'd24:begin
                o_data <= locationStart2;
             end
           'd28:begin
               o_data <= highestScore3;
            end
           'd32:begin
                o_data <= locationEnd3;
            end
           'd36:begin
                o_data <= locationStart3;
                
            end
           'd40:begin
                 o_data <= highestScore4;
            end
           'd44:begin
                o_data <= locationEnd4;
            end
           'd48:begin
                o_data <= locationStart4;
            end
           'd52:begin
                o_data <= highestScore5;
            end
           'd56:begin
                o_data <= locationEnd5;
            end
           'd60:begin
                o_data <= locationStart5;
            end
            
        endcase
    end
end
always @(posedge clk)
begin
    if (dataValid & address == 60)
        querryValid <= 1'b1;
    else
        querryValid <= 1'b0;
end

always @(posedge clk)
begin
    if(dataValid)
    begin
        case(address)
            0:begin
                querryReg[31:0] <= data;
            end
            4:begin
                querryReg[63:32] <= data;
            end
            8:begin
                querryReg[95:64] <= data;
            end
            12:begin
                querryReg[127:96] <= data;
            end
            16: begin
                querryReg[159:128] <= data;
            end
            20: begin
                querryReg[191:160] <= data;
            end
            24: begin
                querryReg[223:192] <= data;
            end
            28:begin
                querryReg[255:224] <= data;
            end
            32:begin
                querryReg[287:256] <= data;
            end
            36:begin
                querryReg[319:288] <= data;
            end
            40:begin
                querryReg[351:320] <= data;
            end
            44:begin
                querryReg[383:352] <= data;
            end
            48:begin
                querryReg[415:384] <= data;  
            end
            52:begin
                querryReg[447:416] <= data;
            end
            56:begin
                querryReg[479:448] <= data;
            end
            60:begin
                querryReg[511:480] <= data;
            end
            64:begin
                dBData[31:0] <= data;
            end
            68:begin
                dBData[63:32] <= data;
            end
                
        endcase
    end
end

always @(posedge clk)
begin
    if(dataValid & address==68)
        dBDataWrEn <= 1'b1;
    else if(dBDataWrAck)
        dBDataWrEn <= 1'b0;
end

endmodule
