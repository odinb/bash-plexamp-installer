# PlexAmp-installer for Raspberry Pi with armv7l HW.

This is based on the "2020-08-20-raspios-buster-armhf-lite" image.

Release-notes: https://forums.plex.tv/t/plexamp-for-raspberry-pi-release-notes/368282

This script will install NodeJS 9, configure HiFiBerry-HAT if you choose to, or set HDMI-as default for audio out, and installs Plexamp-v2.0.0-rPi-beta.2.

The soundcard used for testing: https://www.fasttech.com/p/5137000

Burn the OS-image to the Micro-SD card using etcher (or app of your choice).
 
How to enable SSH:
For security reasons, as of the November 2016 release, Raspbian has the SSH server disabled by default. You will have to enable it manually.
1. Mount your SD card on your computer.
2. Create or copy a file called ssh in /boot.

On most Linux-distros, after re-mount of micro-SD-card, run:
touch /media/$user/boot/ssh

On MacOS, after re-mount of micro-SD-card, run:
touch /Volumes/boot/ssh

Then unmount and insert card into Raspberry Pi and boot it.

After SSH-ing to it and logged in, Change to root (sudo -i) and run script with:

bash <(wget -qO- https://raw.githubusercontent.com/odinb/bash-plexamp-installer/main/install_Plexamp_pi.sh)


SSH access:
User: pi
Password: raspberry
