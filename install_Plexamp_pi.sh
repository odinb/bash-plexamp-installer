#!/bin/bash
# Script: PlexAmp-install for Pi
# Purpose: install/upgrade Plexamp on Debian Trixie (Raspberry Pi 4, 64-bit) as a user-level service.
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
# Revision update: 2023-10-18 ODIN - Fixed bookworm setup of /boot/config.txt.  Removed SnapJack until officially released.
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
# Revision update: 2025-08-17 ODIN - Updated for Trixie (Debian v13) configuration. Cleanup of major areas performed to speedup script execution and remove legacy code.


# Update package lists
echo ""
echo "--== Updating package lists ==--"
apt update > /dev/null 2>&1 || { echo "Failed to update package lists"; exit 1; }

# Check if jq is installed, install if not
if ! command -v jq &>/dev/null; then
    echo ""
    echo "--== Installing jq for JSON data processing ==--"
    apt install -y jq > /dev/null 2>&1 || { echo "Failed to install jq"; exit 1; }
    echo "jq installed"
else
    echo "jq is already installed"
fi

# Check if curl is installed, install if not
if ! command -v curl &>/dev/null; then
    echo ""
    echo "--== Installing curl for file-fetching ==--"
    apt install -y curl > /dev/null 2>&1 || { echo "Failed to install curl"; exit 1; }
    echo "curl installed"
else
    echo "curl is already installed"
fi

# Variables
if [ -d /home/dietpi ]; then
    USER="dietpi"
else
    USER=$(logname)
fi

HOST=":PlexAmp"
NODE_MAJOR="20"
PLEXAMPV=$(curl -s "https://plexamp.plex.tv/headless/version.json" | jq -r '.updateUrl' || { echo "Unable to extract Plexamp download URL"; exit 1; })
PLEXAMPVA=${PLEXAMPV/.tar.bz2}
PLEXAMPVB=${PLEXAMPVA/https:\/\/plexamp.plex.tv\/headless\/}

# Banner
echo ""
echo ""
echo "   ██████╗ ██╗     ███████╗██╗  ██╗ █████╗ ███╗   ███╗██████╗"
echo "   ██╔══██╗██║     ██╔════╝╚██╗██╔╝██╔══██╗████╗ ████║██╔══██╗"
echo "   ██████╔╝██║     █████╗   ╚███╔╝ ███████║██╔████╔██║██████╔"
echo "   ██╔═══╝ ██║     ██╔══╝   ██╔██╗ ██╔══██║██║╚██╔╝██║██╔═══╝"
echo "   ██║     ███████╗███████╗██╔╝ ██╗██║  ██║██║ ╚═╝ ██║██║"
echo "   ╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝"
echo ""
echo " This will install/upgrade to: $PLEXAMPVB"
echo ""
echo "--== Preparing to start script execution ==--"

# Overview of HW and system
echo ""
echo "--== Overview of HW and system ==--"
    # Check if lsb-release is installed, install if not
    if ! command -v lsb_release &>/dev/null; then
        echo "Installing lsb-release"
        apt install -y lsb-release
        echo "lsb-release installed"
        echo ""
    else
        echo "lsb-release is already installed"
        echo ""
    fi
cat /proc/cpuinfo |grep Model && uname -a && lsb_release -a

# Display DietPi version if dietpi.txt exists
if [ -f /boot/dietpi.txt ]; then
    echo ""
    echo "--== DietPi version ==--"
    cat /boot/dietpi/.version
fi

# Prompt for hostname
echo ""
echo "--== Verifying current hostname ==--"
echo "Current hostname: $HOSTNAME"
echo -n "Do you want to change hostname [y/N]: "
read -r answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    echo "      To change hostname a second time, please reboot first!"
    read -e -p "Hostname for your Raspberry Pi (default: $HOST): " -i "$HOST" HOST
    sed -i "s/$HOSTNAME/$HOST/g" /etc/hostname
    sed -i "s/$HOSTNAME/$HOST/g" /etc/hosts
    if [ -f /boot/dietpi.txt ]; then
        sed -i "s/AUTO_SETUP_NET_HOSTNAME=.*/AUTO_SETUP_NET_HOSTNAME=$HOST/g" /boot/dietpi.txt
    fi
    echo "Hostname set to $HOST"
fi

