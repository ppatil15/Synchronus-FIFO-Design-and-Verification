module fifo #(parameter depth=8, parameter width=8)(input clk, input rst_n, 
 input wr_en, input rd_en, input [width-1:0] din, output reg [width-1:0] dout, 
 output full, output empty, output reg [$clog2(depth):0] count);
 reg [width-1:0] mem [0:depth-1];
 reg [$clog2(depth)-1:0] wr_ptr,rd_ptr;

 always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
	   wr_ptr <=0;
	   count <= 0;
	end
	else if (wr_en && !full) begin
	   mem[wr_ptr] <= din;
	   wr_ptr <= wr_ptr + 1 ;
	   count <= count + 1;
	end
 end

 always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
	   rd_ptr <=0;
	   count <=0;
	end
	else if (rd_en && !empty) begin
	   dout <= mem[rd_ptr];
	   rd_ptr <= rd_ptr + 1;
	   count <= count -1;
	end
 end

 assign full = (count == depth);
 assign empty = (count == 0);

endmodule

	   
//hi

