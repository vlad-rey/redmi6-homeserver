# Rules for agents

Repository: setting up a Redmi 6 as a home server. Plan — [docs/PLAN.md](docs/PLAN.md). Documentation, code comments and instructions are in English; chat with the owner is in Russian.

## Caution

- **Do not perform without the owner's explicit confirmation in chat**: unlocking the bootloader, flashing partitions (`fastboot flash`, `mtk w`), formatting, factory reset, removing system apps, changing charge thresholds (`charge.conf`) outside 30-90%.
- Before any write to partitions — verify there is a recent full backup.
- The treadmill hub (treadmill-hub) is the priority service. Do not install services on the phone that noticeably load CPU/memory without prior agreement.

## Repository is public

- Do not commit: firmware backups, `nvram`/`nvdata`/`persist` (they contain the IMEI), IP/MAC addresses, SSH keys, passwords, `*.local.*`.

## Phone access

- `adb connect <IP>:5555` — IP is in `device.local.json` (not in git). Root: `adb shell su -c ...`.
- SSH: `ssh redmi6` (Termux, port 8022, key `~/.ssh/redmi6_ed25519`). Commands inside Termux via adb: `run-as com.termux sh <script>`.
- Installing APKs: MIUI blocks `adb install`; use `adb push` + `su -c pm install`.