# Prompt for user
echo ""
echo "--== Verifying current username ==--"
echo "Installation will proceed as user $USER."
echo -n "Do you want to create/change to a different user [y/N]: "
read -r answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    read -e -p "User to create/use for Plexamp (default: $USER): " -i "$USER" USER
    echo -n "Enter password for user $USER (required, will not change if user exists): "
    read -r -s PASSWORD
    echo ""
    if [ -z "$PASSWORD" ]; then
        echo "Error: Password cannot be empty"
        exit 1
    fi
    PASSWORDCRYPTED=$(echo "$PASSWORD" | openssl passwd -6 -stdin)
fi

# Create user if needed
if [ ! -d /home/"$USER" ]; then
    echo "--== Creating user $USER ==--"
    useradd -m -p "$PASSWORDCRYPTED" -s /bin/bash "$USER"
    if [ -d /home/pi ]; then
        echo "--== Disabling default user pi ==--"
        usermod -s /sbin/nologin pi
        passwd -d pi
    fi
fi

# Add user to groups
echo ""
echo "--== Adding user $USER to necessary groups ==--"
for group in adm dialout cdrom sudo audio video plugdev games users input render netdev spi i2c gpio; do
    if ! groups "$USER" | grep -qw "$group"; then
        usermod -aG "$group" "$USER"
    else
        echo "$USER already in $group group"
    fi
done

# Configure sudoers
if [ ! -f /boot/dietpi.txt ]; then
echo ""
echo "--== Installing and configuring sudo ==--"
    # Check if sudo is installed, install if not
    if ! command -v sudo &>/dev/null; then
        echo "Installing sudo"
        apt install -y sudo
        echo "sudo installed"
    else
        echo "sudo is already installed"
    fi

    # Add user to sudo group if not already a member
    if groups "$USER" | grep -qw "sudo"; then
        echo "User $USER is already in sudo group"
    else
        usermod -aG sudo "$USER"
        echo "Added $USER to sudo group"
    fi

    # Modify sudoers file for no password
    sudoers_file="/etc/sudoers"
    if grep -q "^%sudo.*ALL=(ALL:ALL).*NOPASSWD: ALL" "$sudoers_file"; then
        echo "NOPASSWD rule already exists in $sudoers_file"
    elif grep -q "^%sudo.*ALL=(ALL:ALL) ALL" "$sudoers_file"; then
        sed -i 's/%sudo.*ALL=(ALL:ALL) ALL/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/' "$sudoers_file"
        echo "Modified $sudoers_file to allow sudo without password"
    else
        echo "Warning: Expected sudoers line not found, appending new rule"
        echo "%sudo ALL=(ALL:ALL) NOPASSWD: ALL" | tee -a "$sudoers_file"
        echo "Appended NOPASSWD rule to $sudoers_file"
    fi
fi

# Timezone configuration
echo ""
echo "--== Timezone configuration ==--"
# Check if timedatectl is available and functional
if command -v timedatectl >/dev/null 2>&1 && timedatectl show >/dev/null 2>&1; then
    # Use timedatectl
    current_timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo "Unknown")
    echo "Current timezone: $current_timezone"
    echo -n "Do you want to change timezone [y/N]: "
    read -r answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    if [ "$answer" = "y" ]; then
        echo "Available major timezone locations:"
        timedatectl list-timezones | cut -d'/' -f1 | sort -u
        read -p "Enter major timezone location (e.g., America, press Enter to keep current): " major_tz
        if [ -n "$major_tz" ]; then
            echo "Available minor locations for $major_tz:"
            timedatectl list-timezones | grep "^$major_tz/" | cut -d'/' -f2 | sort -u
            read -p "Enter minor timezone location (e.g., Chicago): " minor_tz
            if [ -n "$minor_tz" ]; then
                timezone="$major_tz/$minor_tz"
                if timedatectl list-timezones | grep -q "^$timezone$"; then
                    if [ "$timezone" != "$current_timezone" ]; then
                        timedatectl set-timezone "$timezone"
                        echo "Timezone changed to $timezone"
                    else
                        echo "Timezone already set to $timezone"
                    fi
                else
                    echo "Error: Invalid timezone $timezone"
                    exit 1
                fi
            else
                echo "Error: No minor location provided, keeping current timezone: $current_timezone"
                exit 1
            fi
        else
            echo "Keeping current timezone: $current_timezone"
        fi
    else
        echo "Keeping current timezone: $current_timezone"
    fi
