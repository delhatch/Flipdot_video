# Flipdot_video

This project interfaces with a D8M camera module, processes the image, and streams it to a flip-dot display.

![Demo_video1](https://github.com/delhatch/Flipdot_video/blob/master/flipdot_display_hardware.mp4)

![Demo_video2](https://github.com/delhatch/Flipdot_video/blob/master/flipdot_display_demo.mp4)

The incoming camera video (at 60 fps) is de-Bayered, a threshold is applied (black/white pixel), low-pass filtered, down-sampled, and then sent at 19,200 baud to a flip-dot display.

This project uses the Cyclone IV FPGA used in the DE2-115 evaluation board to:

a) configure and interface to the camera module, and

b) buffer the raw video into an SDRAM frame buffer. The FPGA has two VGA frame buffers and the FPGA creates the VGA waveforms for the monitor. A physical switch selects between one frame buffer that holds the RGB (normal) video, and a second VGA frame buffer that holds a full frame of the black/white pixel data. The .mp4 video included in this project shows me switching between the two.

c) Simulataneously with that, I down-samples the resolution (to the value defined in "flipdot_params.h"), and low-pass filter the video frames,  and then store that data to a 56 x 24 bit flipdot frame buffer.

d) The final step is to have a (custom) UART read the flip-dot frame buffer and transmit the image to the flip-dot display at 19200 baud.

*** Possible Improvements ***

1) Auto-exposure control on the source video (to account for changing light conditions).

2) Temporally filter the pixels so that the flip-dot display does not pixels flipping back-and-forth when there is no camera motion.
