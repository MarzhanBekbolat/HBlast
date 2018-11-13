`timescale 1ns / 1ps

module highScore(
       input clk,
       input rst,
       input [1:0] b1,
       input [1:0] b2,
       input stop,
       input [31:0] locationStart,
       input [31:0] locationEnd,
       input startCalc,
       output [10:0] Score, //??? ?????, ????? ???? ????? ??????
       output [10:0] theHighestScore1,
       output [31:0] highestLocationStart1,
       output [31:0] highestLocationEnd1,
              output [10:0] theHighestScore2,
       output [31:0] highestLocationStart2,
       output [31:0] highestLocationEnd2,
              output [10:0] theHighestScore3,
       output [31:0] highestLocationStart3,
       output [31:0] highestLocationEnd3,
              output [10:0] theHighestScore4,
       output [31:0] highestLocationStart4,
       output [31:0] highestLocationEnd4,
              output [10:0] theHighestScore5,
       output [31:0] highestLocationStart5,
       output [31:0] highestLocationEnd5,
       output reg processEnd
    );
	 localparam IDLE = 1'b0,
                COMND = 1'b1; 
    reg [10:0] highScore;
	reg [4:0] bigger;
	reg [3:0] command;
	reg [74:0] reg1;
	reg [74:0] reg2;
	reg [74:0] reg3;
	reg [74:0] reg4;
	reg [10:0] highScoreReg;
	reg [31:0] LocationStartReg;
	reg [31:0] LocationEndReg;
    reg state;
    integer i;
    reg count =1;
    reg [74:0] OutRam [4:0];
    assign Score = highScore;
    assign theHighestScore1 = OutRam[0][10:0];
    assign highestLocationStart1 = OutRam[0][42:11];
    assign highestLocationEnd1 = OutRam[0][74:43];
    assign theHighestScore2 = OutRam[1][10:0];
    assign highestLocationStart2 = OutRam[1][42:11];
    assign highestLocationEnd2 = OutRam[1][74:43];
    assign theHighestScore3 = OutRam[2][10:0];
    assign highestLocationStart3 = OutRam[2][42:11];
    assign highestLocationEnd3 = OutRam[2][74:43];
    assign theHighestScore4 = OutRam[3][10:0];
    assign highestLocationStart4 = OutRam[3][42:11];
    assign highestLocationEnd4 = OutRam[3][74:43];
    assign theHighestScore5 = OutRam[4][10:0];
    assign highestLocationStart5 = OutRam[4][42:11];
    assign highestLocationEnd5 = OutRam[4][74:43];
    
always @(posedge clk)
begin
if(rst)
begin
if(count == 1)
begin
 OutRam [0] =0;
 OutRam [1] =0;
 OutRam [2] =0;
 OutRam [3] =0;
 OutRam [4] =0;
  command <=0;
   i =0;
 state <= IDLE;
end
   count =0;
end
else 
begin
case(state)
IDLE: begin
reg1 <= OutRam[0];
reg2 <= OutRam[1];
reg3 <= OutRam[2];
reg4 <= OutRam[3];
for(i=0; i<5; i = i+1)
		begin
		if(OutRam[i][10:0] > highScore)
		    bigger[i] <= 1;
		else
			bigger[i] <= 0;
		end
if(stop)
begin
highScoreReg <= highScore;
LocationStartReg <= locationStart;
LocationEndReg <= locationEnd;
if(OutRam [0] == 0)
	begin
	OutRam[0] = {{locationEnd,locationStart},highScore};
	end
else
	begin
	command <=0;
	if(command[0] ==1)
		OutRam[1] <= reg1;
	if(command[1] ==1)
		OutRam[2] <= reg2;
	if(command[2] ==1)
		OutRam[3] <= reg3;
	if(command[4] ==1)
		OutRam[4] <= reg4;
		
    state <= COMND;
	end
end
end
COMND:begin
	if(bigger[0] == 0)
		begin
		command <= 4'b1111;
		OutRam[0] <= {{LocationEndReg,LocationStartReg},highScoreReg};
		end
	else if(bigger[1] == 0)
		begin
		$display("True, 0001");
		command <= 4'b1110;
		OutRam[1] <= {{LocationEndReg,LocationStartReg},highScoreReg};
		end
	else if(bigger[2] ==0)
		begin
		$display("True, 0011");
		command <= 4'b1100;
		OutRam[2] <= {{LocationEndReg,LocationStartReg},highScoreReg};
		end	
	else if(bigger[3] ==0)
		begin
		$display("True, 0111");
		command <= 4'b1000;
		OutRam[3] <= {{LocationEndReg,LocationStartReg},highScoreReg};
		end
	else if(bigger[4] ==0)
		begin
		$display("True, 1111");
		command <= 4'b0000;
		OutRam[4] <= {{LocationEndReg,LocationStartReg},highScoreReg};
		end
	state <= IDLE;
end
endcase
end
end

    

    
    always @(posedge clk)
    begin
    if(rst)
       processEnd<=1'b0;
    else if(OutRam [0] [10:0]==1055)
    begin
       processEnd<=1'b1;
       $display("The highest score: %d         locationStart and locationEnd:   %d     - %d", OutRam[0][10:0], OutRam[0][42:11], OutRam[0][74:43]);
       $display("The 2nd high score: %d        locationStart and locationEnd:   %d     - %d", OutRam[1][10:0], OutRam[1][42:11], OutRam[1][74:43]);
       $display("The 3rd high score: %d        locationStart and locationEnd:   %d     - %d", OutRam[2][10:0], OutRam[2][42:11], OutRam[2][74:43]);
       $display("The 4th high score:%d         locationStart and locationEnd:   %d     - %d", OutRam[3][10:0], OutRam[3][42:11], OutRam[3][74:43]);
       $display("The 5th high score:%d         locationStart and locationEnd:   %d     - %d", OutRam[4][10:0], OutRam[4][42:11], OutRam[4][74:43]);
       $stop;
       end
    end
    
    always @(posedge clk)
    begin
    if(rst)
    begin
       highScore <= 55;
       //theHighestScore <= 0;
    end
    else if(startCalc)
    begin
      if(b1 != 2 & b2 != 2)
       begin
          if(b1 == 1 & b2 == 1)
            highScore <= highScore + 10;
          else if(b1 == 0 & b2 == 0)
            highScore <= highScore;   
          else if(b1 == 1 || b2 == 1)
            highScore <= highScore + 1;
       end 
     else if(b1 == 2 & b2 != 2)
     begin
          if(b2 == 0)
            highScore <= highScore; 
          else if(b2 == 1)
            highScore <= highScore + 5;
    end
    else if(b2 == 2 & b1 != 2)
    begin
         if(b1 == 0)
            highScore <= highScore; 
         else if(b1 == 1)
            highScore <= highScore + 5;
    end
    else if(b2 == 2 & b1 == 2)
         highScore <= highScore;
    end
    end
    
    
    
      
endmodule
