#!/bin/bash
# Script: PlexAmp-install for Pi
# Purpose: install/upgrade Plexamp on Debian Bookworm/Trixie (Raspberry Pi 3/4/5, 64-bit) as a user-level service.
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
# Revision update: 2022-08-01 ODIN - Added option for HifiBerry Digi2 Pro. Requested by Andreas Diel[](https://github.com/Dieler).
# Revision update: 2022-08-14 ODIN - Added workarounds for DietPi.
# Revision update: 2022-09-18 ODIN - Made Node.v12 optional to please non-Debian/RPI-users.
# Revision update: 2022-09-18 ODIN - Changed user service to system service, and run process as limited user.
# Revision update: 2022-09-26 ODIN - Added option for allo Boss HIFI DAC and variants. Requested by hvddrift[](https://github.com/hvddrift).
# Revision update: 2022-11-08 ODIN - Fixed /etc/sudoers.d/010_pi-nopasswd for non-pi user.
# Revision update: 2022-11-12 ODIN - Updated to using "Plexamp-Linux-headless-v4.5.3 and upgrading to NodeJS v16".
# Revision update: 2022-11-13 ODIN - Improved logic for installing NodeJS v16 to only if needed.
# Revision update: 2022-12-27 ODIN - Updated to remove hardcoded version, should now install latest.
# Revision update: 2023-02-03 ODIN - Update to remove hardcoded version did not work, now using v4.6.2.
# Revision update: 2023-02-28 ODIN - Fix HDMI-audio setup with change to "dtoverlay" to enable HDMI-alsa device.
# Revision update: 2023-05-03 ODIN - Updated to using "Plexamp-Linux-headless-v4.7.0. If your card is not detected after boot (no audio) ("aplay -l" to check),
#                                  - please do hard reboot, and re-select the card! Now there should be audio!
# Revision update: 2023-08-04 ODIN - Updated to using "Plexamp-Linux-headless-v4.8.2, and added Timezone setting as optional.
# Revision update: 2023-09-05 ODIN - Updated prompts to correspond better with the HiFiBerry Config page.
# Revision update: 2023-09-08 ODIN - Added more TimeZones.
# Revision update: 2023-09-12 ODIN - Updated NodeJS-16 repo to use "https://github.com/nodesource". Removed legacy path ".config" on generic install, fixing dietpi.
# Revision update: 2023-10-08 ODIN - Improvements to installer and variable-handling. Various cosmetic fixes.
# Revision update: 2023-10-08 ODIN - Improvements to motd-manipulation.
# Revision update: 2023-10-10 ODIN - Added SnapJack installation to enable multi-room / multi-device streaming. Added other improvements to script.
# Revision update: 2023-10-15 ODIN - Verified not working on Debian version: 12 (bookworm). HAT-cards are not detected. Added other improvements to script.
# Revision update: 2023-10-17 ODIN - Added version info at start of script execution. Version no longer hard-coded.
# Revision update: 2023-10-18 ODIN - Fixed bookworm setup of /boot/config.txt. Removed SnapJack until officially released.
# Revision update: 2023-11-24 ODIN - Replaced apt-get with apt. Added nala if running bookworm.
# Revision update: 2023-12-06 ODIN - Minor cleanup of menus and README.
# Revision update: 2023-12-22 ODIN - Added option for 9038Q2M-based audiophonics cards. Requested by newelement[](https://github.com/newelement)
# Revision update: 2023-12-28 ODIN - Added option for Allo Boss 2 DAC card. Requested by John-Pienaar[](https://github.com/john-pienaar)
# Revision update: 2023-12-31 ODIN - Added option for JustBoom DAC/DIGI cards. Suggested by Ryuzaki_2[](https://forums.plex.tv/u/Ryuzaki_2)
# Revision update: 2024-03-16 ODIN - Updated to using "Plexamp-Linux-headless-v4.10.0 and upgrading to NodeJS v20".
# Revision update: 2024-06-14 ODIN - Fixed Bookworm setup to use /boot/firmware/config.txt dropping support for Bullseye.
#                                  - More info here: https://www.raspberrypi.com/documentation/computers/config_txt.html Commit contributed by ItsVRK[](https://github.com/ItsVRK)
# Revision update: 2024-09-24 ODIN - Updated to "dtoverlay=vc4-kms-v3d" due to deprecation of "fkms" after input (issue #29) from bhcompy[](https://github.com/bhcompy).
# Revision update: 2024-10-06 ODIN - Added workarounds for DietPi for /boot/config.txt.
# Revision update: 2025-04-18 ODIN - Added update for new WiFi setting to fix "Wi-Fi is currently blocked by rfkill".
# Revision update: 2025-05-09 ODIN - Modified to run Plexamp as a user-level service with DAC access, and automatically enable plexamp user-service. Added WiFi Country Code Setup.
# Revision update: 2025-05-09 ODIN - Modified to detect DietPi and use a system-level service instead of a user-level service, as system services are more reliable in DietPi's minimal environment.
# Revision update: 2025-08-17 ODIN - Updated for Trixie (Debian v13) configuration. Cleanup of major areas performed to speedup script execution and remove legacy code.
# Revision update: 2025-10-03 ODIN - Updated for Trixie (Debian v13) configuration for Raspberry Pi OS, including DietPi on Trixie.
# Revision update: 2025-10-03 ODIN - Updated HDMI audio-settings, adding "hdmi_force_edid_audio=1" and ensuring "dtoverlay=vc4-kms-v3d" whereas non-HDMI will have "dtoverlay=vc4-kms-v3d,noaudio".
# Revision update: 2025-12-05 ODIN - Updated service file (Environment="CLIENT_NAME=$HOSTNAME") to try and avoid all the "undefined" calls to DNS. This seems to be a bug.
# Revision update: 2026-01-03 ODIN - Updated IPv6 disable to fully disable. Updated service file (ExecStart=) to try and avoid all the "undefined" calls to DNS.
#                                  - This is a bug in Plexamp, which assumes CLIENT_NAME exists.
#                                  - Plexamp never checks if the variable is undefined before constructing a hostname; it doesn't fall back gracefully!
# Revision update: 2026-02-27 ODIN - Updated service file one more time, making it more robust, to try and avoid all the "undefined" calls to DNS. This seems to be a bug.
# Revision update: 2026-03-01 ODIN - Updated "Sound output configuration", adding option for "USB Audio Dongle"
# Revision update: 2026-03-05 ODIN - Improved config.txt path detection for Trixie. Added automatic HAT detection via I2C before prompting user.
#                                  - Improved USB audio to use card name instead of index for reboot stability. Added Pi 5 specific audio handling (dtparam=audio=off for HATs).
#                                  - Added post-config audio verification step. Fixed USER detection under sudo (uses SUDO_USER). Added root check at script start.
#                                  - Added Plexamp API response validation. Added Pi model detection for Pi 3/4/5 compatibility.
# Revision update: 2026-03-06 ODIN - Updated service file again to try and avoid all the "undefined" calls to DNS. Added firmware Update check, and inform user of state.
#                                  - Added possible audio enhancement trix. Improved the "Wi-Fi is currently blocked by rfkill" section to allow country changes.

