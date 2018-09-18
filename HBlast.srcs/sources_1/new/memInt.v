`timescale 1ns / 1ps
`define ddrAddrWidth 32

module memInt(
input clk,
input rst,
input ddr_rd_done, // acceptance for reading the data
output reg ddr_rd, // request to read
output reg [`ddrAddrWidth-1:0] readAdd, // address to read from ddr
input ddr_rd_valid, // indicates ddr's readiness 
input [511:0] ddr_rd_data, // data requested from ddr
input [511:0] query,
input queryValid,
//ouput for comparator
//input rdNew,
//output [12:0] maxScoreOut,
//output [31:0] outAddress,
output [31:0] locationStart,
output [31:0] locationEnd,
output [10:0] highestScore,
output processEnd
    );
    
 //From memory interface to expand
 reg [16:0] DataCounter; //???????????????????????????????
 reg [511:0] queryReg; //to write query
 reg [2:0] state; 
 // Hit input
 reg queryValidQ; // queryValid for Hit.v
 reg shift; // shift signal for Hit.v
 reg load; // load signal for Hit.v
 reg [511:0] dbHit; // database for Hit.v
 //hit output
 wire hit; //hit signal that comes from Hit.v
 wire highBitEnd; // signal that goes to Hit.v
 wire [8:0] ShiftNo; // comes from Hit.v
 wire [8:0] locationQ; // comes from Hit.v
 //Expand
 wire loadExpOut; //load request that comes from ExpandFSM.v
 reg queryValidReg; // queryValid signal that goes to ExpandFSM.v
 reg [8:0] locationQReg; // LocationQ that foes to ExpandFSM.v
 reg hitReg; // start signal for ExpandFSM.v
 wire [8:0] ShiftNoReg; // ShiftNo that goes to ExpandFSM.v
 wire [31:0] outAddress; // Address of data requested by  ExpandFSM.v
 reg loadDone; // Signal that goes o  ExpandFSM.v
 reg queryValidExp; // dataValid signal for  ExpandFSM.v
 reg [511:0] dbExpand;  // database for  ExpandFSM.v
 wire stop; // output signal from  ExpandFSM.v 
 reg dbValid; // databaseValid signal that goes to Hit.v
 wire startExpand; 
 localparam IDLE = 3'b000,
            WAIT = 3'b001,
            SHIFT = 3'b011,
            SHIFTLOAD =3'b100,
            WAIT_EXP = 3'b010,
            WAIT_S = 3'b101,
            WAIT_STOP = 3'b111;
 assign ShiftNoReg = ShiftNo;
 always @(posedge clk)
 begin
    if(queryValid)
    begin
    queryReg <= query;
    queryValidQ <=1'b1;
    queryValidReg <= 1'b1;
    end
 end
 
 
 always @(posedge clk)
 begin
 if(rst)
    begin
    queryValidExp <=1'b0;
    queryValidQ <= 1'b0;
    ddr_rd <= 0;
    readAdd <=0;
    DataCounter <=0;
    state <= IDLE;
    end
    
 else 
  begin
     case (state)
     IDLE: begin 
     queryValidExp <= 1'b0;
     
     if( highBitEnd)
         begin
            state <= SHIFT;
            hitReg <= 0;
         end
     else if(startExpand & !stop)
         begin
             hitReg <= 1'b1;
             locationQReg <= locationQ;
             loadDone <= 1'b0;
             if(loadExpOut)
             begin
                ddr_rd <= 1'b1;
                readAdd <= outAddress; 
                state <= WAIT_EXP;
             end
             shift = 1'b0;
             load = 1'b0;
         end
    else 
         begin
            hitReg <= 1'b0;
            if(DataCounter==0)
            begin
                    if(ShiftNo ==0 )   
                    begin
                        if(stop)
                        begin
                        state <= WAIT_STOP;
                        end
                        else
                        begin
                        load <= 1'b0;
                        ddr_rd <= 1'b1;
                        readAdd <= DataCounter*512; 
                        state <= WAIT;
                        shift <=1'b0;
                        end
                    end  
                    
                    else if (ShiftNo != 0 & (ShiftNo % 490 != 0))
                    begin
                        if(!hit)
                        begin
                            shift <=1'b0;
                            state<= SHIFT;
                        end
                        else 
                            state <=IDLE;
                    end
                    
                    else if (ShiftNo % 490 == 0)
                    begin
                         DataCounter <= DataCounter +1; 
                         ddr_rd <= 1'b1;
                         readAdd <= (DataCounter +1)*512; 
                         state <= WAIT; 
                         load <= 0;
                         shift <=0;
                    end
            end
            
           else 
            begin
                if (ShiftNo % 490 != 0 || ShiftNo==0)
                begin
                    if(!hit)
                    begin
                          shift <=1'b0;
                          state<= SHIFT;
                    end
                    
                    else 
                        state <=IDLE;
               end
               
               else if ((ShiftNo % 490 == 0)& ShiftNo !=0)
               begin
                     DataCounter <= DataCounter +1; //Do I need new register to DataCounter?
                     ddr_rd <= 1'b1;
                     readAdd <= (DataCounter +1)*512; 
                     state <= WAIT;
                     load <= 0;
                     shift <=0;
              end
           end
       end
  end
  
      WAIT_STOP:begin
           if(startExpand)
           state <= IDLE;
           else if(highBitEnd)
           begin
            shift <= 1'b1;
            state <= SHIFTLOAD;
             hitReg <= 0;
           end   
      end
      
      WAIT: begin
        ddr_rd <=1'b0;
        if(ddr_rd_valid)// & ddr_rd_done
        begin
            dbValid <= 1'b1;
            dbHit <= ddr_rd_data;
            load <= 1'b1;
             //shift <= 1'b1;
             if(DataCounter == 0)
                 state <= SHIFTLOAD;
             else 
             begin
                shift <= 1'b1;
                state <= SHIFTLOAD;
             end
        end
      end
      
      SHIFT: begin
         if(DataCounter == 0)
         begin
         if(!hit)
            begin
             shift <= 1'b1;
             load <= 1'b0;
             state <= SHIFTLOAD;
             end
          else 
             state <= IDLE;
         end
         else 
         begin
         if(!hitReg)
         begin
            shift <= 1'b1;
            load <= 1'b0;
            state <= SHIFTLOAD;
         end
         else 
            state <= IDLE;
         end
         
      end
      
      SHIFTLOAD: begin
        if(DataCounter == 0)
        begin
            if(queryValid)
            begin
            dbValid <= 1'b1;
            shift <= 1'b0;
            load <= 1'b0;
            state <= WAIT_S;
            end
        end
        else
        begin
            dbValid <= 1'b1;
            shift <= 1'b0;
            load <= 1'b0;
            state <= WAIT_S;
       end
      end
      
     WAIT_EXP: begin
              if(ddr_rd_valid) //& ddr_rd_done)
              begin
                loadDone <= 1'b1;
                queryValidExp <= 1'b1;
                dbValid <= 1'b0;
                dbExpand <= ddr_rd_data;
                ddr_rd <=1'b0;   
              end
              if(loadDone)
                state <= IDLE;
              
           /* if(stop)
            begin
             //  if(highBitEnd)
             //  begin 
                 state <= SHIFT;
                 hitReg <= 0;
              // end
             //  else
               //  state <= IDLE;
            end*/
    end
    WAIT_S: begin
            if(DataCounter == 0)
            begin
              if(queryValid)
                begin
                if(ShiftNo==490 || hit)
                    state <= IDLE;
                else if(!hit)
                    state <= SHIFT;
                end
            end
            else
            begin
                dbValid <=1'b1;
                state <= IDLE;
            end
    end
    endcase
  end
 end 
 

   
 Hit hitMem(
    .clk(clk),
    .rst(rst),
    //only once
    .query(queryReg),
    .queryValid(queryValidQ),
    //data from ddr
    .dataBase(dbHit),  //dataBase 
    .dataBaseValid(dbValid),
    .shift(shift),
    .load(load),
    .stop(stop),
    //output
    .ShiftNo(ShiftNo),
    .hit(hit),
    .startExpand(startExpand),
    .locationQ(locationQ),
    .highBitEnd(highBitEnd)
        );
        
        
    ExpandFSM Expand(
    .clk(clk),
    .rst(rst),
    .start(hitReg), // May be in next state
    .queryValid(queryValidReg),    
    .dataValid(queryValidExp),
    //.ready(ready),
    .shiftNo(ShiftNoReg),
    .dataCounter(DataCounter),
    .inQuery(queryReg),
    .LocationQ(locationQReg),
    .inDB(dbExpand), //dataBase 
    .load(loadExpOut),
    .loadDone(loadDone),
    .outAddress(outAddress),
    .highestLocationStart(locationStart),
    .highestLocationEnd(locationEnd),
    .maxScore(highestScore),
    .stop(stop),
    .processEnd(processEnd)
            );
endmodule
