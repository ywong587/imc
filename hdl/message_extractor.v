module message_extractor (
      input   clk, reset_n, in_valid, in_startofpacket, in_endofpacket, in_error,
      input   [63:0]  in_data,
      input   [2:0]   in_empty,
      output  reg in_ready, out_valid,
      output  reg [255:0] out_data,
      output  reg [31:0]  out_bytemask
      );

      reg     [3:0]   state, next;
      reg     [15:0]  msg_count, msg_length;
      reg     [63:0]  payload0, payload1;
      reg     [3:0]   payload0_sz, payload1_sz;
      reg     [7:0]   payload0_mask, payload1_mask;
      reg     [2:0]   payload_mask;

      parameter IDLE        = 4'b0000,
                FIRST_PKT   = 4'b0001,
                MID_PKT     = 4'b0010,
                LEN_SPLIT   = 4'b0011,
                LEN_LOC0    = 4'b0100,
                LEN_LOC1    = 4'b0101,
                LEN_LOC2    = 4'b0110,
                LEN_LOC3    = 4'b0111,
                LEN_LOC4    = 4'b1000,
                LEN_LOC5    = 4'b1001,
                LEN_LOC6    = 4'b1010,
                LEN_LOC7    = 4'b1011,
                LAST_PKT    = 4'b1100;

      parameter LEN1        = 4'd1,
                LEN2        = 4'd2,
                LEN3        = 4'd3,
                LEN4        = 4'd4,
                LEN5        = 4'd5,
                LEN6        = 4'd6,
                LEN7        = 4'd7,
                LEN8        = 4'd8;

  always @ (negedge clk or negedge reset_n)
    if (!reset_n)   state <= IDLE;
    else            state <= next;
  always @ (state or in_valid or in_startofpacket or in_endofpacket) begin
    next =4'bx;
      case(state)
        IDLE       :  if (in_valid&in_startofpacket)next = FIRST_PKT;

        FIRST_PKT  :  if (in_valid) begin
                        if      (msg_length==16'd7) next = LEN_LOC0;
                        else if (msg_length==16'd6) next = LEN_LOC1;
                        else if (msg_length==16'd5) next = LEN_LOC2;
                        else if (msg_length==16'd4) next = LEN_LOC3;
/* These state transactions not need for: min msg_length=8
                        else if (msg_length==16'd3) next = LEN_LOC4;
                        else if (msg_length==16'd2) next = LEN_LOC5;
                        else if (msg_length==16'd1) next = LEN_LOC6;
                        else if (msg_length==16'd0) next = LEN_LOC7;
                        if (in_endofpacket)         next = LAST_PKT;
*/
                        else                        next = MID_PKT;
                      end

        MID_PKT    :  if (in_valid) begin
                        if      (msg_length==16'd7) next = LEN_LOC0;
                        else if (msg_length==16'd6) next = LEN_LOC1;
                        else if (msg_length==16'd5) next = LEN_LOC2;
                        else if (msg_length==16'd4) next = LEN_LOC3;
                        else if (msg_length==16'd3) next = LEN_LOC4;
                        else if (msg_length==16'd2) next = LEN_LOC5;
                        else if (msg_length==16'd1) next = LEN_LOC6;
                        else if (msg_length==16'd0) next = LEN_LOC7;
                        if (in_endofpacket)         next = LAST_PKT;
                        else                        next = MID_PKT;
                      end
        LEN_SPLIT : if (in_valid) begin
                        if      (msg_length==16'd7) next = LEN_LOC0;
                        else if (msg_length==16'd6) next = LEN_LOC1;
                        else if (msg_length==16'd5) next = LEN_LOC2;
                        else if (msg_length==16'd4) next = LEN_LOC3;
                        else if (msg_length==16'd3) next = LEN_LOC4;
                        else if (msg_length==16'd2) next = LEN_LOC5;
                        else if (msg_length==16'd1) next = LEN_LOC6;
/* These state transactions not need for: min msg_length=8
                        else if (msg_length==16'd0) next = LEN_LOC7;
*/
                        if (in_endofpacket)         next = LAST_PKT;
                        else                        next = MID_PKT;
                      end

        LEN_LOC0  : if (in_valid)                   next = LEN_SPLIT;

        LEN_LOC1  : if (in_valid)
                      if (in_endofpacket)           next = LAST_PKT;
                      else                          next = MID_PKT;

        LEN_LOC2  : if (in_valid) begin
                      if      (msg_length==16'd7)   next = LEN_LOC0;
/* These state transactions not needed for: min msg_length=8
                      else if (msg_length==16'd6)   next = LEN_LOC1;
                      else if (msg_length==16'd5)   next = LEN_LOC2;
                      else if (msg_length==16'd4)   next = LEN_LOC3;
                      else if (msg_length==16'd3)   next = LEN_LOC4;
                      else if (msg_length==16'd2)   next = LEN_LOC5;
                      else if (msg_length==16'd1)   next = LEN_LOC6;
                      else if (msg_length==16'd0)   next = LEN_LOC7;
*/
                      else if (in_endofpacket)      next = LAST_PKT;
                      else                          next = MID_PKT;
                    end
        LEN_LOC3  : if (in_valid) begin
                      if      (msg_length==16'd7)   next = LEN_LOC0;
                      else if (msg_length==16'd6)   next = LEN_LOC1;
/* These state transactions not needed for: min msg_length=8
                      else if (msg_length==16'd5)   next = LEN_LOC2;
                      else if (msg_length==16'd4)   next = LEN_LOC3;
                      else if (msg_length==16'd3)   next = LEN_LOC4;
                      else if (msg_length==16'd2)   next = LEN_LOC5;
                      else if (msg_length==16'd1)   next = LEN_LOC6;
                      else if (msg_length==16'd0)   next = LEN_LOC7;
*/
                      else if (in_endofpacket)      next = LAST_PKT;
                      else                          next = MID_PKT;
                    end

        LEN_LOC4  : if (in_valid) begin
                      if      (msg_length==16'd7)   next = LEN_LOC0;
                      else if (msg_length==16'd6)   next = LEN_LOC1;
                      else if (msg_length==16'd5)   next = LEN_LOC2;
/* These state transactions not needed for: min msg_length=8
                      else if (msg_length==16'd4)   next = LEN_LOC3;
                      else if (msg_length==16'd3)   next = LEN_LOC4;
                      else if (msg_length==16'd2)   next = LEN_LOC5;
                      else if (msg_length==16'd1)   next = LEN_LOC6;
                      else if (msg_length==16'd0)   next = LEN_LOC7;
*/
                      else if (in_endofpacket)      next = LAST_PKT;
                      else                          next = MID_PKT;
                    end

        LEN_LOC5  : if (in_valid) begin
                      if      (msg_length==16'd7)   next = LEN_LOC0;
                      else if (msg_length==16'd6)   next = LEN_LOC1;
                      else if (msg_length==16'd5)   next = LEN_LOC2;
                      else if (msg_length==16'd4)   next = LEN_LOC3;
/* These state transactions not needed for: min msg_length=8
                      else if (msg_length==16'd3)   next = LEN_LOC4;
                      else if (msg_length==16'd2)   next = LEN_LOC5;
                      else if (msg_length==16'd1)   next = LEN_LOC6;
                      else if (msg_length==16'd0)   next = LEN_LOC7;
*/
                      else if (in_endofpacket)      next = LAST_PKT;
                      else                          next = MID_PKT;
                    end

        LEN_LOC6  : if (in_valid) begin
                      if      (msg_length==16'd7)   next = LEN_LOC0;
                      else if (msg_length==16'd6)   next = LEN_LOC1;
                      else if (msg_length==16'd5)   next = LEN_LOC2;
                      else if (msg_length==16'd4)   next = LEN_LOC3;
                      else if (msg_length==16'd3)   next = LEN_LOC4;
/* These state transactions not needed for: min msg_length=8
                      else if (msg_length==16'd2)   next = LEN_LOC5;
                      else if (msg_length==16'd1)   next = LEN_LOC6;
                      else if (msg_length==16'd0)   next = LEN_LOC7;
*/
                      else if (in_endofpacket)      next = LAST_PKT;
                      else                          next = MID_PKT;
                    end

        LEN_LOC7  : if (in_valid) begin
                      if      (msg_length==16'd7)   next = LEN_LOC0;
                      else if (msg_length==16'd6)   next = LEN_LOC1;
                      else if (msg_length==16'd5)   next = LEN_LOC2;
                      else if (msg_length==16'd4)   next = LEN_LOC3;
                      else if (msg_length==16'd3)   next = LEN_LOC4;
                      else if (msg_length==16'd2)   next = LEN_LOC5;
/* These state transactions not needed for: min msg_length=8
                      else if (msg_length==16'd1)   next = LEN_LOC6;
                      else if (msg_length==16'd0)   next = LEN_LOC7;
*/
                      else if (in_endofpacket)      next = LAST_PKT;
                      else                          next = MID_PKT;
                    end

        LAST_PKT  :                                 next <= IDLE;
      endcase
  end

  always @ (negedge clk or negedge reset_n)
    if (!reset_n) begin
      in_ready      <= 1'd1;
      out_valid     <= 1'd0;
      out_data      <= 256'd0;
      out_bytemask  <= 32'd0;
      msg_count     <= 16'd0;
      msg_length    <= 16'd0;
      payload0      <= 64'd0;
      payload0_sz   <= 4'd0;
      payload1      <= 64'd0;
      payload1_sz   <= 4'd0;
    end
    else begin
      in_ready      <= 1'd1;
      out_valid     <= 1'd0;
      out_data      <= 256'd0;
      out_bytemask  <= 32'd0;
      msg_count     <= 16'd0;
      msg_length    <= 16'd0;
      payload0      <= 64'd0;
      payload0_sz   <= 4'd0;
      payload1      <= 64'd0;
      payload1_sz   <= 4'd0;

      case (next)
        IDLE        : begin
                        in_ready      <= 1'b1;
                        out_valid     <= 1'b0;
                        // out_data   <= 256'b0;        // dup
                        out_bytemask  <= 32'b0;
                        msg_count     <= 16'd0;
                        msg_length    <= 16'd0;
                      end

        FIRST_PKT   : begin
                        in_ready      <= 1'b0;          // dup
                        out_valid     <= 1'b0;          // dup
                        out_data      <= in_data[31:0];
                        out_bytemask  <= 32'b1111;
                        msg_count     <= in_data[63:48]-16'd1;
                        msg_length    <= in_data[47:32]-16'd4;
                      end

        MID_PKT     : begin
                        if (payload0_sz > 0) begin
                          out_data      <=  (out_data<<((payload0_sz+16'd8)<<3))|
                                            (payload0<<64)                      |
                                            in_data[63:0];
                          out_bytemask  <=  (out_bytemask<<(payload0_sz+4'd8))  |
                                            (payload0_mask<<8)                  |
                                            payload_mask;
                        end
                        else begin
                          out_data      <= {out_data,in_data[63:0]};
                          out_bytemask  <= {out_bytemask,payload_mask};
                        end
                        msg_length      <= msg_length - 16'd8;
                      end

        LEN_SPLIT   : begin
                        msg_length        <= {msg_length,in_data[63:56]} - 16'd7;
                        out_data          <= {256'b0 | in_data[55:0]};
                        out_bytemask      <= {32'b0 | 32'b1111111};
                        payload0_sz       <= 4'd0;
                      end

        LEN_LOC0    : begin
                        msg_length        <= in_data[7:0];
                        out_data          <= {out_data,in_data[63:8]};
                        out_bytemask      <= {out_bytemask, {7{1'b1}}};
                        out_valid         <= 1'b1;
                        payload0_sz       <= 4'd0;
                        payload0          <= 64'd0;
                        payload0_mask     <= 8'b00000000;
                      end

        LEN_LOC1    : begin
                        msg_length        <= in_data[15:0];
                        out_data          <= {out_data,in_data[63:16]};
                        out_bytemask      <= {out_bytemask, {6{1'b1}}};
                        out_valid         <= 1'b1;
                        payload0_sz       <= 4'd0;
                        payload0          <= 64'd0;
                        payload0_mask     <= 8'b00000000;
                      end

        LEN_LOC2    : begin
                        msg_length        <= in_data[23:8]-16'd1;
                        out_data          <= {out_data,in_data[63:24]};
                        out_bytemask      <= {out_bytemask, {5{1'b1}}};
                        out_valid         <= 1'b1;
                        payload0_sz       <= 4'd1;
                        payload0          <= in_data[7:0];
                        payload0_mask     <= 8'b00000001;
                      end

        LEN_LOC3    : begin
                        msg_length        <= in_data[31:16]-16'd2;
                        out_data          <= {out_data,in_data[63:32]};
                        out_bytemask      <= {out_bytemask, {4{1'b1}}};
                        out_valid         <= 1'b1;
                        payload0_sz       <= 4'd2;
                        payload0          <= in_data[15:0];
                        payload0_mask     <= 8'b00000011;
                      end

        LEN_LOC4    : begin
                        msg_length        <= in_data[39:24]-16'd3;
                        out_data          <= {out_data,in_data[63:40]};
                        out_bytemask      <= {out_bytemask, {3{1'b1}}};
                        out_valid         <= 1'b1;
                        payload0_sz       <= 4'd3;
                        payload0          <= in_data[23:0];
                        payload0_mask     <= 8'b00000111;
                      end

        LEN_LOC5    : begin
                        msg_length        <= in_data[47:32]-16'd4;
                        out_data          <= {out_data,in_data[63:40]};
                        out_bytemask      <= {out_bytemask, {2{1'b1}}};
                        out_valid         <= 1'b1;
                        payload0_sz       <= 4'd4;
                        payload0          <= in_data[31:0];
                        payload0_mask     <= 8'b00001111;
                      end

        LEN_LOC6    : begin
                        msg_length        <= in_data[55:40]-16'd5;
                        out_data          <= {out_data,in_data[63:56]};
                        out_bytemask      <= {out_bytemask, 1'b1};
                        out_valid         <= 1'b1;
                        payload0_sz       <= 4'd5;
                        payload0          <= in_data[39:0];
                        payload0_mask     <= 8'b00011111;
                      end

        LEN_LOC7    : begin
                        msg_length        <= in_data[63:48]-16'd6;
                        out_data          <= out_data;
                        out_bytemask      <= out_bytemask;
                        out_valid         <= 1'b1;
                        payload0_sz       <= 4'd6;
                        payload0          <= in_data[47:0];
                        payload0_mask     <= 8'b00111111;
                      end
        LAST_PKT    : begin
                        msg_length        <= msg_length - (16'd8-in_empty);         // dup
                        out_data          <= out_data | (in_data >> (in_empty<<6));
                        out_bytemask      <= {out_bytemask, 1'b1};
                        out_valid         <= 1'b1;
                      end
      endcase
    end

  always @ (msg_length or in_valid) begin
    case(msg_length)
      LEN1:   if(in_valid)  payload_mask = 8'b00000001;
      LEN2:   if(in_valid)  payload_mask = 8'b00000011;
      LEN3:   if(in_valid)  payload_mask = 8'b00000111;
      LEN4:   if(in_valid)  payload_mask = 8'b00001111;
      LEN5:   if(in_valid)  payload_mask = 8'b00011111;
      LEN6:   if(in_valid)  payload_mask = 8'b00111111;
      LEN7:   if(in_valid)  payload_mask = 8'b01111111;
//    LEN8:   if(in_valid)  payload_mask = 8'b11111111;     // dup
      default:if(in_valid)  payload_mask = 8'b11111111;
    endcase
  end

endmodule