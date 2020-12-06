#!/bin/bash
# Script: PlexAmp-install for Pi
# Purpose: Install PlexAmp on a Raspberry Pi.
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
# Then SSH to raspbian with user/pass: pi/raspberry
#
# Now change to root user with command "sudo -i".
# Copy over this script to the root folder and make executable, i.e. chmod +x setup-pi_Plexamp.sh
# Run with ./install_configure_Plexamp_pi.sh
#
# Revision update: 2020-12-06 ODIN
# 

#####
# Variable(s), updated if needed before execution of script.
#####
USER="pi"  # Name of user to create and run PlexAmp as.
TIMEZONE="America/Chicago"  # Default Timezone
PASSWORD="MySecretPass123"  # Default password
CNFFILE="/boot/config.txt"  # Default config file
HOST="plexamp"				      # Default hostname
playername="PlexAmp"				              			# Dummy placeholders for server.json-file
playerid="abcdefgh-ijkl-mnop-qrst-uvwxyzabcdef"	# Dummy placeholders for server.json-file
userid="1000000"								                # Dummy placeholders for server.json-file
usertoken="zyxwvutsrqponmlkjihg"				        # Dummy placeholders for server.json-file

#####
# prompt for updates to variables/values
#####
echo " "
echo --== For your information ==--
echo -e "$INFO This script is verifed on the "2020-08-20-raspios-buster-armhf-lite" image."
echo    "      It cannot be guaranteed to run on other version of the image without fixes."
echo    "      Installation assumes armv7l HW, and was testen on a Raspberry Pi 4 Model B."
echo    "      Installation also assumes a HiFiBerry HAT or one of its clones installed."
echo    "      If you do not have one, you can also dedicate audio to the HDMI port."
echo
echo " "
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
echo " "
fi
echo " "
echo -e "By default, installation will progress as user pi, unless you choose to create a new user."
echo " "
echo -n "Do you want to create a new user to use for the install [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
echo " "
read -e -p "User to create and install PlexAmp under (default is $USER): " -i "$USER" USER
echo " "
read -e -p "Password for user to create and install PlexAmp under (default is $PASSWORD): " -i "$PASSWORD" PASSWORD
PASSWORDCRYPTED=$(echo "$PASSWORD" | openssl passwd -6 -stdin)
fi
echo " "
echo Now it is time to choose Timezone, pick the number for the Timezone you want, exit with 5.
echo If your Timezone is not covered, additional timezones can be found here: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
echo " "
title="Select your Timezone:"
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
    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
    *) echo "Invalid option. Try another one."; continue;;
    esac
done
echo " "
read -e -p "Timezone to set on Pi (chosen Timezone is $TIMEZONE, change if needed): " -i "$TIMEZONE" TIMEZONE

#####
# start main script execution
#####
echo " "
echo --== Setting timezone ==--
timedatectl set-timezone $TIMEZONE
echo " "
echo --== Date of execution ==--
date
echo " "
echo --== Check OS version ==--
cat /etc/os-release
echo " "
echo --== Verify Hostname and OS ==--
hostnamectl
echo " "
echo --== Verify Partitioning ==--
lsblk
echo " "
echo --== Verify RAM ==--
free -m
echo " "
echo --== Verify CPUs ==--
lscpu
echo " "
echo --== Verify Audio HW ==--
aplay -l
echo " "
echo --== Setting NTP-servers ==--
sed -ri 's/^#NTP=*/NTP=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org/' /etc/systemd/timesyncd.conf
echo " "
echo --== Verify timezone-setup and NTP-sync ==--
timedatectl
echo " "
echo --== Install rpi-eeprom service ==--
apt-get install -y rpi-eeprom
echo " "
echo --== Run the rpi-eeprom-update to check if update is required ==--
rpi-eeprom-update
echo " "
echo --== Reading EEPROM version ==--
vcgencmd bootloader_version
echo " "
echo --== Checking the rpi-eeprom service ==--
systemctl status rpi-eeprom-update.service
echo " "
echo -n "Do you want to install and set vim as your default editor [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
echo " "
echo --== Install vim and change to default editor ==--
apt-get install -y vim
echo " "
update-alternatives --set editor /usr/bin/vim.basic
echo " "
fi
echo -n "Do you want to disable IPv6 [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
echo " "
echo --== Disable IPv6 ==--
if [ ! -f /etc/sysctl.d/disable-ipv6.conf ]; then
cat >> /etc/sysctl.d/disable-ipv6.conf << EOF
net.ipv6.conf.all.disable_ipv6 = 1
EOF
fi
fi
echo " "
if [ ! -d /home/$USER ]; then
echo --== Add user and enable sudo ==--
useradd -m -p $PASSWORDCRYPTED $USER
usermod -aG adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,netdev,spi,i2c,gpio $USER
usermod -aG audio $USER
usermod --shell /bin/bash $USER
passwd -d pi
echo " "
echo --== Disable default user "pi" from logging in ==--
usermod -s /sbin/nologin pi
passwd -d pi
fi
echo " "
echo --== Update motd ==--
if [ ! -f /etc/update-motd.d/20-logo ]; then
cat >> /etc/update-motd.d/20-logo << 'EOF'
#!/bin/sh

