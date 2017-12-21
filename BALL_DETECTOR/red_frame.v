// This module low-pass filters the  pixel data.
// The input is a three-element column of data above the current camera pixel.
// This module fills a 1-bit frame buffer.
module red_frame ( 
   input VGA_clock,
   //input reset,
   input [23:0] pixel_data,
   input [9:0] x_cont,
   input [8:0] y_cont,
   input h_sync,
   input v_sync,
   output reg white_pixel,
   input filter_on,
   //output [6:0] EX_IO   // De-bug signals out to pins
   input [17:0] SW
);

localparam START_UP = 0, WAIT = 1, IS_RED = 2;

wire tap_top, tap_middle, tap_bottom;
reg d1_top, d2_top, d1_middle, d2_middle, d1_bottom, d2_bottom;
reg [3:0] sum;
reg [9:0] cntr;    // counts consecutive red pixels on the active video row (line)). Max value of 640.
reg [9:0] max_ever; // Holds the value of the largest number of consecutive pixels encountered in any line so far, this video frame.
reg [9:0] end_x;      // column that the red streak ended on.
reg [8:0] line_of_max;  // video line (0-479) that contained the maximum number of sequential red pixels.
reg [1:0] state;

// This is the value that gets passed up a level. It represents the pixel two rows above the current
//   camera pixel location. (The filtering creates 2 raster lines of latency.)
always @ (*) begin
   sum = d2_top  +  d1_top  +  tap_top +
         d2_middle + d1_middle + tap_middle +
         d2_bottom + d1_bottom + tap_bottom;
   if( filter_on == 1'b1 ) begin
      if( sum >= 5 ) white_pixel = 1'b1;
      else white_pixel = 1'b0;
      end
   else 
      white_pixel = tap_middle;
end

// Create a 3x3 array from the 1x3 incoming column of pixel data.
always @ (posedge VGA_clock) begin
   d2_top <= d1_top;
   d1_top <= tap_top;
   d2_middle <= d1_middle;
   d1_middle <= tap_middle;
   d2_bottom <= d1_bottom;
   d1_bottom <= tap_bottom;
end
   

// This is the module that buffers three lines of video data so that the 3x3 low-pass
//    algorithm can operate.
red_line_buffer u1 ( 
   .bit_clk( VGA_clock ),
   .pixel( pixel_data ),
   .h_sync( h_sync ),
   .x_cont( x_cont ),
   // The tap outputs are the column of 3 pixels above the current camera pixel location.
   .tap_top( tap_top ),
   .tap_middle( tap_middle ),
   .tap_bottom( tap_bottom ),
   //
   .SW( SW )
);

//assign EX_IO[0] = v_sync;
//assign EX_IO[1] = h_sync;
//assign EX_IO[2] = cntr[0];
//assign EX_IO[3] = cntr[1];
//assign EX_IO[4] = state[0];
//assign EX_IO[5] = state[1];
//assign EX_IO[6] = red_pixel;

endmodule