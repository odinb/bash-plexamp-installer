# PlexAmp-installer for Raspberry Pi with armv7l HW.

This is based on the "2020-08-20-raspios-buster-armhf-lite" image.

This script will install NodeJS 9, configure HiFiBerry-HAT if you choose to, or set HDMI-as default for audio out, and installs Plexamp-v2.0.0-rPi-beta.2.

Release-notes: https://forums.plex.tv/t/plexamp-for-raspberry-pi-release-notes/368282

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

=====================================

To get working server, you need to:
copy "server.json" to "/home/$USER/.config/Plexamp" folder.
Optionally you can edit it with your custom values during install.
This file can currently only be extracted from a running installation of an older version of PlexAmp v1.x.x for MacOS/Windows.
On MacOS, the token is located under: /System/Volumes/Data/Users/MyUser/Library/Application Support/Plexamp after logging in.
On Windows, the token is located under: c:\Users\MyUser\AppData\Local\Plexamp\server.json after logging in.
Please remember to substitute MyUser for your actual username!

The installer-files can still be found for MacOs at: https://plexamp.plex.tv/plexamp.plex.tv/Plexamp-1.1.0.dmg
For Windows at: https://plexamp.plex.tv/plexamp.plex.tv/Plexamp%20Setup%201.1.0.exe

After adding/updating with your name/identifier/id/token, restart the PlexAmp service with command: systemctl restart plexamp
Once done, you can cast to it from existing Plex/PlexAmp instances!

Please remember, you need to remove/delete the Plexamp folder from your MacOS/Windows installation,
or you will get weird behaviour, and end up with a non-functioning PlexAmp due to 2 or more clients using the same ID/tokens!

If the service (systemctl status plexamp) is not starting with error: code=exited, status=1/FAILURE,
it is most likely due to invalid configuration in /home/$USER/.config/Plexamp/server.json
Fix the server.json file, and restart the service (systemctl restart plexamp).