else
    # Fallback for systems without timedatectl (e.g., minimal DietPi)
    current_timezone=$(cat /etc/timezone 2>/dev/null || readlink /etc/localtime | grep -o 'zoneinfo/.*' | cut -d'/' -f2- || echo "Unknown")
    echo "Current timezone: $current_timezone"
    echo -n "Do you want to change timezone [y/N]: "
    read -r answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    if [ "$answer" = "y" ]; then
        echo "Available major timezone locations:"
        ls /usr/share/zoneinfo | grep -v '\.' | sort -u
        read -p "Enter major timezone location (e.g., America, press Enter to keep current): " major_tz
        if [ -n "$major_tz" ]; then
            if [ -d "/usr/share/zoneinfo/$major_tz" ]; then
                echo "Available minor locations for $major_tz:"
                ls "/usr/share/zoneinfo/$major_tz" | grep -v '\.' | sort -u
                read -p "Enter minor timezone location (e.g., Chicago): " minor_tz
                if [ -n "$minor_tz" ]; then
                    timezone="$major_tz/$minor_tz"
                    if [ -f "/usr/share/zoneinfo/$timezone" ]; then
                        if [ "$timezone" != "$current_timezone" ]; then
                            ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
                            echo "$timezone" > /etc/timezone
                            echo "Timezone changed to $timezone"
                        else
                            echo "Timezone already set to $timezone"
                        fi
                    else
                        echo "Error: Invalid timezone $timezone"
                        exit 1
                    fi
                else
                    echo "Error: No minor location provided, keeping current timezone: $current_timezone"
                    exit 1
                fi
            else
                echo "Error: Invalid major timezone $major_tz"
                exit 1
            fi
        else
            echo "Keeping current timezone: $current_timezone"
        fi
    else
        echo "Keeping current timezone: $current_timezone"
    fi
fi

# Main execution for current setup
echo ""
echo "--== OS version ==--"
cat /etc/os-release

# Hostname display
echo ""
echo "--== Hostname ==--"
# Check if hostnamectl is available and functional
if command -v hostnamectl >/dev/null 2>&1 && hostnamectl status >/dev/null 2>&1; then
    # Use hostnamectl for Debian systems
    hostnamectl | grep "Static hostname" | awk '{print $3}'
else
    # Fallback for systems without hostnamectl (e.g., minimal DietPi)
    # Try /etc/hostname first, then hostname command
    if [ -f /etc/hostname ]; then
        cat /etc/hostname
    else
        hostname
    fi
fi

# Hardware configuration
echo ""
echo "--== Hardware Configuration ==--"
echo -n "Do you want to list hardware configuration (Partitioning, RAM, CPUs)? [y/N]: "
read -r answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    echo ""
    echo "--== Partitioning ==--"
    lsblk
    echo ""
    echo "--== RAM ==--"
    free -m
    echo ""
    echo "--== CPUs ==--"
    lscpu
else
    echo "Skipping hardware configuration"
fi

# Sound output configuration
echo ""
echo "--== Sound output configuration ==--"
echo -n "Do you want to configure sound output (HiFiBerry, Allo, JustBoom, Audiophonics, or HDMI)? [y/N]: "
read -r answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    echo ""
    echo "--== Installing alsa-utils ==--"
    if ! command -v aplay &>/dev/null; then
        apt update > /dev/null 2>&1 || { echo "Failed to update package lists"; exit 1; }
        apt install -y alsa-utils > /dev/null 2>&1 || { echo "Failed to install alsa-utils"; exit 1; }
        echo "alsa-utils installed"
    else
        echo "alsa-utils is already installed"
    fi
    echo ""
    echo "--== Analog and digital audio devices ==--"
    cat /proc/asound/cards
    echo ""
    echo "--== PCMs defined ==--"
    aplay -L

# Detect OS and Debian version
OS_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
DEBIAN_VERSION=$(grep VERSION_CODENAME /etc/os-release | cut -d'=' -f2 | tr -d '"')
if [ -f /boot/dietpi.txt ] || [ -d /DietPi ]; then
    CNFFILE="/boot/firmware/config.txt"
    echo "Detected DietPi ($DEBIAN_VERSION), using $CNFFILE for configuration"
elif [ "$DEBIAN_VERSION" = "trixie" ]; then
    CNFFILE="/boot/firmware/usercfg.txt"
    echo ""
    echo "--== Checking for Trixie, and creating /boot/firmware/usercfg.txt if needed ==--"
    echo "Detected Debian Trixie, using $CNFFILE for configuration"
else
    CNFFILE="/boot/firmware/config.txt"
    echo "Detected Debian Bookworm or compatible, using $CNFFILE for configuration"
fi
# Ensure config file exists
if [ ! -f "$CNFFILE" ]; then
    mkdir -p "$(dirname "$CNFFILE")"
    touch "$CNFFILE"
    chmod 644 "$CNFFILE"
    echo "Created $CNFFILE"
