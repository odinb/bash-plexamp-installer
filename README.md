# PlexAmp-installer for Raspberry Pi with ARMv7 & ARMv8 HW.

For more information and hardware used, see here:<br /> https://github.com/odinb/bash-plexamp-installer/wiki

## Burning the image.
Burn the OS-image to the Micro-SD card using etcher (or app of your choice).

This will currently only work with 64-bit capable Raspberry Pi and Pi OS that is 64-bit.
Images for Bullseye can be found here:
https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-64-bit

### Enable SSH.
How to enable SSH:<br />
For security reasons, as of the November 2016 release, Raspbian OS has the SSH server disabled by default. You will have to enable it manually.
1. Mount your SD card on your computer.
2. Create or copy a file called ssh in /boot. 
On most Linux-distros, after re-mount of micro-SD-card, run: ```touch /media/$user/boot/ssh```.
On MacOS, after re-mount of micro-SD-card, run: ```touch /Volumes/boot/ssh```.

Then unmount and insert card into Raspberry Pi and boot it.

SSH access on "Raspberry Pi OS": User/pass: pi/raspberry<br />
SSH access on "DietPi OS": User/pass: root/dietpi<br />

After SSH-ing to the SBC, on the "Raspberry Pi OS", change to root (```sudo -i```) and run script with:

```bash <(wget -qO- https://raw.githubusercontent.com/odinb/bash-plexamp-installer/main/install_Plexamp_pi.sh)```

### Post-install and post-reboot tasks
After reboot, as your regular user please run the command:

```node /home/USER/plexamp/js/index.js```
where USER is your user, normally pi.
At this point, go to the URL provided in response, and enter the claim token at prompt.

Once entered, the web-GUI should be available on the ip-of-plexamp-pi:32500 from a browser.
On that GUI you will be asked to login to your Plex-acoount for security-reasons,
and then choose a librabry where to fetch/stream music from.

Now play some music! Or control it from any other instance of Plexamp.

Start and enable the Plexamp service if you feel like having it start on boot!
Hit ctrl+c to stop process, then enter:

```systemctl --user enable plexamp.service && systemctl --user start plexamp.service```

### Re-running the script

The script can be re-run to fix configuration/setup errors, just say no/bypass the sections you do not want to re-run!

For hostname-change, please make sure to reboot in-between, or you might face issues.
