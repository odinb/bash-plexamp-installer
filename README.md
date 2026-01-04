# PlexAmp-installer for Raspberry Pi with ARMv8, 64-bit HW.

For more information and hardware used, see here:<br /> https://github.com/odinb/bash-plexamp-installer/wiki

Assumes 64-bit capable Raspberry Pi HW and Raspberry Pi OS that is 64-bit.<br />

The script is currently maintained for Debian Bookworm and Trixie.<br />
Debian Trixie Raspbian OS was officially released on 2024-10-01.<br />
Bullseye was end-of-life on 2024-08-14.<br />
https://wiki.debian.org/DebianReleases#Current_Releases.2FRepositories

This script will install nodeJS (currently NodeJS-20), install/upgrade/configure Plexamp-Linux-headless.

NOTE!<br />
Last verified upgrade was to Plexamp-Linux-headless-v4.12.x.
If newer version is available, and there have been major changes like support for new NodeJS version, please be aware that it might be untested by me, and script might malfunction if any major changes have been made to the application or installation procedure, and installation might fail. Re-running script after script-update usually fixes this, but cannot be guaranteed.

If your card is not detected after upgrade & reboot (no audio) ("aplay -l" to check), please do hard reboot (pull power), and re-select the card via web-GUI. Now there should be audio!

## Install Raspberry Pi OS using Raspberry Pi Imager.
Raspberry Pi Imager is the quick and easy way to install Raspberry Pi OS and other operating systems to a microSD card, ready to use with your Raspberry Pi.