fi

    echo ""
    echo "--== Select audio configuration ==--"
    title="Select audio option, exit with 6:"
    prompt="Pick your option:"
    options=("HiFiBerry HAT" "Allo HAT" "JustBoom HAT" "Audiophonics HAT" "HDMI Audio")
    echo "$title"
    PS3="$prompt "
    select opt in "${options[@]}" "Quit"; do
        case "$REPLY" in
        1)
            echo ""
            echo "--== Configuring HiFiBerry HAT ==--"
            echo "Select your HiFiBerry card, exit with 9:"
            hifi_options=("DAC/DAC+ Light/zero/MiniAmp/BeoCreate/DSP/RTC" "DAC+ standard/pro/AMP2" "DAC2 HD" "DAC+ ADC PRO" "Digi/Digi+" "Digi+ Pro" "Amp/Amp+" "Amp3")
            PS3="Pick your HiFiBerry card: "
            select hifi_opt in "${hifi_options[@]}" "Quit"; do
                case "$REPLY" in
                1) HIFIBERRY="dtoverlay=hifiberry-dac"; echo "Selected $hifi_opt";;
                2) HIFIBERRY="dtoverlay=hifiberry-dacplus"; echo "Selected $hifi_opt";;
                3) HIFIBERRY="dtoverlay=hifiberry-dacplushd"; echo "Selected $hifi_opt";;
                4) HIFIBERRY="dtoverlay=hifiberry-dacplusadcpro"; echo "Selected $hifi_opt";;
                5) HIFIBERRY="dtoverlay=hifiberry-digi"; echo "Selected $hifi_opt";;
                6) HIFIBERRY="dtoverlay=hifiberry-digi-pro"; echo "Selected $hifi_opt";;
                7) HIFIBERRY="dtoverlay=hifiberry-amp"; echo "Selected $hifi_opt";;
                8) HIFIBERRY="dtoverlay=hifiberry-amp3"; echo "Selected $hifi_opt";;
                9) echo "Continuing"; break;;
                *) echo "Invalid option"; continue;;
                esac
                break
            done
            if [ -n "$HIFIBERRY" ]; then
                sed -i '/dtoverlay=hifiberry/d' "$CNFFILE"
                sed -i '/dtoverlay=allo/d' "$CNFFILE"
                sed -i '/dtoverlay=justboom/d' "$CNFFILE"
                sed -i '/dtoverlay=i-sabre/d' "$CNFFILE"
                sed -i '/hdmi_force_hotplug=/d' "$CNFFILE"
                sed -i '/hdmi_drive=/d' "$CNFFILE"
                if ! grep -q "dtoverlay=vc4-kms-v3d" "$CNFFILE"; then
                    echo "dtoverlay=vc4-kms-v3d,noaudio" | tee -a "$CNFFILE"
                else
                    sed -i 's/dtoverlay=vc4-kms-v3d\(,noaudio\)\?/dtoverlay=vc4-kms-v3d,noaudio/' "$CNFFILE"
                fi
                echo "$HIFIBERRY" | tee -a "$CNFFILE"
                sed -i '/#dtparam=audio=on/!s/dtparam=audio=on/#&/' "$CNFFILE"
                echo ""
                echo "Configured $HIFIBERRY in $CNFFILE"
            fi
            break
            ;;
        2)
            echo ""
            echo "--== Configuring Allo HAT ==--"
            echo "Select your Allo card, exit with 6:"
            allo_options=("Piano HIFI DAC" "Piano 2.1 HIFI DAC" "Boss HIFI DAC/Mini Boss" "DIGIOne" "BOSS2 Player")
            PS3="Pick your Allo card: "
            select allo_opt in "${allo_options[@]}" "Quit"; do
                case "$REPLY" in
                1) DIGICARD="dtoverlay=allo-piano-dac-pcm512x-audio"; echo "Selected $allo_opt";;
                2) DIGICARD="dtoverlay=allo-piano-dac-plus-pcm512x-audio"; echo "Selected $allo_opt";;
                3) DIGICARD="dtoverlay=allo-boss-dac-pcm512x-audio"; echo "Selected $allo_opt";;
                4) DIGICARD="dtoverlay=allo-digione"; echo "Selected $allo_opt";;
                5) DIGICARD="dtoverlay=allo-boss2-dac-audio"; echo "Selected $allo_opt";;
                6) echo "Continuing"; break;;
                *) echo "Invalid option"; continue;;
                esac
                break
            done
            if [ -n "$DIGICARD" ]; then
                sed -i '/dtoverlay=hifiberry/d' "$CNFFILE"
                sed -i '/dtoverlay=allo/d' "$CNFFILE"
                sed -i '/dtoverlay=justboom/d' "$CNFFILE"
                sed -i '/dtoverlay=i-sabre/d' "$CNFFILE"
                sed -i '/hdmi_force_hotplug=/d' "$CNFFILE"
                sed -i '/hdmi_drive=/d' "$CNFFILE"
                if ! grep -q "dtoverlay=vc4-kms-v3d" "$CNFFILE"; then
                    echo "dtoverlay=vc4-kms-v3d,noaudio" | tee -a "$CNFFILE"
                else
                    sed -i 's/dtoverlay=vc4-kms-v3d\(,noaudio\)\?/dtoverlay=vc4-kms-v3d,noaudio/' "$CNFFILE"
                fi
                echo "$DIGICARD" | tee -a "$CNFFILE"
                sed -i '/#dtparam=audio=on/!s/dtparam=audio=on/#&/' "$CNFFILE"
                echo ""
                echo "Configured $DIGICARD in $CNFFILE"
            fi
            break
            ;;
        3)
            echo ""
            echo "--== Configuring JustBoom HAT ==--"
            echo "Select your JustBoom card, exit with 3:"
            justboom_options=("DAC and Amp cards" "Digi cards")
            PS3="Pick your JustBoom card: "
            select justboom_opt in "${justboom_options[@]}" "Quit"; do
                case "$REPLY" in
                1) DIGICARD="dtoverlay=justboom-dac"; echo "Selected $justboom_opt";;
                2) DIGICARD="dtoverlay=justboom-digi"; echo "Selected $justboom_opt";;
                3) echo "Continuing"; break;;
                *) echo "Invalid option"; continue;;
                esac
                break
            done
            if [ -n "$DIGICARD" ]; then
                sed -i '/dtoverlay=hifiberry/d' "$CNFFILE"
                sed -i '/dtoverlay=allo/d' "$CNFFILE"
                sed -i '/dtoverlay=justboom/d' "$CNFFILE"
                sed -i '/dtoverlay=i-sabre/d' "$CNFFILE"
                sed -i '/hdmi_force_hotplug=/d' "$CNFFILE"
                sed -i '/hdmi_drive=/d' "$CNFFILE"
                if ! grep -q "dtoverlay=vc4-kms-v3d" "$CNFFILE"; then
                    echo "dtoverlay=vc4-kms-v3d,noaudio" | tee -a "$CNFFILE"
                else
                    sed -i 's/dtoverlay=vc4-kms-v3d\(,noaudio\)\?/dtoverlay=vc4-kms-v3d,noaudio/' "$CNFFILE"
                fi
                echo "$DIGICARD" | tee -a "$CNFFILE"
                sed -i '/#dtparam=audio=on/!s/dtparam=audio=on/#&/' "$CNFFILE"
                echo ""
                echo "Configured $DIGICARD in $CNFFILE"
            fi
            break
            ;;
        4)
            echo ""
            echo "--== Configuring Audiophonics HAT ==--"
            echo "Select your Audiophonics card, exit with 2:"
            audio_options=("I-SABRE 9038Q2M HIFI DAC")
            PS3="Pick your Audiophonics card: "
            select audio_opt in "${audio_options[@]}" "Quit"; do
                case "$REPLY" in
                1) DIGICARD="dtoverlay=i-sabre-q2m"; echo "Selected $audio_opt";;
                2) echo "Continuing"; break;;
                *) echo "Invalid option"; continue;;
                esac
                break
            done
            if [ -n "$DIGICARD" ]; then
                sed -i '/dtoverlay=hifiberry/d' "$CNFFILE"
                sed -i '/dtoverlay=allo/d' "$CNFFILE"
                sed -i '/dtoverlay=justboom/d' "$CNFFILE"
                sed -i '/dtoverlay=i-sabre/d' "$CNFFILE"
                sed -i '/hdmi_force_hotplug=/d' "$CNFFILE"
                sed -i '/hdmi_drive=/d' "$CNFFILE"
                if ! grep -q "dtoverlay=vc4-kms-v3d" "$CNFFILE"; then
                    echo "dtoverlay=vc4-kms-v3d,noaudio" | tee -a "$CNFFILE"
                else
                    sed -i 's/dtoverlay=vc4-kms-v3d\(,noaudio\)\?/dtoverlay=vc4-kms-v3d,noaudio/' "$CNFFILE"
                fi
                echo "$DIGICARD" | tee -a "$CNFFILE"
                sed -i '/#dtparam=audio=on/!s/dtparam=audio=on/#&/' "$CNFFILE"
                echo ""
                echo "Configured $DIGICARD in $CNFFILE"
            fi
            break
            ;;
        5)
            echo ""
            echo "--== Configuring HDMI audio ==--"
            sed -i '/dtoverlay=hifiberry/d' "$CNFFILE"
            sed -i '/dtoverlay=allo/d' "$CNFFILE"
            sed -i '/dtoverlay=justboom/d' "$CNFFILE"
            sed -i '/dtoverlay=i-sabre/d' "$CNFFILE"
            sed -i '/hdmi_force_hotplug=/d' "$CNFFILE"
            sed -i '/hdmi_drive=/d' "$CNFFILE"
            echo "hdmi_force_hotplug=1" | tee -a "$CNFFILE"
            echo "hdmi_drive=2" | tee -a "$CNFFILE"
            sed -i 's/dtoverlay=vc4-kms-v3d\(,noaudio\)\?/dtoverlay=vc4-kms-v3d/' "$CNFFILE"
            echo ""
            echo "Configured HDMI audio in $CNFFILE"
            break
            ;;
        6)
            echo "Skipping audio configuration"
            break
            ;;
        *) echo "Invalid option"; continue;;
        esac
    done
    sed -i 's/^[ \t]*//' "$CNFFILE"
    sed -i ':a; /^\n*$/{ s/\n//; N; ba};' "$CNFFILE"
    sed -i '/DIGI/{N;s/\n$//}' "$CNFFILE"
    sed -i '${/^$/d}' "$CNFFILE"