# ============================================================
#
# Root check
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Use: sudo bash $0"
    exit 1
fi

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
# Robust user detection: prefer SUDO_USER over logname
if [ -d /home/dietpi ]; then
    USER="dietpi"
elif [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    USER="$SUDO_USER"
else
    USER=$(logname 2>/dev/null || who | awk 'NR==1{print $1}' || echo "pi")
fi

HOST="PlexAmp"
NODE_MAJOR="20"

# Fetch and validate Plexamp version from API
PLEXAMPV=$(curl -s "https://plexamp.plex.tv/headless/version.json" | jq -r '.updateUrl' 2>/dev/null || true)
if [ -z "$PLEXAMPV" ] || [ "$PLEXAMPV" = "null" ]; then
    echo "ERROR: Failed to fetch Plexamp download URL from Plex API."
    echo "Check your internet connection and try again."
    exit 1
fi
PLEXAMPVA=${PLEXAMPV/.tar.bz2}
PLEXAMPVB=${PLEXAMPVA/https:\/\/plexamp.plex.tv\/headless\/}

# Detect Pi model
PI_MODEL=$(tr -d '\0' < /proc/device-tree/model 2>/dev/null || grep "Model" /proc/cpuinfo | cut -d: -f2 | xargs || echo "Unknown")
if echo "$PI_MODEL" | grep -q "Raspberry Pi 5"; then
    IS_PI5=true
else
    IS_PI5=false
fi

# Detect OS/distro
IS_DIETPI=false
if [ -f /boot/dietpi.txt ] || [ -d /DietPi ]; then
    IS_DIETPI=true
fi
DEBIAN_VERSION=$(grep VERSION_CODENAME /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "unknown")

# Derive human-readable OS label for banner
if [ "$IS_DIETPI" = true ]; then
    OS_LABEL="DietPi ($DEBIAN_VERSION)"
else
    OS_LABEL="Raspberry Pi OS ($DEBIAN_VERSION)"
fi

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
echo " Hardware : $PI_MODEL"
echo " OS       : $OS_LABEL"
echo ""
echo "--== Preparing to start script execution ==--"

# Overview of HW and system
echo ""
echo "--== Overview of HW and system ==--"
if ! command -v lsb_release &>/dev/null; then
    echo "Installing lsb-release"
    apt install -y lsb-release
    echo "lsb-release installed"
    echo ""
else
    echo "lsb-release is already installed"
    echo ""
fi
cat /proc/cpuinfo | grep Model && uname -a && lsb_release -a

# Display DietPi version if dietpi.txt exists
if [ "$IS_DIETPI" = true ] && [ -f /boot/dietpi/.version ]; then
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
    echo "To change hostname a second time, please reboot first!"
    read -e -p "Hostname for your Raspberry Pi (default: $HOST): " -i "$HOST" HOST
    sed -i "s/^$HOSTNAME/$HOST/" /etc/hostname
    sed -i "s/$HOSTNAME/$HOST/g" /etc/hosts
    if [ "$IS_DIETPI" = true ]; then
        sed -i "s/AUTO_SETUP_NET_HOSTNAME=.*/AUTO_SETUP_NET_HOSTNAME=$HOST/g" /boot/dietpi.txt
    fi
    echo "Hostname set to $HOST"
    echo " "
    echo "!!!!!!!!!!          !!!!!!!!!!"
    echo " "
    echo "Please hit CTRL-C and reboot to re-start script, or the service-file will have the old hostname."
    echo "This can cause issues with DNS and other items for Node.JS."
    echo " "
    echo "!!!!!!!!!!          !!!!!!!!!!"
    echo " "
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
if [ "$IS_DIETPI" = false ]; then
    echo ""
    echo "--== Installing and configuring sudo ==--"
    if ! command -v sudo &>/dev/null; then
        echo "Installing sudo"
        apt install -y sudo
        echo "sudo installed"
    else
        echo "sudo is already installed"
    fi
    if ! groups "$USER" | grep -qw "sudo"; then
        usermod -aG sudo "$USER"
        echo "Added $USER to sudo group"
    else
        echo "User $USER is already in sudo group"
    fi
    sudoers_file="/etc/sudoers"
    if ! grep -q "^%sudo.*NOPASSWD: ALL" "$sudoers_file"; then
        echo "%sudo ALL=(ALL:ALL) NOPASSWD: ALL" | tee -a "$sudoers_file"
        echo "Added NOPASSWD rule to $sudoers_file"
    else
        echo "NOPASSWD rule already exists"
    fi
fi

# Timezone configuration
echo ""
echo "--== Timezone configuration ==--"
if command -v timedatectl >/dev/null 2>&1 && timedatectl show >/dev/null 2>&1; then
    current_timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "Unknown")
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
                echo "No minor location provided, keeping current timezone"
            fi
        else
            echo "Keeping current timezone"
        fi
    else
        echo "Keeping current timezone: $current_timezone"
    fi
