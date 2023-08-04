#!/bin/bash
# Script: PlexAmp-install for Pi
# Purpose: Install PlexAmp on a Raspberry Pi.
# Make sure you have a 64-bit capable Raspberry Pi and Pi OS is 64-bit.
# Script will install node.v16 and set it on hold.
# Needs to be run as the root user.
#
# How to enable SSH on Raspberry Pi OS:
# For security reasons, as of the November 2016 release, Raspbian has the SSH server disabled by default.
# After burning the image to your Micro-SD-card (with etcher), you need to enable.
#
# To enable:
# 1. Mount your SD card on your computer.
# 2. Create or copy an empty file called ssh in /boot.
# on MacOS you can do: touch /Volumes/boot/ssh
#
#
# SSH access on "Raspberry Pi OS": (2022-04-04) To set up a user on first boot on headless, create a file called userconf or userconf.txt in
# the boot partition of the SD card. This file should contain a single line of text, consisting of username:encrypted-password –
# so your desired username, followed immediately by a colon, followed immediately by an encrypted representation of the password you want to use.
#
# To generate the encrypted password, the easiest way is to use OpenSSL on a Raspberry Pi that is already running (or most any linux you have running)
# – open a terminal window and enter: echo ‘mypassword’ | openssl passwd -6 -stdin
#
# This will produce what looks like a string of random characters, which is actually an encrypted version of the supplied password.
#
# Then SSH to raspbian with user/pass: pi/raspberry
#
# Now change to root user with command "sudo -i".
# Copy over this script to the root folder and make executable, i.e. chmod +x setup-pi_Plexamp.sh
# Run with ./install_configure_Plexamp_pi.sh
#
# Revision update: 2020-12-06 ODIN - Initial version.
# Revision update: 2020-12-16 ODIN - Added MacOS information for Plexamp V1.x.x and workarounds for DietPi.
# Revision update: 2022-05-04 ODIN - Changed to new version of Pi OS (64-bit), Plexamp V4.2.2. Not tested on DietPi.
# Revision update: 2022-05-07 ODIN - Fixed systemd user instance terminating at logout of user.
# Revision update: 2022-05-08 ODIN - Updated to using "Plexamp-Linux-arm64-v4.2.2-beta.3" and corrected service-file.
# Revision update: 2022-05-09 ODIN - Updated to using "Plexamp-Linux-arm64-v4.2.2-beta.5" and added update-function. Version still hardcoded.
# Revision update: 2022-05-09 ODIN - Updated to using "Plexamp-Linux-arm64-v4.2.2-beta.7". Version still hardcoded.
# Revision update: 2022-06-03 ODIN - Updated to using "Plexamp-Linux-arm64-v4.2.2". No more beta. Version still hardcoded.
# Revision update: 2022-08-01 ODIN - Added option for HifiBerry Digi2 Pro. Submitted by Andreas Diel (https://github.com/Dieler).
# Revision update: 2022-08-02 ODIN - Updated to using "Plexamp-Linux-headless-v4.3.0". No more beta. Version still hardcoded.
# Revision update: 2022-08-14 ODIN - Added workarounds for DietPi.
# Revision update: 2022-09-17 ODIN - Updated to using "Plexamp-Linux-headless-v4.4.0".
# Revision update: 2022-09-18 ODIN - Made Node.v12 optional to please non-Debian/RPI-users.
# Revision update: 2022-09-18 ODIN - changed user service to system service, and run process as limited user.
# Revision update: 2022-09-26 ODIN - Added option for allo Boss HIFI DAC and variants. Requested for by hvddrift (https://github.com/hvddrift).
# Revision update: 2022-10-20 ODIN - Updated to using "Plexamp-Linux-headless-v4.5.0".
# Revision update: 2022-10-30 ODIN - Updated to using "Plexamp-Linux-headless-v4.5.1".
# Revision update: 2022-10-30 ODIN - Updated to using "Plexamp-Linux-headless-v4.5.2".
# Revision update: 2022-11-08 ODIN - Fixed /etc/sudoers.d/010_pi-nopasswd for non-pi user.
# Revision update: 2022-11-12 ODIN - Updated to using "Plexamp-Linux-headless-v4.5.3 and upgrading to NodeJS v16".
# Revision update: 2022-11-13 ODIN - Improved logic for installing NodeJS v16 to only if needed.
# Revision update: 2022-11-12 ODIN - Updated to using "Plexamp-Linux-headless-v4.6.0.
# Revision update: 2022-12-05 ODIN - Updated to using "Plexamp-Linux-headless-v4.6.1.
# Revision update: 2022-12-27 ODIN - Updated to remove hardcoded version, should now install latest.
# Revision update: 2023-02-03 ODIN - Update to remove hardcoded version did not work, now using v4.6.2.
# Revision update: 2023-02-28 ODIN - Fix HDMI-audio setup with change to "dtoverlay" to enable HDMI-alsa device.
# Revision update: 2023-05-03 ODIN - Updated to using "Plexamp-Linux-headless-v4.7.0. If your card is not detected after boot (no audio) ("aplay -l" to check),
# please do hard reboot, and re-select the card! Now there should be audio!
# Revision update: 2023-05-05 ODIN - Updated to using "Plexamp-Linux-headless-v4.7.1.
# Revision update: 2023-05-05 ODIN - Updated to using "Plexamp-Linux-headless-v4.7.2.
# Revision update: 2023-05-10 ODIN - Updated to using "Plexamp-Linux-headless-v4.7.3.
# Revision update: 2023-05-10 ODIN - Updated to using "Plexamp-Linux-headless-v4.7.4.
# Revision update: 2023-07-18 ODIN - Updated to using "Plexamp-Linux-headless-v4.8.0.
# Revision update: 2023-07-23 ODIN - Updated to using "Plexamp-Linux-headless-v4.8.1.
# Revision update: 2023-08-04 ODIN - Updated to using "Plexamp-Linux-headless-v4.8.2.
#
#