else
    echo "Skipping sound output configuration"
fi

# vim configuration
echo ""
echo "--== Installing and configuring vim ==--"
echo -n "Do you want to install and set vim as default editor [y/N]: "
read -r answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    # Check if vim is installed, install if not
    if ! command -v vim &>/dev/null; then
        echo "Installing vim"
        apt install -y vim > /dev/null 2>&1
        echo "vim installed"
    else
        echo "vim is already installed"
    fi
    # Check if vim is set as default editor, set if not
    if ! update-alternatives --get-selections | grep -q "editor.*vim.basic"; then
        update-alternatives --set editor /usr/bin/vim.basic
        echo "Set vim as default editor"
    else
        echo "vim is already set as default editor"
    fi
fi

# IPv6 configuration (non-DietPi)
if [ ! -f /boot/dietpi.txt ]; then
    echo ""
    echo "--== IPv6 configuration ==--"
    echo -n "Do you want to disable IPv6 [y/N]: "
    read -r answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    if [ "$answer" = "y" ]; then
        echo ""
        echo "--== Disabling IPv6 ==--"
        if [ ! -f /etc/sysctl.d/disable-ipv6.conf ]; then
            echo "net.ipv6.conf.all.disable_ipv6 = 1" > /etc/sysctl.d/disable-ipv6.conf
            sysctl -p /etc/sysctl.d/disable-ipv6.conf
            echo "IPv6 disabled"
        else
            echo "IPv6 already disabled"
        fi
    fi
