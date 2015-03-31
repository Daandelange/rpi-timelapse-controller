# rpi-timelapse-controller
Bash script for capturing time lapses using gphoto2, lsusb and wiringPi to control a light trough GPIO. Made for raspberryPi, should work on other linux systems.
It offers more control than the standard gphoto2 capture modes and can continue after capture failures.

## Dependencies:
You must have lsusb, wiringPi (gpio command) and gphoto2 installed.
See comments in the file for adjusting this to your configuration.

In order to be able to force a USB reset on the camera port, you need to compile [a script](http://marc.info/?l=linux-usb&m=121459435621262&q=p3) and follow [these instructions](http://askubuntu.com/questions/645/how-do-you-reset-a-usb-device-from-the-command-line).  

_If not installed, some errors are thrown and the script continues normally._

## Hardware
It uses wiringPi to turn on a light while capturing, then shut it off until the next capture starts over.  The GPIO ports of the raspberryPi are used to output a small electrical signal indicating ON/OFF.  
You'll need to make a little circuit with a transistor so you can control high current and switch off regular lights. Search the web for details.

_Simply comment out the GPIO parts if you don't need this._

## Use
There are some configuration options in the top of the main script. Let the comments guide you for instructions. There are also instructions for setting it up with `init.d` so it starts at boot time.

`cd` to the script's directory then execute with `sudo` for better performances. (usb reset and a better camera lock)  
_(No arguments, configure directly in bash file)_  

__The current script is just a basic start script, make it your own! :D  __

## License
wtfpl
http://www.wtfpl.net/