#!/bin/bash

# Set some variables
USR="sandbox1"
PASS="S4ndB0x"

# Check if the script was run with sudo
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run the script using the 'sudo' command"
  exit 1
fi

# Create the new user with a home directory and set the shell to /usr/sbin/nologin to disable command-line access
echo "Creating user $USR..."
useradd -m -s /usr/sbin/nologin "$USR"
echo "$USR:$PASS" | chpasswd

# Update sources -y automatically says yes to everything
echo "Updating package sources..."
apt-get update -y

# Use apt-get install
echo "Installing necessary packages..."
apt-get install -y --no-install-recommends openbox pulseaudio freerdp2-x11 gdm3

# Add user to audio group
echo "Adding $USR to audio group..."
usermod -a -G audio "$USR"

# Configure Openbox autostart
echo "Configuring Openbox autostart..."
mkdir -p /etc/xdg/openbox
mv /etc/xdg/openbox/autostart /etc/xdg/openbox/autostart.old 2>/dev/null
cat > /etc/xdg/openbox/autostart <<EOF
xfce-mcs-manager &
/snap/bin/firefox "https://google.com" &
EOF

# Configure GDM3 for automatic login
echo "Configuring GDM3 for automatic login..."
mv /etc/gdm3/custom.conf /etc/gdm3/custom-old.conf 2>/dev/null
cat > /etc/gdm3/custom.conf <<EOF
[daemon]
# WaylandEnable=false

# Enabling automatic login
AutomaticLoginEnable = true
AutomaticLogin = $USR

[security]

[xdmcp]

[chooser]
EOF

# Configure AccountsService
echo "Configuring AccountsService for $USR..."
mkdir -p /var/lib/AccountsService/users
cat > /var/lib/AccountsService/users/$USR <<EOF
[InputSource0]
xkb=es

[User]
XSession=openbox
SystemAccount=false
EOF

# Configure Openbox menu
echo "Configuring Openbox menu..."
mv /etc/xdg/openbox/menu.xml /etc/xdg/openbox/menu.xml.old 2>/dev/null
cat > /etc/xdg/openbox/menu.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>

<openbox_menu xmlns="http://openbox.org/"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://openbox.org/
                file:///usr/share/openbox/menu.xsd">

<menu id="root-menu" label="Openbox 3">
  <item label="Web browser">
    <action name="Execute"><execute>x-www-browser</execute></action>
  </item>
  <separator />
  <item label="Exit">
    <action name="Exit" />
  </item>
</menu>

</openbox_menu>
EOF

echo "Script completed successfully."

reboot now
