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
  reg     [255:0] payload0, nx_payload0;
  reg     [3:0]   payload0_sz, nx_payload0_sz;
  reg     [7:0]   payload0_mask, nx_payload0_mask;
  reg     [255:0] payload, nx_payload;
  reg     [255:0] payload_mask, nx_payload_mask;
  reg     [31:0]  pl_mask, nx_pl_mask;
  reg     [5:0]   payload_sz, nx_payload_sz;
  reg             vout, nx_vout;

  parameter IDLE        	= 3'd0,
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
      vout					<= 1'b0;
    end
    else begin
      state         <= nextstate;
      msg_count     <= nx_msg_count;
      msg_length    <= nx_msg_length;
      payload       <= nx_payload;
      payload0      <= nx_payload0;
      vout 					<= nx_vout;      
    end
  end

// outputs updating block:
  always @(state or in_valid or in_startofpacket or in_endofpacket or in_error or msg_length)
  begin
    in_ready = 1'b0;
    out_valid = vout;         
    out_data  = payload;      
    payload_size = payload_sz;
    case(state)
      IDLE: 				in_ready = 1'b1;
      default:			in_ready = 1'b0;
    endcase
  end

// nextstate and nx_<variable> updating block:
  always @(state or in_valid or in_startofpacket or in_endofpacket or in_error or in_data)
  begin
    nextstate       = IDLE;
    nx_msg_count    = 16'd0;
    nx_msg_length   = 16'd0;
    nx_payload      = 256'd0;
    nx_payload_sz   = 6'd0;
    nx_payload0     = 256'd0;;
    nx_payload0_sz  = 4'd0;
    nx_vout         = 1'b0;

    case (state)
      IDLE: if (in_valid & in_startofpacket & !in_error) 
      			begin
              nextstate       = PARTIAL_PKT;
              nx_msg_count    = in_data[63:48];
              nx_msg_length   = in_data[47:32] - 16'd4;
              nx_payload0     = in_data[31:0];
              nx_payload0_sz  = 4'd4;
              nx_payload      = 256'd0;
              nx_payload_sz   = 6'd0;
              nx_vout         = 1'b0;
            end
      PARTIAL_PKT:   if (in_valid & !in_error)
            begin
              if (msg_length == 16'd0) 
              begin
              	if (msg_count > 0)
                	nextstate   = FULL_PKT;              	
              	else
              		nextstate   = PARTIAL_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[63:48] - 16'd6;
                nx_payload    = 256'd0;
                nx_payload_sz = 6'd0;
                nx_payload0   = in_data[47:0];
                nx_payload0_sz  = 4'd6;
                nx_vout         = 1'b1;
              end
              else if (msg_length == 16'd1) 
              begin
              	if (msg_count == 0)
              		nextstate   = LAST_PKT;
              	else
                	nextstate   = PARTIAL_PKT;
                nx_msg_count  = msg_count - 16'd1;
                // in_data[(16'd64-16'd16-(msg_length<<3)+:16]
                nx_msg_length = in_data[55:40] - 16'd5;
                nx_payload    = (payload0 <<  (msg_length<<3))              |
                                in_data[63:56];
                nx_payload_sz = payload_sz + msg_length;
                nx_payload0   = in_data[39:0];
                nx_payload0_sz  = 4'd5;
                nx_vout         = 1'b1;
              end
              else if (msg_length == 16'd2) 
              begin
              	if (msg_count == 0)
              		nextstate   = LAST_PKT;
              	else
                	nextstate   = PARTIAL_PKT;               
                nx_msg_count  = msg_count - 16'd1;
//nx_msg_length=in_data[(16'd48-(msg_length<<3))+:16]-(16'd6-msg_length);
                nx_msg_length = in_data[47:32] - 16'd4;
                nx_payload    = (payload0 <<  (msg_length<<3))              |
                                in_data[63:48];

                nx_payload_sz = payload_sz + msg_length;
                nx_payload0   = in_data[31:0];
                // nx_payload0_sz = 4'd6-4'd2-msg_length;
                nx_payload0_sz  = 4'd4;
                nx_vout         = 1'b1;
              end
              else if (msg_length == 16'd3) 
              begin
              	if (msg_count == 0)
              		nextstate   = LAST_PKT;
              	else
                	nextstate   = PARTIAL_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[39:24] - 16'd3;
                nx_payload    = (payload0 <<  (msg_length<<3))              |
                                in_data[63:40];
                nx_payload_sz = payload_sz + msg_length;
                nx_payload0   = in_data[23:0];
                nx_payload0_sz  = 4'd3;
                nx_vout         = 1'b1;
              end
              else if (msg_length == 16'd4) 
              begin
              	if (msg_count == 0)
              		nextstate   = LAST_PKT;
              	else
                	nextstate   = PARTIAL_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[31:16] - 16'd2;
                nx_payload    = (payload0 <<  (msg_length<<3))              |
                								in_data[63:32];
                nx_payload_sz = payload_sz + msg_length;
                nx_payload0   = in_data[15:0];
                nx_payload0_sz  = 4'd2;
                nx_vout         = 1'b1;
              end
              else if (msg_length == 16'd5) 
              begin
              	if (msg_count == 0)
              		nextstate   = LAST_PKT;
              	else
                	nextstate   = PARTIAL_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[23:8] - 16'd1;
                nx_payload    = (payload0 <<  (msg_length<<3))              |
                                in_data[63:24];
                nx_payload_sz = payload_sz + msg_length;
                nx_payload0   = in_data[7:0];
                nx_payload0_sz  = 4'd1;
                nx_vout         = 1'b1;
              end
              else if (msg_length == 16'd6) 
              begin
              	if (msg_count == 0)
              		nextstate   = LAST_PKT;
              	else
                	nextstate   = PARTIAL_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[15:0];
                nx_payload    = (payload0 <<  (msg_length<<3))              |
                                in_data[63:16];
                nx_payload_sz = payload_sz + msg_length;
                nx_payload0   = 256'd0;;
                nx_payload0_sz  = 4'd0;
                nx_vout         = 1'b1;
              end
              else if (msg_length == 16'd7) 
              begin
                nextstate     = SPLIT_LEN_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[7:0];
                nx_payload    = (payload0 <<  (msg_length<<3))              |
                                in_data[63:8];
                nx_payload_sz = payload_sz + msg_length;
                nx_payload0   = 256'd0;;
                nx_payload0_sz  = 4'd0;
                nx_vout         = 1'b1;
              end
              else begin // msg_length > 8
              	if (msg_count == 0)
              		nextstate   = LAST_PKT;
              	else
                	nextstate   = FULL_PKT;
                nx_msg_count  = msg_count;
                nx_msg_length = msg_length - 16'd8;
                nx_payload    = // (payload  << ((16'd8+payload0_sz)<<3))      |
                                (payload0 <<  64)                           |
                                in_data[63:0];
                nx_payload_sz = payload_sz + 16'd8;
                nx_payload0   = 256'd0;;
                nx_payload0_sz  = 4'd0;
                nx_vout         = 1'b0;
              end
            end
      SPLIT_LEN_PKT:  if (in_valid & !in_error)
            begin
                  nextstate     = FULL_PKT;
                  nx_msg_count  = msg_count;
                  nx_msg_length = {msg_length, in_data[63:56]} - 16'd7;
                  nx_payload    = in_data[55:0];
                  nx_payload_sz = 6'd7;
                  nx_payload0   = 256'd0;;
                  nx_payload0_sz  = 4'd0;
                  nx_vout         = 1'b0;
            end
      FULL_PKT:  if (in_valid & !in_error)
            begin            	
              if (msg_length == 16'd0) 
              begin
              	if (msg_count == 0)
              		nextstate   = LAST_PKT;
              	else
                	nextstate   = PARTIAL_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[63:48] - 16'd6;
                nx_payload    = 256'd0;
                nx_payload_sz = 6'd0;
                nx_payload0   = in_data[47:0];
                nx_payload0_sz  = 4'd6;
                nx_vout         = 1'b1;
              end
              else if (msg_length == 16'd1) 
              begin
              	if (msg_count == 0)
              		nextstate   = LAST_PKT;
              	else
                	nextstate   = PARTIAL_PKT;
                nx_msg_count  = msg_count - 16'd1;
                // in_data[(16'd64-16'd16-(msg_length<<3)+:16]
                nx_msg_length = in_data[55:40] - 16'd5;
                nx_payload    = (payload <<  8) | in_data[63:56];
                nx_payload_sz = payload_sz + msg_length;
                nx_payload0   = in_data[39:0];
                nx_payload0_sz  = 4'd5;
                nx_vout         = 1'b1;
              end
              else if (msg_length == 16'd2) 
              begin
              	if (msg_count == 0)
              		nextstate   = LAST_PKT;
              	else
                	nextstate   = PARTIAL_PKT;
                nx_msg_count  = msg_count - 16'd1;
//nx_msg_length=in_data[(16'd48-(msg_length<<3))+:16]-(16'd6-msg_length);
                nx_msg_length = in_data[47:32] - 16'd4;
//                  nx_payload    = (payload << 16) | in_data[63:48];
							    nx_payload    = {payload, in_data[63:48]};
							
                nx_payload_sz = payload_sz + msg_length;
                nx_payload0   = in_data[31:0];
                // nx_payload0_sz = 4'd6-4'd2-msg_length;
                nx_payload0_sz  = 4'd4;
                nx_vout         = 1'b1;
              end
              else if (msg_length == 16'd3) 
              begin
              	if (msg_count == 0)
              		nextstate   = LAST_PKT;
              	else
                	nextstate   = PARTIAL_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[39:24] - 16'd3;
                nx_payload    = (payload <<  24) | in_data[63:40];
                nx_payload_sz = payload_sz + msg_length;
                nx_payload0   = in_data[23:0];
                nx_payload0_sz  = 4'd3;
                nx_vout         = 1'b1;
              end
              else if (msg_length == 16'd4) 
              begin
              	if (msg_count == 0)
              		nextstate   = LAST_PKT;
              	else
                	nextstate   = PARTIAL_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[31:16] - 16'd2;
                nx_payload    = (payload << 32)| in_data[63:32];
                nx_payload_sz = payload_sz + msg_length;
                nx_payload0   = in_data[15:0];
                nx_payload0_sz  = 4'd2;
                nx_vout         = 1'b1;
              end
              else if (msg_length == 16'd5) 
              begin
              	if (msg_count == 0)
              		nextstate   = LAST_PKT;
              	else
                	nextstate   = PARTIAL_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[23:8] - 16'd1;
                nx_payload    = (payload <<  40) | in_data[63:24];
                nx_payload_sz = payload_sz + msg_length;
                nx_payload0   = in_data[7:0];
                nx_payload0_sz  = 4'd1;
                nx_vout         = 1'b1;
              end
              else if (msg_length == 16'd6) 
              begin
              	if (msg_count == 0)
              		nextstate   = LAST_PKT;
              	else
                	nextstate   = PARTIAL_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[15:0];
                nx_payload    = (payload <<  48) | in_data[63:16];
                nx_payload_sz = payload_sz + msg_length;
                nx_payload0   = 256'd0;;
                nx_payload0_sz  = 4'd0;
                nx_vout         = 1'b1;
              end
              else if (msg_length == 16'd7) 
              begin
                nextstate     = SPLIT_LEN_PKT;
                nx_msg_count  = msg_count - 16'd1;
                nx_msg_length = in_data[7:0];
                nx_payload    = (payload << 56) | in_data[63:8];
                nx_payload_sz = payload_sz + msg_length;
                nx_payload0   = 256'd0;;
                nx_payload0_sz  = 4'd0;
                nx_vout         = 1'b1;
              end
              else 
              begin 
                nextstate     = FULL_PKT;
                nx_msg_count  = msg_count;
                nx_msg_length = msg_length - 16'd8;
                nx_payload    = (payload << 64) | in_data[63:0];
                nx_payload_sz = payload_sz + 16'd8;
                nx_payload0   = 256'd0;;
                nx_payload0_sz  = 4'd0;
                nx_vout         = 1'b0;
              end
            end
      LAST_PKT: 
      			begin 
              nextstate     = IDLE;
              nx_msg_count  = 16'd0;
              nx_msg_length = 16'd0;
              nx_payload    = 256'd0;
              nx_payload_sz = 6'd0;
              nx_payload0   = 256'd0;;
              nx_payload0_sz= 4'd0;
              nx_vout       = 1'b0;
            end

    endcase
  end

  always @(nx_payload_sz)
    case(nx_payload_sz)
      6'd0:   nx_payload_mask = 256'h0000000000000000000000000000000000000000000000000000000000000000;
      6'd1:   nx_payload_mask = 256'h00000000000000000000000000000000000000000000000000000000000000ff;
      6'd2:   nx_payload_mask = 256'h000000000000000000000000000000000000000000000000000000000000ffff;
      6'd3:   nx_payload_mask = 256'h0000000000000000000000000000000000000000000000000000000000ffffff;
      6'd4:   nx_payload_mask = 256'h00000000000000000000000000000000000000000000000000000000ffffffff;
      6'd5:   nx_payload_mask = 256'h000000000000000000000000000000000000000000000000000000ffffffffff;
      6'd6:   nx_payload_mask = 256'h0000000000000000000000000000000000000000000000000000ffffffffffff;
      6'd7:   nx_payload_mask = 256'h00000000000000000000000000000000000000000000000000ffffffffffffff;
      6'd8:   nx_payload_mask = 256'h000000000000000000000000000000000000000000000000ffffffffffffffff;
      6'd9:   nx_payload_mask = 256'h0000000000000000000000000000000000000000000000ffffffffffffffffff;
      6'd10:  nx_payload_mask = 256'h00000000000000000000000000000000000000000000ffffffffffffffffffff;
      6'd11:  nx_payload_mask = 256'h000000000000000000000000000000000000000000ffffffffffffffffffffff;
      6'd12:  nx_payload_mask = 256'h0000000000000000000000000000000000000000ffffffffffffffffffffffff;
      6'd13:  nx_payload_mask = 256'h00000000000000000000000000000000000000ffffffffffffffffffffffffff;
      6'd14:  nx_payload_mask = 256'h000000000000000000000000000000000000ffffffffffffffffffffffffffff;
      6'd15:  nx_payload_mask = 256'h0000000000000000000000000000000000ffffffffffffffffffffffffffffff;
      6'd16:  nx_payload_mask = 256'h00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
      6'd17:  nx_payload_mask = 256'h000000000000000000000000000000ffffffffffffffffffffffffffffffffff;
      6'd18:  nx_payload_mask = 256'h0000000000000000000000000000ffffffffffffffffffffffffffffffffffff;
      6'd19:  nx_payload_mask = 256'h00000000000000000000000000ffffffffffffffffffffffffffffffffffffff;
      6'd20:  nx_payload_mask = 256'h000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
      6'd21:  nx_payload_mask = 256'h0000000000000000000000ffffffffffffffffffffffffffffffffffffffffff;
      6'd22:  nx_payload_mask = 256'h00000000000000000000ffffffffffffffffffffffffffffffffffffffffffff;
      6'd23:  nx_payload_mask = 256'h000000000000000000ffffffffffffffffffffffffffffffffffffffffffffff;
      6'd24:  nx_payload_mask = 256'h0000000000000000ffffffffffffffffffffffffffffffffffffffffffffffff;
      6'd25:  nx_payload_mask = 256'h00000000000000ffffffffffffffffffffffffffffffffffffffffffffffffff;
      6'd26:  nx_payload_mask = 256'h000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffff;
      6'd27:  nx_payload_mask = 256'h0000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffff;
      6'd28:  nx_payload_mask = 256'h00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
      6'd29:  nx_payload_mask = 256'h000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
      6'd30:  nx_payload_mask = 256'h0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
      6'd31:  nx_payload_mask = 256'h00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
      6'd32:  nx_payload_mask = 256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    endcase
endmodule

