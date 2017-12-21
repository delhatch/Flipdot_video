# Flipdot_video

This project interfaces with a D8M camera module by Terasic, processes the image, and streams it to a flip-dot display.

The incoming camera video (at 60 fps) is filtered...

This project uses the Cyclone IV FPGA used in the DE2-115 evaluation board to:

a) configure and interface to the camera module

b) buffer the raw video into an SDRAM frame buffer

c) simulataneously, applies a threshold, low-pass filters the video frames, down-samples the resolution (to the value defined in "flipdot_params.h"), and creates a second frame buffer

d) while creating the second frame buffer, ...

f) Reads the flipdot buffer, and using custom UART sends the image to the flip-dot display.

g) FPGA also has a VGA frame buffer and creates the VGA waveform


*** Possible Improvements ***

1) Auto-exposure control on the source video (to account for changing light conditions) would be nice.

2) 