else
    current_timezone=$(cat /etc/timezone 2>/dev/null || echo "Unknown")
    echo "Current timezone: $current_timezone"
    echo -n "Do you want to change timezone [y/N]: "
    read -r answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    if [ "$answer" = "y" ]; then
        echo "Available major timezone locations:"
        ls /usr/share/zoneinfo | grep -v '\.' | sort -u
        read -p "Enter major timezone location (press Enter to keep current): " major_tz
        if [ -n "$major_tz" ] && [ -d "/usr/share/zoneinfo/$major_tz" ]; then
            echo "Available minor locations for $major_tz:"
            ls "/usr/share/zoneinfo/$major_tz" | grep -v '\.' | sort -u
            read -p "Enter minor timezone location: " minor_tz
            if [ -n "$minor_tz" ] && [ -f "/usr/share/zoneinfo/$major_tz/$minor_tz" ]; then
                timezone="$major_tz/$minor_tz"
                ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
                echo "$timezone" > /etc/timezone
                echo "Timezone changed to $timezone"
            else
                echo "Invalid timezone, keeping current"
            fi
        else
            echo "Invalid major timezone, keeping current"
        fi
    else
        echo "Keeping current timezone: $current_timezone"
    fi
fi

# OS version
echo ""
echo "--== OS version ==--"
cat /etc/os-release

# Hostname display
echo ""
echo "--== Hostname ==--"
if command -v hostnamectl >/dev/null 2>&1 && hostnamectl status >/dev/null 2>&1; then
    hostnamectl | grep "Static hostname" | awk '{print $3}'
else
    if [ -f /etc/hostname ]; then
        cat /etc/hostname
    else
        hostname
    fi
fi

# Hardware configuration
echo ""
echo "--== Hardware Configuration ==--"
echo -n "Do you want to list hardware configuration (Partitioning, RAM, WiFi, CPUs)? [y/N]: "
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

# Firmware update check
echo ""
echo "--== Firmware update check ==--"

# Install rpi-update if not present
if ! command -v rpi-update &>/dev/null; then
    echo "rpi-update not found, installing..."
    apt install -y rpi-update > /dev/null 2>&1 || true
    if command -v rpi-update &>/dev/null; then
        echo "rpi-update installed"
    else
        echo "rpi-update could not be installed, skipping firmware check."
    fi
else
    echo "rpi-update is already installed"
fi

if command -v rpi-update &>/dev/null; then
    echo ""

    # Show current revision from known file locations
    CURRENT_FW=""
    for fw_file in \
        /boot/firmware/.firmware_revision \
        /boot/.firmware_revision; do
        if [ -f "$fw_file" ]; then
            CURRENT_FW=$(cat "$fw_file" 2>/dev/null | tr -d '[:space:]' || true)
            [ -n "$CURRENT_FW" ] && break
        fi
    done
    if [ -n "$CURRENT_FW" ]; then
        echo "Current firmware revision : $CURRENT_FW"
    else
        echo "Current firmware revision : unable to determine"
    fi

    echo "Checking for firmware updates (this may take a moment)..."
    # JUST_CHECK=1 makes rpi-update check and report without applying anything
    # SKIP_BACKUP=1 prevents it from trying to write a backup during check
    FW_CHECK=$(JUST_CHECK=1 SKIP_BACKUP=1 rpi-update 2>&1 || true)

    if echo "$FW_CHECK" | grep -q "already up to date"; then
        echo "Firmware is up to date."
    elif echo "$FW_CHECK" | grep -q "update available\|would be updated\|Downloading"; then
        echo ""
        echo "      A firmware update is available!"
        echo ""
        echo "      NOTE: rpi-update installs pre-release firmware directly from GitHub."
        echo "      It is NOT the same as the stable firmware delivered via apt, and it"
        echo "      can confuse apt into thinking a downgrade is needed on next upgrade."
        echo "      Only use rpi-update if you need a specific fix or have been asked"
        echo "      to test pre-release firmware."
        echo ""
        echo "      To update firmware, run the following command and reboot:"
        echo "      sudo rpi-update"
    else
        echo "rpi-update check output:"
        echo "$FW_CHECK" | grep -v "^$" | head -20
        echo ""
        echo "      If an update is needed, run:"
        echo "      sudo rpi-update"
    fi
fi

# Wi-Fi rfkill configuration
if [ "$IS_DIETPI" = false ]; then
    echo ""
    echo "--== Wi-Fi configuration ==--"
    if ! command -v rfkill &>/dev/null; then
        apt install -y rfkill > /dev/null 2>&1 || { echo "Failed to install rfkill"; exit 1; }
        echo "rfkill installed"
    else
        echo "rfkill is already installed"
    fi

    # Show current rfkill status
    echo ""
    echo "--== Current Wi-Fi status ==--"
    rfkill list wifi

    # Detect current country code
    CURRENT_CC=""
    if command -v raspi-config >/dev/null; then
        CURRENT_CC=$(raspi-config nonint get_wifi_country 2>/dev/null || true)
    fi
    if [ -z "$CURRENT_CC" ] && [ -f /etc/wpa_supplicant/wpa_supplicant.conf ]; then
        CURRENT_CC=$(grep "^country=" /etc/wpa_supplicant/wpa_supplicant.conf | cut -d'=' -f2 | tr -d ' ' || true)
    fi
    if [ -z "$CURRENT_CC" ]; then
        CURRENT_CC="not set"
    fi
    echo "Current Wi-Fi country code: $CURRENT_CC"

    # Derive suggested CC from timezone
    current_timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo "Unknown")
    ZONETAB=/usr/share/zoneinfo/zone.tab
    SUGGESTED_CC=$(awk -v tz="$current_timezone" '$3 == tz {print $1}' $ZONETAB 2>/dev/null || true)
    if [ -n "$SUGGESTED_CC" ] && [ "$SUGGESTED_CC" != "$CURRENT_CC" ]; then
        echo "Suggested country code based on timezone ($current_timezone): $SUGGESTED_CC"
    fi

    # Ask about rfkill block if blocked
    if rfkill list wifi | grep -q "Soft blocked: yes"; then
        echo ""
        echo "Wi-Fi is currently soft-blocked by rfkill."
        echo -n "Do you want to remove the Wi-Fi rfkill block? [y/N]: "
        read -r answer
        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
        if [ "$answer" = "y" ]; then
            if command -v raspi-config >/dev/null; then
                raspi-config nonint do_wifi_country "${SUGGESTED_CC:-$CURRENT_CC}"
            else
                sed -i "/^country=/d" /etc/wpa_supplicant/wpa_supplicant.conf
                echo "country=${SUGGESTED_CC:-$CURRENT_CC}" | tee -a /etc/wpa_supplicant/wpa_supplicant.conf >/dev/null
                wpa_cli -i wlan0 reconfigure 2>/dev/null || true
            fi
            rfkill unblock wifi
            echo "Wi-Fi unblocked with country code: ${SUGGESTED_CC:-$CURRENT_CC}"
        fi
    else
        echo "Wi-Fi is not blocked."
    fi

    # Always ask about country code change, regardless of rfkill state
    echo ""
    echo -n "Do you want to change the Wi-Fi country code (currently: $CURRENT_CC)? [y/N]: "
    read -r answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    if [ "$answer" = "y" ]; then
        echo ""
        echo "Available country codes (2-letter ISO 3166-1)."
        echo "Common examples: US, GB, DE, FR, CA, AU, NL, SE, DK, NO, FI"
        if [ -n "$SUGGESTED_CC" ]; then
            echo "Suggested based on your timezone: $SUGGESTED_CC"
            read -e -p "Enter country code: " -i "$SUGGESTED_CC" NEW_CC
        else
            read -e -p "Enter country code: " NEW_CC
        fi
        NEW_CC=$(echo "$NEW_CC" | tr '[:lower:]' '[:upper:]' | tr -d ' ')
        if [ -n "$NEW_CC" ]; then
            if command -v raspi-config >/dev/null; then
                raspi-config nonint do_wifi_country "$NEW_CC"
            else
                sed -i "/^country=/d" /etc/wpa_supplicant/wpa_supplicant.conf
                echo "country=$NEW_CC" | tee -a /etc/wpa_supplicant/wpa_supplicant.conf >/dev/null
                wpa_cli -i wlan0 reconfigure 2>/dev/null || true
            fi
            echo "Wi-Fi country code set to: $NEW_CC"
        else
            echo "No country code entered, keeping current: $CURRENT_CC"
        fi
    fi
