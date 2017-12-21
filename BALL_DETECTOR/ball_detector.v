// This module looks at the video, selects red pixels, low-pass filters that, and
//   then finds the center of the red object.
// The output is the placement of a marker (+ like symbol) overlaying the camera video.

module ball_detector (
   input reset, 
   input [23:0] video_in,       // RGB camera video, post-de-Bayer
   input [19:0] vAddress,       // Address of the current pixel being displayed. Pixel pointer.
   input h_sync,
   input v_sync,
   input ball_clock,
   input freeze,            // Stop filling the ball_ram RAM with new image data. Freezes the display.
   input active_area,     // high when VGA is in the active area (not Hsync,Vsync...)
   input vid_select,        // Selects camera video, or ball_ram video image.
   output reg [23:0] video_out,  // output to VGA generator
   input uclk,
   output txd,               // serial data to flipdot display
   //
   output [6:0] EX_IO,   // De-bug signals out to pins
   input [17:0] SW
);

wire [8:0] horz_line;  // row number of the middle of the red object.
wire [9:0] vert_line;

wire seems_white;
wire [7:0] RED;
wire [7:0] GREEN;
wire [7:0] BLUE;

wire ram_seems_white;  // stored value of white pixels (in ball_ram).
wire [9:0] h_value;
wire [8:0] v_value;

assign RED = video_in[23:16];
assign GREEN = video_in[15:8];
assign BLUE = video_in[7:0];

red_frame u1 ( 
   .VGA_clock( ball_clock ),
   //.reset( reset ),
   .pixel_data( video_in ),
   .h_sync( h_sync ),
   .v_sync( v_sync ),
   .x_cont( h_value ),
   .y_cont( v_value ),
   .white_pixel( seems_white ),  // This is the output of "red_frame.v". Low-pass filtered bright/white pixel determination.
   .filter_on( SW[15] )
   //.EX_IO( EX_IO )
);

// Mux. Combinatorial logic to select the camera video, or, the white pixel detector video frame.
always @(*)
   if( vid_select == 1'b0 ) video_out = { RED[7:0], GREEN[7:0], BLUE[7:0] };
   else video_out = { 3{1'b0, {7{ram_seems_white}}}};
  
// Create a two-port RAM (ball_ram)). 1x640x480 bits.
// Input = Camera image, but intensity-thresholded (black or white) and low-pass filtered by red_frame.v.
// Each pixel is 1 or 0, depending on pixel intensity level.
// Output feeds the VGA waveform generator.
ball_ram this_ball_ram( 
	.clock( ball_clock ),
	.data( seems_white ),
	.rdaddress( vAddress ),
	.rden( h_sync || v_sync ),   // is high when VGA generator is in the active area
	.wraddress( vAddress /*>= 1 ? VGA_ADDRESS-1 : VGA_ADDRESS*/ ),   // counters that track the output of the SDRAM
	.wren( active_area & ~freeze ),
	.q( ram_seems_white )
);

serial_stream_gen stream_gen_u1 (
   .ball_clock( ball_clock ),
   .reset( reset ),
   .h_sync( h_sync ),
   .v_sync( v_sync ),
   .h_value( h_value ),   // row and column of the current video pixel
   .v_value( v_value ),
   .seems_white( seems_white ),  // Gets real-time pixel value. Will create small flipdot memory.
   //
   .uclk( uclk ),     // UART clock
   .txd( txd ),        // Serial output to the flipdot display.
   // debug header
   .EX_IO( EX_IO )
);

Mod_counter #(.N(10), .M(640)) h_count (
		.clk( ball_clock ),
		.clk_en( h_sync  ),
		.reset( ~h_sync ),
		.max_tick( ),
		.q( h_value )    // horizontal (column) pixel counter, 0 to 639
);

Mod_counter #(.N(9), .M(480)) v_count (
		.clk( h_sync ),
		.clk_en( v_sync ),
		.reset( ~v_sync ),
		.max_tick( ),
		.q( v_value )    // vertical (row) pixel counter, 0 to 479
);

/*
Mod_counter #(.N(19), .M(307200)) pixel_count (
		.clk( ball_clock ),
		.clk_en( h_sync & v_sync ),
		.reset( ~v_sync ),
		.max_tick( ),
		.q()
);
*/

//assign EX_IO[0] = ball_clock;
//assign EX_IO[1] = h_sync;
//assign EX_IO[2] = h_value[0];
//assign EX_IO[3] = h_value[1];
//assign EX_IO[4] = h_value[2];
//assign EX_IO[5] = h_value[3];
//assign EX_IO[6] = h_value==5 ? 1'b1 : 1'b0;

endmodule