# mame-inactivity-exit
A lightweight Lua script for MAME that automatically exits the emulator after a set period of user inactivity. The script monitors real joystick button presses and resets a timer on each input. If no buttons are pressed within the configured timeout (default: 10 minutes), MAME exits cleanly by sending the ESC key.