fi

# Sound output configuration
detect_config_path() {
    if [ "$IS_DIETPI" = true ]; then
        CNFFILE="/boot/firmware/config.txt"
        SECONDFILE=""
        echo "Detected DietPi ($DEBIAN_VERSION), using $CNFFILE"
    elif [ -f /boot/firmware/config.txt ]; then
        # Bookworm and Trixie both use /boot/firmware/config.txt
        CNFFILE="/boot/firmware/config.txt"
        SECONDFILE=""
        echo "Detected $DEBIAN_VERSION, using $CNFFILE"
    elif [ -f /boot/config.txt ]; then
        # Legacy fallback for very old Pi OS layouts
        CNFFILE="/boot/config.txt"
        SECONDFILE=""
        echo "Detected legacy boot path, using $CNFFILE"
    else
        echo "ERROR: Cannot find config.txt — are you running Raspberry Pi OS?"
        exit 1
    fi
}

# Attempt HAT detection via I2C before prompting user
detect_hat() {
    echo ""
    echo "--== Attempting automatic HAT detection via I2C ==--"
    if ! command -v i2cdetect &>/dev/null; then
        apt install -y i2c-tools > /dev/null 2>&1 || true
    fi
    modprobe i2c-dev 2>/dev/null || true

    HAT_HINT=""
    if command -v i2cdetect &>/dev/null; then
        # Bus 1 is standard on Pi 3/4/5
        I2C_OUT=$(i2cdetect -y 1 2>/dev/null || true)
        if echo "$I2C_OUT" | grep -q "4d"; then
            HAT_HINT="HiFiBerry DAC+, DAC2, or Allo Boss (I2C 0x4d detected)"
        elif echo "$I2C_OUT" | grep -q "60"; then
            HAT_HINT="HiFiBerry DAC2 HD (I2C 0x60 detected)"
        elif echo "$I2C_OUT" | grep -q "1a"; then
            HAT_HINT="HiFiBerry DAC+ ADC PRO (I2C 0x1a detected)"
        fi
    fi

    if [ -n "$HAT_HINT" ]; then
        echo "Possible HAT detected: $HAT_HINT"
        echo "This is a best-guess based on I2C address — verify before confirming."
    else
        echo "No HAT detected via I2C."
        echo "(Digi/SPDIF cards and USB audio devices won't appear here — this is expected.)"
    fi
}

# Write HAT overlay to config.txt
# Handles Pi 5 specific audio=off requirement
write_hat_config() {
    local overlay="$1"
    local f="$CNFFILE"

    # Remove any previous audio overlays to avoid conflicts
    sed -i '/dtoverlay=hifiberry/d' "$f"
    sed -i '/dtoverlay=allo/d' "$f"
    sed -i '/dtoverlay=justboom/d' "$f"
    sed -i '/dtoverlay=i-sabre/d' "$f"
    sed -i '/hdmi_force_hotplug=/d' "$f"
    sed -i '/hdmi_drive=/d' "$f"
    sed -i '/dtparam=audio=/d' "$f"
    sed -i '/hdmi_force_edid_audio=/d' "$f"
    sed -i '/dtoverlay=vc4-kms-v3d/d' "$f"

    # Pi 5 requires audio=off to avoid conflict with built-in audio
    if [ "$IS_PI5" = true ]; then
        grep -q "dtparam=audio=off" "$f" || echo "dtparam=audio=off" >> "$f"
    else
        grep -q "dtparam=audio=on" "$f" || echo "dtparam=audio=on" >> "$f"
    fi

    grep -q "dtoverlay=vc4-kms-v3d,noaudio" "$f" || echo "dtoverlay=vc4-kms-v3d,noaudio" >> "$f"
    grep -q "$overlay" "$f" || echo "$overlay" >> "$f"

    # Remove /etc/asound.conf — not needed for HATs
    if [ -f /etc/asound.conf ]; then
        rm /etc/asound.conf
        echo "Removed /etc/asound.conf (not needed for HAT configuration)"
    fi

    echo "Configured: $overlay"
    [ "$IS_PI5" = true ] && echo "Pi 5 detected: set dtparam=audio=off to avoid built-in audio conflict."
}

# Verify audio after configuration
verify_audio() {
    echo ""
    echo "--== Verifying audio configuration ==--"
    if command -v aplay &>/dev/null; then
        echo "Currently detected audio cards:"
        aplay -l 2>/dev/null || echo "No cards detected."
        echo ""
        echo "NOTE: HAT cards often do not appear until after a reboot."
        echo "If your HAT is missing from the list above, reboot and check with: aplay -l"
    fi
}

