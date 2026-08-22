# Arch Linux iOS Sideloading Guide

This document serves as a complete reference for how we configured Arch Linux to sideload iOS applications (specifically AltStore) onto your iPhone over USB and Wi-Fi.

## 1. Core USB Dependencies
To allow Arch Linux to communicate with an iPhone, we installed the open-source Apple USB protocols:
- **Packages Installed:** `libimobiledevice`, `usbmuxd`
- **What they do:** They act as translators. `usbmuxd` is a background daemon that wakes up when an iPhone is plugged in.
- **Commands used:**
  `sudo pacman -S libimobiledevice usbmuxd`
  `sudo systemctl start usbmuxd`

## 2. Device Pairing
Before you can install apps, the iPhone must mathematically trust the Arch system.
- **Command used:** `sudo idevicepair pair`
- **Process:** You ran this command while the phone was unlocked, and tapped "Trust" on the iPhone screen. It generated a pairing certificate for your specific Device ID (UDID).

## 3. AltServer-Linux Installation
AltStore requires a "Server" application running on the PC to sign and push the apps.
- **Package Installed:** `altserver-linux-bin` (from AUR via `yay`)
- **Installed Size:** ~79.00 MB
- **Installation Path:** `/opt/altserver/` (Executables: `AltServer` and `netmuxd`)
- **Systemd Services:** `/usr/lib/systemd/user/altserver.service` and `netmuxd.service`

## 4. The "Fake Mac" Anisette Server (Docker)
Apple blocks app signing from Linux by requiring a "Mac Fingerprint" called Anisette V3. To bypass this, we run a tiny Docker container that tricks Apple's servers.
- **Docker Image:** `dadoum/anisette-v3-server`
- **Port:** `6969`
- **Command used to start it permanently:**
  `sudo docker run -d --restart always --name anisette-v3 -p 6969:6969 --volume anisette-v3_data:/home/Alcoholic/.config/anisette-v3/lib/ dadoum/anisette-v3-server`

## 5. Background Services
To allow AltStore to refresh apps automatically over Wi-Fi so they don't expire every 7 days, we enabled the background user services:
- **Command used:**
  `systemctl --user enable --now netmuxd.service altserver.service`

## 6. Pushing the App to the iPhone (The Final Command)
Once everything was running, we downloaded `altstore.ipa` (~5.2 MB) into the `/home/crdy/testing/iPhone/` folder.
To push this (or any future `.ipa`) to your phone via USB, this is the master command:

```bash
ALTSERVER_ANISETTE_SERVER="http://127.0.0.1:6969" /opt/altserver/AltServer -u YOUR_UDID -a "YOUR_APPLE_ID" -p "YOUR_PASSWORD" /home/crdy/testing/iPhone/altstore.ipa
```
*(Note: Replace YOUR_UDID with your 00008110-... string, and your Apple login details).*

## 7. Post-Installation (On the iPhone)
1. Go to **Settings -> General -> VPN & Device Management**
2. Tap your Apple ID email.
3. Tap **Trust**.
4. You can now open AltStore on your home screen!

## 8. Usage & Maintenance Guide

### How to Manually Install New Apps (.ipa files)
You do not need to use the Linux terminal to install new apps! You do everything directly on your iPhone:
1. On your iPhone, download any `.ipa` file using Safari (e.g., from a GitHub release).
2. Open the **AltStore** app on your iPhone.
3. Tap on the **My Apps** tab at the bottom.
4. Tap the **+ (Plus)** icon in the top left corner.
5. Select the `.ipa` file you just downloaded.
6. AltStore will communicate with your Arch Linux PC over Wi-Fi and install the app!

### How Many Apps Can I Install?
Apple places strict limits on **Free Developer Accounts**:
- You can only have **3 active apps** installed at one time. 
- *Note:* The AltStore app itself counts as 1 app, meaning you have **2 free slots** for your own apps.
- If you reach the limit, you can "Deactivate" an app in AltStore to free up a slot without deleting the app's save data.
- You are limited to registering 10 App IDs every 7 days.

### How to Manually Refresh Apps (Linux Workaround)
Apps expire every 7 days on free accounts. Normally, you can refresh them inside the AltStore app over Wi-Fi. However, due to a known bug with `netmuxd` on Linux, the in-app refresh button often fails with a "provisioning profile" error.

