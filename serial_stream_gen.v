module serial_stream_gen (
   input ball_clock,
   input reset,
   input h_sync,
   input v_sync,
   input [9:0] h_value,   // row and column of the current video pixel
   input [8:0] v_value,
   input seems_white,
   //
   input uclk,     // UART clock
   output reg txd,
   //
   output [6:0] EX_IO   // De-bug signals out to pins
);

`include "flipdot_param.h"

localparam [2:0] WAIT4VS_HIGH = 0, WAIT2_START = 1, XFER = 2, PREP_NEXT_ROW1 = 3, PREP_NEXT_ROW2 = 4, WAIT4VS_LOW = 5;

wire [10:0] flip_addr;  // Address pointer for writing into flipdot ram dual-port buffer. 0 to 1567.
reg [6:0] a[0:223];   // This holds the (4 rows x 56 col's) of 7-bit bytes that will be read by the UART, and sent to the flipdot display.
reg [2:0] state, next;
reg [7:0] wr_row;   // pointer into the "a" flipdot pixel data, for writing into it.
reg [4:0] row;
reg [5:0] col;
reg [7:0] a_col;   // Index into the array of a[] bytes that will be read by the UART.
reg [10:0] rd_addr;   // Linear counter addresses for reading the data in the dot_ram. 0 to (56x24 -1 = 1343). 1344 pixels.
reg [7:0] txd_word;   // pointer into the "a" flipdot pixel data, for reading.
reg [2:0] row_0_to_6;   // Each of the four horizontal sections of the flipdot have row index 0 to 6.

wire [3:0] core_state;
wire [4:0] byte_count;
wire [2:0] line_count;
wire wr_enable;

wire byte_done, line_done, display_done;
wire [7:0] a_index;   // index into the "a" data. Used by the UART to transmit the "a" data.
wire dot_ram_ce;       // High when VGA video is in the flipdot display region.
wire read_ram_ce;
wire my_dot_ram_q;
wire v_div_out, h_div_out;

// This signal is high when the incoming video pixel is located within the flipdot display region.
assign dot_ram_ce = (h_value >= start_x) && (h_value <= end_x) && (v_value >= start_y) && (v_value <= end_y);
// For reading out dot_ram into the byte-oriented registers, use the signal below as a read enable. 56x28 flipdot pixels.
assign read_ram_ce = (h_value >= 292) && (h_value <= 347) && (v_value >= 226) && (v_value <= 253);

// dot_ram_ce is high during the whole rectangle, but only store selected rows and columns.
assign wr_enable = dot_ram_ce & h_div_out & v_div_out;

// This creates "divided by 'sampling_ratio'" pulses while dot_ram_ce is high. Indicates which video columns -> flipdot display.
Mod_counter #(.N(4), .M(sampling_ratio)) h_div_gen (
		.clk( ball_clock ),
		.clk_en( dot_ram_ce ),
		.reset( ~dot_ram_ce ),
		.max_tick( h_div_out ),
		.q(  )
);
// This creates a row-long pulse, using the "sampling_ratio." Indicates if this row will be displayed on the flipdot display.
Mod_counter #(.N(4), .M(sampling_ratio)) v_div_gen (
		.clk( h_sync ),
		.clk_en( 1'b1 ),
		.reset( ~v_sync ),
		.max_tick( v_div_out ),
		.q(  )
);

// Create a 28 (tall) x 56 pixel (wide) buffer. This holds the 1-bit data heading to the flipdot display.
dot_ram my_dot_ram(
	.wrclock( ball_clock ),
   .wren( wr_enable ), 
	.data( seems_white ),
	.wraddress( flip_addr ),  // Keep write addresses contiguous while sampling every other pixel.
	.rdaddress( rd_addr ),
	.rdclock( ball_clock ),
	.rden( read_ram_ce ),
	.q( my_dot_ram_q )
);

// This generates the write address for writing the pixel value (1 or 0) INTO the dual port RAM.
Mod_counter #(.N(11), .M(1568)) wr_addr_gen (
		.clk( ball_clock ),
		.clk_en( wr_enable ),
		.reset( ~v_sync ),
		.max_tick( ),
		.q( flip_addr ) // Address for writing pixels into the 56 x 24 bit flipdot pixel array (dot_ram).
);
   
// end of generating the write addresses.
// Now read out the 1-bit pixel values, form them into a 7-bit value that corresponds to flipdot columns,
//    and write the data into the "a" registers. The "a" registers will be read out by
//    the UART.
always @ (posedge ball_clock or posedge reset )
   if( reset )
      state <= WAIT4VS_LOW;
   else
      state <= next;

always @* begin
   next = WAIT4VS_LOW;
   case( state )
      WAIT4VS_HIGH   : if( v_sync == 1'b0 ) next = WAIT4VS_HIGH;
                       else next = WAIT2_START;
      WAIT2_START    : if( read_ram_ce == 1'b0 ) next = WAIT2_START;
                       else next = XFER;
      XFER           : if( read_ram_ce == 1'b1 ) next = XFER;
                       else next = PREP_NEXT_ROW1;
      PREP_NEXT_ROW1 : next = PREP_NEXT_ROW2;
      PREP_NEXT_ROW2 : if( wr_row == 224 ) next = WAIT4VS_LOW;      // done transferring the data from 2-port RAM to registers.
                       else if( read_ram_ce == 1'b0 ) next = PREP_NEXT_ROW2;
                       else next = XFER;
      WAIT4VS_LOW    : if( v_sync == 1'b1 ) next = WAIT4VS_LOW;
                       else next = WAIT4VS_HIGH;
    endcase
end
      
always @ (posedge ball_clock or posedge reset )
   if( reset ) begin
      row <= 0;
      col <= 0;
      wr_row <= 0;
      a_col <= 0;
      rd_addr <= 0;
      row_0_to_6 <= 0;
      end
   else
      case( next )
         WAIT4VS_HIGH   : begin   // state 0
                             row <= 0;
                             col <= 0;
                             wr_row <= 0;
                             row_0_to_6 <= 0;
                          end
         WAIT2_START    : begin    // state 1
                             row <= 0;
                             col <= 0;
                             wr_row <= 0;
                             rd_addr <= 0;
                             a_col <= 0;
                             row_0_to_6 <= 0;
                          end
         XFER           : begin    // state 2
                             a[a_col][row_0_to_6] <= my_dot_ram_q;  // This is where the pixel data transfer happens.
                             col <= col + 1;
                             rd_addr <= rd_addr + 1;
                             a_col <= wr_row + col + 1;
                          end
         PREP_NEXT_ROW1 : begin    // state 3
                             row <= row + 1;
                             row_0_to_6 <= row_0_to_6 + 1;
                             col <= 0;
                             if( (row==6) || (row==13) || (row==20) || (row==27) ) begin
                                wr_row <= wr_row + 56;  // Increments after every 7 rows of dot_ram row.
                                row_0_to_6 <= 0;
                                end
                          end
         PREP_NEXT_ROW2 : begin    // state 4
                             rd_addr <= row * 56;  // Defensive. Ensures address start properly for each row.
                             a_col <= wr_row;
                          end
      endcase
// end of creating the state machine outputs.

// The UART -------------------------------------------------------------
assign a_index = (line_count * 28) + (byte_count - 3);  // will count from 0 to 223

// Load the byte to xmit into txd_word.
always @ ( posedge uclk or posedge reset )
   if( reset )
      txd_word <= 0;
   else begin
      if( byte_count == 0 )      txd_word <= 8'h80;
      else if( byte_count == 1 ) txd_word <= 8'h83;
      else if( byte_count == 2 ) txd_word <= { {5{1'b0}}, line_count };
      else if( (byte_count>2) && (byte_count<=30) ) txd_word <= {1'b0, a[a_index]};
      else txd_word <= 8'h8f;
      end

// Line counter. 0 to 7. Display is in 8 sections, two section per row.
Mod_counter #(.N(3), .M(8)) row_count (
		.clk( uclk ),
		.clk_en( line_done & byte_done ),
		.reset( reset ),
		.max_tick( display_done ),      // output when final count is reached
		.q( line_count )    // horizontal (column) pixel counter, 0 to 639
);
// Line byte counter. 0 to 31. Each half-row of the display requires 32 bytes to be xmitted.
Mod_counter #(.N(5), .M(32)) byte_counter (
		.clk( uclk ),
		.clk_en( byte_done ),
		.reset( reset ),
		.max_tick( line_done ),      // output when final count is reached
		.q( byte_count )    // horizontal (column) pixel counter, 0 to 639
);
// Core state counter. Shifts out txd_word bits. 0 to 9.
Mod_counter #(.N(4), .M(10)) state_count (
		.clk( uclk ),
		.clk_en( 1'b1 ),
		.reset( reset ),
		.max_tick( byte_done ),      // output when final count is reached
		.q( core_state )    // horizontal (column) pixel counter, 0 to 639
);
      
always @ ( posedge uclk or posedge reset )
   if( reset )
      txd <= 1'b1;
   else
      case( core_state )  // synthesis full_case parallel_case
         4'd0 : txd <= 1'b0;
         4'd1 : txd <= txd_word[0];
         4'd2 : txd <= txd_word[1];
         4'd3 : txd <= txd_word[2];
         4'd4 : txd <= txd_word[3];
         4'd5 : txd <= txd_word[4];
         4'd6 : txd <= txd_word[5];
         4'd7 : txd <= txd_word[6];
         4'd8 : txd <= txd_word[7];
         4'd9 : txd <= 1'b1;           // One stop bit.
      endcase
      
assign EX_IO[0] = txd;
//assign EX_IO[1] = my_dot_ram_q;
//assign EX_IO[2] = a_col[1];
//assign EX_IO[3] = a_col[3];
//assign EX_IO[4] = a_col[5];
//assign EX_IO[5] = a_col[6];
//assign EX_IO[6] = a_col[7];
      
endmodule