fi

# Wi-Fi configuration for rfkill block according to current set timezone
if [ ! -f /boot/dietpi.txt ]; then
    echo ""
    echo "--== Wi-Fi configuration ==--"
    # Check if rfkill is installed, install if not
    if ! command -v rfkill &>/dev/null; then
        echo "Installing rfkill for Wi-Fi configuration:"
        sudo apt install -y rfkill > /dev/null 2>&1 || { echo "Failed to install rfkill"; exit 1; }
        echo "rfkill installed"
    else
        echo "rfkill is already installed"
    fi
    echo -n "Do you want to remove Wi-Fi rfkill block [y/N]: "
    read -r answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    if [ "$answer" = "y" ]; then
        if rfkill list wifi | grep -q "Soft blocked: yes"; then
            echo "Wi-Fi is blocked by rfkill, configuring country code"
            current_timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo "Unknown")
            ZONETAB=/usr/share/zoneinfo/zone.tab
            CC=$(awk -v tz="$current_timezone" '$3 == tz {print $1}' $ZONETAB)
            if [ -z "$CC" ]; then
                echo "No country code found for timezone $current_timezone"
                exit 1
            fi
            if command -v raspi-config >/dev/null; then
                sudo raspi-config nonint do_wifi_country "$CC"
            else
                sudo sed -i "/^country=/d" /etc/wpa_supplicant/wpa_supplicant.conf
                echo "country=$CC" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf >/dev/null
                sudo wpa_cli -i wlan0 reconfigure
            fi
            sudo rfkill unblock wifi
            echo "Wi-Fi country set to $CC and unblocked"
        else
            echo "Wi-Fi is not blocked, skipping configuration"
        fi
    fi
