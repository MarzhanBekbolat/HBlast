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
       output  [10:0] theHighestScore,
       output reg [31:0] highestLocationStart,
       output reg [31:0] highestLocationEnd,
       output reg processEnd
    );
    
    reg [10:0] highScore;
     reg [10:0] theHighestScoreReg=0;
    assign Score = highScore;
    assign theHighestScore = theHighestScoreReg;
    
    always @(posedge clk)
    begin
      if(stop)
      begin
         if(highScore > theHighestScoreReg)
         begin
            highestLocationStart <= locationStart;
            highestLocationEnd <= locationEnd;
            theHighestScoreReg <= highScore; 
         end
      end   
    end
    
    always @(posedge clk)
    begin
    if(rst)
       processEnd<=1'b0;
    else if(theHighestScore==1055)
       processEnd<=1'b1;
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
