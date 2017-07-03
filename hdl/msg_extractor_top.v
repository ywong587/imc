  `timescale 1 ns / 100 ps

  module msg_extractor_top (
      input   clk, reset_n, in_valid, in_startofpacket, in_endofpacket, in_error,
      input   [63:0]  in_data,
      input   [2:0]   in_empty,
      output  in_ready, out_valid,
      output  [255:0] out_data,
      output  [31:0] out_bytemask
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
            .out_bytemask(out_bytemask),
            .payload_size(payload_sz)
      );

  endmodule
