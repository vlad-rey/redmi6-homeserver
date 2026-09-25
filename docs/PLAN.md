# Plan: Redmi 6 as a home server

Last updated: 2026-09-24.

## Device

| Parameter | Value |
|---|---|
| Model | Xiaomi Redmi 6, 4/64 GB |
| Codename | `cereus` |
| SoC | MediaTek Helio P22 (MT6762), 8x Cortex-A53 |
| ABI | **32-bit Android**: `armeabi-v7a`, kernel `armv7l` (the processor is 64-bit, but the system is built for 32-bit) |
| MIUI / Android | MIUI Global 11.0.4.0 (PCGMIXM) Stable / Android 9 (API 28), security patch 2020-05-01 |
| Bootloader / root | **unlocked** / **Magisk v30.7** (2026-09-25). BROM is accessible: SBC/SLA/DAA are enabled, but `mtkclient` bypasses them (Kamakiri) — a fallback unlock path with no waiting |

Performance is roughly on par with a Raspberry Pi 3. Suitable for lightweight services. Home Assistant, Docker and heavy databases — no.

## Decisions

| # | Decision |
|---|---|
| 1 | Firmware: stock MIUI + Magisk. Unofficial LineageOS — only if MIUI gets in the way (Bluetooth risk) |
| 2 | Power: 40-80% charge limit via our own script through `battery/charging_enable` (ACC wasn't needed). No smart plug needed |
| 3 | Before any firmware operations — a full backup of all partitions via `mtkclient` |
| 4 | The treadmill hub is the priority service. Other services are resource-limited |
| 5 | Access only from the home network. Static IP via DHCP reservation on the router |

## Steps

| # | Step | Who | Status |
|---|---|---|---|
| S0 | Find out the MIUI/Android version. Link the Mi account for unlocking | owner | ✅ 2026-09-24: account linked |
| S1 | Full firmware backup (`mtkclient`) | owner + agent | ✅ 2026-09-25: 40 GPT partitions (except `userdata`), 4.8 GB, sizes verified against the GPT. Stored locally, outside git. `vbmeta` is present. Preloader (eMMC boot1) not dumped — optional |
| S2 | Bootloader unlock → Magisk → root check | owner + agent | ✅ 2026-09-25: bootloader unlocked via Mi Unlock 7.6.727.43 with no timer; Magisk v30.7, `vbmeta` with verification disabled, `su` → `uid=0`, SELinux Enforcing |
| S3 | ADB over Wi-Fi on boot, 40-80% charge limit | agent (ADB) | ✅ 2026-09-25: custom `service.d` scripts instead of ACC (the kernel exposes `battery/charging_enable`). See [02-adb-wifi-and-charge-limit.md](02-adb-wifi-and-charge-limit.md) |
| S4 | MIUI cleanup, Termux + SSH, autostart | agent (ADB/SSH) | ✅ 2026-09-25: 56 packages removed (reversible), SSH :8022 by key, autostart via Magisk (MIUI resets Termux:Boot's autostart permission). See [03-cleanup-termux-ssh.md](03-cleanup-termux-ssh.md) |
| S5 | Install treadmill-hub as the priority service | agent | ✅ 2026-09-25: `service.d/40-treadmill-hub.sh` starts `HubService` as root; Bluetooth enabled (`svc bluetooth enable`) |
| S6 | Monitoring: charge, temperature, uptime, free memory. Alerts | agent | ⬜ |
| S8 | Power saving and auto-boot after full discharge | agent | ✅ 2026-09-25: ~60 mA idle; auto-boot from charging mode via `overlay.d` in `boot` (verified: 91 s). See [05-power-and-autoboot.md](05-power-and-autoboot.md) |
| S7 | Hub data backup to PC | agent | ✅ 2026-09-25: daily at 23:00, Windows Task Scheduler, `D:\Backups\treadmill-hub`, 90 copies kept. See [04-backup.md](04-backup.md) |

Details for steps S0-S2: [01-backup-and-unlock.md](01-backup-and-unlock.md).

## Notes discovered in practice

- MIUI blocks `adb install` without a Mi account ("Install via USB"). Workaround: `adb push` + install via File Manager, or after root — `su -c pm install`.
- `adb reboot bootloader` sometimes boots into Android instead — repeat the command.
- `fastboot --disable-verity --disable-verification flash vbmeta` on Windows fails with `Failed to find AVB_MAGIC at offset: 0` on an 8 MB partition dump. Workaround: truncate the dump to 256 bytes + auth + aux bytes and set flags = 3 (offset 120, big-endian), then flash without flags.
- MIUI resets the autostart permission (appop `10008`) on reboot — anything that needs to start at boot is launched from Magisk's `service.d` instead.
- One of the charging cables caused 2.4 GHz interference: after boot, Wi-Fi wouldn't connect (`status_code=16`). Cable replaced.
- The `boot` partition can't be written from Android (eMMC protection) — flashing only works via fastboot over USB.
- All binaries for the phone (hub, Termux packages, modules) are `armeabi-v7a`.

## Candidate services (after S5)

To be decided separately, one at a time:

- AdGuard Home (ad blocking on the home network).
- Syncthing (file sync/backup).
- Telegram bot (hub notifications).
- Backing up workout history to PC.

## Open questions

- [x] MIUI/Android version: MIUI Global 11.0.4.0 (PCGMIXM), Android 9. Staying on it, updates disabled (otherwise the `boot` backup would no longer match for Magisk).
- [x] Charge control on the MT6762 kernel: `/sys/class/power_supply/battery/charging_enable` works.
- [x] After a full discharge, the phone boots itself once power is restored (`overlay.d` rule, 2026-09-25).