upSeconds="$(/usr/bin/cut -d. -f1 /proc/uptime)"
secs=$((${upSeconds}%60))
mins=$((${upSeconds}/60%60))
hours=$((${upSeconds}/3600%24))
days=$((${upSeconds}/86400))
UPTIME=`printf "%d days, %02dh%02dm%02ds" "$days" "$hours" "$mins" "$secs"`

# get the load averages
read one five fifteen rest < /proc/loadavg

echo "$(tput setaf 2)
   .~~.   .~~.    `date +"%A, %e %B %Y, %r"`
  '. \ ' ' / .'   `uname -srmo`$(tput setaf 1)
   .~ .~~~..~.
  : .~.'~'.~. :   Uptime.............: ${UPTIME}
 ~ (   ) (   ) ~  Memory.............: `cat /proc/meminfo | grep MemFree | awk {'print $2'}`kB (Free) / `cat /proc/meminfo | grep MemTotal | awk {'print $2'}`kB (Total)
( : '~'.~.'~' : ) Load Averages......: ${one}, ${five}, ${fifteen} (1, 5, 15 min)
 ~ .~ (   ) ~. ~  Running Processes..: `ps ax | wc -l | tr -d " "`
  (  : '~' :  )   IP Addresses.......: `ip a | grep glo | awk '{print $2}' | head -1 | cut -f1 -d/` and `wget -q -O - http://icanhazip.com/ | tail`
   '~ .~~~. ~'    Weather............: `curl -s "http://rss.accuweather.com/rss/liveweather_rss.asp?metric=1&locCode=EUR|UK|UK001|NAILSEA|" | sed -n '/Currently:/ s/.*: \(.*\): \([0-9]*\)\([CF]\).*/\2°\3, \1/p'`
       '~'
$(tput sgr0)"


