#!/bin/bash

###############################################
#  V0.1 - 20/10/2024
#  Thomas Eeles. 
#  Raspberry PI Kiosk Deployment Script

#We need to be sudo, if not fail
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use sudo." 
   exit 1
fi

while getopts "h:" opt; do
  case ${opt} in
    h )
      h=$OPTARG
      ;;
    \? )
      echo "Usage: ./setup.sh -h <HOSTNAME>"
      exit 1
      ;;
  esac
done

#Exit if we dont have a hostname
if [ -z "$h" ]; then
  echo "Hostname must be specified with -h <HOSTNAME>"
  exit 1
fi

#Veribales
conf=".config/wayfire.ini"
host="RMPI-$h"
CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
#current_user=$(whoami)
PASS=$(openssl rand -base64 15 | tr -dc 'a-zA-Z0-9' | head -c 20)

echo "RM PI Kiosk Setup Script V0.1"
echo "This script will setup the PI for kiosk use at Rightmove"
echo "The script will create a new hostname, set user passwords, and create an auto start function"
echo "During the setup you will need to take note of the unequie password"
echo "running upates, this will take a long ass time"
sleep 5
#update le pi
apt update && apt upgrade -y
#set the hostname
echo "setting $host as the new hostname"
while true; do
    read -p "Is this the correct hostname? (Y/N): " choice
    case "$choice" in
        [Yy]* )
            echo "Setting the hostname"
            sleep 5
            echo $host > /etc/hostname
			sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$host/g" /etc/hosts
            break
            ;;
        [Nn]* )
            echo "Operation aborted."
            exit 1
            ;;
        * )
            echo "Please enter Y or N."
            ;;
    esac
done
echo "installing stuff and making some config tweaks"
#Install wtype
apt install wtype -y

#Updaty the wtype config
cat <<EOF >> "$conf"
[autostart]
panel = wfrespawn wf-panel-pi
background = wfrespawn pcmanfm --desktop --profile LXDE-pi
xdg-autostart = lxsession-xdg-autostart
chromium = chromium-browser https://rightmove.co.uk --kiosk --noerrdialogs --disable-infobars --no-first-run --ozone-platform=wayland --enable-features=OverlayScrollbar --start-maximized
switchtab = bash ~/switchtab.sh
screensaver = false
dpms = false
EOF
#make the switchtab.sh file for boot
cat <<EOF > ~/switchtab.sh
#!/bin/bash

# Find Chromium browser process ID
chromium_pid=$(pgrep chromium | head -1)

# Check if Chromium is running
while
[
[ -z $chromium_pid ]]; do
  echo "Chromium browser is not running yet."
  sleep 5
  chromium_pid=$(pgrep chromium | head -1)
done

echo "Chromium browser process ID: $chromium_pid"

export XDG_RUNTIME_DIR=/run/user/1000

# Loop to send keyboard events
while true; do
  # Send Ctrl+Tab using `wtype` command
  wtype -k F5

  # Send Ctrl+Tab using `wtype` command
  wtype -k F5

  sleep 10
done
EOF
#run all the security stuff, turn off the USB ports, and turn off blue tooth 
cat <<EOF > /etc/rc.local
#!/bin/sh -e
#
*#* rc.local
#
*#* This script is executed at the end of each multiuser runlevel.
*#* Make sure that the script will "exit 0" on success or any other
*#* value on error.
#
*#* In order to enable or disable this script just change the execution
*#* bits.
#
*#* By default this script does nothing.

echo '1-1' | sudo tee /sys/bus/usb/drivers/usb/unbind

exit 0
EOF

cat <<EOF >> /boot/firmware/config.txt
dtoverlay=disable-bt
EOF

echo "A new password will be set for $current_user for remote login"
echo "RMManage:$PASS" | chpasswd
  
 while true; do
     read -p "The following $PASS has been set, press Y to confirm you have recorded the password: " confirm
     case "$confirm" in
          [Yy]* )
              echo "Thank you. Continuing..."
              break
              ;;
          * )
              echo "Please press Y when you have recorded the password."
              ;;
      esac
  done
echo "time to setup automatic updates, this might take a while"
sleep 10
apt-get update
apt-get install unattended-upgrades
dpkg-reconfigure --priority=low unattended-upgrades
echo "Enable VNC for remote changes to the browser"
raspi-config nonint do_vnc 0

echo "You can now set the correct HTTPS landing page for a static view, or use VNC to create an authenticated display"
echo "The system will now reboot, if you have issues contact IT Security"
sleep 10

#that should all be done now, so we will reboot
reboot now
 
#END