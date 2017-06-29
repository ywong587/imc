module msg_extractor_fsm (
      input   clk, reset_n, in_valid, in_startofpacket, in_endofpacket, in_error,
      input   [63:0]  in_data,
      input   [2:0]   in_empty,
      output  reg in_ready, out_valid,
      output  reg [255:0] out_data,
      output  reg [5:0]  payload_size
      );

      reg     [3:0]   state, nextstate;
      reg     [15:0]  msg_count, nx_msg_count;
      reg     [15:0]  msg_length, nx_msg_length;
      reg     [63:0]  payload0, nx_payload0;
      reg     [3:0]   payload0_sz, nx_payload0_sz;
      reg     [7:0]   payload0_mask, nx_payload0_mask;
      reg     [255:0] payload, nx_payload;
      reg     [31:0]  payload_mask, nx_payload_mask;
      reg     [5:0]   payload_sz, nx_payload_sz;

      parameter IDLE        = 3'd0,
                GO          = 3'd1,
                STOP        = 3'd2;

// state and variables updating block:
      always @(posedge clk or negedge reset_n)
      begin
        if (!reset_n)
        begin
          state         <= IDLE;
          msg_count     <= 16'd0;
          msg_length    <= 16'd0;
          payload       <= 256'd0;
          payload_mask  <= 32'd0;
          payload_sz    <= 6'd0;
          payload0      <= 64'd0;
          payload0_mask <= 8'd0;
          payload0_sz   <= 4'd0;

        end
        else
        begin
          state         <= nextstate;
          msg_count     <= nx_msg_count;
          msg_length    <= nx_msg_length;
          payload       <= nx_payload;
          payload_mask  <= nx_payload_mask;
          payload_sz    <= nx_payload_sz;
          payload0      <= nx_payload0;
          payload0_mask <= nx_payload0_mask;
          payload0_sz   <= nx_payload0_sz;

        end
      end