echo    ""
echo    ""
echo    "   ██████╗ ██╗     ███████╗██╗  ██╗ █████╗ ███╗   ███╗██████╗"
echo    "   ██╔══██╗██║     ██╔════╝╚██╗██╔╝██╔══██╗████╗ ████║██╔══██╗"
echo    "   ██████╔╝██║     █████╗   ╚███╔╝ ███████║██╔████╔██║██████╔"
echo    "   ██╔═══╝ ██║     ██╔══╝   ██╔██╗ ██╔══██║██║╚██╔╝██║██╔═══╝"
echo    "   ██║     ███████╗███████╗██╔╝ ██╗██║  ██║██║ ╚═╝ ██║██║"
echo    "   ╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝"
echo    ""
echo    "   Plexamp-v2.0.0-rPi-beta.2"
echo " "
EOF
chmod +x /etc/update-motd.d/20-logo
fi
echo " "
echo --== Check WiFi-status and enable WiFi ==--
echo --== Before ==--
rfkill list all
rfkill unblock 0
echo " "
echo --== After ==--
rfkill list all
echo " "
echo --== Fix HiFiBerry setup ==--
echo -e "$INFO Configuring overlay for HifiBerry HATs:"
echo    "      If you own other audio HATs, or want to keep defaults - skip this step"
echo    "      you will have to manually configure your HAT later."
echo    "      If you want to change audio-output from Headphones to HDMI as default output,"
echo    "      skip this step, you get the option to configure that later."
echo " "
echo    "      Information about the HifiBerry cards can be found at https://www.hifiberry.com"
echo    "      Configuration for the HifiBerry cards can be found at https://www.hifiberry.com/docs/software/configuring-linux-3-18-x/"
echo
echo -n "Do you want to configure your HifiBerry HAT [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
echo " "
echo Now you need to choose your HiFiBerry card, pick the number for the card you have, exit with 5.
sed -i /hifiberry-/d /boot/config.txt
echo " " >> /boot/config.txt
grep -qxF '# --== Configuration for HiFi-Berry ==--' /boot/config.txt || echo '# --== Configuration for HiFi-Berry ==--' >> /boot/config.txt
echo " " >> /boot/config.txt
echo " "
title="Select your HiFiBerry card, exit with 5:"
prompt="Pick your option:"
options=("setup for DAC+ standard/pro" "setup for DAC/DAC+ Light" "setup for Digi/Digi+" "setup for Amp/Amp+")
echo "$title"
PS3="$prompt "
select opt in "${options[@]}" "Quit"; do
    case "$REPLY" in
    1 ) echo "You picked $opt, continue with 5 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-dacplus";;
    2 ) echo "You picked $opt, continue with 5 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-dac";;
    3 ) echo "You picked $opt, continue with 5 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-digi";;
    4 ) echo "You picked $opt, continue with 5 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-amp";;
    $(( ${#options[@]}+1 )) ) echo "Continuing!"; break;;
    *) echo "Invalid option. Try another one."; continue;;
    esac
done
echo " "
echo "$(cat $CNFFILE)$HIFIBERRY" > $CNFFILE
sed -i '/#dtparam=audio=on/!s/dtparam=audio=on/#&/' /boot/config.txt
sed -i 's/^[ \t]*//' /boot/config.txt # Remove empty spaces infront of line.
sed -i ':a; /^\n*$/{ s/\n//; N;  ba};' /boot/config.txt # Remove if two consecutive blank lines and replace with one in a file.
sed -i '/Berry/{N;s/\n$//}' /boot/config.txt # Remove blank line after match.
sed -i '${/^$/d}' /boot/config.txt # Remove last blank line in file.
fi
echo " "
echo --== Fix HDMI-audio setup ==--
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
sed -i '/#hdmi_drive=2/s/^# *//' /boot/config.txt
fi
echo " "
echo -n "Do you want to install and configure NodeJS9 and PlexAmp v2.0.0-rPi-beta.2 [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
echo " "
if [ ! -f /etc/apt/sources.list.d/nodesource.list ]; then
echo --== Install nodejs 9 ==--
apt-mark unhold nodejs
apt-get purge -y nodejs
curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
apt-get install -y nodejs=9.11.2-1nodesource1
apt-mark hold nodejs
fi
echo " "
echo --== Verify that nodejs 9 is set to hold ==--
apt-mark showhold
echo " "
echo --== Verify nodejs 9 versions, should be "v9.11.2" and "5.6.0"  ==--
node -v ; npm -v
echo " "
if [ ! -f  /home/$USER/Plexamp-v2.0.0-rPi-beta.2.tar.bz2 ]; then
echo --== Fetch, unpack and install "Plexamp-v2.0.0-rPi-beta.2" ==--
cd /home/$USER
wget https://files.plexapp.com/elan/Plexamp-v2.0.0-rPi-beta.2.tar.bz2
tar -xf Plexamp-v2.0.0-rPi-beta.2.tar.bz2
echo " "
fi
echo --== Fix plexamp.service ==--
cp /home/$USER/plexamp/plexamp.service /lib/systemd/system/plexamp.service
sed -i "s/pi/$USER/g" /lib/systemd/system/plexamp.service
systemctl daemon-reload
systemctl enable plexamp
echo " "
echo --== Fix path for server.json and create skeleton ==--
if [ ! -f /home/$USER/.config/Plexamp/server.json ]; then
mkdir -p /home/$USER/.config/Plexamp
cat >> /home/$USER/.config/Plexamp/server.json << EOF
{
  "player": {
    "name": "playername",
    "identifier": "playerid"
  },
  "user": {
    "id": userid,
    "token": "usertoken"
  },
 "logging": {
    "level": "warn"
  }
}
EOF
fi
echo " "
echo --== Manually fix PlexAmp server.json setup ==--
echo -e "$INFO Configuring server.json for PlexAmp:"
echo    "      If you do not want to configure the token maually - skip this step"
echo    "      You will need to copy the token manually to /home/$USER/.config/Plexamp/server.json"
echo    "      The token is located under: c:\Users\MyUser\AppData\Local\Plexamp\server.json on Windows"
echo    "      You can only extract it from a running installation of PlexAmp 1.1.0 for Windows."
echo    "      which can still be found at: https://plexamp.plex.tv/plexamp.plex.tv/Plexamp%20Setup%201.1.0.exe"
echo    " "
echo    "      The below placeholders will not work (except for Player Name), you need your own numbers from a working player!"
echo
echo -n "Do you want to configure server.json with your information [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
read -e -p "Player name: (default placeholder is $playername): " -i "$playername" playername
read -e -p "Player identifier: (default placeholder is $playerid): " -i "$playerid" playerid
read -e -p "User id: (default placeholder is $userid): " -i "$userid" userid
read -e -p "User token: (default placeholder is $usertoken): " -i "$usertoken" usertoken
echo " "
if [ "$playername" -a "$playerid" -a "$userid" -a "$usertoken" ]; then
  echo -e "$INFO Configuring Plexamp"
  systemctl stop plexamp
  sed -i "s/playername/$playername/" /home/$USER/.config/Plexamp/server.json
  sed -i "s/playerid/$playerid/" /home/$USER/.config/Plexamp/server.json
  sed -i "s/userid/$userid/" /home/$USER/.config/Plexamp/server.json
  sed -i "s/usertoken/$usertoken/" /home/$USER/.config/Plexamp/server.json
  sleep 5
  echo -e "$INFO Starting Plexamp"
  systemctl start plexamp.service
else
  echo -e "$ERROR At least one of the parameters were empty - Please try again"
  echo "       Call: `pwd`/`basename $0`"
fi
fi
fi
chown -R $USER:$USER /home/$USER
chmod 600 /home/$USER/.config/Plexamp/server.json
echo " "
echo -n "Do you want to run full OS-update? This is recommended [y/N]: "
read answer
answer=`echo "$answer" | tr '[:upper:]' '[:lower:]'`
if [ "$answer" = "y" ]; then
echo " "
echo --== Perform OS-update ==--
apt update --allow-releaseinfo-change
apt-get -y update ; apt-get -y upgrade ; apt-get -y dist-upgrade
apt-get -y install deborphan
apt-get clean ; apt-get autoclean ; apt-get autoremove ; deborphan | xargs apt-get -y remove --purge
fi
echo " "
echo --== Fix PlexAmp server.json setup ==--
echo -e "$INFO Please note!!! If you did not run the server.json setup:"
echo    "      To get working server, you need to:"
echo    "      Copy "server.json" to "/home/$USER/.config/Plexamp" folder."
echo    "      Optionally you can edit it with your custom values."
echo    "      This file can only be extracted from a running installation of PlexAmp 1.1.0 for Windows."
echo    "      The token is located under: c:\Users\MyUser\AppData\Local\Plexamp\server.json on Windows"
echo    "      Which can still be found at: https://plexamp.plex.tv/plexamp.plex.tv/Plexamp%20Setup%201.1.0.exe"
echo    "      then restart the PlexAmp service with command: systemctl restart plexamp"
echo    "      once done, you can cast to it from existing Plex/PlexAmp instances!"
echo    " "
echo    "      WARNING!!!			WARNING!!!			WARNiNG!!!"
echo    " "
echo    "      Please remember, you need to remove/delete the c:\Users\MyUser\AppData\Local\Plexamp folder from"
echo    "      your Windows installation, or you will get weird behaviour, and end up with a non-functioning PlexAmp"
echo    "      due to 2 or more clients using the same ID/tokens!"
echo    "      If the service (systemctl status plexamp) is not starting with error: code=exited, status=1/FAILURE,"
echo    "      it is most likely due to invalid configuration in /home/$USER/.config/Plexamp/server.json"
echo    "      Fix the server.json file, and restart the service (systemctl restart plexamp)."
echo
echo " "
echo --== For Linux 5.4 and higher ==--
echo -e "$INFO This not needed for the "PiFi HIFI DiGi+ Digital Sound Card" found at:"
echo    "      https://www.fasttech.com/p/5137000"
echo " "
echo    "      If correct overlay is configured, but the system still doesn’t load the driver,"
echo    "      disable the onboard EEPROM by adding: "force_eeprom_read=0" to "/boot/config.txt""
echo
echo " "
echo --==          End of Post-PlexAmp-script          ==--
echo --== Please reboot for all changes to take effect ==--
echo " "
# end