[Download and install Raspberry Pi Imager](https://www.raspberrypi.com/software/) to a computer with an SD card reader. Put the SD card you'll use with your Raspberry Pi into the reader and run Raspberry Pi Imager.

[The main screen of Pi-imager:](https://www.raspberrypi.com/software/)
<br /> <img src="https://github.com/odinb/bash-plexamp-installer/blob/main/Pi-imager_Main.png" width="450">

[Choose the Raspberry Pi OS (other):](https://www.raspberrypi.com/software/)
<br /> <img src="https://github.com/odinb/bash-plexamp-installer/blob/main/Pi-imager_OS.png" width="450">

[Then Raspberry Pi OS Lite (64-bit):](https://www.raspberrypi.com/software/)
<br /> <img src="https://github.com/odinb/bash-plexamp-installer/blob/main/Pi-imager_OS_64.png" width="450">

[The advanced screen of Pi-imager:](https://www.raspberrypi.com/software/)
<br /> <img src="https://github.com/odinb/bash-plexamp-installer/blob/main/Pi-imager_Advanced.png" width="400">

Once done, unmount and insert card into Raspberry Pi and boot it.

SSH access on "DietPi OS" as user: dietpi/dietpi and as root: root/dietpi<br />
NOTE!!! DietPi is best-effort, and might not work.
DietPi is best effort, and was last tested on 2025-10-03 on DietPi v9.17.2 (Trixie).

After SSH-ing to the SBC, on the "Raspberry Pi OS", change to root (```sudo su -```) and run script with:

```bash <(wget -qO- https://raw.githubusercontent.com/odinb/bash-plexamp-installer/main/install_Plexamp_pi.sh)```

### Re-running the script

The script can be re-run to fix configuration/setup errors, just say no/bypass the sections you do not want to re-run!

If there is a new version, and script has been updated, you can upgrade by re-running the script, and reboot.

For hostname-change, please make sure to reboot in-between, or you might face issues.

### Q & A

Q:
The RPi will show up in my cast list. However the moment I select a song to play, it either keeps loading forever (black screen with loading circle) or it flips back to the album overview without starting the selected song. This is the case for all file types tried.

A:
Go into the plexamp settings (via the web UI) and select the right audio output device. Rebooting the RPi a second time sometimes also helps (or restarting/verifying the PlexAmp service), this of course will only help if correct audio device is already chosen.

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

However, this should not be needed for the PiFi HIFI DiGi+ Digital Sound Card.

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

https://forums.raspberrypi.com/viewtopic.php?t=359847#p2158626
https://forums.raspberrypi.com/viewtopic.php?p=1598691#p1598691
https://forums.raspberrypi.com/viewtopic.php?t=342661&sid=27f581984f8d93321b227d3b981d3c15#p2053197

======

Q:
Performed a password reset and now things are funky!

A1 (Raspberry Pi OS):
After a Plex password reset + auto sign-out from all devices, follow the steps below to get headless back up and running (needs improvement).

- Restart plexamp systemd service: "systemctl --user restart plexamp.service", or reboot the device.

- After restart, stop plexamp service: "systemctl --user stop plexamp.service".

- Manually start plexamp from terminal (as same user who did the original install) "node ~/plexamp/js/index.js" Enter claim code and player name, wait for plexamp to start, ignore other messages.

- Restart plexamp service: "systemctl --user restart plexamp.service", or reboot device. Headless should now be visible to other players.

- Go to the headless browser interface: hostname:32500, then go to "settings" > "account" and sign out. Now sign back in, then click on the "cast" icon and re-select the headless player. Check any playback settings that revert to defaults after sign-in, things like sample rate matching, sample rate conversion, autoplay, etc.

A2 (DietPi):
After a Plex password reset + auto sign-out from all devices, follow the steps below to get headless back up and running (needs improvement).

- Restart plexamp systemd service: "sudo systemctl restart plexamp.service", or reboot the device.

- After restart, stop plexamp service: "sudo systemctl stop plexamp.service".

- Manually start plexamp from terminal (as same user who did the original install) "node ~/plexamp/js/index.js" Enter claim code and player name, wait for plexamp to start, ignore other messages.

- Restart plexamp service: "sudo systemctl restart plexamp.service", or reboot device. Headless should now be visible to other players.

- Go to the headless browser interface: hostname:32500, then go to "settings" > "account" and sign out. Now sign back in, then click on the cast icon and re-select the headless player. Check any playback settings that revert to defaults after sign-in, things like sample rate matching, sample rate conversion, autoplay, etc.

======

Q:
Performed an update of PlexAmp, but I am still seeing "undefined" in my DNS!

A:
This Plexamp "Undefined" bug is VERY persistent! So why is it happening?
Plexamp Headless stores state locally (in JSON files). Incorrect or missing fields can turn into "undefined" in JavaScript.

JavaScript/Node will string-concatenate or interpolate "undefined" into hostnames if a field is missing.
Plexamp then tries to resolve that string as a hostname via DNS, leading to repeated DNS lookups (your DNS/Pi-hole logs).

This pattern is consistent with headless network discovery being unreliable and buggy in certain setups, and many community threads focus on related networking oddities.
The situation seen here is a known headless Plexamp networking quirk that dozens of users have reported in different forms:<br />
- Unexpected hostnames used for resolution
- DNS resolution failures for local services
- Strange behavior after power loss or state corruption

So, to fix this, one have 2 options.
Bruteforce-way, removing the whole status/state file:<br />
Stop the service.<br />
$ systemctl --user stop plexamp.service

Remove the cachefile.<br />
$ rm ~/.local/share/Plexamp/Settings/%40Plexamp%3Astate

Restart the service.<br />
$ systemctl --user start plexamp.service


Surgical way, removing only fields that are empty or contain undefined:<br />
Check file for corrupt/empty fields, if output is "[]", there are no corrupt fields.<br />
$ jq 'to_entries | map(select(.value == null or .value == "" or .value == "undefined"))' ~/.local/share/Plexamp/Settings/%40Plexamp%3Astate

Cleanup only empty/undefined fields (requires "sponge" to be installed, done with "sudo apt install moreutils").<br />
$ jq 'with_entries(select(.value != null and .value != "" and .value != "undefined"))' ~/.local/share/Plexamp/Settings/%40Plexamp%3Astate | sponge ~/.local/share/Plexamp/Settings/%40Plexamp%3Astate

Output the full file.<br />
$ cat ~/.local/share/Plexamp/Settings/%40Plexamp%3Astate

The DNS spam with "undefined" should now be gone untill next time this file is corrupted.

======
