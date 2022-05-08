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


### Get working server with "server.json"

To get working server:
You will need to copy the token to "/home/MyUser/.config/Plexamp/server.json".
Optionally you can edit it with your custom values during install.
This file can currently only be extracted from a running installation of an older version of PlexAmp v1.x.x for MacOS/Windows.

On MacOS, the token is located under: "/System/Volumes/Data/Users/MyUser/Library/Application Support/Plexamp/server.json" after logging in.
On Windows, the token is located under: "c:\Users\MyUser\AppData\Local\Plexamp\server.json" after logging in.
Please remember to substitute MyUser for your actual username!

The installer-files can still be found for MacOs at: https://plexamp.plex.tv/plexamp.plex.tv/Plexamp-1.1.0.dmg
For Windows at: https://plexamp.plex.tv/plexamp.plex.tv/Plexamp%20Setup%201.1.0.exe

After adding/updating with your name/identifier/id/token, restart the PlexAmp service with command: "systemctl restart plexamp".
Once done, you can cast to it from existing Plex/PlexAmp instances!

Please remember, you need to remove/delete the Plexamp folder from your MacOS/Windows installation, or logout/re-login on your MacOS/Windows
installation to generate new tokens, or you will get weird behaviour, and end up with a non-functioning PlexAmp due to 2 or more clients
using the same ID/tokens!

If the service (systemctl status plexamp) is not starting with error: "code=exited, status=1/FAILURE",
it is most likely due to invalid configuration in "/home/MyUser/.config/Plexamp/server.json"
Fix the errors in the "server.json" file, and restart the service ("systemctl restart plexamp").

### Re-running the script

The script can be re-run to fix configuration/setup errors, just say no/bypass the sections you do not want to re-run!

For hostname-change, please make sure to reboot in-between, or you might face issues.
