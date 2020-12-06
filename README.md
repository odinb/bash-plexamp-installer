# PlexAmp-installer for Raspberry Pi with armv7l HW.

This is based on the "2020-08-20-raspios-buster-armhf-lite" image.

Burn the OS-image to the Micro-SD card using etcher (or app of your choice).
 
How to enable SSH:
For security reasons, as of the November 2016 release, Raspbian has the SSH server disabled by default. You will have to enable it manually.
1. Mount your SD card on your computer.
2. Create or copy a file called ssh in /boot.

On MacOS, after re-mount of micro-SD-card, run:
touch /Volumes/boot/ssh

Change to root (sudo -i) and run script with:
bash <(wget http://mywebsite.com/myscript.txt)


SSH access:
User: pi
Password: raspberry

This script will install NodeJS 9, configure HiFiBerry-HAT if you choose to, or set HDMI-as default for audio out, and installs PlexAmp.
Card used for testing is this: https://www.fasttech.com/p/5137000
