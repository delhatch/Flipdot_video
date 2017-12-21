# Red_Tracker

This project interfaces with a D8M camera module by Terasic. It detects any red object, and tracks it.

The incoming camera video (at 60 fps) is filtered for red pixels and creates a frame buffer. This red-pixel frame buffer is shown on the MP4 video file.

It then finds the center of the largest red mass, and overlays a crosshair on it.

This project uses the Cyclone IV FPGA used in the DE2-115 evaluation board to:

a) configure and interface to the camera module

b) buffer the raw video into an SDRAM frame buffer

c) simulataneously, detect red pixels and create a second frame buffer

d) while creating the second frame buffer, detect the largest red mass

e) generate the x,y coordinate of the center of the red mass

f) overlay a crosshair onto the video going to the VGA output

g) FPGA also has a VGA frame buffer and creates the VGA waveform


*** Possible Improvements ***

1) Could create a PWM signal to drive servo motors to move the camera to track the red object.

2) Fire a nerf cannon at the red object.
