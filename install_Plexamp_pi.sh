#!/bin/bash
# Script: PlexAmp-install for Pi
# Purpose: Install PlexAmp on a Raspberry Pi as a user-level service.
# Make sure you have a 64-bit capable Raspberry Pi and Pi OS is 64-bit.
# Script will install node.v20 and set it on hold.
# Needs to be run as the root user.
#
# For more info:
# https://github.com/odinb/bash-plexamp-installer
#
# Revision update: 2020-12-06 ODIN - Initial version.
# Revision update: 2020-12-16 ODIN - Added MacOS information for Plexamp V1.x.x and workarounds for DietPi.
# Revision update: 2022-05-04 ODIN - Changed to new version of Pi OS (64-bit), Plexamp V4.2.2. Not tested on DietPi.
# Revision update: 2022-05-07 ODIN - Fixed systemd user instance terminating at logout of user.
# Revision update: 2022-05-08 ODIN - Updated to using "Plexamp-Linux-arm64-v4.2.2-beta.3" and corrected service-file.
# Revision update: 2022-05-09 ODIN - Updated to using "Plexamp-Linux-arm64-v4.2.2-beta.5" and added update-function. Version still hardcoded.
# Revision update: 2022-08-01 ODIN - Added option for HifiBerry Digi2 Pro. Requested by Andreas Diel (https://github.com/Dieler).
# Revision update: 2022-08-14 ODIN - Added workarounds for DietPi.
# Revision update: 2022-09-18 ODIN - Made Node.v12 optional to please non-Debian/RPI-users.
# Revision update: 2022-09-18 ODIN - Changed user service to system service, and run process as limited user.
# Revision update: 2022-09-26 ODIN - Added option for allo Boss HIFI DAC and variants. Requested by hvddrift (https://github.com/hvddrift).
# Revision update: 2022-11-08 ODIN - Fixed /etc/sudoers.d/010_pi-nopasswd for non-pi user.
# Revision update: 2022-11-12 ODIN - Updated to using "Plexamp-Linux-headless-v4.5.3 and upgrading to NodeJS v16".
# Revision update: 2022-11-13 ODIN - Improved logic for installing NodeJS v16 to only if needed.
# Revision update: 2022-12-27 ODIN - Updated to remove hardcoded version, should now install latest.
# Revision update: 2023-02-03 ODIN - Update to remove hardcoded version did not work, now using v4.6.2.
# Revision update: 2023-02-28 ODIN - Fix HDMI-audio setup with change to "dtoverlay" to enable HDMI-alsa device.
# Revision update: 2023-05-03 ODIN - Updated to using "Plexamp-Linux-headless-v4.7.0. If your card is not detected after boot (no audio) ("aplay -l" to check),
#                                    please do hard reboot, and re-select the card! Now there should be audio!
# Revision update: 2023-08-04 ODIN - Updated to using "Plexamp-Linux-headless-v4.8.2, and added Timezone setting as optional.
# Revision update: 2023-09-05 ODIN - Updated prompts to correspond better with the HifiBerry Config page.
# Revision update: 2023-09-08 ODIN - Added more TimeZones.
# Revision update: 2023-09-12 ODIN - Updated NodeJS-16 repo to use "https://github.com/nodesource". Removed legacy path ".config" on generic install, fixing dietpi.
# Revision update: 2023-10-08 ODIN - Improvements to installer and variable-handling. Various cosmetic fixes.
# Revision update: 2023-10-08 ODIN - Improvements to motd-manipulation.
# Revision update: 2023-10-10 ODIN - Added SnapJack installation to enable multi-room / multi-device streaming. Added other improvements to script.
# Revision update: 2023-10-15 ODIN - Verified not working on Debian version: 12 (bookworm). HAT-cards are not detected. Added other improvements to script.
# Revision update: 2023-10-17 ODIN - Added version info at start of script execution. Version no longer hard-coded.
# Revision update: 2023-10-18 ODIN - Fixed bookworm setup of /boot/config.txt.  Removed SnapJack untill officially released.
# Revision update: 2023-11-24 ODIN - Replaced apt-get with apt. Added nala if running bookworm.
# Revision update: 2023-12-06 ODIN - Minor cleanup of menus and README.
# Revision update: 2023-12-22 ODIN - Added option for 9038Q2M-based audiophonics cards. Requested by newelement (https://github.com/newelement)
# Revision update: 2023-12-28 ODIN - Added option for Allo Boss 2 DAC card. Requested by John-Pienaar (https://github.com/john-pienaar)
# Revision update: 2023-12-31 ODIN - Added option for JustBoom DAC/DIGI cards. Suggested by Ryuzaki_2 (https://forums.plex.tv/u/Ryuzaki_2)
# Revision update: 2024-03-16 ODIN - Updated to using "Plexamp-Linux-headless-v4.10.0 and upgrading to NodeJS v20".
# Revision update: 2024-06-14 ODIN - Fixed Bookworm setup to use /boot/firmware/config.txt dropping support for Bullseye.
# More info here: https://www.raspberrypi.com/documentation/computers/config_txt.html Commit contributed by ItsVRK (https://github.com/ItsVRK)
# Revision update: 2024-09-24 ODIN - Updated to "dtoverlay=vc4-kms-v3d" due to deprecation of "fkms" after input (issue #29) from bhcompy (https://github.com/bhcompy).
# Revision update: 2024-10-06 ODIN - Added workarounds for DietPi for /boot/config.txt.
# Revision update: 2025-04-18 ODIN - Added update for new wifi setting to fix "Wi-Fi is currently blocked by rfkill".
# Revision update: 2025-05-09 ODIN - Modified to run Plexamp as a user-level service with DAC access, and automatically enable plexamp user-service. Added WiFi Country Code Setup.
# Revision update: 2025-05-09 ODIN - Modified to detect DietPi and use a system-level service instead of a user-level service, as system services are more reliable in DietPi’s minimal environment.