# Main sound configuration section
echo ""
echo "--== Sound output configuration ==--"
echo -n "Do you want to configure sound output (HiFiBerry, Allo, JustBoom, Audiophonics, HDMI, or USB Audio Dongle)? [y/N]: "
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

    # Detect config.txt path
    detect_config_path

    # Ensure config file exists
    if [ ! -f "$CNFFILE" ]; then
        mkdir -p "$(dirname "$CNFFILE")"
        touch "$CNFFILE"
        chmod 644 "$CNFFILE"
        echo "Created $CNFFILE"
    fi

    # Attempt I2C HAT detection
    detect_hat

    echo ""
    echo "--== Select audio configuration ==--"
    title="Select audio option:"
    prompt="Pick your option:"
    options=("HiFiBerry HAT" "Allo HAT" "JustBoom HAT" "Audiophonics HAT" "HDMI Audio" "USB Audio Dongle")
    echo "$title"
    PS3="$prompt "
    select opt in "${options[@]}" "Quit"; do
        case "$REPLY" in
        1)
            echo ""
            echo "--== Configuring HiFiBerry HAT ==--"
            echo "Select your HiFiBerry card:"
            hifi_options=(
                "DAC / DAC+ Light / Zero / MiniAmp / BeoCreate / DSP / RTC"
                "DAC+ Standard / Pro / AMP2"
                "DAC2 HD"
                "DAC+ ADC PRO"
                "Digi / Digi+"
                "Digi+ Pro"
                "Amp / Amp+"
                "Amp3"
            )
            PS3="Pick your HiFiBerry card: "
            select hifi_opt in "${hifi_options[@]}" "Quit"; do
                case "$REPLY" in
                1) HIFIBERRY="dtoverlay=hifiberry-dac";            echo "Selected: $hifi_opt";;
                2) HIFIBERRY="dtoverlay=hifiberry-dacplus";        echo "Selected: $hifi_opt";;
                3) HIFIBERRY="dtoverlay=hifiberry-dacplushd";      echo "Selected: $hifi_opt";;
                4) HIFIBERRY="dtoverlay=hifiberry-dacplusadcpro";  echo "Selected: $hifi_opt";;
                5) HIFIBERRY="dtoverlay=hifiberry-digi";           echo "Selected: $hifi_opt";;
                6) HIFIBERRY="dtoverlay=hifiberry-digi-pro";       echo "Selected: $hifi_opt";;
                7) HIFIBERRY="dtoverlay=hifiberry-amp";            echo "Selected: $hifi_opt";;
                8) HIFIBERRY="dtoverlay=hifiberry-amp3";           echo "Selected: $hifi_opt";;
                9) echo "Continuing without HiFiBerry selection"; break;;
                *) echo "Invalid option"; continue;;
                esac
                break
            done
            if [ -n "${HIFIBERRY:-}" ]; then
                write_hat_config "$HIFIBERRY"
            fi
            break
            ;;
        2)
            echo ""
            echo "--== Configuring Allo HAT ==--"
            echo "Select your Allo card:"
            allo_options=(
                "Piano HIFI DAC"
                "Piano 2.1 HIFI DAC"
                "Boss HIFI DAC / Mini Boss"
                "DIGIOne"
                "Boss2 Player"
            )
            PS3="Pick your Allo card: "
            select allo_opt in "${allo_options[@]}" "Quit"; do
                case "$REPLY" in
                1) DIGICARD="dtoverlay=allo-piano-dac-pcm512x-audio";      echo "Selected: $allo_opt";;
                2) DIGICARD="dtoverlay=allo-piano-dac-plus-pcm512x-audio"; echo "Selected: $allo_opt";;
                3) DIGICARD="dtoverlay=allo-boss-dac-pcm512x-audio";       echo "Selected: $allo_opt";;
                4) DIGICARD="dtoverlay=allo-digione";                       echo "Selected: $allo_opt";;
                5) DIGICARD="dtoverlay=allo-boss2-dac-audio";              echo "Selected: $allo_opt";;
                6) echo "Continuing"; break;;
                *) echo "Invalid option"; continue;;
                esac
                break
            done
            if [ -n "${DIGICARD:-}" ]; then
                write_hat_config "$DIGICARD"
            fi
            break
            ;;
        3)
            echo ""
            echo "--== Configuring JustBoom HAT ==--"
            echo "Select your JustBoom card:"
            justboom_options=(
                "DAC and Amp cards"
                "Digi cards"
            )
            PS3="Pick your JustBoom card: "
            select justboom_opt in "${justboom_options[@]}" "Quit"; do
                case "$REPLY" in
                1) DIGICARD="dtoverlay=justboom-dac";  echo "Selected: $justboom_opt";;
                2) DIGICARD="dtoverlay=justboom-digi"; echo "Selected: $justboom_opt";;
                3) echo "Continuing"; break;;
                *) echo "Invalid option"; continue;;
                esac
                break
            done
            if [ -n "${DIGICARD:-}" ]; then
                write_hat_config "$DIGICARD"
            fi
            break
            ;;
        4)
            echo ""
            echo "--== Configuring Audiophonics HAT ==--"
            echo "Select your Audiophonics card:"
            audio_options=(
                "I-SABRE 9038Q2M HIFI DAC"
            )
            PS3="Pick your Audiophonics card: "
            select audio_opt in "${audio_options[@]}" "Quit"; do
                case "$REPLY" in
                1) DIGICARD="dtoverlay=i-sabre-q2m"; echo "Selected: $audio_opt";;
                2) echo "Continuing"; break;;
                *) echo "Invalid option"; continue;;
                esac
                break
            done
            if [ -n "${DIGICARD:-}" ]; then
                write_hat_config "$DIGICARD"
            fi
            break
            ;;
        5)
            echo ""
            echo "--== Configuring HDMI audio ==--"
            f="$CNFFILE"
            sed -i '/dtoverlay=hifiberry/d;/dtoverlay=allo/d;/dtoverlay=justboom/d;/dtoverlay=i-sabre/d;/hdmi_force_hotplug=/d;/hdmi_drive=/d;/dtparam=audio=/d;/hdmi_force_edid_audio=/d;/dtoverlay=vc4-kms-v3d/d' "$f"
            grep -q "hdmi_force_hotplug=1"   "$f" || echo "hdmi_force_hotplug=1"   >> "$f"
            grep -q "hdmi_drive=2"           "$f" || echo "hdmi_drive=2"           >> "$f"
            grep -q "hdmi_force_edid_audio=1" "$f" || echo "hdmi_force_edid_audio=1" >> "$f"
            grep -q "dtoverlay=vc4-kms-v3d"  "$f" || echo "dtoverlay=vc4-kms-v3d"  >> "$f"
            echo "Configured HDMI audio"
            if [ -f /etc/asound.conf ]; then
                rm /etc/asound.conf
                echo "Removed /etc/asound.conf (not needed for HDMI)"
            fi
            break
            ;;
        6)
            echo ""
            echo "--== Configuring USB Audio Dongle ==--"
            f="$CNFFILE"
            sed -i '/dtoverlay=hifiberry/d;/dtoverlay=allo/d;/dtoverlay=justboom/d;/dtoverlay=i-sabre/d;/hdmi_force_hotplug=/d;/hdmi_drive=/d;/dtparam=audio=/d;/hdmi_force_edid_audio=/d;/dtoverlay=vc4-kms-v3d/d' "$f"
            grep -q "dtoverlay=vc4-kms-v3d" "$f" || echo "dtoverlay=vc4-kms-v3d" >> "$f"
            grep -q "dtparam=audio=on"       "$f" || echo "dtparam=audio=on"       >> "$f"

            # Detect USB audio card by name for reboot stability
            echo ""
            echo "--== Detected USB audio devices ==--"
            USB_DEVICES=$(aplay -l 2>/dev/null | grep -i "usb" || true)
            if [ -z "$USB_DEVICES" ]; then
                echo "WARNING: No USB audio device detected right now."
                echo "Plug it in before running this section for best results."
                echo "Proceeding with fallback configuration (card index 1)."
                USB_CARD_NAME=""
            else
                echo "$USB_DEVICES"
                # Extract the card short name (3rd field) for use in asound.conf
                # Using card name is more stable than index across reboots
                USB_CARD_NAME=$(aplay -l 2>/dev/null | grep -i "usb" | head -1 | sed 's/.*\[\(.*\)\].*/\1/' | tr -d ' ' || true)
                USB_CARD_NUM=$(aplay -l 2>/dev/null | grep -i "usb" | head -1 | awk '{print $2}' | tr -d ':' || true)
                echo "Using card: $USB_CARD_NAME (card $USB_CARD_NUM)"
            fi

            if [ -n "$USB_CARD_NAME" ]; then
                cat > /etc/asound.conf << EOF
