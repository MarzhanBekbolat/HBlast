`timescale 1ns / 1ps
`define th 200

   module ExpandFSM(
    input clk,
    input rst,
    input start,
    input queryValid,    
    input dataValid,
    input [8:0] shiftNo,
    input [16:0] dataCounter,
    input [511:0] inQuery,
    input [8:0] LocationQ,
    input [511:0]inDB,
       
    output reg load,
    input  loadDone,
    output [31:0] outAddress,
    output  [31:0] hsStart1,
    output  [31:0] hsnEnd1,
    output [10:0] hs1,
    output  [31:0] hsStart2,
    output  [31:0] hsnEnd2,
    output [10:0] hs2,
    output  [31:0] hsStart3,
    output  [31:0] hsnEnd3,
    output [10:0] hs3,
    output  [31:0] hsStart4,
    output  [31:0] hsnEnd4,
    output [10:0] hs4,
    output  [31:0] hsStart5,
    output  [31:0] hsnEnd5,
    output [10:0] hs5,
    output reg stop,
    output processEnd
    );
    
    reg [9:0] shiftNumber;
    reg [511:0] dataSet1;
    reg [511:0] dataSet2;
    reg [31:0] addressCalc;
    reg [1023:0] dataMerged;
    reg [511:0] Query;
    reg [2:0] state;
    reg rst1;
    wire [10:0] Score;
    reg [31:0] locationStart;
    reg [31:0] locationEnd;
         
    wire [8:0] range1;
    wire [8:0] range2;
    reg [8:0] rangeD;
    reg [8:0] k1=0;
    reg [8:0] k2=0;
    reg [8:0] i1;
    reg [8:0] i2;
    reg [9:0] m1;
    reg [9:0] m2;
    reg [1:0] b1;
    reg [1:0] b2;
    reg startCalc;
    
    
    localparam IDLE = 3'b000,
               LOAD1 = 3'b001,
               LOAD2 = 3'b010,
               EXPAND = 3'b011,
               WAIT   = 3'b100,
               MERGE  = 3'b101,
               WAIT_LOAD_DONE = 3'b110;
                              

               
    
    assign outAddress = addressCalc;
    assign  range1 = LocationQ <= `th ? LocationQ : `th;    
    assign  range2 = (512 - (LocationQ + 22)) <= `th ? (512 - (LocationQ + 22)) : `th; 
    //assign rangeD =  ( LocationQ <= `th ? LocationQ : `th)<= locationStart ? ( LocationQ <= `th ? LocationQ : `th) : locationStart;
        
    always @(posedge clk)
    begin
        if(rst)
        begin
            state <= IDLE;
            load = 1'b0;
            stop =  1'b0;
        end
        else
        begin
            case(state)
                IDLE:begin 
                    rst1 <= 1'b1;
                    stop <= 1'b0;
                    shiftNumber = shiftNo;  
                    addressCalc = dataCounter * 512 + shiftNumber;
                    i1 <= LocationQ;
                    i2 <= LocationQ + 22;
                    m1 <= shiftNumber;
                    m2 <= shiftNumber + 22;
                    locationStart <= dataCounter * 512 + shiftNumber;
                    locationEnd <= dataCounter * 512 + shiftNumber + 21;
                    startCalc <=0;
                    if(queryValid)
                        Query <= inQuery;
                    if(!stop & start)
                    begin
                        rangeD <=  ( LocationQ <= `th ? LocationQ : `th)<= locationStart ? ( LocationQ <= `th ? LocationQ : `th) : locationStart;
                        state <= WAIT;
                        load <= 1'b1;
                    end
                end
                WAIT:begin
                     rst1 <= 1'b0;
                     //load <= 1'b0;
                     if(loadDone)
                     begin
                        load <= 1'b0;
                        state <= LOAD1;
                     end
                end
                LOAD1:begin
                    if(dataValid)
                    begin
                        if(dataCounter == 0 & shiftNumber < 199)
                        begin
                            dataMerged[511:0] <= inDB;
                            dataMerged[1023:512] <= 512'h0;
                            state <= EXPAND;
                             startCalc <= 1;
                        end    
                        else if(shiftNumber < 199)
                         begin
                            m1 <= shiftNumber + 512;
                            m2 <= shiftNumber + 512 + 22;
                            dataMerged[1023:512] <= inDB;
                            state <= LOAD2;
                            //load <= 1'b1;
                         end
                         else if(shiftNumber > 290)
                         begin
                            dataMerged[511:0] <= inDB;
                            state <= LOAD2;
                            //load <= 1'b1;
                         end 
                         else
                         begin
                            dataMerged[511:0] <= inDB;
                            dataMerged[1023:512] <= 512'h0;
                            state <= EXPAND;
                             startCalc <= 1;
                         end
                    end
                end
                LOAD2:begin
                    load <= 1'b1; 
                    if(shiftNumber < 199)
                    begin
                       addressCalc <= addressCalc - 512; 
                    end
                    else if(shiftNumber > 290)
                    begin
                        addressCalc <= addressCalc + 512;     
                    end          
                        state <=WAIT_LOAD_DONE;
                        
                end
                WAIT_LOAD_DONE:begin
                load <= 1'b0;
                if(loadDone)
                   state <= MERGE;
                end
                MERGE:begin
                    if(dataValid)
                    begin
                        if(shiftNumber < 199)
                        begin
                             //shiftNumber <= shiftNumber + 512;              
                             dataMerged[511:0] <= inDB;                       
                        end
                        else if(shiftNumber > 290)
                        begin
                             dataMerged[1023:512] <= inDB;               
                        end
                        state <= EXPAND;
                        startCalc <= 1;
                    end
                end
                
                EXPAND:begin
                        if(dataMerged[m1-:2] != Query[i1-:2] & dataMerged[m2+:2] != Query[i2+:2]) 
                        begin
                            stop <= 1'b1;
                            b1 <= 0;
                            b2 <= 0;
                            k1 <=0;
                            k2 <=0;
                            state <= IDLE;
                        end
                        else if(k1 == range1 & k2 == range2)
                        begin
                            b1 <= 0;
                            b2 <= 0;                        
                            k1 <=0;
                            k2 <=0;
                            stop <= 1'b1;
                            state <= IDLE;
                        end
                        else 
                        begin
                        if(k1 != range1)
                        begin
                              stop <= 1'b0;
                              //k1 <= k1 + 2;
                              m1 <= m1 - 2;
                              i1 <= i1 - 2; 
                              if(dataCounter==0 & k1==rangeD)
                              begin
                                // stop <=1;
                                 k1 <=range1;
                              end
                              else if(dataMerged[m1-:2] == Query[i1-:2]) 
                              begin
                                   k1 <= k1 + 2;
                                   locationStart <= locationStart - 2;
                                   b1 <= 1;
                              end     
                              else if(dataMerged[m2+:2] == Query[i2+:2] & k2!= range2) // Added lines by me
                              begin
                                    k1 <= k1 + 2;
                                   locationStart <= locationStart - 2;
                                   b1 <= 0;
                              end
                              else
                              begin
                              stop <= 1;
                              k2 <= 0;
                              k1 <= 0;
                              state <= IDLE;
                              b1 <= 0;
                              b2 <= 0;  
                              end
                        end
                            else if(k1 == range1)
                            begin
                              b1 <= 2;
                            end
                            if(k2 != range2)
                            begin
                                stop <= 1'b0;
                                k2 <= k2 + 2;
                                m2 <= m2 + 2;
                                i2 <= i2 + 2; 
                                if(dataMerged[m2+:2] == Query[i2+:2]) 
                                begin
                                   locationEnd  <= locationEnd + 2;
                                   b2 <= 1;
                                 end
                                  else if(dataMerged[m1-:2] == Query[i1-:2]& k1!= range1) 
                                 begin
                                   locationEnd  <= locationEnd + 2;
                                   b2 <= 0;
                                 end
                                 else
                                  begin
                                   b1 <= 0;
                                   b2 <= 0;
                                   k2 <= 0;
                                   k1 <= 0;
                                   state <= IDLE;
                                   stop <= 1;
                                  end
                                  
                            end  
                            else if(k2 == range2)  
                            b2 <= 2;
                        end        
                end
            endcase
        end
    end        
    
    
    highScore ScoreX(
           .clk(clk),
           .rst(rst1),
           .b1(b1),
           .b2(b2),
           .stop(stop),
           .locationStart(locationStart),
           .locationEnd(locationEnd),
           .startCalc(startCalc),
           .Score(Score),
           .theHighestScore1(hs1),
           .highestLocationStart1(hsStart1),
           .highestLocationEnd1(hsnEnd1),
           .theHighestScore2(hs2),
           .highestLocationStart2(hsStart2),
           .highestLocationEnd2(hsnEnd2),
           .theHighestScore3(hs3),
           .highestLocationStart3(hsStart3),
           .highestLocationEnd3(hsnEnd3),
           .theHighestScore4(hs4),
           .highestLocationStart4(hsStart4),
           .highestLocationEnd4(hsnEnd4),
           .theHighestScore5(hs5),
           .highestLocationStart5(hsStart5),
           .highestLocationEnd5(hsnEnd5),
           .processEnd(processEnd)
        );
   endmodule
