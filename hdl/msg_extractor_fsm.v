`timescale 1ns / 100ps

module msg_extractor_fsm (
  input   clk, reset_n, in_valid, in_startofpacket, in_endofpacket, in_error,
  input   [63:0]  in_data,
  input   [2:0]   in_empty,
  output  reg in_ready, out_valid,
  output  reg [255:0] out_data,
  output  reg [31:0]  out_bytemask
  );

  reg     [3:0]   state, nextstate;
  reg     [15:0]  msg_count, nx_msg_count;
  reg     [15:0]  msg_length, nx_msg_length;
  reg     [255:0] payload0, nx_payload0;
  reg     [31:0]  payload0_mask, nx_payload0_mask;
  reg     [255:0] payload, nx_payload;
  reg     [31:0]  payload_mask, nx_payload_mask;
  reg             vout, nx_vout;

  parameter IDLE          = 3'd0,
            PARTIAL_PKT   = 3'd1,
            SPLIT_LEN_PKT = 3'd2,
            FULL_PKT      = 3'd3,
            LAST_PKT      = 3'd4;

// state and variables updating block:
  always @(posedge clk or negedge reset_n)
  begin
    if (!reset_n)
    begin
      state         <= IDLE;
      msg_count     <= 16'd0;
      msg_length    <= 16'd0;
      payload       <= 256'd0;
      payload0      <= 256'd0;
      vout          <= 1'b0;
      payload_mask  <= 32'd0;
      payload0_mask <= 32'd0;

    end
    else begin
      state         <= nextstate;
      msg_count     <= nx_msg_count;
      msg_length    <= nx_msg_length;
      payload       <= nx_payload;
      payload0      <= nx_payload0;
      vout          <= nx_vout;
      payload_mask  <= nx_payload_mask;
      payload0_mask <= nx_payload0_mask;
    end
  end

// outputs updating block:
  always @(state or vout or payload or payload_mask or msg_count)
  begin
    if (msg_count==16'd0) in_ready = 1'b1;
    else                  in_ready = 1'b0;

    out_valid = vout;
    out_data  = payload;
    out_bytemask = payload_mask;
  end

// nextstate and nx_<variable> updating block:
  always @(in_data or in_valid or in_error or in_startofpacket or in_endofpacket or
            state or msg_length or msg_count or payload or payload0 or payload_mask or payload0_mask)
  begin
    nextstate       = IDLE;
    nx_msg_count    = 16'd0;
    nx_msg_length   = 16'd0;
    nx_payload      = 256'd0;
    nx_payload0     = 256'd0;;
    nx_vout         = 1'b0;
    nx_payload_mask = 32'd0;
    nx_payload0_mask= 32'd0;
    case (state)
      IDLE: if (in_valid & in_startofpacket & !in_error)
            begin
              nextstate       = PARTIAL_PKT;
              nx_msg_count    = in_data[63:48];
              nx_msg_length   = in_data[47:32] - 16'd4;
              nx_payload0     = in_data[31:0];
              nx_payload      = 256'd0;
              nx_vout         = 1'b0;
              nx_payload_mask = 32'd0;
              nx_payload0_mask= {4{1'b1}};
            end
      PARTIAL_PKT:
            if (in_valid & !in_error)
            begin
              if (msg_length == 16'd0)
              begin
                if (msg_count > 0)
                  nextstate   = PARTIAL_PKT;
                else
                  nextstate   = LAST_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[63:48] - 16'd6;
                nx_payload    = 256'd0;
                nx_payload0   = in_data[47:0];
                nx_vout       = 1'b1;
                nx_payload_mask = 32'd0;
                nx_payload0_mask= {6{1'b1}};
              end
              else if (msg_length == 16'd1)
              begin
                if (msg_count > 0)
                  nextstate   = PARTIAL_PKT;
                else
                  nextstate   = LAST_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[55:40] - 16'd5;
                nx_payload    = {payload0,in_data[63:56]};
                nx_payload0   = in_data[39:0];
                nx_vout         = 1'b1;
                nx_payload_mask = {payload0_mask , 1'b1} ;
                nx_payload0_mask= {5{1'b1}};
              end
              else if (msg_length == 16'd2)
              begin
                if (msg_count > 0)
                  nextstate   = PARTIAL_PKT;
                else
                  nextstate   = LAST_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[47:32] - 16'd4;
                nx_payload    = {payload0 , in_data[63:48]};
                nx_payload0   = in_data[31:0];
                nx_vout         = 1'b1;
                nx_payload_mask = {payload0_mask , {2{1'b1}}} ;
                nx_payload0_mask= {4{1'b1}};
              end
              else if (msg_length == 16'd3)
              begin
                if (msg_count > 0)
                  nextstate   = PARTIAL_PKT;
                else
                  nextstate   = LAST_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[39:24] - 16'd3;
                nx_payload    = {payload0 , in_data[63:40]};
                nx_payload0   = in_data[23:0];
                nx_vout         = 1'b1;
                nx_payload_mask = {payload0_mask , {3{1'b1}}} ;
                nx_payload0_mask= {3{1'b1}};
              end
              else if (msg_length == 16'd4)
              begin
                if (msg_count > 0)
                  nextstate   = PARTIAL_PKT;
                else
                  nextstate   = LAST_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[31:16] - 16'd2;
                nx_payload    = {payload0 , in_data[63:32]};
                nx_payload0   = in_data[15:0];
                nx_vout         = 1'b1;
                nx_payload_mask = {payload0_mask , {4{1'b1}}} ;
                nx_payload0_mask= {2{1'b1}};
              end
              else if (msg_length == 16'd5)
              begin
                if (msg_count > 0)
                  nextstate   = PARTIAL_PKT;
                else
                  nextstate   = LAST_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[23:8] - 16'd1;
                nx_payload    = {payload0 , in_data[63:24]};
                nx_payload0   = in_data[7:0];
                nx_vout         = 1'b1;
                nx_payload_mask = {payload0_mask , {5{1'b1}}} ;
                nx_payload0_mask= 1'b1;
              end
              else if (msg_length == 16'd6)
              begin
                if (msg_count > 0)
                  nextstate   = PARTIAL_PKT;
                else
                  nextstate   = LAST_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[15:0];
                nx_payload    = {payload0 , in_data[63:16]};
                nx_payload0   = 256'd0;;
                nx_vout         = 1'b1;
                nx_payload_mask = {payload0_mask , {6{1'b1}}} ;
                nx_payload0_mask= 32'd0;
              end
              else if (msg_length == 16'd7)
              begin
                nextstate     = SPLIT_LEN_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[7:0];
                nx_payload    = {payload0 , in_data[63:8]};
                nx_payload0   = 256'd0;;
                nx_vout         = 1'b1;
                nx_payload_mask = {payload0_mask , {7{1'b1}}} ;
                nx_payload0_mask= 32'd0;
              end
              else begin // msg_length > 8
                if (msg_count == 0)
                  nextstate   = LAST_PKT;
                else
                  nextstate   = FULL_PKT;
                nx_msg_count  = msg_count;
                nx_msg_length = msg_length - 16'd8;
                nx_payload    = {payload0 , in_data[63:0]};
                nx_payload0   = 256'd0;;
                nx_vout         = 1'b0;
                nx_payload_mask = {payload0_mask , {8{1'b1}}} ;
                nx_payload0_mask= 32'd0;
              end
            end
      SPLIT_LEN_PKT:
            if (in_valid & !in_error)
            begin
              nextstate     = FULL_PKT;
              nx_msg_count  = msg_count;
              nx_msg_length = {msg_length, in_data[63:56]} - 16'd7;
              nx_payload    = in_data[55:0];
              nx_payload0   = 256'd0;;
              nx_vout         = 1'b0;
              nx_payload_mask = {payload0_mask , {7{1'b1}}} ;
              nx_payload0_mask= 32'd0;
            end
      FULL_PKT:
            if (in_valid & !in_error)
            begin
              if (msg_length == 16'd0)
              begin
                if (msg_count > 0)
                  nextstate   = PARTIAL_PKT;
                else
                  nextstate   = LAST_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[63:48] - 16'd6;
                nx_payload    = 256'd0;
                nx_payload0   = in_data[47:0];
                nx_vout         = 1'b1;
                nx_payload_mask = 32'd0;
                nx_payload0_mask= {6{1'b1}};
              end
              else if (msg_length == 16'd1)
              begin
                if (msg_count > 0)
                  nextstate   = PARTIAL_PKT;
                else
                  nextstate   = LAST_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[55:40] - 16'd5;
                nx_payload    = {payload0,in_data[63:56]};
                nx_payload0   = in_data[39:0];
                nx_vout         = 1'b1;
                nx_payload_mask = {payload_mask , 1'b1} ;
                nx_payload0_mask= {5{1'b1}};
              end
              else if (msg_length == 16'd2)
              begin
                if (msg_count > 0)
                  nextstate   = PARTIAL_PKT;
                else
                  nextstate   = LAST_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[47:32] - 16'd4;
                nx_payload    = {payload, in_data[63:48]};
                nx_payload0   = in_data[31:0];
                nx_vout         = 1'b1;
                nx_payload_mask = {payload_mask , {2{1'b1}}} ;
                nx_payload0_mask= {4{1'b1}};
              end
              else if (msg_length == 16'd3)
              begin
                if (msg_count > 0)
                  nextstate   = PARTIAL_PKT;
                else
                  nextstate   = LAST_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[39:24] - 16'd3;
                nx_payload    = {payload , in_data[63:40]};
                nx_payload0   = in_data[23:0];
                nx_vout         = 1'b1;
                nx_payload_mask = {payload_mask , {3{1'b1}}} ;
                nx_payload0_mask= {3{1'b1}};
              end
              else if (msg_length == 16'd4)
              begin
                if (msg_count > 0)
                  nextstate   = PARTIAL_PKT;
                else
                  nextstate   = LAST_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[31:16] - 16'd2;
                nx_payload    = {payload , in_data[63:32]};
                nx_payload0   = in_data[15:0];
                nx_vout         = 1'b1;
                nx_payload_mask = {payload_mask , {4{1'b1}}} ;
                nx_payload0_mask= {2{1'b1}};
              end
              else if (msg_length == 16'd5)
              begin
                if (msg_count > 0)
                  nextstate   = PARTIAL_PKT;
                else
                  nextstate   = LAST_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[23:8] - 16'd1;
                nx_payload    = {payload , in_data[63:24]};
                nx_payload0   = in_data[7:0];
                nx_vout         = 1'b1;
                nx_payload_mask = {payload_mask , {5{1'b1}}} ;
                nx_payload0_mask= 1'b1;
              end
              else if (msg_length == 16'd6)
              begin
                if (msg_count > 0)
                  nextstate   = PARTIAL_PKT;
                else
                  nextstate   = LAST_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[15:0];
                nx_payload    = {payload , in_data[63:16]};
                nx_payload0   = 256'd0;;
                nx_vout         = 1'b1;
                nx_payload_mask = {payload_mask , {6{1'b1}}} ;
                nx_payload0_mask= 32'd0;
              end
              else if (msg_length == 16'd7)
              begin
                nextstate     = SPLIT_LEN_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[7:0];
                nx_payload    = {payload , in_data[63:8]};
                nx_payload0   = 256'd0;;
                nx_vout         = 1'b1;
                nx_payload_mask = {payload_mask , {7{1'b1}}} ;
                nx_payload0_mask= 32'd0;
              end
              else // (msg_length >= 16'd8)
              begin
                nextstate     = FULL_PKT;
                nx_msg_count  = msg_count;
                nx_msg_length = msg_length - 16'd8;
                nx_payload    = {payload , in_data[63:0]};
                nx_payload0   = 256'd0;;
                nx_vout         = 1'b0;
                nx_payload_mask = {payload_mask , {8{1'b1}}} ;
                nx_payload0_mask= 32'd0;
              end
            end
      LAST_PKT:
            begin
              nextstate     = IDLE;
              nx_msg_count  = 16'd0;
              nx_msg_length = 16'd0;
              nx_payload    = 256'd0;
              nx_payload0   = 256'd0;;
              nx_vout       = 1'b0;
              nx_payload_mask = {payload_mask , {8{1'b1}}};
              nx_payload0_mask= 32'd0;
            end

    endcase
  end

endmodule

