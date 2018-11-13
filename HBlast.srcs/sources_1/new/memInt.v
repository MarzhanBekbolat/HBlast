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
output [31:0] locationStart1,
output [31:0] locationEnd1,
output [10:0] highestScore1,
output [31:0] locationStart2,
output [31:0] locationEnd2,
output [10:0] highestScore2,
output [31:0] locationStart3,
output [31:0] locationEnd3,
output [10:0] highestScore3,
output [31:0] locationStart4,
output [31:0] locationEnd4,
output [10:0] highestScore4,
output [31:0] locationStart5,
output [31:0] locationEnd5,
output [10:0] highestScore5,
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
                 $display("Read signal from expand from address:   %d", outAddress);
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
                        else if(queryValid)
                        begin
                        load <= 1'b0;
                        ddr_rd <= 1'b1;
                        $display("Read signal for not start expand from address:   %d", DataCounter*512);
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
                         $display("Read signal for ShiftNo rem 490 == 0 from address:   %d", (DataCounter +1)*512);
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
                     $display("Read signal for ShiftNo rem 490 == 0 and shiftNo non zero from address:   %d", (DataCounter +1)*512);
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
            $display("Data came from ddr:   %h", ddr_rd_data);
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
   
            dbValid <= 1'b1;
            shift <= 1'b0;
            load <= 1'b0;
            state <= WAIT_S;
      end
      
     WAIT_EXP: begin
              ddr_rd <=1'b0;  
              if(ddr_rd_valid) //& ddr_rd_done)
              begin
                loadDone <= 1'b1;
                queryValidExp <= 1'b1;
                 $display("Data came from ddr to Exapnd:   %h", ddr_rd_data);
                dbValid <= 1'b0;
                dbExpand <= ddr_rd_data; 
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
              /*if(queryValid)
                begin*/
                if(ShiftNo==490 || hit)
                    state <= IDLE;
                else if(!hit)
                    state <= SHIFT;
                end
            //end
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
    .hsStart1(locationStart1),
    .hsnEnd1(locationEnd1),
    .hs1(highestScore1),
    .hsStart2(locationStart2),
    .hsnEnd2(locationEnd2),
    .hs2(highestScore2),
    .hsStart3(locationStart3),
    .hsnEnd3(locationEnd3),
    .hs3(highestScore3),
    .hsStart4(locationStart4),
    .hsnEnd4(locationEnd4),
    .hs4(highestScore4),
    .hsStart5(locationStart5),
    .hsnEnd5(locationEnd5),
    .hs5(highestScore5),
    .stop(stop),
    .processEnd(processEnd)
            );
           
endmodule
