# Run this to install dependencies.
# cd /path/to/rpi-timelapse-controller
# chmod +x ./install.sh && ./install.sh

echo "::Setting permissions for timelapse.sh ..."
chmod +x ./timelapse.sh

echo "::Installing gphoto2 and wiringpi..."
#sudo apt-get update
sudo apt-get install gphoto2 wiringpi

echo "::Downloading and compiling usbreset script..."
wget -q --output-document=usbreset.c "http://marc.info/?l=linux-usb&m=121459435621262&q=p3"
cc usbreset.c -o usbreset
chmod +x usbreset
echo "Warning !!!"
echo "Installed a 3rd party script. You might want to check its content before continuing. See ./usbreset.c"

echo "::Done, you can now configure and run ./timelapse.sh .";