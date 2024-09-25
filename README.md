# PlexAmp-installer for Raspberry Pi with ARMv8, 64-bit HW.

For more information and hardware used, see here:<br /> https://github.com/odinb/bash-plexamp-installer/wiki

Assumes 64-bit capable Raspberry Pi HW and Raspberry Pi OS that is 64-bit.<br />

Due to the change here: https://www.raspberrypi.com/documentation/computers/config_txt.html<br />
the script will no longer be backwards compatible with 11 (bullseye), and moving forward will only support 12 (bookworm).<br />
Bullseye has a planned end-of-life end of summer/early fall: https://wiki.debian.org/DebianReleases#Current_Releases.2FRepositories

This script will install nodeJS (currently NodeJS-20), install/upgrade/configure Plexamp-Linux-headless.

NOTE!<br />
Last verified upgrade was to Plexamp-Linux-headless-v4.10.x.
If newer version is available, and there have been major changes like support for new NodeJS version, please be aware that it might be untested by me, and script might malfunction if any major changes have been made to the application or installation procedure, and installation might fail. Re-running script after script-update usually fixes this, but cannot be guaranteed.

If your card is not detected after upgrade & reboot (no audio) ("aplay -l" to check), please do hard reboot, and re-select the card via web-GUI. Now there should be audio!

## Install Raspberry Pi OS using Raspberry Pi Imager.
Raspberry Pi Imager is the quick and easy way to install Raspberry Pi OS and other operating systems to a microSD card, ready to use with your Raspberry Pi.