**The Solution:** You must refresh apps manually using the command line. "Refreshing" an app this way simply overwrites the 7-day certificate without deleting your data.
1. Plug your iPhone into your Arch Linux PC with a USB cable.
2. Open your terminal and run the installation script for the app you want to refresh.
   - For AltStore: `/home/crdy/testing/iPhone/install.sh "YOUR_PASSWORD"`
   - For YouTube: `/home/crdy/testing/iPhone/install_youtube.sh "YOUR_PASSWORD"`
*(Do not press the Refresh button in the AltStore app on your phone while doing this. Let the Linux script do the work!)*

### Managing AltServer Services on Arch Linux
If your iPhone says "Could not find AltServer", make sure your background services are running on your Arch Linux PC.

**Check if they are running:**
```bash
systemctl --user status netmuxd.service altserver.service
```

**Turn the services ON:**
```bash
systemctl --user enable --now netmuxd.service altserver.service
```

**Restart the services (Useful if Wi-Fi sync breaks):**
```bash
systemctl --user restart netmuxd.service altserver.service
```

**Check the Anisette (Mac Fingerprint) Docker server:**
If authentication fails, make sure the Docker container is running:
```bash
sudo docker ps
```
*(You should see `anisette-v3-server` in the list).*

## 9. Troubleshooting Log (Problems We Solved)

### Problem 1: Terminal Copy-Paste Bugs (Command breaking in half)
- **The Issue:** When pasting the long AltServer installation command into the terminal, the terminal would insert a hidden "Enter" keyline. This caused `AltServer` to launch in a broken "server mode" instead of installing the `.ipa`.
- **The Solution:** We stopped pasting the command. Instead, we wrote the command inside executable bash scripts (`install.sh` and `install_delta.sh`) so they can be run securely without terminal formatting issues.

### Problem 2: AltServer Crashes with `DNSServiceRegister result: -65537`
- **The Issue:** Apple software relies on "Bonjour" network discovery to find devices over Wi-Fi. This crashed because Arch Linux did not have a Bonjour-equivalent running.
- **The Solution:** We installed Avahi (the Linux equivalent of Bonjour) and started it:
  ```bash
  sudo pacman -S avahi
  sudo systemctl enable --now avahi-daemon
  ```

### Problem 3: Error "there is no provisioning profile with the requested identifier" (In-App Refresh)
- **The Issue:** When trying to refresh apps directly from the AltStore app on the iPhone (either over Wi-Fi or USB), Apple rejected the signature. The `netmuxd` background daemon fails to hold a stable heartbeat with the phone on Linux.
- **The Solution:** We bypassed the phone's "Refresh" button entirely. Instead, we refresh apps by running the Linux terminal scripts (`install.sh`, `install_youtube.sh`) while the phone is plugged in via USB.

### Problem 4: Alert: Installing AltStore with Multiple AltServers Not Supported
- **The Issue:** When running the refresh script for AltStore, the terminal pauses and warns that using multiple AltServers will cause old apps to stop working.
- **The Solution:** This is a generic warning. As long as you are using the exact same Arch Linux PC and the exact same Apple ID, it is completely safe. Just press **Enter** (or any key) in the terminal to continue the refresh process.

## 10. Bonus: How to Transfer Photos to Linux (Bypassing the Empty Folder Bug)
When you plug an iPhone into Linux, the default photo protocol (`gphoto2://`) often breaks or shows an empty folder due to Apple's strict privacy prompts. 

Because you already have the iPhone "Trusted" for AltStore, you can use a tool called `ifuse` to forcefully mount your camera roll like a standard USB flash drive.

**1. Install ifuse:**
```bash
sudo pacman -S ifuse
```

**2. Create a folder and mount the iPhone:**
```bash
mkdir -p ~/iphone_photos
ifuse ~/iphone_photos
```

**3. Access your Photos:**
Open your file manager, go to your Home directory, and open `iphone_photos`. Your camera roll is located inside the **`DCIM`** folder!

**4. Safely Unmount (When Finished):**
```bash
fusermount -u ~/iphone_photos
```
*(Troubleshooting: If you get a "Device or resource busy" error, it means a window or terminal is still open inside the folder. Close your file manager, type `cd ~` in your terminal, and try again. Alternatively, you can just physically unplug the USB cable and Linux will safely kill the mount automatically.)*
