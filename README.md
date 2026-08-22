# iPhone Sideloading Quick Commands

*(For the full, detailed tutorial and troubleshooting log, see `iphone-usb-arch-guide.md` in this folder).*

### 🔄 How to Refresh Apps (Do this every 7 days)
Plug in your iPhone via USB, open a terminal in this folder, and run:

```bash
# Refresh AltStore
./install.sh "YOUR_APPLE_ID_PASSWORD"

# Refresh Delta
./install_delta.sh "YOUR_APPLE_ID_PASSWORD"

# Refresh YouTube
./install_youtube.sh "YOUR_APPLE_ID_PASSWORD"
```
*(Note: These scripts overwrite the 7-day timer. They will not delete your app data).*

---

### 📸 How to Access Camera Roll (Photos)
Bypass the buggy Linux popup by using `ifuse` to directly mount the camera partition:

```bash
# 1. Create the folder (only need to do this once)
mkdir -p ~/iphone_photos

# 2. Mount the iPhone (Make sure iPhone is unlocked!)
ifuse ~/iphone_photos

# 3. Access Photos
# Open your file manager and go to ~/iphone_photos/DCIM

# 4. Safely Unmount (When done)
fusermount -u ~/iphone_photos
```

---

### ⚙️ Background Service Management
If your PC says "Could not find AltServer", ensure the background daemons are running:

```bash
# Check status
systemctl --user status netmuxd.service altserver.service

# Restart services
systemctl --user restart netmuxd.service altserver.service
```
