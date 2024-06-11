#!/bin/bash

#Set some veriables
USR="sanbox1"
PASS="S4ndB0x"

# Check if the script was run with sudo
if [ "$USR" == "" ]; then
  echo "Please run the script using the 'sudo' command"
  exit 0
fi

#Create the new user with a home directory and set the shell to /usr/sbin/nologin to disable command-line access

useradd -m -s /usr/sbin/nologin "$USR"

#Update sources -y automaticlly says yes to everything
apt-get update -y
#Use apt-get intall 
apt-get install -y --no-install-recommends openbox pulseaudio freerdp2-x11 gdm3

usermod -a -G audio $USR

mv /etc/xdg/openbox/autostart /etc/xdg/openbox/autostart.old
cat > /etc/xdg/openbox/autostart <<EOF 
xfce-mcs-manager &
/snap/bin/firefox "https://google.com" &
EOF

mv /etc/gdm3/custom.conf /etc/gdm3/custom-old.conf
cat > /etc/gdm3/custom.conf <<EOF
[daemon]
#WaylandEnable=false

# Enabling automatic login
AutomaticLoginEnable = true
AutomaticLogin = $USR

# Enabling timed login
#  TimedLoginEnable = true
#  TimedLogin = user1
#  TimedLoginDelay = 10

[security]

[xdmcp]

[chooser]
EOF

cat > /var/lib/AccountsService/users/$USR <<EOF
[InputSource0]
xkb=es

[User]
XSession=openbox
SystemAccount=false
EOF

mv /etc/xdg/openbox/menu.xml /etc/xdg/openbox/menu.xml.old

cat > /etc/xdg/openbox/menu.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>

<openbox_menu xmlns="http://openbox.org/"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://openbox.org/
                file:///usr/share/openbox/menu.xsd">

<menu id="root-menu" label="Openbox 3">
  <item label="Web browser">
  e <action name="Execute"><execute>x-www-browser</execute></action>
  </item>
  <separator />
  <item label="Exit">
    <action name="Exit" />
  </item>
</menu>

</openbox_menu>
EOF