# Plexamp USB Audio configuration
# Auto-generated by PlexAmp installer
# Uses card name ($USB_CARD_NAME) for stability across reboots
# If audio stops working after a reboot, re-run the installer sound section

pcm.!default {
    type hw
    card $USB_CARD_NAME
    device 0
}

ctl.!default {
    type hw
    card $USB_CARD_NAME
}
EOF
                echo "Created /etc/asound.conf using card name: $USB_CARD_NAME"
            else
                cat > /etc/asound.conf << EOF
# Plexamp USB Audio configuration - fallback
# No USB device was detected at install time.
# Verify card number with 'aplay -l' after plugging in your device,
# then update the card number below accordingly.

pcm.!default {
    type hw
    card 1
    device 0
}

ctl.!default {
    type hw
    card 1
}
EOF
                echo "WARNING: Created fallback asound.conf using card index 1."
                echo "Verify with 'aplay -l' after plugging in your USB device and update /etc/asound.conf if needed."
            fi
            break
            ;;
        7)
            echo "Skipping audio configuration"
            break
            ;;
        *) echo "Invalid option"; continue;;
        esac
    done

    # Cleanup: remove extra blank lines from config file
    [ -n "$CNFFILE" ] && [ -f "$CNFFILE" ] && sed -i '/^[[:space:]]*$/d' "$CNFFILE"

    # Verify audio after configuration
    verify_audio

else
    echo "Skipping sound output configuration"
fi

# Possible Audio enhancements
echo ""
echo "--== Possible Audio Enhancement Tricks ==--"
echo "     The Raspberry Pi 5 can be noisier than older versions of the Raspberry Pi"
echo "     due to these Raspberry Pi 5 introductions:"
echo "     - Faster CPU"
echo "     - PCIe controller"
echo "     - Higher switching currents"
echo "     - More aggressive power management"
echo ""
echo "     These factors create more broadband RF noise inside the board compared to earlier versions."
echo ""
echo "     NOTE: These enhancements are most effective for HAT DAC and USB audio users."
echo "           HDMI audio is a fully digital signal and is inherently immune to power rail"
echo "           and RF noise — these tweaks will have no audible effect for HDMI audio users."
echo ""
echo -n "Do you want to set or remove additional audio enhancements? [y/N]: "
read -r answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then

    # Detect config.txt path if not already set (in case sound section was skipped)
    if [ -z "${CNFFILE:-}" ]; then
        detect_config_path
    fi

    # Detect current audio output type for context-aware advice
    AUDIO_TYPE="unknown"
    if [ -n "${CNFFILE:-}" ] && [ -f "$CNFFILE" ]; then
        if grep -q "hdmi_force_hotplug" "$CNFFILE" 2>/dev/null; then
            AUDIO_TYPE="hdmi"
        elif grep -q "dtoverlay=hifiberry\|dtoverlay=allo\|dtoverlay=justboom\|dtoverlay=i-sabre" "$CNFFILE" 2>/dev/null; then
            AUDIO_TYPE="hat"
        elif [ -f /etc/asound.conf ] && grep -q "USB" /etc/asound.conf 2>/dev/null; then
            AUDIO_TYPE="usb"
        fi
    fi

    if [ "$AUDIO_TYPE" = "hdmi" ]; then
        echo ""
        echo "      Detected HDMI audio configuration."
        echo "      HDMI transmits audio as a fully digital signal — it is inherently immune"
        echo "      to power rail switching noise and RF interference from WiFi/Bluetooth."
        echo "      The enhancements below will have no audible effect for HDMI audio."
        echo "      Continuing anyway in case your setup has changed since audio was configured."
        echo ""
    fi

    # WiFi and Bluetooth
    echo ""
    echo "      Disabling WiFi and Bluetooth removes RF interference from the 2.4GHz radio"
    echo "      which shares a chip on the Pi and can bleed into the I2S bus and power rails"
    echo "      used by HAT DACs and USB audio devices."
    if [ "$AUDIO_TYPE" = "hdmi" ]; then
        echo "      For HDMI audio this is unlikely to have any audible effect."
    fi
    echo "      Only recommended if your Pi is on wired ethernet."
    echo ""

    WIFI_BT_DISABLED=false
    if grep -q "dtoverlay=disable-wifi" "$CNFFILE" 2>/dev/null; then
        WIFI_BT_DISABLED=true
    fi

    if [ "$WIFI_BT_DISABLED" = false ]; then
        echo -n "Do you want to disable WiFi and Bluetooth to remove possible switching noise? [y/N]: "
        read -r answer
        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
        if [ "$answer" = "y" ]; then
            grep -q "dtoverlay=disable-wifi" "$CNFFILE" || echo "dtoverlay=disable-wifi" >> "$CNFFILE"
            grep -q "dtoverlay=disable-bt"   "$CNFFILE" || echo "dtoverlay=disable-bt"   >> "$CNFFILE"
            echo "WiFi and Bluetooth disabled. Reboot to activate."
            echo ""
        fi
    else
        echo "WiFi and Bluetooth are currently disabled."
        echo -n "Do you want to re-enable WiFi and Bluetooth? [y/N]: "
        read -r answer
        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
        if [ "$answer" = "y" ]; then
            sed -i '/dtoverlay=disable-wifi/d' "$CNFFILE"
            sed -i '/dtoverlay=disable-bt/d'   "$CNFFILE"
            echo "WiFi and Bluetooth re-enabled. Reboot to activate."
            echo ""
        fi
    fi

