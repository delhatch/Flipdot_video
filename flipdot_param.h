//flipdot_param.h

// The scaling ratio. 1 = 1:1.  2 = 1:2 (sample every other video pixel.
// Tested working for values 1, 2 and 4. For 3, the flipdot image has a R-to-L slope to it.
parameter sampling_ratio = 4;

parameter start_x = 320 - ( (sampling_ratio * 56) / 2);
parameter end_x   = 320 + ( (sampling_ratio * 56) / 2) - 1 ;

parameter start_y = 240 - ( (sampling_ratio * 28) / 2);
parameter end_y   = 240 + ( (sampling_ratio * 28) / 2) - 1 ;

parameter H_OFF = 56 * sampling_ratio ; // dimensions of flipdot display is 56 pixels wide x 28 tall.
parameter V_OFF = 28 * sampling_ratio ;