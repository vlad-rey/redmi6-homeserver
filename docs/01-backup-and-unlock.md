# Backup, unlock, root

Path: **backup via `mtkclient` → official unlock via Mi Unlock → Magisk** on stock MIUI.

| Part | What | When | Wipes the phone? |
|---|---|---|---|
| A | Prepare the phone, link the Mi account | today | no |
| B | Prepare the PC | today | — |
| C | Backup of all partitions | today | no |
| D | Unlock the bootloader | in ~7 days | **yes** |
| E | Root (Magisk) | right after D | no |
| F | Rollback if something goes wrong | if needed | — |

Sources: [mtkclient](https://github.com/bkerler/mtkclient), [Magisk](https://github.com/topjohnwu/Magisk), [XDA guide on mtkclient + Magisk](https://xdaforums.com/t/guide-mediatek-windows-only-use-mtkclient-to-root-your-mediatek-device-via-magisk.4709854/).

---

## A. Phone: preparation and linking (today)

1. **Check the version.** Settings → About phone → note the "MIUI version" and "Android version" in [PLAN.md](PLAN.md). Our phone: MIUI Global 11.0.4.0 (PCGMIXM), Android 9.
2. **Disable automatic updates** (an update would change the firmware, and the `boot` backup would no longer match for Magisk): Settings → About phone → "MIUI version" → ⋮ → Settings → turn off "Download updates automatically".
3. **Developer mode**: Settings → About phone → tap "MIUI version" 7 times.
4. **Settings → Additional settings → Developer options**:
   - "OEM unlocking" — **enable**;
   - "USB debugging" — **enable**.
5. **Link the account** for unlocking:
   - sign in to the Mi account (Settings → Mi Account) if not already signed in;
   - insert a SIM card, **turn off Wi-Fi, turn on mobile data**;
   - Developer options → "Mi Unlock status" → "Add account and device". You should see "Successfully added".
6. **While waiting**, do not sign out of the Mi account or re-link — the timer may restart.

> The waiting timer (usually 168 h) is shown by Mi Unlock Tool on the first unlock attempt (part D, steps 1-4). It's worth making this first attempt right after the backup, so the timer starts.

## B. PC: preparation (today)

Needed: Windows 10/11, ~20 GB free space, a USB cable with data transfer.

1. **Python 3.12.** `mtkclient` depends on `keystone-engine`, which has no prebuilt wheels for Python 3.14. Install 3.12 alongside the existing one:
   ```bash
   winget install Python.Python.3.12
   ```
2. **UsbDk driver** (64-bit, `.msi`) — download from [github.com/daynix/UsbDk/releases](https://github.com/daynix/UsbDk/releases) and install. Requires administrator rights.
3. **mtkclient** — the script clones it into `D:\Code\tools\mtkclient` (outside the repositories) and sets up an environment on Python 3.12:
   ```bash
   powershell -ExecutionPolicy Bypass -File D:\Code\redmi6-homeserver\tools\setup-mtkclient.ps1
   ```
   If installing `keystone-engine` still fails — install Visual Studio Build Tools with the "Desktop development with C++" component and run the script again.
4. **Mi Unlock Tool** — download from Xiaomi's official site: [unlock.update.miui.com](https://unlock.update.miui.com) (this link is shown by the phone itself in "Mi Unlock status"). The page serves version 6.5, which lacks `MiUsbDriver.exe`, and the in-app update link returns a 403. The working option is version 7.6.727.43 from the same official server: `https://miuirom.xiaomi.com/rom/u1106245679/7.6.727.43/miflash_unlock_en_7.6.727.43.zip` (~114 MB; the server drops the connection at 10 MB — resume with `curl -C -`). Unpack it, run `miflash_unlock.exe`, in settings (gear icon) → top "Check" button (driver install) or run `MiUsbDriver.exe` directly as administrator. This driver isn't needed for the backup (part C) — only for fastboot.
5. `adb` and `fastboot` are already available: `C:\Users\vreds\AppData\Local\Android\Sdk\platform-tools\`.

## C. Backup of all partitions (today)

> The backup contains the IMEI and radio calibration data (`nvram`, `nvdata`, `protect*`). Store it somewhere safe, never publish it. The `backup/` folder is excluded via `.gitignore`.

1. Charge the phone to at least 50%. **Turn off the phone**, disconnect from USB.
2. Start the backup (the script first saves the partition table, then reads all partitions except `userdata`):
   ```bash
   powershell -ExecutionPolicy Bypass -File D:\Code\redmi6-homeserver\tools\backup-partitions.ps1
   ```
> **Important:** `mtkclient` must **already be running and waiting** when you plug in the phone. BROM waits only a fraction of a second for the host; if nothing is listening on the PC, the phone keeps booting — into fastboot with "Volume down", or into MI-Recovery with "Volume up" (don't select anything there). The script connects twice (partition table, then the partitions themselves) — reconnect the phone the same way between the two steps.

3. When the console shows `Waiting for device` / `Preloader - Waiting`: **hold both volume buttons** on the powered-off phone and, without releasing them, **plug in the USB cable**. The screen stays black — that's normal (BROM mode). Release the buttons once data exchange starts in the console.
   - Not detected → try "Volume up" only, a different USB port (preferably a USB 2.0 port on the back panel), and a different cable.
4. Reading takes from a few minutes up to half an hour. Don't touch the cable.
5. Once finished, check `D:\Code\redmi6-homeserver\backup\<date>\`:
   - `gpt.txt` and `*.bin` files per partition are present;
   - the following must be present and non-empty: `boot.bin`, `recovery.bin`, `nvram.bin`, `nvdata.bin`, `protect1.bin`, `protect2.bin`, `seccfg.bin`, `lk.bin`, `preloader*.bin`;
   - note whether `vbmeta.bin` is present (needed in part E).
6. Disconnect the cable, hold the power button for ~10 s so the phone boots normally.
7. **Copy the backup folder to one more location** (encrypted cloud storage, a flash drive, another disk).

## D. Unlocking the bootloader (in ~7 days)

> ⚠️ **Wipes all data on the phone.** Before this: back up photos, files and Bluetooth logs if needed.

1. Turn off the phone. Hold **"Volume down" + "Power"** until the rabbit logo appears (fastboot mode).
2. Connect the phone to the PC.
3. Run `miflash_unlock.exe`, sign in with the same Mi account as on the phone.
4. Click "Unlock".
   - The first attempt will show how many hours to wait — **this is how the timer starts**. Note the date.
   - Once the wait is over, repeat steps 1-4: the tool will unlock the bootloader and wipe the data.
5. The phone will reboot. On every boot there will be a warning about the unlocked bootloader — that's normal.
6. Do minimal phone setup: Wi-Fi, **no** automatic updates (see A.2), developer mode, "USB debugging".

## E. Root via Magisk (right after D)

1. Verify the firmware hasn't changed: the "MIUI version" matches what was recorded in part A. Otherwise the `boot.bin` from the backup won't match — ask in chat first.
2. Download the latest `Magisk-vXX.X.apk` from [github.com/topjohnwu/Magisk/releases](https://github.com/topjohnwu/Magisk/releases) and install it:
   ```bash
   adb install Magisk-vXX.X.apk
   ```
3. Transfer the `boot` image from the backup to the phone:
   ```bash
   adb push D:\Code\redmi6-homeserver\backup\<date>\boot.bin /sdcard/Download/boot.img
   ```
4. On the phone: Magisk → Magisk "Install" → "Select and Patch a File" → `Download/boot.img` → "Let's Go". Resulting file: `Download/magisk_patched-XXXXX_XXXXX.img`.
5. Pull it to the PC:
   ```bash
   adb pull /sdcard/Download/ D:\Code\redmi6-homeserver\backup\patched\
   ```
6. Reboot into fastboot and flash:
   ```bash
   adb reboot bootloader
   fastboot flash boot D:\Code\redmi6-homeserver\backup\patched\magisk_patched-XXXXX_XXXXX.img
   ```
7. **If the backup contains `vbmeta.bin`** (our Redmi 6 has one, with verification enabled). The command below may fail on Windows with `Failed to find AVB_MAGIC at offset: 0` — if so, see the workaround in [PLAN.md](PLAN.md) → "Notes" (a truncated `vbmeta_disabled.img` with flags = 3, flashed without flags):
   ```bash
   fastboot --disable-verity --disable-verification flash vbmeta D:\Code\redmi6-homeserver\backup\<date>\vbmeta.bin
   ```
8. Reboot:
   ```bash
   fastboot reboot
   ```
9. Open Magisk. If it asks for "additional setup" — agree, the phone will reboot.
10. Check root (the phone will show a Magisk prompt — allow it):
    ```bash
    adb shell su -c id
    ```
    Expected: `uid=0(root)`.

## F. Rollback

| Problem | What to do |
|---|---|
| After flashing `boot`, the phone won't boot | Fastboot (Volume down + Power) → `fastboot flash boot <backup>\boot.bin` → `fastboot reboot` |
| The phone won't even enter fastboot | BROM mode (part C, step 3) → `mtk.py w boot <backup>\boot.bin` (do this together with the agent) |
| IMEI / network lost | Restore `nvram`, `nvdata`, `protect1`, `protect2` from the backup via `mtkclient` (do this together with the agent) |
| Everything is completely broken | Official fastboot firmware for `cereus`, same version, + MiFlash |
