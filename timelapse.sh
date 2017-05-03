#!/usr/bin/env bash
###### !/bin/sh

# the script has to be chmodded with chmod +x
# run with sudo so it can reset itself via lsusb when gphoto crashes

# Setup the pin that controls the light switch
LIGHT_PIN=0

# timelapse trigger delay in seconds
# real delay is DELAY_BETWEEN_SHOTS + trigger execution time
DELAY_BETWEEN_SHOTS=900

# enter your vender:id of camera id (lsusb in shell to get it)
# it is used to reset usb port. (You can leave this empty.)
CAMERA_USB_VENDOR=04a9:3084
# Canon, Inc. EOS 300D / EOS Digital Rebel

# Note
# In order to work as root (by executing on boot using init.d for example)
# some commands like gpio have become /my/path/to/gpio, make sure they match your installation.

# To setup this script with init.d:
# sudo ln ./this_script.sh /etc/init.d/rc.timelapse
# cd /etc/init.d/
# sudo update-rc.d rc.timelapse defaults

# set gpio mode to write (switch control)
gpio mode $LIGHT_PIN out

# cd into photo dir ( changeme )
mkdir /home/pi/Desktop/gphoto_sessions/test3
cd /home/pi/Desktop/gphoto_sessions/test3

# set serial transfer speed / baud rate
gphoto2 --speed=384000

# setup gphoto2 (add you own preset commands)

# if not using autodetect, you must set --camera an --port
gphoto2 --auto-detect
#gphoto2 --camera MODEL
#gphoto2 --camera="Canon EOS 300D (normal mode)"
#gphoto2 --port="usb:001,006"

# set capture speed to make sure
# fit this to your cam. Use gphoto2 --list-config to get names
# then use gphoto --get-config name to getpossible settings
#gphoto2 --set-config name=value


#/main/settings/shootingmode=4|M,8|Manual 2,0|auto,21|neutral
gphoto2 --set-config-index /main/settings/shootingmode=4

#/main/settings/ownername
#/main/settings/capturesizeclass

# /main/settings/iso=1|100,4|200,|400
gphoto2 --set-config-index /main/settings/iso=1

#/main/settings/shutterspeed=0|Bulb,30|1/125
gphoto2 --set-config-index /main/settings/shutterspeed=30

#/main/settings/zoom

#/main/settings/aperture=10|4.0,4|2.0,25|22,16|8
gphoto2 --set-config-index /main/settings/aperture=10

#/main/settings/exposurecompensation

# /main/settings/imageformat=7|Large Fine JPEG,2|Small Normal JPEG,0|RAW,1|RAW 2
gphoto2 --set-config-index /main/settings/imageformat=7

#/main/settings/focusmode=1|Auto focus: AI servo,3|Manual focus,2|Auto focus: AI focus,0|Auto focus: one-shot 
gphoto2 --set-config-index /main/settings/focusmode=3

#/main/settings/flashmode=0|Flash off,1|Flash on,2|Flash auto
gphoto2 --set-config-index /main/settings/flashmode=0

#/main/settings/beep
#/main/actions/syncdatetime
#/main/status/model
#/main/status/datetime
#/main/status/firmwareversion
#/main/status/driver
#/main/Driver/list_all_files

#gphoto2 --mkdir "gphotoTimelapse"


CONTINUE=1
i=0
fails=0
# ininite loop
while [ $CONTINUE = 1 ]
do
	echo "Taking photo $i (including $fails fails) ..."

	# Turn lights on
	gpio write $LIGHT_PIN 1
	sleep 5

	# Take photo!
	#gphoto2 --capture-and-download

	SUCCEEDED=false

	# stackoverflow.com/questions/687948
	# gives x seconds to command to execute a command
	# call the command here! (take photo)
	{
		#gphoto2 --capture-image-and-download --no-keep
		gphoto2 --capture-image --no-keep
	} & pid=$!
	# define timeout limit here
	( sleep 60 && kill -HUP $pid ) 2>/dev/null & watcher=$!
	if wait $pid 2>/dev/null; then
		# command terminated
		echo "Photo taken successfully! :D"
		
		SUCCEEDED=true
		
		# kill watcher
		pkill -HUP -P $watcher
		wait $watcher
	else
		# timeout occured
		echo "Oups, gphoto failed taking the photo within 60 seconds..."
		echo "If this keeps failing, something might be wrong. (Firmware crash? No more batteries? etc.)"
		
		SUCCEEDED=false
	fi

	# shut lights anyways
	sleep 1
	gpio write $LIGHT_PIN 0

	if [ "$SUCCEEDED" = true ]; then
		# download last image
		echo "Downloading image before continuing..."
		#gphoto2 --get-file "first-last"
		gphoto2 --get-file 1  --force-overwrite
		gphoto2 --delete-file 1
		#gphoto2 -d ""
		#gphoto2 --get-all-files  --force-overwrite
		#gphoto2 --delete-all-files
		# max 10sec to wait for dl signal
		#gphoto2 --wait-event-and-download=10
		#gphoto2 --new
	else
		# reset camera with a lsusb reset
		echo "Resetting USB connection now..."

		$(lsusb -d 04a9:3084 | awk -F '[ :]' '{ print "/dev/bus/usb/"$2"/"$4 }' | xargs -I {} echo "/home/pi/GIT/rpi-timelapse-controller/usbreset {}")
		# todo: use gphoto2 --reset

		echo "Waiting a minimum of 60sec before retrying..."
		sleep 60
		
		# restart gphoto and restart capturing
		echo "Auto detecting cameras..."
		gphoto2 --auto-detect
		
		# todo: reboot after 5 tries
		# sudo shutdown -h -F now -r
	fi

	
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
