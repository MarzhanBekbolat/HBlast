`timescale 1ns / 1ps

module shift2Reg(
input clk,
input rst,
input load,
input shift,
input [511:0] inData,
output [511:0] outData                              
);

reg [533:0] shiftReg;
reg [8:0] k=0;
reg state=0;
assign outData = shiftReg[511:0];

always @(posedge clk)
begin
    if(load & shift)
    begin
        shiftReg[533:20] <= {2'b00,inData};
        shiftReg[19:0] <= {shiftReg[21:2]};
    end
    else if(load)
        shiftReg[533:0] <= {22'h0,inData};
    else if(shift)
        shiftReg <= {2'b00,shiftReg[533:2]};
  end
endmodule
