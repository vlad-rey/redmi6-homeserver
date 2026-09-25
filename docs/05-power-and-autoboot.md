# Power consumption and auto-boot

## Power saving (2026-09-25)

Script [`device/power/power-saving.sh`](../device/power/power-saving.sh), run once as root (settings persist):

- airplane mode **for cellular only** (`airplane_mode_radios=cell`) — Wi-Fi and Bluetooth keep working; if Wi-Fi doesn't come back up within 20 s after enabling it, airplane mode is rolled back;
- screen turns off after 15 s, minimum brightness;
- background Wi-Fi/Bluetooth scanning and location are disabled (the treadmill's location is already known);
- Google Play Store removed for user 0 (it used ~24% CPU in the background), see `device/debloat/packages.txt`.

Power draw measured with charging stopped and the screen off: **≈ 57-63 mA** (~0.2 W). The hub uses ≈ 8% of one core. CPU wake lock and Wi-Fi high-perf mode are left on: without high-perf, Wi-Fi speed dropped to ~70 KB/s at the same power draw.

### Charge limiter

The MediaTek controller resumes charging on its own, while the `charging_enable` flag still reads `0`. Because of this, [`20-charge-limit.sh`](../device/service.d/20-charge-limit.sh) checks the actual `status` (`Charging`) and writes `0` again if needed; checked every 30 s.

## Auto-boot after a full discharge

When the battery dies and power returns, MediaTek boots into "charging while powered off" mode (KPOC, `ro.bootmode=charger`). Magisk scripts (`post-fs-data.d`, `service.d`) **do not run** in this mode — verified.

The solution is an init rule in the ramdisk, added via Magisk's standard `overlay.d` mechanism ([`device/boot-overlay/autoboot.rc`](../device/boot-overlay/autoboot.rc)):

```
on charger
    exec_background u:r:magisk:s0 root root -- /system/bin/sh -c "sleep 30; /system/bin/reboot"
```

Verified 2026-09-25: `reboot -p` with power connected → Android booted itself after **91 s**.

### How it was built and flashed

1. The current `boot` (with Magisk) was pulled from the phone: `dd if=/dev/block/by-name/boot`.
2. `magiskboot unpack` → `magiskboot cpio ramdisk.cpio "mkdir 0750 overlay.d" "add 0644 overlay.d/autoboot.rc autoboot.rc"` → `magiskboot repack`.
3. **The `boot` partition can't be written from Android** (`dd` reports success, but nothing actually changes — eMMC protection). Flashing only works via fastboot over USB: `fastboot flash boot boot-magisk-autoboot.img`.

Images (not in git): `backup/patched/boot-magisk-autoboot.img` (current, SHA-1 `aa05a01a…`), `backup/patched/magisk_patched-30700_YhUGg.img` (Magisk without auto-boot), `backup/<date>/boot.bin` (stock).

⚠️ Reinstalling/updating Magisk via the app will re-patch `boot` from the stock image — the `overlay.d` rule will be lost and needs to be added again following the steps above.
