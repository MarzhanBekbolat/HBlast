`timescale 1ns / 1ps

module Hit(
input clk,
input rst,
input [511:0] query,
input queryValid,
input [511:0] dataBase,
input dataBaseValid,
input shift,
input load,
input stop,
output [8:0] ShiftNo,
output wire hit,
output reg startExpand,
output [8:0] locationQ, 
output reg highBitEnd
    );
 localparam IDLE = 1'b0,
            HITLOW = 1'b1;  
 reg state;
 wire [21:0] dBCompareWmer;
 wire [511:0] dbShiftRegOut;
 wire [245:0] ouput;
 reg [8:0] CurrentLocation; 
 reg [511:0] queryReg; 
 reg [8:0] ShiftNoIn=0; 
 reg [8:0] k; 
 
 assign hit = |ouput;
 
   
 always @(posedge clk)
 begin
  if(queryValid)
      queryReg <=  query;
 end
 
 
 assign locationQ = CurrentLocation;
 assign dBCompareWmer = dbShiftRegOut[21:0];  
 assign ShiftNo = ShiftNoIn; 
 
 
 always @(posedge clk) 
   begin
  if (shift)
   begin
    ShiftNoIn <= ShiftNoIn+2;
  end 
 end

always @(posedge clk)
    begin
     if(rst)
        begin
           CurrentLocation <=0;
           startExpand <=0;
           k <= 0;
           highBitEnd <= 0;
           state <=IDLE;
        end 
     else 
       begin
         case(state)
         IDLE: begin
          highBitEnd <= 0;
           if(hit & dataBaseValid)
           begin
             if(ouput[k]==1)
             begin
                startExpand <=1;
                CurrentLocation <= k*2;
                state <=HITLOW;
             end
             else if(k < 246) /////////////////////////////////////////////////////////////////////
                     k <= k+1;
             else if(k == 246)
             begin
                  highBitEnd <= 1; 
                  k <= 0;
             end     
           end
           else if(!highBitEnd & hit)
           begin
           if(ouput[k]==1)
                        begin
                           startExpand <=1;
                           CurrentLocation <= k*2;
                           state <=HITLOW;
                        end
                        else if(k < 246) /////////////////////////////////////////////////////////////////////
                                k <= k+1;
                        else if(k == 246)
                        begin
                             highBitEnd <= 1; 
                             k <= 0;
                        end    
           end
         end
         HITLOW: begin
           if(stop)
           begin
             if(k < 246)
               k <= k+1;
             startExpand <=0; 
           state <=IDLE;
           end
           else if(k==246) // tentative
           begin
            k <= 0;
            highBitEnd <= 1;
             state <=IDLE;
           end
         end
         endcase
       end
    end

 
 genvar i;
 generate 
 for(i =0; i<491; i =i+2)
 begin: compare
 comparator c1(
    .clk(clk),
    .rst(rst),
    .stop(stop),
    .dbValid(dataBaseValid),
    .inQuery(queryReg[i+:22]),
    .inDB(dBCompareWmer),
    .isMatch(ouput[i/2]),
    .highBitEnd(highBitEnd)
        );
  end
 endgenerate
 

 shift2Reg dbShiftReg(
 .clk(clk),
 .rst(rst),
 .load(load),
 .shift(shift),
 .inData(dataBase),
 .outData(dbShiftRegOut)
 );

endmodule
