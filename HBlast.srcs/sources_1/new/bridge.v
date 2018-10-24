`define dbStartAddress  0

module brdige (
//global signals
input clk,
input rst,
//Write signals from PCIe
input i_wr,
output reg o_wr_done,
input [63:0] i_wr_data,
//DDR command interface
output reg o_ddr_app_en,
output reg [2:0] o_ddr_cmd,
output reg [27:0] o_ddr_addr,
input i_ddr_app_rdy,
//DDR Write interface
output reg [63:0] o_ddr_wr_data,
output reg o_ddr_wr_en,
input i_ddr_wr_rdy,
//Read signals from Hit logic
input i_rd,
output reg o_rd_ack,
input [27:0] i_rd_addr,
output wire [511:0] o_rd_data,
output reg o_rd_valid,
//DDR read signals
input [63:0] i_ddr_rd_data,
input i_ddr_rd_data_valid
);

reg [27:0] ddr_wr_addr;
reg [1:0] state;
reg [2:0] rdCount;
reg [2:0] receivedRdCount;
reg [63:0] rdData[7:0]; //This should be 8 bit I guess

assign o_rd_data = {rdData[7],rdData[6],rdData[5],rdData[4],rdData[3],rdData[2],rdData[1],rdData[0]};

localparam IDLE = 'd0,
			WAIT_WR = 'd1,
			WAIT_RD = 'd2,
			WAIT_WR_CMD = 'd3;

always @(posedge clk)
begin
	if(rst)
	begin
		ddr_wr_addr <= `dbStartAddress;
		o_ddr_wr_en <= 1'b0;
		state <= IDLE;
		o_rd_ack <= 1'b0;
		o_wr_done <= 1'b0;
		o_ddr_app_en <= 1'b0;
	end
	case(state)
		IDLE:begin
			if(i_wr)
			begin
				o_ddr_app_en <= 1'b1;
				o_ddr_cmd <= 2'b000;
				o_ddr_addr <= ddr_wr_addr;
				state <= WAIT_WR_CMD;
			end
			else if(i_rd)
			begin
				o_ddr_app_en <= 1'b1;
				o_ddr_cmd <= 2'b001;
				o_ddr_addr <= (i_rd_addr/512)*64;
				rdCount <= 0;
				o_rd_ack <= 1'b1;
				state <= WAIT_RD;
			end
		end
		WAIT_WR_CMD:begin
			if(i_ddr_app_rdy)
			begin
				o_ddr_app_en <= 1'b0;				
				o_ddr_wr_data <= i_wr_data;
				o_ddr_wr_en <= 1'b1;
				o_wr_done <= 1'b1;
				state <= WAIT_WR;
			end
		end
		WAIT_WR:begin
			o_wr_done <= 1'b0;
			if(i_ddr_wr_rdy)
			begin
				o_ddr_wr_en <= 1'b0;
				ddr_wr_addr <= ddr_wr_addr+8;				
				state <= IDLE;
			end
		end
		WAIT_RD:begin
			o_rd_ack <= 1'b0;
			if(i_ddr_app_rdy)
			begin
				rdCount <= rdCount + 1;
				o_ddr_addr <= o_ddr_addr + 8;
				if(rdCount == 7)
				begin
					o_ddr_app_en <= 1'b0;
					state <= IDLE;
				end
			end
		end
	endcase
end

always @(posedge clk)
begin
    if(rst)
        receivedRdCount <= 0;
    else if(i_ddr_rd_data_valid)
    begin
        rdData[receivedRdCount] = i_ddr_rd_data;
        receivedRdCount <= receivedRdCount+1;
    end
end

always @(posedge clk)
begin
    if(receivedRdCount==7 & i_ddr_rd_data_valid)
        o_rd_valid = 1'b1;
    else
        o_rd_valid = 1'b0;
end
    

endmodule