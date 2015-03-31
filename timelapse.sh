#!/usr/bin/env bash
###### !/bin/sh

# the script has to be chmodded with chmod +x
# run with sudo so it can reset itself via lsusb when gphoto crashes

# Setup the pin that controls the light switch
LIGHT_PIN=6

# timelapse trigger delay in seconds
# real delay is DELAY_BETWEEN_SHOTS + trigger execution time
DELAY_BETWEEN_SHOTS=900

# enter your vender:id of camera id (lsusb in shell to get it)
# it is used to reset usb port. (You can leave this empty.)
CAMERA_USB_VENDOR=04a9:3084

# Note
# In order to work as root (by executing on boot using init.d for example)
# some commands like gpio have become /my/path/to/gpio, make sure they match your installation.

# To setup this script with init.d:
# sudo ln ./this_script.sh /etc/init.d/rc.timelapse
# cd /etc/init.d/
# sudo update-rc.d rc.timelapse defaults

# set gpio mode to write (switch control)
/usr/local/bin/gpio mode $LIGHT_PIN out

# cd into photo dir ( changeme )
cd /home/pi/Desktop/gphoto_sessions/test3

# setup gphoto2 (add you own preset commands)
#gphoto2 --auto-detect
#gphoto2 --camera MODEL


CONTINUE=1
i=0
fails=0
# ininite loop
while [ $CONTINUE = 1 ]
do
	echo "Taking photo $i (including $fails fails) ..."

	# Turn lights on
	/usr/local/bin/gpio write $LIGHT_PIN 1
	sleep 5

	# Take photo!
	#gphoto2 --capture-and-download

	SUCCEEDED=false

	# stackoverflow.com/questions/687948
	# gives x seconds to command to execute a command
	# call the command here! (take photo)
	{
		gphoto2 --capture-image-and-download
	} & pid=$!
	# define timeout limit here
	( sleep 40 && kill -HUP $pid ) 2>/dev/null & watcher=$!
	if wait $pid 2>/dev/null; then
		# command terminated
		echo "Photo taken successfully! :D"
		
		SUCCEEDED=true
		
		# kill watcher
		pkill -HUP -P $watcher
		wait $watcher
	else
		# timeout occured
		echo "Oups, gphoto failed taking the photo within 40 seconds..."
		echo "If this keeps failing, something might be wrong. (Firmware crash? No more batteries? etc.)"
		# reset camera with a lsusb reset
		echo "Resetting USB connection now."

		$(lsusb -d 04a9:3084 | awk -F '[ :]' '{ print "/dev/bus/usb/"$2"/"$4 }' | xargs -I {} echo "/home/pi/rpi-timelapse-controller/usbreset {}")
		
		# restart gphoto and restart capturing
		echo "Auto detecting cameras..."
		gphoto2 --auto-detect
		
		# todo: reboot after 5 tries
		# sudo shutdown -h -F now -r
	fi

	# shut lights
	sleep 1
	/usr/local/bin/gpio write $LIGHT_PIN 0
	
	# allow to exit infinite loop by pressing any key
	read -t 1 -n 1 -s KEY
	if [ ! -z "$KEY" ]
	then
		INTERRUPT=1
		echo "Keypressed! Exiting time lapse now..."
		exit 0;
	fi
	
	echo " "
	echo " "

	# end loop ? // todo
	i=`expr $i + 1`
	if [ "$i" -gt 9999999999 ]
	then
		echo "Done taking photos!"
		#CONTINUE=0
		#exit 0
	elif [ "$SUCCEEDED" = true ]
	then
		echo "Waiting for next photo ($i) to be taken... ($DELAY_BETWEEN_SHOTS seconds)"
		sleep $DELAY_BETWEEN_SHOTS
	else
		echo "Due to an error, retrying to take another picture..."
		fails=`expr $fails + 1`
	fi

done

exit 0