// outputs updating block:
      always @(state or in_valid or in_startofpacket or in_endofpacket or in_error)
      begin
        out_data = 256'd0;
        out_valid = 1'b0;
        payload_size = 6'd0;
        in_ready = 1'b0;

        case(state)
          IDLE: begin
                  in_ready = 1'b1;
                end
          GO:   begin
                  in_ready = 1'b0;
                  if (in_valid & !in_error & (msg_length < 16'd8)) begin
                    out_valid = 1'b1;
                    out_data = payload;
                    payload_size = payload0_sz;
                  end
                end
          STOP: begin
                  in_ready = 1'b0;
                  out_valid = 1'b1;
                  out_data = payload;
                  payload_size = payload0_sz;
                end
        endcase
      end

// nextstate and nx_<variable> updating block:
      always @(state or in_valid or in_startofpacket or in_endofpacket or in_error or in_data)
      begin
        nextstate       = IDLE;
        nx_msg_count    = 16'd0;
        nx_msg_length   = 16'd0;
        nx_payload      = 64'd0;
        nx_payload_mask = 63'h00000000;
        nx_payload_sz   = 6'd0;
        nx_payload0     = 64'd0;
        nx_payload_mask = 63'h0;
        nx_payload_sz   = 4'd0;

        case (state)
          IDLE:   if (in_valid & in_startofpacket & !in_error) begin
                    nextstate       = GO;
                    nx_msg_count    = in_data[63:48] - 16'd1;
                    nx_msg_length   = in_data[47:32] - 16'd4;
                    nx_payload      = in_data[31:0];
                    nx_payload_mask = 63'h0000FFFF;
                    nx_payload_sz   = 6'd4;
                    nx_payload0     = 64'd0;
                    nx_payload_mask = 63'h0;
                    nx_payload_sz   = 4'd0;
                  end

          GO:     if (in_valid & !in_error) begin
                    if (msg_count==16'd0) begin
                      nextstate     = STOP;
                      nx_msg_count  = 16'd0;
                      nx_msg_length = 16'd0;
                      nx_payload    = (payload  << ((msg_length+payload0_sz)<<3))   |
                                      (payload0 << (payload0_sz<<3))                |
                                      (in_data  >> (16'd64-(msg_length<<3)));
                      nx_payload_sz = payload_sz + payload0_sz + msg_length;
                      nx_payload0   = 64'd0;
                      nx_payload0_sz  = 4'd0;
                      nx_payload_mask = 32'd0;
                    end
                    else begin
                      nextstate     = GO;
                      nx_msg_count  = msg_count - 16'd1;
                      if (msg_length == 16'd0) begin
                        nx_msg_length = in_data[63:48] - 16'd6;
                        nx_payload    = 256'd0;
                        nx_payload_sz = 6'd0;
                        nx_payload0   = in_data[47:0];
                        nx_payload0_sz  = 4'd6;
                        nx_payload_mask = 32'b111111;
                      end

                      else if (msg_length == 16'd1) begin
                        nx_msg_length = in_data[55:40] - 16'd5; // in_data[(16'd64-16'd16-(msg_length<<3)+:16]
                        nx_payload    = (payload  << ((msg_length+payload0_sz)<<3))   |
                                        (payload0 <<  (msg_length<<3))                |
                                        in_data[63:56];
                        nx_payload_sz = payload_sz + msg_length;
                        nx_payload0   = in_data[39:0];
                        nx_payload0_sz  = 4'd5;
                        nx_payload_mask = 32'b11111;
                      end
                      else if (msg_length == 16'd2) begin
                        nx_msg_length = in_data[47:32] - 16'd4; // nx_msg_length = in_data[(16'd48-(msg_length<<3))+:16]-(16'd6-msg_length);
                        nx_payload    = (payload  << ((msg_length+payload0_sz)<<3))   |
                                        (payload0 <<  (msg_length<<3))                |
                                        in_data[63:48];
                        nx_payload_sz = payload_sz + msg_length;
                        nx_payload0   = in_data[31:0];
                        nx_payload0_sz  = 4'd4;         // nx_payload0_sz = 4'd6-4'd2-msg_length;
                        nx_payload_mask = 32'b1111;     // ?
                      end
                      else if (msg_length == 16'd3) begin
                        nx_msg_length = in_data[39:24] - 16'd3;
                        nx_payload    = (payload  << ((msg_length+payload0_sz)<<3))   |
                                        (payload0 <<  (msg_length<<3))                |
                                        in_data[63:40];
                        nx_payload_sz = payload_sz + msg_length;
                        nx_payload0   = in_data[23:0];
                        nx_payload0_sz  = 4'd3;
                        nx_payload_mask = 32'b111;
                      end
                      else if (msg_length == 16'd4) begin
                        nx_msg_length = in_data[31:16] - 16'd2;
                        nx_payload    = (payload  << ((msg_length+payload0_sz)<<3))   |
                                        (payload0 <<  (msg_length<<3))                |
                                        in_data[63:32];
                        nx_payload_sz = payload_sz + msg_length;
                        nx_payload0   = in_data[15:0];
                        nx_payload0_sz  = 4'd2;
                        nx_payload_mask = 32'b11;
                      end
                      else if (msg_length == 16'd5) begin
                        nx_msg_length = in_data[23:8] - 16'd1;
                        nx_payload    = (payload  << ((msg_length+payload0_sz)<<3))   |
                                        (payload0 <<  (msg_length<<3))                |
                                        in_data[63:24];
                        nx_payload_sz = payload_sz + msg_length;
                        nx_payload0   = in_data[7:0];
                        nx_payload0_sz  = 4'd1;
                        nx_payload_mask = 32'b1;
                      end
                      else if (msg_length == 16'd6) begin
                        nx_msg_length = in_data[23:8];
                        nx_payload    = (payload  << ((msg_length+payload0_sz)<<3))   |
                                        (payload0 <<  (msg_length<<3))                |
                                        in_data[63:16];
                        nx_payload_sz = payload_sz + msg_length;
                        nx_payload0   = 64'd0;
                        nx_payload0_sz  = 4'd0;
                        nx_payload_mask = 32'b0;
                      end
                      else if (msg_length == 16'd7) begin
                        nx_msg_length = in_data[7:0];
                        nx_payload    = (payload  << ((msg_length+payload0_sz)<<3))   |
                                        (payload0 <<  (msg_length<<3))                |
                                        in_data[63:8];
                        nx_payload_sz = payload_sz + msg_length;
                        nx_payload0   = 64'd0;
                        nx_payload0_sz  = 4'd0;
                        nx_payload_mask = 32'b0;
                      end
                      else begin // msg_length > 8
                        nx_msg_length = msg_length - 16'd8;
                        nx_payload    = (payload  << ((16'd8+payload0_sz)<<3))        |
                                        (payload0 <<  64)                             |
                                        in_data[63:0];
                        nx_payload_sz = payload_sz + 16'd8;
                        nx_payload0   = 64'd0;
                        nx_payload0_sz  = 4'd0;
                        nx_payload_mask = 32'b0;
                      end
                    end
                  end
          STOP:   begin // default nothing to do
                    nextstate = IDLE;
                  end
        endcase
      end

endmodule

