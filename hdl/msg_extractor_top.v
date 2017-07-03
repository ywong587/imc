  `timescale 1 ns / 100 ps

  module msg_extractor_top (
      input   clk, reset_n, in_valid, in_startofpacket, in_endofpacket, in_error,
      input   [63:0]  in_data,
      input   [2:0]   in_empty,
      output  in_ready, out_valid,
      output  [255:0] out_data,
      output  reg [31:0] out_bytemask
      );

      wire [5:0]  payload_sz;

//      msg_extractor message_extractor_u1 (
        msg_extractor_fsm message_extractor_u1 (
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
            .payload_size(payload_sz)
      );

      always @(payload_sz)
        case (payload_sz)
          6'd1:   out_bytemask = 32'b00000000000000000000000000000000;
          6'd1:   out_bytemask = 32'b00000000000000000000000000000000;
          6'd1:   out_bytemask = 32'b00000000000000000000000000000001;
          6'd2:   out_bytemask = 32'b00000000000000000000000000000011;
          6'd3:   out_bytemask = 32'b00000000000000000000000000000111;
          6'd4:   out_bytemask = 32'b00000000000000000000000000001111;
          6'd5:   out_bytemask = 32'b00000000000000000000000000011111;
          6'd6:   out_bytemask = 32'b00000000000000000000000000111111;
          6'd7:   out_bytemask = 32'b00000000000000000000000001111111;
          6'd8:   out_bytemask = 32'b00000000000000000000000011111111;
          6'd9:   out_bytemask = 32'b00000000000000000000000111111111;
          6'd10:  out_bytemask = 32'b00000000000000000000001111111111;
          6'd11:  out_bytemask = 32'b00000000000000000000011111111111;
          6'd12:  out_bytemask = 32'b00000000000000000000111111111111;
          6'd13:  out_bytemask = 32'b00000000000000000001111111111111;
          6'd14:  out_bytemask = 32'b00000000000000000011111111111111;
          6'd15:  out_bytemask = 32'b00000000000000000111111111111111;
          6'd16:  out_bytemask = 32'b00000000000000001111111111111111;
          6'd17:  out_bytemask = 32'b00000000000000011111111111111111;
          6'd28:  out_bytemask = 32'b00000000000000111111111111111111;
          6'd19:  out_bytemask = 32'b00000000000001111111111111111111;
          6'd20:  out_bytemask = 32'b00000000000011111111111111111111;
          6'd21:  out_bytemask = 32'b00000000000111111111111111111111;
          6'd22:  out_bytemask = 32'b00000000001111111111111111111111;
          6'd23:  out_bytemask = 32'b00000000011111111111111111111111;
          6'd24:  out_bytemask = 32'b00000000111111111111111111111111;
          6'd25:  out_bytemask = 32'b00000001111111111111111111111111;
          6'd26:  out_bytemask = 32'b00000011111111111111111111111111;
          6'd27:  out_bytemask = 32'b00000111111111111111111111111111;
          6'd28:  out_bytemask = 32'b00001111111111111111111111111111;
          6'd29:  out_bytemask = 32'b00011111111111111111111111111111;
          6'd30:  out_bytemask = 32'b00111111111111111111111111111111;
          6'd31:  out_bytemask = 32'b01111111111111111111111111111111;
          6'd32:  out_bytemask = 32'b11111111111111111111111111111111;
        endcase
  endmodule