#####
# Variable(s), update if needed before execution of script.
#####

if [ -d /home/dietpi ]; then # Name of user to create and run PlexAmp as.
USER="dietpi"
else
USER="pi"
fi
TIMEZONE="America/Chicago"                      # Default Timezone
PASSWORD="MySecretPass123"                      # Default password
CNFFILE="/boot/config.txt"                      # Default config file
HOST="plexamp"                                  # Default hostname
SPACES="   "                                    # Default spaces
PLEXAMPV="Plexamp-Linux-headless-v4.8.2"        # Default Plexamp-version


#####
# prompt for updates to variables/values
#####
echo " "
echo "--== For your information ==--"
echo -e "$INFO This script is verifed on the following image(s):"
echo    "      2022-09-22-raspios-bullseye-arm64-lite"
echo " "
echo    "      NOTE!!!! Raspberry Pi OS 64-bit version is assumed."
echo " "
echo    "      It cannot be guaranteed to run on other version of the image without fixes."
echo    "      Installation assumes ARMv8, 64-bit HW, and was testen on a Raspberry Pi 4 Model B."
echo    "      Installation also assumes a HiFiBerry HAT or one of its clones installed."
echo    "      If you do not have one, you can also dedicate audio to the HDMI port."
echo    "      DietPi is best effort, and was last tested on 20220814."
echo " "
echo " "
echo "--== Starting Installation ==--"
echo -n "Do you want to change hostname [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
echo " "
echo    "      To change hostname a second time, please reboot first!"
echo " "
read -e -p "Hostname for your Raspberry Pi (default is $HOST): " -i "$HOST" HOST
sed -i "s/$HOSTNAME/$HOST/g" /etc/hostname
sed -i "s/$HOSTNAME/$HOST/g" /etc/hosts
if [ -f /boot/dietpi.txt ]; then
sed -i "s/AUTO_SETUP_NET_HOSTNAME=.*/AUTO_SETUP_NET_HOSTNAME=$HOST/g" /boot/dietpi.txt
fi
fi
echo " "
echo -e "By default, installation will progress as user $USER, unless you choose to create/change to a diferent user."
echo " "
echo -n "Do you want to create or change to a new or different user for the install (currently "$USER") [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
echo " "
read -e -p "User to create/use and install PlexAmp under (default is $USER): " -i "$USER" USER
echo " "
read -e -p "Password for user to create and install PlexAmp under (will not change if user already exist): " -i "$PASSWORD" PASSWORD
PASSWORDCRYPTED=$(echo "$PASSWORD" | openssl passwd -6 -stdin)
fi
if [ ! -f /boot/dietpi.txt ]; then
echo "Now it is time to choose Timezone, pick the number for the Timezone you want, exit with 5."
echo "If your Timezone is not covered, additional timezones can be found here: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
echo " "
title="Select your Timezone (just hit "5" if you want to continue without change):"
prompt="Pick your option:"
options=("Eastern time zone: America/New_York" "Central time zone: America/Chicago" "Mountain time zone: America/Denver" "Pacific time zone: America/Los_Angeles")
echo "$title"
PS3="$prompt "
select opt in "${options[@]}" "Quit"; do
    case "$REPLY" in
    1 ) echo "You picked $opt, continue with 5 or choose again!"; TIMEZONE="America/New_York";;
    2 ) echo "You picked $opt, continue with 5 or choose again!"; TIMEZONE="America/Chicago";;
    3 ) echo "You picked $opt, continue with 5 or choose again!"; TIMEZONE="America/Denver";;
    4 ) echo "You picked $opt, continue with 5 or choose again!"; TIMEZONE="America/Los_Angeles";;
    $(( ${#options[@]}+1 )) ) echo "Continuing!"; break;;
    *) echo "Invalid option. Try another one."; continue;;
    esac
done
echo " "
read -e -p "Timezone to set on Pi (chosen Timezone is $TIMEZONE, change if needed): " -i "$TIMEZONE" TIMEZONE
fi

#####
# start main script execution
#####
echo " "
if [ ! -f /boot/dietpi.txt ]; then
echo "--== Setting timezone ==--"
timedatectl set-timezone "$TIMEZONE"
fi
echo " "
echo "--== Date of execution ==--"
date
echo " "
echo "--== Check OS version ==--"
cat /etc/os-release
if [ ! -f /boot/dietpi.txt ]; then
echo " "
echo "--== Verify Hostname and OS ==--"
hostnamectl
else
echo "--== Verify Hostname ==--"
cat /etc/hostname
fi
if [ -f /boot/dietpi.txt ]; then
echo " "
echo "--== Check DietPi version ==--"
cat /boot/dietpi/.version
fi
echo " "
echo "--== Verify Partitioning ==--"
lsblk
echo " "
echo "--== Verify RAM ==--"
free -m
echo " "
echo "--== Verify CPUs ==--"
lscpu
echo " "
if [ -f /boot/dietpi.txt ]; then
echo "--== Verify alsa-utils installed ==--"
apt-get -y install alsa-utils > /dev/null 2>&1
echo " "
fi
echo "--== Verify Audio HW, list all soundcards and digital audio devices ==--"
cat /proc/asound/cards
echo " "
echo "--== Verify Audio HW, list all PCMs defined ==--"
aplay -L
echo " "
if [ ! -f /boot/dietpi.txt ]; then
echo "--== Setting NTP-servers ==--"
sed -ri 's/^#NTP=*/NTP=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org/' /etc/systemd/timesyncd.conf
echo " "
echo "--== Verify timezone-setup and NTP-sync ==--"
timedatectl
echo " "
fi
echo "--== Install/upgrade rpi-eeprom service ==--"
apt-get install -y rpi-eeprom > /dev/null 2>&1
echo " "
echo "--== Run the rpi-eeprom-update to check if update is required ==--"
rpi-eeprom-update
echo " "
echo "--== Reading EEPROM version ==--"
vcgencmd bootloader_version
echo " "
echo "--== Checking the rpi-eeprom service ==--"
systemctl status rpi-eeprom-update.service --no-pager -l
echo " "
echo -n "Do you want to install and set vim as your default editor [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
echo " "
echo "--== Install vim and change to default editor ==--"
apt-get install -y vim > /dev/null 2>&1
update-alternatives --set editor /usr/bin/vim.basic
fi
echo " "
if [ ! -f /boot/dietpi.txt ]; then
echo -n "Do you want to disable IPv6 [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
echo " "
echo "--== Disable IPv6 ==--"
if [ ! -f /etc/sysctl.d/disable-ipv6.conf ]; then
cat >> /etc/sysctl.d/disable-ipv6.conf << EOF
net.ipv6.conf.all.disable_ipv6 = 1
EOF
fi
fi
fi
if [ ! -d /home/"$USER" ]; then
echo " "
echo "--== Add user and enable sudo ==--"
useradd -m -p "$PASSWORDCRYPTED" "$USER"
usermod --shell /bin/bash "$USER" > /dev/null 2>&1
usermod -aG adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,render,netdev,lpadmin,spi,i2c,gpio "$USER"
if [ -d /home/pi ]; then
echo " "
echo "--== Disable default user "pi" from logging in ==--"
usermod -s /sbin/nologin pi
passwd -d pi
fi
fi
echo " "
echo "--== Set user-groups and enable sudo ==--"
if [ ! -f /boot/dietpi.txt ]; then
usermod -aG adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,render,netdev,lpadmin,spi,i2c,gpio "$USER"
fi
if [ ! -f /boot/dietpi.txt ]; then
grep -qxF $USER' ALL=(ALL) NOPASSWD: ALL' /etc/sudoers.d/010_pi-nopasswd || echo $USER' ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/010_pi-nopasswd
fi
if [ -f /boot/dietpi.txt ]; then
usermod -aG adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,render,netdev,spi,i2c,gpio "$USER"
fi
echo " "
echo "--== Update motd ==--"
if [ ! -f /etc/update-motd.d/20-logo ]; then
cat >> /etc/update-motd.d/20-logo << 'EOF'
#!/bin/sh
echo    ""
echo    ""
echo    "   ██████╗ ██╗     ███████╗██╗  ██╗ █████╗ ███╗   ███╗██████╗"
echo    "   ██╔══██╗██║     ██╔════╝╚██╗██╔╝██╔══██╗████╗ ████║██╔══██╗"
echo    "   ██████╔╝██║     █████╗   ╚███╔╝ ███████║██╔████╔██║██████╔"
echo    "   ██╔═══╝ ██║     ██╔══╝   ██╔██╗ ██╔══██║██║╚██╔╝██║██╔═══╝"
echo    "   ██║     ███████╗███████╗██╔╝ ██╗██║  ██║██║ ╚═╝ ██║██║"
echo    "   ╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝"
echo    ""
echo    "   Plexamp-Linux-headless-v4.8.2"
echo " "
EOF
sed -i "s#Plexamp-Linux-.*#"$PLEXAMPV\""#g" /etc/update-motd.d/20-logo
chmod +x /etc/update-motd.d/20-logo
fi
echo " "
if [ ! -f /boot/dietpi.txt ]; then
echo "--== Check WiFi-status and enable WiFi ==--"
echo " "
echo "--== Before ==--"
rfkill list all
rfkill unblock 0
echo " "
echo "--== After ==--"
rfkill list all
echo " "
fi
echo "--== Fix HiFiBerry setup ==--"
echo -e "$INFO Configuring overlay for HifiBerry HATs (or clones):"
echo    "      If you own other audio HATs, or want to keep defaults - skip this step"
echo    "      you will have to manually configure your HAT later."
echo    "      If you want to change audio-output from Headphones to HDMI as default output,"
echo    "      skip this step, you get the option to configure that later."
echo " "
echo    "      Information about the HifiBerry cards can be found at https://www.hifiberry.com"
echo    "      Configuration for the HifiBerry cards can be found at https://www.hifiberry.com/docs/software/configuring-linux-3-18-x/"
echo
echo -n "Do you want to configure your HifiBerry HAT (or clone) [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
echo " "
echo "Now you need to choose your HiFiBerry card, pick the number for the card you have, exit with 6."
sed -i /hifiberry-/d /boot/config.txt # Remove existing hiFiBerry config.
echo " " >> /boot/config.txt
grep -qxF '# --== Configuration for DIGI-DAC ==--' /boot/config.txt || echo '# --== Configuration for DIGI-DAC ==--' >> /boot/config.txt
echo " " >> /boot/config.txt
echo " "
title="Select your HiFiBerry card, exit with 6:"
prompt="Pick your option:"
options=("setup for DAC+ standard/pro" "setup for DAC/DAC+ Light" "setup for Digi/Digi+" "setup for Digi2 Pro" "setup for Amp/Amp+")
echo "$title"
PS3="$prompt "
select opt in "${options[@]}" "Quit"; do
    case "$REPLY" in
    1 ) echo "You picked $opt, continue with 6 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-dacplus";;
    2 ) echo "You picked $opt, continue with 6 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-dac";;
    3 ) echo "You picked $opt, continue with 6 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-digi";;
    4 ) echo "You picked $opt, continue with 6 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-digi-pro";;
    5 ) echo "You picked $opt, continue with 6 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-amp";;
    $(( ${#options[@]}+1 )) ) echo "Continuing!"; break;;
    *) echo "Invalid option. Try another one."; continue;;
    esac
done
sed -i '/dtoverlay=hifiberry/d' /boot/config.txt # Remove old configuration.
sed -i '/dtoverlay=allo/d' /boot/config.txt # Remove old configuration.
echo "$(cat $CNFFILE)$HIFIBERRY" > $CNFFILE
if [ ! -f /boot/dietpi.txt ]; then
sed -i '/#dtparam=audio=on/!s/dtparam=audio=on/#&/' /boot/config.txt # Add hashtag, disable internal audio/headphones.
fi
sed -i 's/^[ \t]*//' /boot/config.txt # Remove empty spaces infront of line.
sed -i ':a; /^\n*$/{ s/\n//; N;  ba};' /boot/config.txt # Remove if two consecutive blank lines and replace with one in a file.
sed -i '/DIGI/{N;s/\n$//}' /boot/config.txt # Remove blank line after match.
sed -i '${/^$/d}' /boot/config.txt # Remove last blank line in file.
echo " "
fi
echo "--== Fix allo setup ==--"
echo -e "$INFO Configuring overlay for allo HATs (or clones):"
echo    "      If you own other audio HATs, or want to keep defaults - skip this step"
echo    "      you will have to manually configure your HAT later."
echo    "      If you want to change audio-output from Headphones to HDMI as default output,"
echo    "      skip this step, you get the option to configure that later."
echo " "
echo    "      Information about the allo cards can be found at https://allo.com/sparky-dac.html"
echo    "      Configuration for the allo cards can be found at https://www.amazon.com/clouddrive/share/vLk3XO9HOt3sStRUBpf4jwaX7k6J0Im91vo4z2FWVPV"
echo " "
echo -n "Do you want to configure your allo HAT (or clone) [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
echo " "
echo "Now you need to choose your allo card, pick the number for the card you have, exit with 5."
sed -i /allo-/d /boot/config.txt # Remove existing allo config.
echo " " >> /boot/config.txt
grep -qxF '# --== Configuration for DIGI-DAC ==--' /boot/config.txt || echo '# --== Configuration for DIGI-DAC ==--' >> /boot/config.txt
echo " " >> /boot/config.txt
echo " "
title="Select your allo card, exit with 5:"
prompt="Pick your option:"
options=("setup for ALLO Piano HIFI DAC" "setup for ALLO Piano 2.1 HIFI DAC" "setup for ALLO Boss HIFI DAC / Mini Boss HIFI DAC" "setup for ALLO DIGIOne")
echo "$title"
PS3="$prompt "
select opt in "${options[@]}" "Quit"; do
    case "$REPLY" in
    1 ) echo "You picked $opt, continue with 5 or choose again!"; DIGICARD="dtoverlay=allo-piano-dac-pcm512x-audio";;
    2 ) echo "You picked $opt, continue with 5 or choose again!"; DIGICARD="dtoverlay=allo-piano-dac-plus-pcm512x-audio";;
    3 ) echo "You picked $opt, continue with 5 or choose again!"; DIGICARD="dtoverlay=allo-boss-dac-pcm512x-audio";;
    4 ) echo "You picked $opt, continue with 5 or choose again!"; DIGICARD="dtoverlay=allo-digione";;
    $(( ${#options[@]}+1 )) ) echo "Continuing!"; break;;
    *) echo "Invalid option. Try another one."; continue;;
    esac
done
sed -i '/dtoverlay=hifiberry/d' /boot/config.txt # Remove old configuration.
sed -i '/dtoverlay=allo/d' /boot/config.txt # Remove old configuration.
echo "$(cat $CNFFILE)$DIGICARD" > $CNFFILE
if [ ! -f /boot/dietpi.txt ]; then
sed -i '/#dtparam=audio=on/!s/dtparam=audio=on/#&/' /boot/config.txt # Add hashtag, disable internal audio/headphones.
fi
sed -i 's/^[ \t]*//' /boot/config.txt # Remove empty spaces infront of line.
sed -i ':a; /^\n*$/{ s/\n//; N;  ba};' /boot/config.txt # Remove if two consecutive blank lines and replace with one in a file.
sed -i '/DIGI/{N;s/\n$//}' /boot/config.txt # Remove blank line after match.
sed -i '${/^$/d}' /boot/config.txt # Remove last blank line in file.
echo " "
fi
echo " "
echo "--== Fix HDMI-audio setup ==--"
echo -e "$INFO Configuring HDMI for Audio:"
echo    "      If you do not have an audio-HAT, you might want to set HDMI as default for audio."
echo    " "
echo    "      WARNING!!!     WARNING!!!      WARNiNG!!!"
echo    " "
echo    "      Please only run this if you did not run the HiFiBerry HAT setup above,"
echo    "      and are sure you want to change from Headphones to HDMI for audio out!"
echo
echo -n "Do you want to configure HDMI as default audio-output [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
sed -i '/#hdmi_drive=2/s/^# *//' /boot/config.txt # Remove hashtag.
sed -i 's/vc4-kms-v3d/vc4-fkms-v3d/g' /boot/config.txt # Change dtoverlay to enable HDMI-alsa device.
fi
echo " "
echo "--== Cleanup for upgrade ==--"
echo -n "Do you want to prep for upgrade to new version "$PLEXAMPV", only run if you are upgrading [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
ps ax |grep index.js |grep -v grep |awk '{print $1}' |xargs kill
rm -rf /home/"$USER"/plexamp/
rm -rf /home/"$USER"/Plexamp-Linux-*
rm -rf /home/"$USER"/.config/systemd/user/plexamp.service
fi
echo " "
echo "--== Install or upgrade ==--"
echo " "
echo "--== If upgrading to Plexamp 4.5.3 or later, you have to re-run the NodeJS install to upgrade to Node.v16 at least once! ==--"
echo " "
echo -n "Do you want to install/upgrade and configure Node.v16? Needed on Plexamp 4.5.3 install/upgrade or later! [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
if ! grep -q node_16.x "/etc/apt/sources.list.d/nodesource.list"; then
echo " "
echo "--== Install node.v16 ==--"
apt-mark unhold nodejs > /dev/null 2>&1
apt-get purge -y nodejs > /dev/null 2>&1
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
apt-get install -y nodejs=16.*-1nodesource1
apt-mark hold nodejs
fi
echo " "
echo "--== Verify that node.v16 is set to hold ==--"
apt-mark showhold
echo " "
echo "--== Verify node.v16 and npm versions, should be "v16.20.*" and "8.19.*"  ==--"
node -v ; npm -v
fi
echo " "
echo -n "Do you want to install and configure "$PLEXAMPV" [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then

if [ ! -f /home/"$USER"/plexamp/plexamp.service ]; then
echo " "
echo "--== Fetch, unpack and install "$PLEXAMPV" ==--"
cd /home/"$USER"
wget https://plexamp.plex.tv/headless/"$PLEXAMPV".tar.bz2
chown -R "$USER":"$USER" /home/"$USER"/"$PLEXAMPV".tar.bz2
tar -xf "$PLEXAMPV".tar.bz2
mkdir -p /home/"$USER"/.local/share/Plexamp/Offline
chown -R "$USER":"$USER" /home/"$USER"/plexamp/
chown -R "$USER":"$USER" /home/"$USER"/.local/share/Plexamp/
sed -i "s#Plexamp-Linux-.*#"$PLEXAMPV\""#g" /etc/update-motd.d/20-logo
fi
echo "--== Fix plexamp.service ==--"
if [ ! -f /boot/dietpi.txt ]; then
sed -i "s/User=pi/User="$USER"/g" /home/"$USER"/plexamp/plexamp.service
sed -i "s#WorkingDirectory=/home/pi/plexamp#WorkingDirectory=/home/"$USER"/plexamp#g" /home/"$USER"/plexamp/plexamp.service
sed -i "s#/home/pi/plexamp/js/index.js#/home/"$USER"/plexamp/js/index.js#g" /home/"$USER"/plexamp/plexamp.service
chown -R "$USER":"$USER" /home/"$USER"/.config/
systemctl daemon-reload
if [ ! -f /etc/systemd/system/plexamp.service ]; then
ln -s /home/"$USER"/plexamp/plexamp.service /etc/systemd/system/plexamp.service
fi
fi
if [ -f /boot/dietpi.txt ]; then
sed -i "s/User=pi/User=dietpi/g" /home/dietpi/plexamp/plexamp.service
sed -i "s#WorkingDirectory=/home/pi/plexamp#WorkingDirectory=/home/dietpi/plexamp#g" /home/dietpi/plexamp/plexamp.service
sed -i "s#/home/pi/plexamp/js/index.js#/home/dietpi/plexamp/js/index.js#g" /home/dietpi/plexamp/plexamp.service
sed -i '/^Restart*/a Group=dietpi' /home/dietpi/plexamp/plexamp.service
systemctl daemon-reload
if [ ! -f /etc/systemd/system/plexamp.service ]; then
ln -s /home/dietpi/.config/systemd/user/plexamp.service /etc/systemd/system/plexamp.service
systemctl daemon-reload
fi
fi
fi
echo " "
echo "--== OS-update including Node.v16 ==--"
echo -n "Do you want to run full OS-update? This is recommended [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
echo " "
echo "--== Perform OS-update including Node.v16 ==--"
apt update --allow-releaseinfo-change
apt-mark unhold nodejs > /dev/null 2>&1
apt-get -y upgrade nodejs > /dev/null 2>&1
apt-mark hold nodejs > /dev/null 2>&1
apt-get -y update ; apt-get -y upgrade ; apt-get -y dist-upgrade
apt-get -y install deborphan > /dev/null 2>&1
apt-get clean ; apt-get autoclean ; apt-get autoremove -y ; deborphan | xargs apt-get -y remove --purge
fi
echo " "
echo "--== For Linux 5.4 and higher ==--"
echo -e "$INFO This not needed for the "PiFi HIFI DiGi+ Digital Sound Card" found at:"
echo    "      https://www.fasttech.com/p/5137000"
echo " "
echo    "      If correct overlay is configured, but the system still doesn’t load the driver,"
echo    "      disable the onboard EEPROM by adding: 'force_eeprom_read=0' to '/boot/config.txt'"
echo " "
echo "--== End of Post-PlexAmp-script, please reboot for all changes to take effect ==--"
echo " "
echo -e "$INFO Configuration post-reboot:"
echo    "      Note !! Only needed if fresh install, not if upgrading. Tokens are preserved during upgrade."
echo    "      After reboot, as your regular user please run the command: node /home/"$USER"/plexamp/js/index.js"
echo    "      now, go to the URL provided in response, and enter the claim token at prompt."
echo    "      Please give the player a name at prompt (can be changed via Web-GUI later)."
echo    "      At this point, Plexamp is now signed in and ready, but not running!"
echo    " "
echo    "      Now either start Plexamp manually using: node /home/"$USER"/plexamp/js/index.js"
echo    "      or enable the service and then start the Plexamp service."
echo    "      If process is running, hit ctrl+c to stop process, then enter:"
echo    "      sudo systemctl enable plexamp.service && sudo systemctl start plexamp.service"
echo    " "
echo    "      Once done, the web-GUI should be available on the ip-of-plexamp-pi:32500 from a browser."
echo    "      On that GUI you will be asked to login to your Plex-account for security-reasons,"
echo    "      and then choose a librabry where to fetch/stream music from."
echo    "      Now play some music! Or control it from any other instance of Plexamp."
echo " "
echo    "      NOTE!! If you upgraded, only reboot is needed, tokens are preserved."
echo    "      One can verify the service with: sudo systemctl status plexamp.service"
echo    "      All should work at this point."
echo " "
echo    "      Logs are located at: ~/.cache/Plexamp/log/Plexamp.log"
echo " "
# end