#####
# Dependencies, needed before execution of script.
#####
echo "--== Install/upgrade jq which is needed to execute commands related to JSON data processing ==--"
apt install -y jq > /dev/null 2>&1

#####
# Variable(s), update if needed before execution of script.
#####
if [ -d /home/dietpi ]; then
    USER="dietpi"
else
    USER=$(logname)
fi
OS_VERSION=$(lsb_release -sr)
TIMEZONE="America/Chicago"
PASSWORD="MySecretPass123"
CNFFILE="/boot/firmware/config.txt"
HOST="plexamp"
SPACES="   "
NODE_MAJOR="20"
PLEXAMPV=$(curl -s "https://plexamp.plex.tv/headless/version.json" | jq -r '.updateUrl' || (>&2 echo "Unable to extract download URL for PlexAmp"; exit 1))
PLEXAMPVA=${PLEXAMPV/.tar.bz2}
PLEXAMPVB=${PLEXAMPVA/https:\/\/plexamp.plex.tv\/headless\/}

#####
# Banner introduction.
#####
echo " "
echo "   ██████╗ ██╗     ███████╗██╗  ██╗ █████╗ ███╗   ███╗██████╗"
echo "   ██╔══██╗██║     ██╔════╝╚██╗██╔╝██╔══██╗████╗ ████║██╔══██╗"
echo "   ██████╔╝██║     █████╗   ╚███╔╝ ███████║██╔████╔██║██████╔"
echo "   ██╔═══╝ ██║     ██╔══╝   ██╔██╗ ██╔══██║██║╚██╔╝██║██╔═══╝"
echo "   ██║     ███████╗███████╗██╔╝ ██╗██║  ██║██║ ╚═╝ ██║██║"
echo "   ╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝"
echo ""
echo " This will install or upgrade to:"
echo " $PLEXAMPVB"
echo " "
echo "--== Preparing to start script execution ==--"

#####
# Prompt for updates to variables/values
#####
echo " "
echo "--== For your information ==--"
echo -e "$INFO This script is verified on the following image(s):"
echo "      2025-04-18-Debian GNU/Linux 12 (bookworm) - working."
echo " "
echo "      NOTE!!!! Raspberry Pi OS 64-bit lite version is assumed."
echo " "
echo "      It cannot be guaranteed to run on other version of the image without fixes."
echo "      Installation assumes ARMv8, 64-bit HW, and was tested on a Raspberry Pi 4 Model B."
echo "      Installation also assumes a HiFiBerry HAT or one of its clones installed."
echo "      If you do not have one, you can also dedicate audio to the HDMI port."
echo "      DietPi is best effort, and was last tested on 2025-04-18 on DietPi v9.12.1."
echo " "
echo "--== Starting Installation ==--"
echo " "
echo -n "Do you want to change hostname [y/N]: "
read answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    echo " "
    echo "      To change hostname a second time, please reboot first!"
    echo " "
    read -e -p "Hostname for your Raspberry Pi (default is $HOST): " -i "$HOST" HOST
    sed -i "s/$HOSTNAME/$HOST/g" /etc/hostname
    sed -i "s/$HOSTNAME/$HOST/g" /etc/hosts
    if [ -f /boot/dietpi.txt ]; then
        sed -i "s/AUTO_SETUP_NET_HOSTNAME=.*/AUTO_SETUP_NET_HOSTNAME=$HOST/g" /boot/dietpi.txt
    fi
fi
echo " "
echo -e "By default, installation will progress as user "$USER", unless you choose to create/change to a different user."
echo " "
echo -n "Do you want to create or change to a new or different user for the install (currently "$USER") [y/N]: "
read answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    echo " "
    read -e -p "User to create/use and install PlexAmp under (default is $USER): " -i "$USER" USER
    echo " "
    read -e -p "Password for user to create and install PlexAmp under (will not change if user already exist): " -i "$PASSWORD" PASSWORD
    PASSWORDCRYPTED=$(echo "$PASSWORD" | openssl passwd -6 -stdin)