# CPU frequency governor
    echo ""
    echo "      Setting the CPU governor to powersave locks the CPU to its minimum frequency,"
    echo "      eliminating switching spikes on the power rail caused by CPU frequency changes."
    echo "      This is most effective for USB audio dongles which share the Pi's power rail"
    echo "      directly, and for HAT DACs on Pi 5 which has more aggressive power management."

# Check current state BEFORE printing the prompt
    CPU_POWERSAVE=false
    if [ -f /etc/default/cpufrequtils ] && grep -q 'GOVERNOR="powersave"' /etc/default/cpufrequtils; then
        CPU_POWERSAVE=true
    fi

    if [ "$CPU_POWERSAVE" = false ]; then
        if [ "$AUDIO_TYPE" = "hdmi" ]; then
            echo ""
            echo "      HDMI audio is fully digital and immune to power rail noise."
            echo "      This setting will have no audible effect for HDMI audio users and is"
            echo "      not recommended as it reduces CPU performance for no audio benefit."
            echo -n "Do you want to set the CPU governor to powersave anyway? [y/N]: "
        elif [ "$AUDIO_TYPE" = "usb" ]; then
            echo "      USB audio shares the Pi's 5V rail directly — this is the most"
            echo "      impactful setting for USB audio dongles."
            echo ""
            echo -n "Do you want to set the CPU governor to powersave? [y/N]: "
        else
            echo ""
            echo -n "Do you want to set the CPU governor to powersave? [y/N]: "
        fi
        read -r answer
        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
        if [ "$answer" = "y" ]; then
            apt install -y cpufrequtils > /dev/null 2>&1 || true
            echo 'GOVERNOR="powersave"' > /etc/default/cpufrequtils
            if command -v cpufreq-set &>/dev/null; then
                for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
                    cpufreq-set -c "${cpu##*cpu}" -g powersave 2>/dev/null || true
                done
                echo "CPU frequency governor set to powersave (active now and on reboot)."
            else
                for gov in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
                    echo "powersave" > "$gov" 2>/dev/null || true
                done
                echo "CPU frequency governor set to powersave via sysfs (active now and on reboot)."
            fi
        fi
    else
        echo ""
        echo "CPU frequency governor is currently set to powersave."
        echo -n "Do you want to re-enable dynamic CPU frequency scaling? [y/N]: "
        read -r answer
        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
        if [ "$answer" = "y" ]; then
            rm -f /etc/default/cpufrequtils
            if command -v cpufreq-set &>/dev/null; then
                for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
                    cpufreq-set -c "${cpu##*cpu}" -g ondemand 2>/dev/null || true
                done
                echo "CPU frequency governor restored to ondemand (active now and on reboot)."
            else
                for gov in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
                    echo "ondemand" > "$gov" 2>/dev/null || true
                done
                echo "CPU frequency governor restored to ondemand via sysfs (active now and on reboot)."
            fi
        fi
    fi
fi

# vim configuration
echo ""
echo "--== Installing and configuring vim ==--"
echo -n "Do you want to install and set vim as default editor [y/N]: "
read -r answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    if ! command -v vim &>/dev/null; then
        apt install -y vim > /dev/null 2>&1
        echo "vim installed"
    else
        echo "vim is already installed"
    fi
    if ! update-alternatives --get-selections | grep -q "editor.*vim.basic"; then
        update-alternatives --set editor /usr/bin/vim.basic
        echo "Set vim as default editor"
    else
        echo "vim is already set as default editor"
    fi
fi

# IPv6 configuration (non-DietPi)
if [ "$IS_DIETPI" = false ]; then
    echo ""
    echo "--== IPv6 configuration ==--"
    echo -n "Do you want to disable IPv6 [y/N]: "
    read -r answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    if [ "$answer" = "y" ]; then
        echo ""
        echo "--== Disabling IPv6 ==--"
        if [ ! -f /etc/sysctl.d/disable-ipv6.conf ]; then
            cat > /etc/sysctl.d/disable-ipv6.conf << EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
            sysctl -p /etc/sysctl.d/disable-ipv6.conf
            echo "IPv6 disabled"
        else
            echo "IPv6 already disabled"
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
    ps ax | grep index.js | grep -v grep | awk '{print $1}' | xargs kill > /dev/null 2>&1 || true
    rm -rf /home/"$USER"/plexamp /home/"$USER"/Plexamp-Linux-*
    su - "$USER" -c "systemctl --user stop plexamp.service"    > /dev/null 2>&1 || true
    su - "$USER" -c "systemctl --user disable plexamp.service" > /dev/null 2>&1 || true
    rm -f /home/"$USER"/.config/systemd/user/plexamp.service
    systemctl stop plexamp.service    > /dev/null 2>&1 || true
    systemctl disable plexamp.service > /dev/null 2>&1 || true
    rm -f /etc/systemd/system/plexamp.service
    echo "Cleanup completed"
