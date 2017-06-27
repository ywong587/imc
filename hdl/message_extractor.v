`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 06/26/2017 10:03:25 AM
// Design Name:
// Module Name: message_extractor
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module message_extractor (
      input   clk,
      input   ce,
      input   reset_n,
      input   [63:0]  in_data,
      input   in_valid,
      input   in_startofpacket,
      input   in_endofpacket,
      input   [2:0]   in_empty,
      input   in_error,
      output  reg in_ready,
      output  reg out_valid,
      output  reg [255:0] out_data,
      output  reg [31:0]  out_bytemask
      );

      reg     [3:0]   state;
      reg     [15:0]  msg_count;
      reg     [15:0]  msg_length;

      reg     [63:0]  pl0;
      reg     [3:0]   pl0_size;
      reg     [63:0]  pl1;
      reg     [3:0]   pl1_size;

			integer		i;
			
      parameter IDLE          = 0;
      parameter FIRST_PKT     = 1;
      parameter MIDDLE_PKT    = 2;

      parameter LEN_PKT_B76   = 3;
      parameter LEN_PKT_B10   = 4;
      parameter LEN_PKT_B17   = 5;
      
      parameter LAST_PKT      = 8;

  always @ (negedge clk or negedge reset_n) begin
      if (!reset_n) begin
        state         <= IDLE;
        out_valid     <= 1'b0;
        in_ready      <= 1'b1;
        out_data      <= 256'd0;
        out_bytemask  <= 32'd0;

        msg_count     <= 16'd0;
        msg_length    <= 16'd0;
      end
  // assumptions:
  // 1) MSG Count always at byte 7 and byte 8 of the first packet of a input data stream.
  // 2) "in_empty" only assert at the last packet of the data stream
  // 3) minimum message length is 8 bytes, so the first packet of the data stream payload
  //   is always 4 bytes.

  else begin
    case (state) 
      IDLE:
        if (in_valid & in_startofpacket) begin
          state <= FIRST_PKT;
          msg_count   <= in_data[63:48] - 16'd1;
          msg_length  <= in_data[47:32] - 16'd4;
          out_data    <= in_data[31:0];
          out_bytemask<= {4{1'b1}};
          in_ready    <= 1'b0;
        end

      FIRST_PKT:
          if (in_valid) begin
            if (msg_length == 16'd0) begin
            // This case should never happen assuming MSG Length >= 8 bytes.
              if ((msg_count == 16'd0) & in_endofpacket) begin
                in_ready <= 1'b1;
                state <= IDLE;
              end
              else begin
                msg_count   <= msg_count - 16'd1;
                msg_length  <= in_data[63:48] - 16'd6;
                pl0         <= in_data[47:0] - 16'd16;
                pl0_size    <= 4'd8;
                state <= MIDDLE_PKT;
              end
            end
            else if (msg_length == 16'd1) begin
              // assume The first byte following the "Message Length"
              // is the most significant byte of the payload data.
              if (pl0_size != 4'd0) begin
                // out_data <= {out_data, pl0, in_data[63:56]};                              	                
                out_data <= (out_data<<(pl0_size*8+8) | (pl0<<8) | in_data[63:56]);
                out_bytemask  <= {out_bytemask, pl0_size, 1'b1};
              end
              else begin
                out_data      <= {out_data, in_data[63:56]};
                out_bytemask  <= {out_bytemask, 1'b1};
              end

              out_valid     <= 1'b1;

              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[55:40] - 16'd1;
              pl0           <= in_data[39:0];
              pl0_size      <= 4'd5;
              state <= MIDDLE_PKT;
            end
            else if (msg_length == 16'd2) begin
              if (pl0_size != 4'd0) begin
                out_data      <= {out_data, pl0, in_data[63:48]};
//                out_bytemask  <= {out_bytemask, pl0_size, 2{1'b1}};
              end
              else begin
                out_data      <= {out_data,in_data[63:48]};
                out_bytemask  <= {out_bytemask,{2{1'b1}}};
              end
              out_valid     <= 1'b1;

              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[47:32] - 16'd1;
              pl0           <= in_data[31:0];
              pl0_size      <= 4'd4;
            end
            else if (msg_length == 16'd3) begin
              if (pl0_size != 4'd0) begin
                out_data      <= {out_data,in_data[63:40]};
                out_bytemask  <= {out_bytemask,{3{1'b1}}};
              end
              else begin
                out_data      <= {out_data,in_data[63:40]};
                out_bytemask  <= {out_bytemask,{3{1'b1}}};
              end

              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[39:24] - 16'd1;
              pl0           <= in_data[23:0];
              pl0_size      <= 4'd3;
            end
            else if (msg_length == 16'd4) begin
              out_data      <= {out_data,in_data[63:32]};
              out_bytemask  <= {out_bytemask,{4{1'b1}}};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[31:16] - 16'd1;
              pl0           <= in_data[15:0];
              pl0_size      <= 4'd2;
            end
            else if (msg_length == 16'd5) begin
              out_data      <= {out_data,in_data[63:24]};
              out_bytemask  <= {out_bytemask,{5{1'b1}}};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[23:8] - 16'd1;
              pl0           <= in_data[7:0];
              pl0_size      <= 4'd1;
            end
            else if (msg_length == 16'd6) begin
              out_data      <= {out_data,in_data[63:16]};
              out_bytemask  <= {out_bytemask,{6{1'b1}}};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[15:0] - 16'd1;
              pl0           <= 64'd0;
              pl0_size      <= 4'd0;
              state <= LEN_PKT_B10;
            end
            else if (msg_length == 16'd7) begin
              out_data      <= {out_data,in_data[63:8]};
              out_bytemask  <= {out_bytemask,{7{1'b1}}};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[7:0];
              pl0           <= 64'd0;
              pl0_size      <= 4'd0;
              state <= LEN_PKT_B17;
            end
            else if (msg_length == 16'd8) begin
              out_data      <= {out_data,in_data[63:0]};
              out_bytemask  <= {out_bytemask,{8{1'b1}}};
              out_valid     <= 1'b1;

              if ((msg_count == 16'd0) & in_endofpacket) begin
                in_ready <= 1'b1;
                state <= IDLE;
              end
              else begin
                msg_count   <= msg_count - 16'd1;
                msg_length  <= msg_length - 16'd8;
                pl0         <= 64'd0;
                pl0_size    <= 4'd0;
                state <= LEN_PKT_B76;
              end
            end
            else begin  // (msg_length > 16'd8)
              out_data      <= {out_data,in_data[63:0]};
              out_bytemask  <= {out_bytemask,{8{1'b1}}};
              state <= MIDDLE_PKT;
            end
          end




      MIDDLE_PKT:
          if (in_valid) begin
            if (msg_length == 16'd0) begin
              if (msg_count == 16'd0) begin
                state <= IDLE;
                in_ready <= 1'b1;
              end
              else begin
                msg_count   <= msg_count - 16'd1;
                msg_length  <= in_data[63:48] - 16'd1;
                out_data    <= in_data[47:0]; // New out_data
                out_bytemask<= {6{1'b1}};     // New out_bytemask
              end
            end
            else if (msg_length == 16'd1) begin
              // assume The first byte following the "Message Length"
              // is the most significant byte of the payload data.
              out_data      <= {out_data,in_data[63:56]};
              out_bytemask  <= {out_bytemask,1'b1};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[55:40] - 16'd1;
              pl0           <= in_data[39:0];
              pl0_size      <= 4'd1;
            end
            else if (msg_length == 16'd2) begin
              out_data      <= {out_data,in_data[63:48]};
              out_bytemask  <= {out_bytemask,{2{1'b1}}};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[47:32] - 16'd1;
              pl0           <= in_data[31:0];
              pl0_size      <= 4'd2;
            end
            else if (msg_length == 16'd3) begin
              out_data      <= {out_data,in_data[63:40]};
              out_bytemask  <= {out_bytemask,{3{1'b1}}};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[39:24] - 16'd1;
              pl0           <= in_data[23:0];
              pl0_size      <= 4'd3;
            end
            else if (msg_length == 16'd4) begin
              out_data      <= {out_data,in_data[63:32]};
              out_bytemask  <= {out_bytemask,{4{1'b1}}};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[31:16] - 16'd1;
              pl0           <= in_data[15:0];
              pl0_size      <= 4'd4;
            end
            else if (msg_length == 16'd5) begin
              out_data      <= {out_data,in_data[63:24]};
              out_bytemask  <= {out_bytemask,{5{1'b1}}};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[23:8] - 16'd1;
              pl0           <= in_data[7:0];
              pl0_size      <= 4'd5;
            end
            else if (msg_length == 16'd6) begin
              out_data      <= {out_data,in_data[63:16]};
              out_bytemask  <= {out_bytemask,{6{1'b1}}};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[15:0] - 16'd1;
              pl0           <= 64'd0;
              pl0_size      <= 4'd0;
            end
            else if (msg_length == 16'd7) begin
              out_data      <= {out_data,in_data[63:8]};
              out_bytemask  <= {out_bytemask,{7{1'b1}}};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[7:0];
              pl0           <= 64'd0;
              pl0_size      <= 4'd0;
            end
            else begin  // (msg_length > 16'd7)
            end
          end
//       LEN_PKT_B76:
//       LEN_PKT_B10:
      LEN_PKT_B17:
          if (in_valid) begin
            if (msg_length == 16'd0) begin
              if (msg_count == 16'd0) begin
                state <= IDLE;
                in_ready <= 1'b1;
              end
              else begin
                msg_count   <= msg_count - 16'd1;
                msg_length  <= in_data[63:48] - 16'd1;
                out_data    <= in_data[47:0]; // New out_data
                out_bytemask<= {6{1'b1}};     // New out_bytemask
              end
            end
            else if (msg_length == 16'd1) begin
              // assume The first byte following the "Message Length"
              // is the most significant byte of the payload data.
              out_data      <= {out_data,in_data[63:56]};
              out_bytemask  <= {out_bytemask,1'b1};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[55:40] - 16'd1;
              pl0           <= in_data[39:0];
              pl0_size      <= 4'd1;
            end
            else if (msg_length == 16'd2) begin
              out_data      <= {out_data,in_data[63:48]};
              out_bytemask  <= {out_bytemask,{2{1'b1}}};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[47:32] - 16'd1;
              pl0           <= in_data[31:0];
              pl0_size      <= 4'd2;
            end
            else if (msg_length == 16'd3) begin
              out_data      <= {out_data,in_data[63:40]};
              out_bytemask  <= {out_bytemask,{3{1'b1}}};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[39:24] - 16'd1;
              pl0           <= in_data[23:0];
              pl0_size      <= 4'd3;
            end
            else if (msg_length == 16'd4) begin
              out_data      <= {out_data,in_data[63:32]};
              out_bytemask  <= {out_bytemask,{4{1'b1}}};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[31:16] - 16'd1;
              pl0           <= in_data[15:0];
              pl0_size      <= 4'd4;
            end
            else if (msg_length == 16'd5) begin
              out_data      <= {out_data,in_data[63:24]};
              out_bytemask  <= {out_bytemask,{5{1'b1}}};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[23:8] - 16'd1;
              pl0           <= in_data[7:0];
              pl0_size      <= 4'd5;
            end
            else if (msg_length == 16'd6) begin
              out_data      <= {out_data,in_data[63:16]};
              out_bytemask  <= {out_bytemask,{6{1'b1}}};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
              msg_length    <= in_data[15:0] - 16'd1;
              pl0           <= 64'd0;
              pl0_size      <= 4'd0;
            end
            else if (msg_length == 16'd7) begin
              out_data      <= {out_data,in_data[63:8]};
              out_bytemask  <= {out_bytemask,{7{1'b1}}};
              out_valid     <= 1'b1;
              msg_count     <= msg_count - 16'd1;
// LEN Upper byte:
              msg_length    <= in_data[7:0];

              pl0           <= 64'd0;
              pl0_size      <= 4'd0;
            end
            else begin  // (msg_length > 16'd7)
            end
          end
      LAST_PKT:
      begin
          if (in_valid) begin
            state <= IDLE;
          end
      end
    endcase
  end
endmodule