fi
if [ ! -f /boot/dietpi.txt ]; then
    echo " "
    echo "Now it is time to choose Timezone, pick the number for the Timezone you want."
    echo "If your Timezone is not covered, additional timezones can be found here: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
    echo " "
    echo "Current settings are:"
    timedatectl show
    echo " "
    echo -n "Do you want to change timezone [y/N]: "
    read answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    if [ "$answer" = "y" ]; then
        title="Select your Timezone, exit with 34:"
        prompt="Pick your option:"
        options=("Eastern time zone (EST/EDT): America/New_York" "Central time zone (CST/CDT): America/Chicago" "Mountain time zone (MST/MDT): America/Denver" "Pacific time zone (PST/PDT): America/Phoenix" "Pacific time zone (PST): America/Los_Angeles" "Arctic (AKST/AKDT): America/Anchorage" "Arctic (HST/HDT): America/Adak" "Pacific (HST): Pacific/Honolulu" "Pacific (SST): Pacific/Pago_Pago" "Europe: Europe/Istanbul" "Europe (EET/EEST): Europe/Kiev" "Europe (CET/CEST): Europe/Berlin" "Europe (UTC): UTC" "Europe (GMT/BST): Europe/London" "Atlantic: Atlantic/Azores" "America: America/Nuuk" "America: America/Sao_Paulo" "America (AST): America/Puerto_Rico" "Pacific: Pacific/Kiritimati" "Pacific: Pacific/Tongatapu" "New Zealand time (NZST/NZDT): Pacific/Auckland" "Pacific: Pacific/Guadalcanal" "Australian Eastern Time (AEST/AEDT): Australia/Sydney" "Australian Central Time (ACST/ACDT): Australia/Adelaide" "Asia (KST): Asia/Seoul" "Australian Western Time (AWST): Australia/Perth" "Asia: Asia/Bangkok" "Asia: Asia/Yangon" "Asia: Asia/Dhaka" "Asia: Asia/Kathmandu" "Asia (IST): Asia/Kolkata" "Asia: Indian/Maldives" "Asia: Asia/Dubai")
        echo "$title"
        PS3="$prompt "
        select opt in "${options[@]}" "Quit"; do
            case "$REPLY" in
            1 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="America/New_York";;
            2 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="America/Chicago";;
            3 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="America/Denver";;
            4 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="America/Phoenix";;
            5 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="America/Los_Angeles";;
            6 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="America/Anchorage";;
            7 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="America/Adak";;
            8 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Pacific/Honolulu";;
            9 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Pacific/Pago_Pago";;
            10 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Europe/Istanbul";;
            11 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Europe/Kiev";;
            12 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Europe/Berlin";;
            13 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="UTC";;
            14 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Europe/London";;
            15 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Atlantic/Azores";;
            16 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="America/Nuuk";;
            17 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="America/Sao_Paulo";;
            18 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="America/Puerto_Rico";;
            19 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Pacific/Kiritimati";;
            20 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Pacific/Tongatapu";;
            21 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Pacific/Auckland";;
            22 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Pacific/Guadalcanal";;
            23 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Australia/Sydney";;
            24 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Australia/Adelaide";;
            25 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Asia/Seoul";;
            26 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Australia/Perth";;
            27 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Asia/Bangkok";;
            28 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Asia/Yangon";;
            29 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Asia/Dhaka";;
            30 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Asia/Kathmandu";;
            31 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Asia/Kolkata";;
            32 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Indian/Maldives";;
            33 ) echo "You picked $opt, continue with 34 or choose again!"; TIMEZONE="Asia/Dubai";;
            $(( ${#options[@]}+1 )) ) echo "Continuing!"; break;;
            *) echo "Invalid option. Try another one."; continue;;
            esac
        done
        echo " "
        read -e -p "Timezone to set on Pi (chosen Timezone is $TIMEZONE, change if needed): " -i "$TIMEZONE" TIMEZONE
        echo " "
        if [ ! -f /boot/dietpi.txt ]; then
            echo "--== Setting timezone ==--"
            timedatectl set-timezone "$TIMEZONE"
        fi
    fi
fi

#####
# Start main script execution
#####
echo " "
echo "--== Date of execution ==--"
date
echo " "
if [ ! -f /boot/dietpi.txt ]; then
    echo "--== Setting NTP-servers ==--"
    sed -ri 's/^#NTP=*/NTP=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org/' /etc/systemd/timesyncd.conf
    echo " "
    echo "--== Verify timezone-setup and NTP-sync ==--"
    timedatectl show
    echo " "
fi
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
    apt -y install alsa-utils > /dev/null 2>&1
    echo " "
fi
echo "--== Verify Audio HW, list all soundcards and digital audio devices ==--"
cat /proc/asound/cards
echo " "
echo "--== Verify Audio HW, list all PCMs defined ==--"
aplay -L
echo " "
echo "--== Install/upgrade rpi-eeprom service ==--"
apt install -y rpi-eeprom > /dev/null 2>&1
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
echo " "
echo "--== If update is needed, you can update at the end by running: "rpi-eeprom-update -d -a" ==--"
echo "--== Please perform full OS-update prior to executing this ==--"
echo " "
echo -n "Do you want to install and set vim as your default editor [y/N]: "
read answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    echo " "
    echo "--== Install vim and change to default editor ==--"
    apt install -y vim > /dev/null 2>&1
    update-alternatives --set editor /usr/bin/vim.basic
fi
echo " "
if [ ! -f /boot/dietpi.txt ]; then
    echo -n "Do you want to disable IPv6 [y/N]: "
    read answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
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
if [ ! -f /boot/dietpi.txt ]; then
    echo " "
    echo "--== Check WiFi-status and enable WiFi ==--"
    echo " "
    echo "--== Before ==--"
    rfkill list all
    rfkill unblock 0
    rfkill unblock 1
    echo " "
    echo "--== After ==--"
    rfkill list all
    echo " "
    echo "--== Configure WiFi country code to unblock rfkill ==--"
    echo " "
    echo "      To enable WiFi, the country code must be set using raspi-config."
    echo "      This avoids the 'Wi-Fi is currently blocked by rfkill' error."
    echo "      Select your country code from the list (e.g., US for United States)."
    echo "      See https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2 for codes."
    echo " "
    echo -n "Do you want to set the WiFi country code [y/N]: "
    read answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    if [ "$answer" = "y" ]; then
        echo " "
        read -e -p "Enter your two-letter country code (e.g., US, GB, DE): " -i "US" COUNTRY_CODE
        echo " "
        echo "--== Setting WiFi country code to $COUNTRY_CODE ==--"
        raspi-config nonint do_wifi_country "$COUNTRY_CODE" # NEW
        echo " "
        echo "--== Verify WiFi status after setting country code ==--"
        rfkill list all
    fi
fi
if [ ! -d /home/"$USER" ]; then
    echo " "
    echo "--== Add user and enable sudo ==--"
    useradd -m -p "$PASSWORDCRYPTED" "$USER"
    usermod --shell /bin/bash "$USER" > /dev/null 2>&1
    usermod -aG adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,render,netdev,spi,i2c,gpio "$USER"
    if [ -d /home/pi ]; then
        echo " "
        echo "--== Disable default user "pi" from logging in ==--"
        usermod -s /sbin/nologin pi
        passwd -d pi
    fi
else
    echo " "
    echo "--== Ensure user is in audio group for DAC access ==--"
    usermod -aG audio "$USER"
fi
echo " "
echo "--== Set user-groups and enable sudo ==--"
if [ ! -f /boot/dietpi.txt ]; then
    usermod -aG adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,render,netdev,spi,i2c,gpio "$USER"
fi
if [ ! -f /boot/dietpi.txt ]; then
    grep -qxF "$USER ALL=(ALL) NOPASSWD: ALL" /etc/sudoers.d/010_pi-nopasswd || echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/010_pi-nopasswd
fi
if [ -f /boot/dietpi.txt ]; then
    usermod -aG adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,render,netdev,spi,i2c,gpio "$USER"
    echo " "
fi
if [ ! -f /boot/dietpi.txt ]; then
    echo " "
    echo "--== Check WiFi-status and enable WiFi ==--"
    echo " "
    echo "--== Before ==--"
    rfkill list all
    rfkill unblock 0
    rfkill unblock 1
    echo " "
    echo "--== After ==--"
    rfkill list all
    echo " "
fi

# Workaround for DietPi part 1 of 2
if [ -f /boot/dietpi.txt ] && [ -f /boot/config.txt ] && [ ! -f /boot/firmware/config.txt ]; then
    mkdir -p /boot/firmware/
    touch /boot/firmware/tempfolder
    cp /boot/config.txt /boot/firmware/config.txt
fi

echo "--== Fix HiFiBerry setup ==--"
echo -e "$INFO Configuring overlay for HifiBerry HATs (or clones):"
echo "      If you own other audio HATs, or want to keep defaults - skip this step"
echo "      you will have to manually configure your HAT later."
echo "      If you want to change audio-output from Headphones to HDMI as default output,"
echo "      skip this step, you get the option to configure that later."
echo " "
echo "      Information about the HifiBerry cards can be found at https://www.hifiberry.com"
echo "      Configuration for the HifiBerry cards can be found at https://www.hifiberry.com/docs/software/configuring-linux-3-18-x/"
echo
echo -n "Do you want to configure your HifiBerry HAT (or clone) [y/N]: "
read answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    echo " "
    echo "Now you need to choose your HiFiBerry card, pick the number for the card you have, exit with 9."
    sed --in-place --follow-symlinks /hifiberry-/d /boot/firmware/config.txt
    echo " " >> /boot/firmware/config.txt
    grep -qxF '# --== Configuration for DIGI-DAC ==--' /boot/firmware/config.txt || echo '# --== Configuration for DIGI-DAC ==--' >> /boot/firmware/config.txt
    echo " " >> /boot/firmware/config.txt
    echo " "
    title="Select your HiFiBerry card, exit with 9:"
    prompt="Pick your option:"
    options=("Setup for DAC/DAC+ Light/zero/MiniAmp/BeoCreate/DSP/RTC" "Setup for DAC+ standard/pro/AMP2" "Setup for DAC2 HD" "Setup for DAC+ ADC PRO" "Setup for Digi/Digi+" "Setup for Digi+ Pro" "Setup for Amp/Amp+" "Setup for Amp3")
    echo "$title"
    PS3="$prompt "
    select opt in "${options[@]}" "Quit"; do
        case "$REPLY" in
        1 ) echo "You picked $opt, continue with 9 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-dac";;
        2 ) echo "You picked $opt, continue with 9 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-dacplus";;
        3 ) echo "You picked $opt, continue with 9 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-dacplushd";;
        4 ) echo "You picked $opt, continue with 9 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-dacplusadcpro";;
        5 ) echo "You picked $opt, continue with 9 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-digi";;
        6 ) echo "You picked $opt, continue with 9 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-digi-pro";;
        7 ) echo "You picked $opt, continue with 9 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-amp";;
        8 ) echo "You picked $opt, continue with 9 or choose again!"; HIFIBERRY="dtoverlay=hifiberry-amp3";;
        $(( ${#options[@]}+1 )) ) echo "Continuing!"; break;;
        *) echo "Invalid option. Try another one."; continue;;
        esac
    done
    sed --in-place --follow-symlinks '/dtoverlay=hifiberry/d' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=allo/d' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=justboom/d' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=i-sabre/d' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=vc4-kms-v3d/c\dtoverlay=vc4-kms-v3d,audio=off' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=vc4-kms-v3d/c\dtoverlay=vc4-kms-v3d,noaudio' /boot/firmware/config.txt
    echo "$(cat $CNFFILE)$HIFIBERRY" > $CNFFILE
    if [ ! -f /boot/dietpi.txt ]; then
        sed --in-place --follow-symlinks '/#dtparam=audio=on/!s/dtparam=audio=on/#&/' /boot/firmware/config.txt
    fi
    sed --in-place --follow-symlinks 's/^[ \t]*//' /boot/firmware/config.txt
    sed --in-place --follow-symlinks ':a; /^\n*$/{ s/\n//; N;  ba};' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/DIGI/{N;s/\n$//}' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '${/^$/d}' /boot/firmware/config.txt
fi
echo " "
echo "--== Fix allo setup ==--"
echo -e "$INFO Configuring overlay for allo HATs (or clones):"
echo "      If you own other audio HATs, or want to keep defaults - skip this step"
echo "      you will have to manually configure your HAT later."
echo "      If you want to change audio-output from Headphones to HDMI as default output,"
echo "      skip this step, you get the option to configure that later."
echo " "
echo "      Information about the allo cards can be found at https://allo.com/sparky-dac.html"
echo "      Configuration for the allo cards can be found at https://www.amazon.com/clouddrive/share/vLk3XO9HOt3sStRUBpf4jwaX7k6J0Im91vo4z2FWVPV"
echo "      Configuration for the allo BOSS2 card can be found at https://www.amazon.com/clouddrive/share/ZHSkYGJtUZNZd3L96gyU7DkVRqMmOMP6hcclcgSrYH3"
echo " "
echo -n "Do you want to configure your allo HAT (or clone) [y/N]: "
read answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    echo " "
    echo "Now you need to choose your allo card, pick the number for the card you have, exit with 6."
    sed --in-place --follow-symlinks /allo-/d /boot/firmware/config.txt
    echo " " >> /boot/firmware/config.txt
    grep -qxF '# --== Configuration for DIGI-DAC ==--' /boot/firmware/config.txt || echo '# --== Configuration for DIGI-DAC ==--' >> /boot/firmware/config.txt
    echo " " >> /boot/firmware/config.txt
    echo " "
    title="Select your allo card, exit with 6:"
    prompt="Pick your option:"
    options=("Setup for ALLO Piano HIFI DAC" "Setup for ALLO Piano 2.1 HIFI DAC" "Setup for ALLO Boss HIFI DAC / Mini Boss HIFI DAC" "Setup for ALLO DIGIOne" "Setup for ALLO BOSS2 Player")
    echo "$title"
    PS3="$prompt "
    select opt in "${options[@]}" "Quit"; do
        case "$REPLY" in
        1 ) echo "You picked $opt, continue with 6 or choose again!"; DIGICARD="dtoverlay=allo-piano-dac-pcm512x-audio";;
        2 ) echo "You picked $opt, continue with 6 or choose again!"; DIGICARD="dtoverlay=allo-piano-dac-plus-pcm512x-audio";;
        3 ) echo "You picked $opt, continue with 6 or choose again!"; DIGICARD="dtoverlay=allo-boss-dac-pcm512x-audio";;
        4 ) echo "You picked $opt, continue with 6 or choose again!"; DIGICARD="dtoverlay=allo-digione";;
        5 ) echo "You picked $opt, continue with 6 or choose again!"; DIGICARD="dtoverlay=allo-boss2-dac-audio";;
        $(( ${#options[@]}+1 )) ) echo "Continuing!"; break;;
        *) echo "Invalid option. Try another one."; continue;;
        esac
    done
    sed --in-place --follow-symlinks '/dtoverlay=hifiberry/d' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=allo/d' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=justboom/d' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=i-sabre/d' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=vc4-kms-v3d/c\dtoverlay=vc4-kms-v3d,audio=off' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=vc4-kms-v3d/c\dtoverlay=vc4-kms-v3d,noaudio' /boot/firmware/config.txt
    echo "$(cat $CNFFILE)$DIGICARD" > $CNFFILE
    if [ ! -f /boot/dietpi.txt ]; then
        sed --in-place --follow-symlinks '/#dtparam=audio=on/!s/dtparam=audio=on/#&/' /boot/firmware/config.txt
    fi
    sed --in-place --follow-symlinks 's/^[ \t]*//' /boot/firmware/config.txt
    sed --in-place --follow-symlinks ':a; /^\n*$/{ s/\n//; N;  ba};' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/DIGI/{N;s/\n$//}' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '${/^$/d}' /boot/firmware/config.txt
fi
echo " "
echo "--== Fix JustBoom setup ==--"
echo -e "$INFO Configuring overlay for JustBoom HATs (or clones):"
echo "      If you own other audio HATs, or want to keep defaults - skip this step"
echo "      you will have to manually configure your HAT later."
echo "      If you want to change audio-output from Headphones to HDMI as default output,"
echo "      skip this step, you get the option to configure that later."
echo " "
echo "      Information about the JustBoom cards can be found at https://shop.justboom.co/collections/raspberry-pi-audio-boards"
echo "      Configuration for the JustBoom cards can be found at https://www.justboom.co/faqs/#FAQ-1"
echo " "
echo -n "Do you want to configure your JustBoom HAT (or clone) [y/N]: "
read answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    echo " "
    echo "Now you need to choose your JustBoom card, pick the number for the card you have, exit with 3."
    sed --in-place --follow-symlinks /JustBoom-/d /boot/firmware/config.txt
    echo " " >> /boot/firmware/config.txt
    grep -qxF '# --== Configuration for DIGI-DAC ==--' /boot/firmware/config.txt || echo '# --== Configuration for DIGI-DAC ==--' >> /boot/firmware/config.txt
    echo " " >> /boot/firmware/config.txt
    echo " "
    title="Select your JustBoom card, exit with 3:"
    prompt="Pick your option:"
    options=("Setup for DAC and Amp cards" "Setup for Digi cards")
    echo "$title"
    PS3="$prompt "
    select opt in "${options[@]}" "Quit"; do
        case "$REPLY" in
        1 ) echo "You picked $opt, continue with 3 or choose again!"; DIGICARD="dtoverlay=justboom-dac";;
        2 ) echo "You picked $opt, continue with 3 or choose again!"; DIGICARD="dtoverlay=justboom-digi";;
        $(( ${#options[@]}+1 )) ) echo "Continuing!"; break;;
        *) echo "Invalid option. Try another one."; continue;;
        esac
    done
    sed --in-place --follow-symlinks '/dtoverlay=hifiberry/d' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=allo/d' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=justboom/d' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=i-sabre/d' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=vc4-kms-v3d/c\dtoverlay=vc4-kms-v3d,audio=off' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=vc4-kms-v3d/c\dtoverlay=vc4-kms-v3d,noaudio' /boot/firmware/config.txt
    echo "$(cat $CNFFILE)$DIGICARD" > $CNFFILE
    if [ ! -f /boot/dietpi.txt ]; then
        sed --in-place --follow-symlinks '/#dtparam=audio=on/!s/dtparam=audio=on/#&/' /boot/firmware/config.txt
    fi
    sed --in-place --follow-symlinks 's/^[ \t]*//' /boot/firmware/config.txt
    sed --in-place --follow-symlinks ':a; /^\n*$/{ s/\n//; N;  ba};' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/DIGI/{N;s/\n$//}' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '${/^$/d}' /boot/firmware/config.txt
fi
echo " "
echo "--== Fix audiophonics setup ==--"
echo -e "$INFO Configuring overlay for audiophonics HATs (or clones):"
echo "      If you own other audio HATs, or want to keep defaults - skip this step"
echo "      you will have to manually configure your HAT later."
echo "      If you want to change audio-output from Headphones to HDMI as default output,"
echo "      skip this step, you get the option to configure that later."
echo " "
echo "      Information about the audiophonics cards can be found at https://www.audiophonics.fr/en/dac-and-interface-modules/audiophonics-dac-i-sabre-es9038q2m-raspberry-pi-i2s-spdif-pcm-dsd-usb-c-power-supply-p-12795.html"
echo "      Configuration for the audiophonics cards can be found at https://www.audiophonics.fr/en/dac-and-interface-modules/ian-canada-dual-mono-mkii-dac-es9038q2m-hat-raspberry-pi-i2s-spdif-pcm-dsd-p-18359.html"
echo " "
echo -n "Do you want to configure your audiophonics HAT (or clone) [y/N]: "
read answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    echo " "
    echo "Now you need to choose your audiophonics card, pick the number for the card you have, exit with 2."
    sed --in-place --follow-symlinks /i-sabre-q2m/d /boot/firmware/config.txt
    echo " " >> /boot/firmware/config.txt
    grep -qxF '# --== Configuration for DIGI-DAC ==--' /boot/firmware/config.txt || echo '# --== Configuration for DIGI-DAC ==--' >> /boot/firmware/config.txt
    echo " " >> /boot/firmware/config.txt
    echo " "
    title="Select your audiophonics card, exit with 2:"
    prompt="Pick your option:"
    options=("Setup for audiophonics I-SABRE 9038Q2M HIFI DAC")
    echo "$title"
    PS3="$prompt "
    select opt in "${options[@]}" "Quit"; do
        case "$REPLY" in
        1 ) echo "You picked $opt, continue with 2 or choose again!"; DIGICARD="dtoverlay=i-sabre-q2m";;
        $(( ${#options[@]}+1 )) ) echo "Continuing!"; break;;
        *) echo "Invalid option. Try another one."; continue;;
        esac
    done
    sed --in-place --follow-symlinks '/dtoverlay=hifiberry/d' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=allo/d' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=justboom/d' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=i-sabre/d' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=vc4-kms-v3d/c\dtoverlay=vc4-kms-v3d,audio=off' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/dtoverlay=vc4-kms-v3d/c\dtoverlay=vc4-kms-v3d,noaudio' /boot/firmware/config.txt
    echo "$(cat $CNFFILE)$DIGICARD" > $CNFFILE
    if [ ! -f /boot/dietpi.txt ]; then
        sed --in-place --follow-symlinks '/#dtparam=audio=on/!s/dtparam=audio=on/#&/' /boot/firmware/config.txt
    fi
    sed --in-place --follow-symlinks 's/^[ \t]*//' /boot/firmware/config.txt
    sed --in-place --follow-symlinks ':a; /^\n*$/{ s/\n//; N;  ba};' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '/DIGI/{N;s/\n$//}' /boot/firmware/config.txt
    sed --in-place --follow-symlinks '${/^$/d}' /boot/firmware/config.txt
fi
echo " "
echo "--== Fix HDMI-audio setup ==--"
echo -e "$INFO Configuring HDMI for Audio:"
echo "      If you do not have an audio-HAT, you might want to set HDMI as default for audio."
echo " "
echo "      WARNING!!!     WARNING!!!      WARNiNG!!!"
echo " "
echo "      Please only run this if you did not run any of the the Audiocard HAT setup above,"
echo "      and are sure you want to change from Headphones to HDMI for audio out!"
echo
echo -n "Do you want to configure HDMI as default audio-output [y/N]: "
read answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    sed --in-place --follow-symlinks '/#hdmi_drive=2/s/^# *//' /boot/firmware/config.txt
    sed --in-place --follow-symlinks 's/vc4-kms-v3d/vc4-kms-v3d/g' /boot/firmware/config.txt
fi

# Workaround for DietPi part 2 of 2
if [ -f /boot/dietpi.txt ] && [ -f /boot/config.txt ] && [ -f /boot/firmware/tempfolder ]; then
    cp /boot/firmware/config.txt /boot/config.txt
    rm -rf /boot/firmware/
fi

echo " "
echo "--== Cleanup for upgrade ==--"
echo " "
echo -n "Do you want to prep for upgrade/reinstall of version: "$PLEXAMPVB"? Only run if you are upgrading/reinstalling. [y/N]: "
read answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    ps ax | grep index.js | grep -v grep | awk '{print $1}' | xargs kill > /dev/null 2>&1
    rm -rf /home/"$USER"/plexamp/
    rm -rf /home/"$USER"/Plexamp-Linux-*
    su - "$USER" -c "systemctl --user stop plexamp.service" > /dev/null 2>&1
    su - "$USER" -c "systemctl --user disable plexamp.service" > /dev/null 2>&1
    rm -f /home/"$USER"/.config/systemd/user/plexamp.service
    systemctl stop plexamp.service > /dev/null 2>&1
    systemctl disable plexamp.service > /dev/null 2>&1
    rm -f /etc/systemd/system/plexamp.service
fi
echo " "
echo "--== Install or upgrade ==--"
echo " "
echo "--== If upgrading to Plexamp 4.10.0 or newer from an older version, you have to re-run the NodeJS install to upgrade to Node.v20 at least once! ==--"
echo " "
echo -n "Do you want to install/upgrade and configure Node.v20? Needed if upgrading from older versions of Plexamp with a version number less than 4.10.0! [y/N]: "
read answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    echo " "
    echo "--== Install node.v20, please be patient ==--"
    apt-mark unhold nodejs > /dev/null 2>&1
    apt purge -y nodejs npm > /dev/null 2>&1
    rm -rf /etc/apt/sources.list.d/nodesource.list
    rm -rf /etc/apt/keyrings/nodesource.gpg
    rm -rf /etc/apt/preferences.d/preferences
    mkdir -p /etc/apt/preferences.d
    apt update
    apt install -y ca-certificates curl gnupg
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    echo "Package: nodejs" >> /etc/apt/preferences.d/preferences
    echo "Pin: origin deb.nodesource.com" >> /etc/apt/preferences.d/preferences
    echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/preferences
    apt update
    apt install nodejs -y
    apt-mark hold nodejs
    echo " "
    echo "--== Verify that node.v20 is set to hold ==--"
    apt-mark showhold
    echo " "
    echo "--== Verify node.v20 and npm versions, should be v20.*.* and 10.*.* ==--"
    node -v
    npm -v
fi
echo " "
echo -n "Do you want to install and configure "$PLEXAMPVB" [y/N]: "
read answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    echo " "
    echo "--== Fetch, unpack and install "$PLEXAMPVB" ==--"
    cd /home/"$USER"
    wget "$PLEXAMPV"
    chown -R "$USER":"$USER" /home/"$USER"/Plexamp-Linux-headless-*
    tar -xf Plexamp-Linux-headless-*
    mkdir -p /home/"$USER"/.local/share/Plexamp/Offline
    chown -R "$USER":"$USER" /home/"$USER"/plexamp/
    chown -R "$USER":"$USER" /home/"$USER"/.local/
    rm -rf /home/"$USER"/"$PLEXAMPVB".tar.bz2
    echo " "
    if [ -f /boot/dietpi.txt ]; then
        echo "--== Create system-level plexamp.service for DietPi ==--"
        cat > /etc/systemd/system/plexamp.service << EOF
[Unit]
Description=Plexamp Headless (System Service)
After=network.target

[Service]
User=$USER
Group=$USER
ExecStart=/usr/bin/node /home/$USER/plexamp/js/index.js
WorkingDirectory=/home/$USER/plexamp
Restart=always

[Install]
WantedBy=multi-user.target
EOF
        echo " "
        echo "--== Enable and start system-level plexamp.service ==--"
        systemctl daemon-reload
        systemctl enable plexamp.service
        systemctl start plexamp.service
    else
        echo "--== Create user-level plexamp.service ==--"
        mkdir -p /home/"$USER"/.config/systemd/user
        cat > /home/"$USER"/.config/systemd/user/plexamp.service << EOF
[Unit]
Description=Plexamp Headless
After=network.target

[Service]
ExecStart=/usr/bin/node /home/$USER/plexamp/js/index.js
WorkingDirectory=/home/$USER/plexamp
Restart=always

[Install]
WantedBy=default.target
EOF
        chown -R "$USER":"$USER" /home/"$USER"/.config
        echo " "
        echo "--== Ensure runtime directory exists ==--"
        USER_UID=$(id -u "$USER")
        mkdir -p /run/user/"$USER_UID"
        chown "$USER":"$USER" /run/user/"$USER_UID"
        echo " "
        echo "--== Enable lingering for user to keep service running after logout ==--"
        loginctl enable-linger "$USER"
        echo " "
        echo "--== Set up plexamp.service to enable and start on first login ==--"
        # Create a one-time script to enable and start the service
        cat > /home/"$USER"/.plexamp_setup.sh << EOF
#!/bin/bash
systemctl --user daemon-reload
systemctl --user enable plexamp.service
systemctl --user start plexamp.service
# Remove this script after execution
rm -f /home/$USER/.plexamp_setup.sh
# Remove the line that sources this script from .profile
sed -i '/.plexamp_setup.sh/d' /home/$USER/.profile
EOF
        chown "$USER":"$USER" /home/"$USER"/.plexamp_setup.sh
        chmod +x /home/"$USER"/.plexamp_setup.sh
        # Add the script to .profile to run on first login
        echo "[ -f /home/$USER/.plexamp_setup.sh ] && /home/$USER/.plexamp_setup.sh" >> /home/"$USER"/.profile
    fi
fi
echo " "
echo "--== Update motd ==--"
rm -rf /etc/update-motd.d/20-logo > /dev/null 2>&1
cat >> /etc/update-motd.d/20-logo << EOF
#!/bin/sh
echo ""
echo ""
echo "   ██████╗ ██╗     ███████╗██╗  ██╗ █████╗ ███╗   ███╗██████╗"
echo "   ██╔══██╗██║     ██╔════╝╚██╗██╔╝██╔══██╗████╗ ████║██╔══██╗"
echo "   ██████╔╝██║     █████╗   ╚███╔╝ ███████║██╔████╔██║██████╔"
echo "   ██╔═══╝ ██║     ██╔══╝   ██╔██╗ ██╔══██║██║╚██╔╝██║██╔═══╝"
echo "   ██║     ███████╗███████╗██╔╝ ██╗██║  ██║██║ ╚═╝ ██║██║"
echo "   ╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝"
echo ""
echo "   $PLEXAMPVB"
echo " "
EOF
chmod +x /etc/update-motd.d/20-logo
echo " "
echo "--== OS-update including Node.v20 ==--"
echo " "
echo -n "Do you want to run full OS-update? This is recommended [y/N]: "
read answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    echo " "
    echo "--== Perform OS-update including Node.v20 (not installation), please be patient this usually takes quite a while! ==--"
    apt update --allow-releaseinfo-change > /dev/null 2>&1
    apt-mark unhold nodejs > /dev/null 2>&1
    apt -y upgrade nodejs > /dev/null 2>&1
    apt-mark hold nodejs > /dev/null 2>&1
    if [[ $OS_VERSION == "12" ]]; then
        apt install -y nala
        nala clean
        nala update
        nala upgrade -y
        nala autopurge -y
    else
        apt update
        apt upgrade -y
        apt full-upgrade -y
        apt --purge autoremove -y
    fi
fi
echo " "
echo "--== End of Post-PlexAmp-script, please reboot for all changes to take effect ==--"
echo " "
echo -e "$INFO Configuration post-reboot:"
echo "      Note !! Run PlexAmp for the first time after install to manually add the claim token."
echo "      After reboot, as user $USER, please run the following command:"
echo "      node /home/$USER/plexamp/js/index.js"
echo " "
echo "      Visit https://plex.tv/claim, copy the claim code, paste it in the Terminal, and follow the prompts."
echo "      At this point, Plexamp is now signed in and ready."
echo " "
echo "      The Plexamp service has been automatically enabled and started."
echo "      You can verify the service with: systemctl --user status plexamp.service"
echo " "
echo "      The web-GUI should be available on http://#.#.#.#:32500 from a browser."
echo "      Replace the placeholder IP address in this example with your own."
echo "      On that GUI you will be asked to login to your Plex-account for security-reasons,"
echo "      and then choose a library where to fetch/stream music from."
echo " "
echo "      If using a HAT, it is possible you need to select it via:"
echo "      Settings (cogwheel lower right corner) >> Playback >> Audio output >> Audio Device."
echo "      As an example, if you have chosen the “Digi/Digi+“ option during install in the script,"
echo "      pick “Default” if the card is not showing, reboot the pi. Now the card will show up in the list,"
echo "      and at this point you can choose it!"
echo " "
echo "      Now play some music! Or control it from any other instance of Plexamp."
echo " "
echo "      NOTE!! If you upgraded, reboot and a first login to create the symlink for autostart is needed."
echo "      The login-tokens are preserved. All should work at this point."
echo " "
echo "      Logs are located at: ~/.cache/Plexamp/log/Plexamp.log"
echo " "
# end
