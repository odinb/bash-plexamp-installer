# PlexAmp-installer for Raspberry Pi with ARMv8, 64-bit HW.

For more information and hardware used, see here:<br /> https://github.com/odinb/bash-plexamp-installer/wiki

Assumes 64-bit capable Raspberry Pi HW and Pi OS that is 64-bit.

Currently installs/upgrades to: Plexamp-Linux-headless-v4.3.0

## Burning the image.
Burn the OS-image to the Micro-SD card using Raspberry pi imager, etcher (or app of your choice).

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

SSH access on "Raspberry Pi OS": (2022-04-04) To set up a user on first boot on headless, create a file called userconf or userconf.txt in the boot partition of the SD card.
This file should contain a single line of text, consisting of username:encrypted-password – so your desired username, followed immediately by a colon, followed immediately by an encrypted representation of the password you want to use.

To generate the encrypted password, the easiest way is to use OpenSSL on a Raspberry Pi that is already running (or most any linux you have running) – open a terminal window and enter:
```echo ‘mypassword’ | openssl passwd -6 -stdin```

This will produce what looks like a string of random characters, which is actually an encrypted version of the supplied password.<br />

SSH access on "DietPi OS" as user: dietpi/dietpi and as root: root/dietpi<br />
NOTE!!! DietPi is best-effort, and might not work.

After SSH-ing to the SBC, on the "Raspberry Pi OS", change to root (```sudo -i```) and run script with:

```bash <(wget -qO- https://raw.githubusercontent.com/odinb/bash-plexamp-installer/main/install_Plexamp_pi.sh)```

### Post-install and post-reboot tasks
Note !! Only needed if fresh install, not if upgrading. Tokens are preserved during upgrade.
After reboot, as your regular user please run the command:

```node /home/USER/plexamp/js/index.js```
where USER is your user, normally pi.
Now, go to the URL provided in response, and enter the claim token at prompt.
Please give the player a name at prompt (can be changed via Web-GUI later).
At this point, Plexamp is now signed in and ready, but not running!

Now either start Plexamp manually using: ```node /home/"$USER"/plexamp/js/index.js```
or enable the service and then start the Plexamp service.
If process is running, hit ctrl+c to stop process, then enter:
```systemctl --user enable plexamp.service && systemctl --user start plexamp.service```
On DietPi: ```sudo systemctl enable plexamp.service && sudo systemctl start plexamp.service```

Once done, the web-GUI should be available on the ip-of-plexamp-pi:32500 from a browser.
On that GUI you will be asked to login to your Plex-acoount for security-reasons, and then choose a librabry where to fetch/stream music from.

Wherever possible, you should choose output device via the script (gets set in "/boot/config.txt") when installing, to make it default system-wide.
If you have audio-problems, or want to choose output after install, go to the web-GUI.
Here the menu is found via: Settings (cogwheel lower right corner) >> Playback >> Audio output >> Audio Device.
As an example, if you have chosen the “ Digi/Digi+“ option during install in the script, pick “Default” if the card is not showing, then reboot the pi. Now the card will show up in the list, and you can choose it!

Now play some music! Or control it from any other instance of Plexamp.


### Re-running the script

The script can be re-run to fix configuration/setup errors, just say no/bypass the sections you do not want to re-run!

If there is a new version, and script has been updated, you can upgrade by re-running the script, and reboot.

For hostname-change, please make sure to reboot in-between, or you might face issues.

### Q & A

Q: The rPi will show up in my cast list. However the moment I select a song to play, it either keeps loading forever (black screen with loading circle) or it flips back to the album overview without starting the selected song. This is the case for all file types tried.

A: Go into the plexamp settings (via the web UI) and select the right audio output device. Rebooting the rPI a second time sometimes also helps (or restarting/veirfying the PlexAmp service), this of course will only help if correct audio device is already chosen.
(```systemctl --user restart plexamp.service && systemctl --user status plexamp.service```)

======

Q:
When starting Plexamp (4.3.0), I get this:
Starting Plexamp 4.3.0 DEVICE: No provider for source 80df67e4336a1a1c9911d2b4b6b4133c9f7d4cab
Any idea what this is about?

A:
You need to choose your source, i.e. Plex server or TIDAL other. This can be done from the GUI.

Q:
I got an error during the first Plexamp install and start up:

xxx@PlexampPi:~ $ node /home/xxx/plexamp/js/index.js
Starting Plexamp 4.3.0
Please visit https://plex.tv/claim and enter the claim token: claim-xxxxxxxxxxxxxxxxxxxx
Please give the player a name (e.g. Bedroom, Kitchen): Marantz
DEVICE: Error loading cloud players from plex.tv HTTP status 403

A:
That is not a bad thing per se, it just means you didn’t link any “cloud players”.
See also:
https://forums.plex.tv/t/plexamp-headless-not-playing-music/809078/21?u=odinb1

Q:
When I execute the following commands I get:

xxx@PlexampPi:~ $ systemctl --user enable plexamp.service && systemctl --user start plexamp.service
Created symlink /home/xxx/.config/systemd/user/basic.target.wants/plexamp.service → /home/xxx/.config/systemd/user/plexamp.service.
Failed to start plexamp.service: Unit network-online.target not found.

Same for:

xxx@PlexampPi:~ $ systemctl --user restart plexamp.service
Failed to restart plexamp.service: Unit network-online.target not found.

A:
Sounds like you did not reboot the RPi! Try rebooting and try again!
The service-file is from Pleaxmp, the script just modifies it for the user. No modifications to the "[Unit]" part.

Q: After upgrading to 4.4.0, I am getting "ALSA lib pcm_dmix.c:1075:(snd_pcm_dmix_open) unable to open slave".

A: Go to the GUI and re-select your Audio device under Settings >> Playback >> Audio Output. Reboot if it does not fix it, and verify setting is still there. If your device is missing, and reboot does not fix it, powercycle the RPi and try again.
