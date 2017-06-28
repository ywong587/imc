`timescale 1ns / 1ps

module message_extractor_tb;
	
  reg clk, reset_n, in_valid, in_startofpacket, in_endofpacket, in_error;
 	reg [2:0]			in_empty;
 	reg [63:0]		in_data;
	wire					in_ready, out_valid;
	wire [255:0]	out_data; 
	wire [31:0]		out_bytemask;		


  initial begin
    clk = 1'b0;
    reset_n = 1'b0;
    repeat(4) #10 clk = ~clk;
    reset_n = 1'b1;    
    forever #10 clk = ~clk; 
  end			
	     
  message_extractor dut (
	      .clk(clk), 
	      .reset_n(reset_n), 
	      .in_valid(in_valid), 
	      .in_startofpacket(in_startofpacket), 
	      .in_endofpacket(in_endofpacket), 
	      .in_error(in_error), 
	      .in_data(in_data), 
	      .in_empty(in_empty),
	       
	      .in_ready(in_ready),       
	      .out_valid(out_valid), 
	      .out_data(out_data), 
	      .out_bytemask(out_bytemask)
      );

	
endmodule	