fi

# Plexamp cleanup
echo ""
echo "--== Cleanup previous Plexamp installation ==--"
echo -n "Do you want to clean up for Plexamp upgrade/reinstall ($PLEXAMPVB)? [y/N]: "
read -r answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    ps ax | grep index.js | grep -v grep | awk '{print $1}' | xargs kill > /dev/null 2>&1
    rm -rf /home/"$USER"/plexamp /home/"$USER"/Plexamp-Linux-*
    su - "$USER" -c "systemctl --user stop plexamp.service" > /dev/null 2>&1
    su - "$USER" -c "systemctl --user disable plexamp.service" > /dev/null 2>&1
    rm -f /home/"$USER"/.config/systemd/user/plexamp.service
    systemctl stop plexamp.service > /dev/null 2>&1
    systemctl disable plexamp.service > /dev/null 2>&1
    rm -f /etc/systemd/system/plexamp.service
    echo "Cleanup completed"
fi

# Node.js installation
echo ""
echo "--== Installing Node.js v$NODE_MAJOR ==--"
echo "--== This is mandatory to run at least once prior to installing Plexamp initially ==--"
echo "--== This is also needed if upgrade of Node.js is required ==--"
echo "--== If already run, or no upgrade is needed, it can be skipped ==--"
echo -n "Do you want to install/upgrade Node.js v$NODE_MAJOR? [y/N]: "
read -r answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    if ! dpkg -l | grep -q gnupg; then
        apt install -y gnupg
    fi
    apt-mark unhold nodejs > /dev/null 2>&1
    apt purge -y nodejs npm > /dev/null 2>&1
    rm -rf /etc/apt/sources.list.d/nodesource.list /etc/apt/keyrings/nodesource.gpg /etc/apt/preferences.d/preferences
    apt update
    mkdir -p /etc/apt/keyrings /etc/apt/preferences.d
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
    echo -e "Package: nodejs\nPin: origin deb.nodesource.com\nPin-Priority: 1001" > /etc/apt/preferences.d/preferences
    apt update
    apt install -y nodejs
    apt-mark hold nodejs
    apt autoremove -y
    echo ""
    echo "--== Node.js and npm versions ==--"
    node -v
    npm -v
fi

# Plexamp installation
echo ""
echo "--== Installing $PLEXAMPVB ==--"
echo -n "Do you want to install $PLEXAMPVB? [y/N]: "
read -r answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
apt update > /dev/null 2>&1 || { echo "Failed to update package lists"; exit 1; }
if ! command -v wget &>/dev/null; then
        echo ""
        echo "--== Installing wget for file-fetching ==--"
        apt install -y wget || { echo "Failed to install wget"; exit 1; }
        echo "wget installed"
    else
        echo "wget is already installed"
    fi
    if ! command -v lbzip2 &>/dev/null; then
        echo ""
        echo "--== Installing lbzip2 for file-unpacking ==--"
        apt install -y lbzip2 || { echo "Failed to install lbzip2"; exit 1; }
        echo "lbzip2 installed"
    else
        echo "lbzip2 is already installed"
    fi
    cd /home/"$USER"
    echo ""
    echo "--== Fetching $PLEXAMPVB and installing ==--"
    wget "$PLEXAMPV"
    tar -xf Plexamp-Linux-headless-*
    mkdir -p /home/"$USER"/plexamp /home/"$USER"/.local/share/Plexamp/Offline
    chown -R "$USER":"$USER" /home/"$USER"/plexamp /home/"$USER"/.local /home/"$USER"/Plexamp-Linux-headless-*
    rm -f /home/"$USER"/"$PLEXAMPVB".tar.bz2
    if [ -f /boot/dietpi.txt ]; then
        echo "--== Creating system-level plexamp.service for DietPi ==--"
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
        systemctl daemon-reload
        systemctl enable plexamp.service
        systemctl start plexamp.service
        echo "System-level plexamp.service enabled and started"
    else
        echo "--== Creating user-level plexamp.service ==--"
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
        USER_UID=$(id -u "$USER")
        mkdir -p /run/user/"$USER_UID"
        chown "$USER":"$USER" /run/user/"$USER_UID"
        loginctl enable-linger "$USER"
        cat > /home/"$USER"/.plexamp_setup.sh << EOF