[Download and install Raspberry Pi Imager](https://www.raspberrypi.com/software/) to a computer with an SD card reader. Put the SD card you'll use with your Raspberry Pi into the reader and run Raspberry Pi Imager.

[The main screen of Pi-imager:](https://www.raspberrypi.com/software/)
<br /> <img src="https://github.com/odinb/bash-plexamp-installer/blob/main/Pi-imager_Main.png" width="450">

[Choose the Raspberry Pi OS (other):](https://www.raspberrypi.com/software/)
<br /> <img src="https://github.com/odinb/bash-plexamp-installer/blob/main/Pi-imager_OS.png" width="450">

[Then Raspberry Pi OS (64-bit):](https://www.raspberrypi.com/software/)
<br /> <img src="https://github.com/odinb/bash-plexamp-installer/blob/main/Pi-imager_OS_64.png" width="450">

[The advanced screen of Pi-imager:](https://www.raspberrypi.com/software/)
<br /> <img src="https://github.com/odinb/bash-plexamp-installer/blob/main/Pi-imager_Advanced.png" width="400">

Once done, unmount and insert card into Raspberry Pi and boot it.

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

Now, again as your user, run ```sudo systemctl enable plexamp.service && sudo systemctl restart plexamp.service``` to set plexamp to start on reboot, and to run it immediately.

Once done, the web-GUI should be available on "ip-of-plexamp-pi:32500" from a browser.
On that GUI you will be asked to login to your Plex-account for security-reasons, and then choose a librabry where to fetch/stream music from.

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

Q:
The RPi will show up in my cast list. However the moment I select a song to play, it either keeps loading forever (black screen with loading circle) or it flips back to the album overview without starting the selected song. This is the case for all file types tried.

A:
Go into the plexamp settings (via the web UI) and select the right audio output device. Rebooting the RPi a second time sometimes also helps (or restarting/veirfying the PlexAmp service), this of course will only help if correct audio device is already chosen.
(```sudo systemctl enable plexamp.service && sudo systemctl restart plexamp.service```)

======

Q:
When starting Plexamp (4.3.0), I get this:
Starting Plexamp 4.3.0 DEVICE: No provider for source 80df67e4336a1a1c9911d2b4b6b4133c9f7d4cab
Any idea what this is about?

A:
You need to choose your source, i.e. Plex server or TIDAL other. This can be done from the GUI.

======

Q:
I got an error during the first Plexamp install and start up:

```xxx@PlexampPi:~ $ node /home/xxx/plexamp/js/index.js
Starting Plexamp 4.3.0
Please visit https://plex.tv/claim and enter the claim token: claim-xxxxxxxxxxxxxxxxxxxx
Please give the player a name (e.g. Bedroom, Kitchen): Marantz
DEVICE: Error loading cloud players from plex.tv HTTP status 403
```
A:
That is not a bad thing per se, it just means you didn’t link any “cloud players”.
See also:
https://forums.plex.tv/t/plexamp-headless-not-playing-music/809078/21

======

Q:
After upgrading to 4.4.0 (or later), I am getting "ALSA lib pcm_dmix.c:1075:(snd_pcm_dmix_open) unable to open slave".

A:
Go to the GUI and re-select your Audio device under Settings (cogwheel lower right corner) >> Playback >> Audio output >> Audio Device. Reboot if it does not fix it, and verify setting is still there. If your device is missing, and reboot does not fix it, powercycle the RPi and try again.

======

Q:
Correct overlay has been configured, and hard reboot has been performed, but the system still doesn't load the driver.

A:
For Linux 5.4 and higher:  
Disable the onboard EEPROM by adding: 'force_eeprom_read=0' to '/boot/config.txt'

However, this should not be needed for the PiFi HIFI DiGi+ Digital Sound Card found at:
      https://www.fasttech.com/p/5137000

======

Q:
My HifiBerry card (or clone) is not detected after installation and reboot with ``` aplay -l ``` command, what could be wrong?

A1:
Sometimes the card is not detected after upgrade, try doing a hard reboot, i.e. pull the power-cable for 10 seconds and then re-insert power to boot. Card should now be detected. If needed, go to: Settings (cogwheel lower right corner) >> Playback >> Audio output >> Audio Device and re-select your audio-card.

A2:
On your Raspberry Pi, run the following command: ``` cat /proc/device-tree/model ```. If it says “Raspberry Pi 4 Model B Rev 1.5”, the HifiBerry card might not work as expected.
The new Pi release uses a new power management circuit that doesn’t ramp up the voltages as clean as all previous versions did. This results in an inconsistent state of the circuit and the HifiBerry card isn’t detected by the Pi anymore.

Note that this affects only the Digi+ Pro and Digi2 Pro (and some clones of these cards).

For more information:
https://www.hifiberry.com/blog/digi2-pro-raspberry-pi-4-1-5-incompatibilities/
https://www.hifiberry.com/blog/compatibility-issues-of-the-digi2-pro-and-raspberry-pi-4-rev-1-5/
https://forums.raspberrypi.com/viewtopic.php?t=329299

======

Q:
Having issues with audio on HDMI on desktop install.
Tried setting "dtoverlay=vc4-fkms-v3d" and "adding hdmi_drive=2" etc. to config.txt but still does not work.

A:
Script now sets "dtoverlay=vc4-kms-v3d" since this is recommended from RPi4 and newer.

Some background info:

Here's what we know at time of writing about KMS (Kernel Mode Setting) and FKMS (Fake Kernel Mode Setting) on Raspberry Pi:

KMS vs FKMS
KMS (Kernel Mode Setting):
- Is the standard Linux framework for setting video modes
- Directly accesses hardware registers for HDMI/DSI initialization
- More extensible and open-source
- Generally preferred for newer Raspberry Pi models, especially Pi 4 or later

FKMS (Fake Kernel Mode Setting):
- A special driver for Raspberry Pi
= Uses the proprietary DispmanX API to set up HDMI
- Simpler for Linux to use but relies on closed-source components
- Was more common on older Pi models

Recommendations
For Raspberry Pi 4 or later:
- KMS is now the preferred and more actively developed option
- FKMS has some significant bugs on Pi 4 and is less supported

For older Raspberry Pi models:
-FKMS may still be a viable option, especially if having issues with KMS

Important Considerations
1. KMS on Pi affects more than just mode setting - it also configures 2D compositing planes through the DRM (Direct Render Manager) subsystem.
2. Switching between KMS and FKMS may require additional configuration changes:
- Modifying boot/config.txt
- Potentially adjusting hdmi_mode and group_mode parameters
- Possibly editing /boot/cmdline.txt

3. The choice between KMS and FKMS can impact performance and compatibility with certain features or software.
4. If using the official Raspberry Pi 7" Touchscreen, additional overlays may be needed for KMS:
   dtoverlay=vc4-kms-dsi-7inch
   dtoverlay=rpi-ft5406

5. For the most up-to-date and model-specific recommendations, it's best to consult the official Raspberry Pi documentation or forums, as the preferred options can change with software updates.

======
