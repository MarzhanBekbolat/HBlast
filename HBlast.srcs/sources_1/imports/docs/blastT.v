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
input [31:0] data,
input [31:0] address, //How many bits should it be? 
input dataValid,
output [511:0] querry,
output reg querryValid
);

reg [511:0] querryReg;

assign querry = querryReg;

always @(posedge clk)
begin
    if (dataValid & address == 64)
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
                querryReg[512:480] <= data;
            end
                
        endcase
    end
end

endmodule