#!/bin/bash
systemctl --user daemon-reload
systemctl --user enable plexamp.service
systemctl --user start plexamp.service
rm -f /home/$USER/.plexamp_setup.sh
sed -i '/.plexamp_setup.sh/d' /home/$USER/.profile
EOF
        chown "$USER":"$USER" /home/"$USER"/.plexamp_setup.sh
        chmod +x /home/"$USER"/.plexamp_setup.sh
        echo "[ -f /home/$USER/.plexamp_setup.sh ] && /home/$USER/.plexamp_setup.sh" >> /home/"$USER"/.profile
        echo "User-level plexamp.service configured"
    fi
fi

# Update motd
echo ""
echo "--== Updating motd ==--"
cat > /etc/update-motd.d/20-logo << EOF
#!/bin/sh
echo ""
echo "   ██████╗ ██╗     ███████╗██╗  ██╗ █████╗ ███╗   ███╗██████╗"
echo "   ██╔══██╗██║     ██╔════╝╚██╗██╔╝██╔══██╗████╗ ████║██╔══██╗"
echo "   ██████╔╝██║     █████╗   ╚███╔╝ ███████║██╔████╔██║██████╔"
echo "   ██╔═══╝ ██║     ██╔══╝   ██╔██╗ ██╔══██║██║╚██╔╝██║██╔═══╝"
echo "   ██║     ███████╗███████╗██╔╝ ██╗██║  ██║██║ ╚═╝ ██║██║"
echo "   ╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝"
echo ""
echo "   $PLEXAMPVB"
echo ""
EOF
chmod +x /etc/update-motd.d/20-logo
echo "Updated motd"

# OS update
echo ""
echo "--== Updating host OS ==--"
echo -n "Do you want to run full OS update? [y/N]: "
read -r answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    echo "Performing OS update"
    apt update --allow-releaseinfo-change
    apt-mark unhold nodejs
    apt upgrade -y
    apt full-upgrade -y
    apt autoremove --purge -y
    apt-mark hold nodejs
    echo "OS update completed"
fi


echo "Script completed successfully"
echo ""
echo "--== End of Post-PlexAmp-script, do not reboot yet if this was a fresh install ==--"
echo ""
echo -e "$INFO Configuration post-install:"
echo "      Note !! Run PlexAmp for the first time after initial installation to manually add the claim token."
echo "      As user $USER, please run the following command:"
echo "      node /home/$USER/plexamp/js/index.js"
echo ""
echo "      Visit https://plex.tv/claim, copy the claim code, paste it in the Terminal, and follow the prompts."
echo "      At this point, Plexamp is now signed in and ready."
echo ""
echo "      NOTE!! A reboot and re-login is at this point needed to automatically create the symlink for autostart."
echo "      Please go ahead and issue a reboot at this point and login as your user."
echo "      This is not needed on DietPi, since it is a system-service there"
echo ""
echo "      The Plexamp service has now been automatically enabled and started."
echo "      You can verify the service with: systemctl --user status plexamp.service"
echo "      On Dietpi, it is a system service, use: sudo systemctl status plexamp.service"
echo ""
echo "      The web-GUI should be available on http://hostname:32500 from a browser."
echo "      Replace the hostname with IP address in this example with your own."
echo "      On that GUI you will be asked to login to your Plex-account for security-reasons,"
echo "      and then choose a library where to fetch/stream music from."
echo "      If not asked to login, then go to "settings" > "account" and sign out."
echo "      Now sign back in, then click on the "cast" icon and re-select the headless player."
echo ""
echo "      If web-GUI is not accessible after following above, try rebooting once more, and then load the GUI."
echo ""
echo "      If using a HAT, it is possible you need to select it via:"
echo "      Settings (cogwheel lower right corner) >> Playback >> Audio output >> Audio Device."
echo "      As an example, if you have chosen the “Digi/Digi+“ option during install in the script,"
echo "      pick “Default” if the card is not showing, reboot the pi. Now the card will show up in the list,"
echo "      and at this point you can choose it!"
echo ""
echo "      Now play some music! Or control it from any other instance of Plexamp."
echo ""
echo "      NOTE!! For upgrades from an older version, a second reboot might be needed to automatically create the symlink for autostart."
echo "      Please go ahead and issue a reboot to create this symlink."
echo "      This is not needed on DietPi, since it is a system-service there"
echo "      The login-tokens are preserved. All should work at this point."
echo ""
echo "      Logs are located at: ~/.cache/Plexamp/log/Plexamp.log"
echo ""
# end
