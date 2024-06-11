#!/bin/bash

# Functions
generate_random_string() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 8
}

# Set some variables
USR="sandbox1"
PASS=$(openssl rand -base64 15 | tr -dc 'a-zA-Z0-9' | head -c 20)
NEW_HOSTNAME="sandbox-$(generate_random_string)"

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

# Schedule daily reboot at 02:00 AM
echo "Scheduling daily reboot at 02:00 AM..."
(crontab -l 2>/dev/null; echo "0 2 * * * /sbin/reboot") | crontab -

# Change the hostname
hostnamectl set-hostname "$NEW_HOSTNAME"

# Update /etc/hosts to reflect the new hostname
sed -i "s/127.0.1.1.*/127.0.1.1 $NEW_HOSTNAME/" /etc/hosts

echo "Script completed successfully."

reboot now
