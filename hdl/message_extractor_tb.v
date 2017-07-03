`timescale 1ns / 100ps

module message_extractor_tb;

  reg reset_n = 0;
  reg clk;
  reg in_valid = 0;
  reg in_startofpacket = 0;
  reg in_endofpacket = 0;
  reg in_error = 0;
  reg [2:0]     in_empty = 0;
  reg [63:0]    in_data = 0;

  wire          in_ready, out_valid;
  wire [255:0]  out_data;
  wire [31:0]   out_bytemask;

  initial #10 reset_n = 1;

  always begin
     clk = 1'b0;
     #(10/2) clk = 1'b1;
     #(10/2);
  end

  msg_extractor_top dut (
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

initial begin
  @(posedge reset_n);
  @(posedge clk);
  @(posedge clk); {in_data,in_startofpacket,in_endofpacket,in_valid,in_empty,in_error}<={64'h0008000862626262,1'b1,1'b0,1'b1,3'bX,1'b0};
  @(posedge clk); {in_data,in_startofpacket,in_endofpacket,in_valid,in_empty,in_error}<={64'h62626262000c6868,1'b0,1'b0,1'b1,3'bX,1'b0};
  @(posedge clk); {in_data,in_startofpacket,in_endofpacket,in_valid,in_empty,in_error}<={64'h6868686868686868,1'b0,1'b0,1'b1,3'bX,1'b0};
  @(posedge clk); {in_data,in_startofpacket,in_endofpacket,in_valid,in_empty,in_error}<={64'h6868000a70707070,1'b0,1'b0,1'b1,3'bX,1'b0};
  @(posedge clk); {in_data,in_startofpacket,in_endofpacket,in_valid,in_empty,in_error}<={64'h707070707070000f,1'b0,1'b0,1'b1,3'bX,1'b0};
  @(posedge clk); {in_data,in_startofpacket,in_endofpacket,in_valid,in_empty,in_error}<={64'h7a7a7a7a7a7a7a7a,1'b0,1'b0,1'b1,3'bX,1'b0};
  @(posedge clk); {in_data,in_startofpacket,in_endofpacket,in_valid,in_empty,in_error}<={64'h7a7a7a7a7a7a7a00,1'b0,1'b0,1'b1,3'bX,1'b0};
  @(posedge clk); {in_data,in_startofpacket,in_endofpacket,in_valid,in_empty,in_error}<={64'h0e4d4d4d4d4d4d4d,1'b0,1'b0,1'b1,3'bX,1'b0};
  @(posedge clk); {in_data,in_startofpacket,in_endofpacket,in_valid,in_empty,in_error}<={64'h4d4d4d4d4d4d4d00,1'b0,1'b0,1'b1,3'bX,1'b0};
  @(posedge clk); {in_data,in_startofpacket,in_endofpacket,in_valid,in_empty,in_error}<={64'h1138383838383838,1'b0,1'b0,1'b1,3'bX,1'b0};
  @(posedge clk); {in_data,in_startofpacket,in_endofpacket,in_valid,in_empty,in_error}<={64'h3838383838383838,1'b0,1'b0,1'b1,3'bX,1'b0};
  @(posedge clk); {in_data,in_startofpacket,in_endofpacket,in_valid,in_empty,in_error}<={64'h3838000b31313131,1'b0,1'b0,1'b1,3'bX,1'b0};
  @(posedge clk); {in_data,in_startofpacket,in_endofpacket,in_valid,in_empty,in_error}<={64'h3131313131313100,1'b0,1'b0,1'b1,3'bX,1'b0};
  @(posedge clk); {in_data,in_startofpacket,in_endofpacket,in_valid,in_empty,in_error}<={64'h095a5a5a5a5a5a5a,1'b0,1'b0,1'b1,3'bX,1'b0};
  @(posedge clk); {in_data,in_startofpacket,in_endofpacket,in_valid,in_empty,in_error}<={64'h5a5a000000000000,1'b0,1'b1,1'b1,3'd6,1'b0};
end

always @(posedge clk)
begin
    if (out_valid)
        $display("output pakets = %h, packet_size =%d "  , out_data, "./dut/payload_sz" );     
end    

endmodule