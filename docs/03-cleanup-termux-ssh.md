# S4. Cleanup, Termux and SSH

## MIUI cleanup

List: [`device/debloat/packages.txt`](../device/debloat/packages.txt) — 56 packages (ads, analytics, Facebook, extra MIUI and Google apps, MediaTek loggers). Removed for user 0, system APKs stay in place:

```bash
powershell -ExecutionPolicy Bypass -File tools\debloat.ps1 -Serial <IP>:5555
powershell -ExecutionPolicy Bypass -File tools\debloat.ps1 -Serial <IP>:5555 -Restore
```

Eight third-party preinstalled apps (Facebook, WPS, Joom, etc.) were regular apps — `-Restore` won't bring them back, they need to be reinstalled.

Result (2026-09-25): `com.facebook.katana` crashes every ~30 s stopped, ~2.6 GB RAM free out of 3.9 GB.

## Termux + SSH

- Termux `v0.118.3` (`armeabi-v7a`) and Termux:Boot `v0.8.1` — GitHub builds (the signature must match on both). Install via `adb push` + `su -c pm install`.
- The GitHub build is debuggable, so commands inside Termux are run via `adb shell run-as com.termux sh <script>` to get the correct SELinux context.
- OpenSSH, port **8022**, **key-only** login (`PasswordAuthentication no`). Setup: [`device/termux/setup-sshd.sh`](../device/termux/setup-sshd.sh).
- A dedicated key `~/.ssh/redmi6_ed25519` on the PC and an alias in `~/.ssh/config`:

```
Host redmi6
    HostName <IP>
    Port 8022
    IdentityFile ~/.ssh/redmi6_ed25519
    IdentitiesOnly yes
```

## Autostart on boot

MIUI **resets the autostart permission** (appop `10008`) on every reboot, so Termux:Boot gets `process is not permitted to auto start`. Because of this, the `~/.termux/boot/*` scripts are launched by Magisk instead: [`device/service.d/30-termux-boot.sh`](../device/service.d/30-termux-boot.sh) via `RunCommandService` (`RUN_COMMAND`). This requires `allow-external-apps = true` in `~/.termux/termux.properties`.

[`device/termux/boot/10-sshd.sh`](../device/termux/boot/10-sshd.sh) takes a `termux-wake-lock` and starts `sshd`.

Verified by rebooting on charger: Wi-Fi up in ~45 s, SSH up in ~60 s, the `termux:service-wakelock` wake lock is held.

## Wi-Fi and charging

The Redmi 6 only works on 2.4 GHz. With one of the charging cables, after boot the phone couldn't connect to Wi-Fi (`ASSOC-REJECT status_code=16`) — interference. With a different cable, it connects right away. If the problem comes back: try a different charger/cable, keep the charger further from the phone, use 2.4 GHz channel 6 or 11, 20 MHz width.