fi

# Node.js installation
echo ""
echo "--== Installing Node.js v$NODE_MAJOR ==--"
echo "--== It is mandatory to install Node.js prior to installing Plexamp initially ==--"
echo "--== If already installed, it can be skipped ==--"
echo "--== If minor upgrade of Node.js is needed, running full OS update at the end will update to next minor version ==--"
echo ""
echo -n "Do you want to install/upgrade Node.js v$NODE_MAJOR? [y/N]: "
read -r answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
    if ! dpkg -l | grep -q gnupg; then
        apt install -y gnupg
    fi
    apt-mark unhold nodejs > /dev/null 2>&1 || true
    apt purge -y nodejs npm > /dev/null 2>&1 || true
    rm -rf /etc/apt/sources.list.d/nodesource.list \
           /etc/apt/keyrings/nodesource.gpg \
           /etc/apt/preferences.d/preferences
    apt update
    mkdir -p /etc/apt/keyrings /etc/apt/preferences.d
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" \
        | tee /etc/apt/sources.list.d/nodesource.list
    echo -e "Package: nodejs\nPin: origin deb.nodesource.com\nPin-Priority: 1001" \
        > /etc/apt/preferences.d/preferences
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
        apt install -y wget || { echo "Failed to install wget"; exit 1; }
        echo "wget installed"
    else
        echo "wget is already installed"
    fi
    if ! command -v lbzip2 &>/dev/null; then
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
    chown -R "$USER":"$USER" \
        /home/"$USER"/plexamp \
        /home/"$USER"/.local \
        /home/"$USER"/Plexamp-Linux-headless-*
    rm -f /home/"$USER"/"$PLEXAMPVB".tar.bz2

    if [ "$IS_DIETPI" = true ]; then
        echo "--== Creating system-level plexamp.service for DietPi ==--"
        cat > /etc/systemd/system/plexamp.service << EOF
[Unit]
Description=Plexamp Headless (System Service)
After=network-online.target nss-lookup.target
Wants=network-online.target nss-lookup.target

[Service]
User=$USER
Group=$USER
Environment=CLIENT_NAME=$(hostname -s)
ExecStartPre=/bin/bash -c 'for i in \$(seq 1 30); do getent hosts plex.tv > /dev/null 2>&1 && break || sleep 2; done'
ExecStart=/bin/bash -c 'export CLIENT_NAME=$(hostname -s); exec /usr/bin/node /home/$USER/plexamp/js/index.js'
WorkingDirectory=/home/$USER/plexamp
Restart=on-failure
RestartSec=10
KillSignal=SIGINT
TimeoutStopSec=5

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
Description=Plexamp Headless (User Service)
After=network-online.target nss-lookup.target
Wants=network-online.target nss-lookup.target

[Service]
Environment=CLIENT_NAME=$(hostname -s)
ExecStartPre=/bin/bash -c 'for i in \$(seq 1 30); do getent hosts plex.tv > /dev/null 2>&1 && break || sleep 2; done'
ExecStart=/bin/bash -c 'export CLIENT_NAME=\$(hostname -s); exec /usr/bin/node /home/$USER/plexamp/js/index.js'
WorkingDirectory=/home/$USER/plexamp
Restart=on-failure
RestartSec=10
KillSignal=SIGINT
TimeoutStopSec=5

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
        echo "[ -f /home/$USER/.plexamp_setup.sh ] && /home/$USER/.plexamp_setup.sh" \
            >> /home/"$USER"/.profile
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

# End of script
echo "Script completed successfully"
echo ""
echo "--== End of Post-PlexAmp-script, do not reboot yet if this was a fresh install ==--"
echo ""
echo "      Configuration post-install:"
echo "      Note !! Run PlexAmp for the first time after initial installation to manually add the claim token."
echo "      As user $USER, please run the following command:"
echo "      node /home/$USER/plexamp/js/index.js"
echo ""
echo "      Visit https://plex.tv/claim, copy the claim code, paste it in the Terminal, and follow the prompts."
echo "      At this point, Plexamp is now signed in and ready."
echo ""
echo "      NOTE!! A reboot and re-login as user $USER is at this point needed to automatically create the symlink for autostart."
echo "      Please go ahead and issue a reboot at this point and login as user $USER."
echo "      The re-login after reboot is not needed on DietPi, since it is a system-service there."
echo ""
echo "      The Plexamp service has now been automatically enabled and started."
echo "      You can verify the service with: systemctl --user status plexamp.service"
echo "      On DietPi, it is a system service, use: sudo systemctl status plexamp.service"
echo ""
echo "      The web-GUI should be available on http://hostname:32500 from a browser."
echo "      Replace the hostname with IP address in this example with your own."
echo "      On that GUI you will be asked to login to your Plex-account for security-reasons,"
echo "      and then choose a library where to fetch/stream music from."
echo "      If not asked to login, then go to 'settings' > 'account' and sign out."
echo "      Now sign back in, then click on the 'cast' icon and re-select the headless player."
echo ""
echo "      If web-GUI is not accessible after following above, try rebooting once more, and then load the GUI."
echo ""
echo "      If using a HAT, it is possible you need to select it via:"
echo "      Settings (cogwheel lower right corner) >> Playback >> Audio output >> Audio Device."
echo "      As an example, if you have chosen the 'Digi/Digi+' option during install in the script,"
echo "      pick 'Default' if the card is not showing, reboot the pi. Now the card will show up in the list,"
echo "      and at this point you can choose it!"
echo ""
echo "      Now play some music! Or control it from any other instance of Plexamp."
echo ""
echo "      NOTE!! For upgrades from an older version, a second reboot might be needed to automatically create the symlink for autostart."
echo "      Please go ahead and issue a reboot to create this symlink."
echo "      This is not needed on DietPi, since it is a system-service there."
echo "      The login-tokens are preserved. All should work at this point."
echo ""
echo "      Logs are located at: ~/.cache/Plexamp/log/Plexamp.log"
echo ""
