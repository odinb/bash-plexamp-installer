# PlexAmp-installer for Raspberry Pi with ARMv7 & ARMv8 HW.

For more information and hardware used, see here:<br /> https://github.com/odinb/bash-plexamp-installer/wiki

## Burning the image.
Burn the OS-image to the Micro-SD card using etcher (or app of your choice).

This will currently only work with 64-bit capable Raspberry Pi and Pi OS that is 64-bit.
Images for Bullseye can be found here:
https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-64-bit

### Enable SSH.
How to enable SSH:<br />
For security reasons, as of the November 2016 release, Raspbian has the SSH server disabled by default. You will have to enable it manually.
1. Mount your SD card on your computer.
2. Create or copy a file called ssh in /boot. 
On most Linux-distros, after re-mount of micro-SD-card, run: "touch /media/$user/boot/ssh".
On MacOS, after re-mount of micro-SD-card, run: "touch /Volumes/boot/ssh".

Then unmount and insert card into Raspberry Pi and boot it.

SSH access on "Raspberry Pi OS": User/pass: pi/raspberry<br />
SSH access on "DietPi OS": User/pass: root/dietpi<br />

After SSH-ing to the SBC, on the "Raspberry Pi OS", change to root ("sudo -i") and run script with:

```bash <(wget -qO- https://raw.githubusercontent.com/odinb/bash-plexamp-installer/main/install_Plexamp_pi.sh)```


### Re-running the script

The script can be re-run to fix configuration/setup errors, just say no/bypass the sections you do not want to re-run!

For hostname-change, please make sure to reboot in-between, or you might face issues.
