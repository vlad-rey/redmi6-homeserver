# S3. ADB over Wi-Fi and charge limiting

Magisk autostart scripts live in [`device/service.d/`](../device/service.d/) and are installed on the phone at `/data/adb/service.d/`:

```bash
powershell -ExecutionPolicy Bypass -File tools\deploy-service-d.ps1
```

## ADB over Wi-Fi — `10-adb-wifi.sh`

After boot, it sets `service.adb.tcp.port=5555` and restarts `adbd`. USB debugging keeps working in parallel.

```bash
adb connect <IP>:5555
```

The phone's IP is reserved on the router and recorded in `device.local.json` (not in git). Only a computer whose RSA key is authorized on the phone can connect.

## Charge limiting — `20-charge-limit.sh`

Kernel control file: `/sys/class/power_supply/battery/charging_enable` (`0` — charging stopped, the phone runs on battery while USB is connected; `1` — charging in progress). Verified 2026-09-25: at `0`, status is `Not charging`, current -46 mA.

| Parameter | Default |
|---|---|
| `STOP` | 80% — turn charging off |
| `START` | 40% — turn charging on |
| `TEMP_MAX` | 450 (45.0 °C) — turn charging off on overheating |
| `INTERVAL` | 60 s |

Override without reinstalling: `/data/adb/homeserver/charge.conf`, for example:

```sh
STOP=75
START=60
```

Files on the phone:

- `/data/adb/homeserver/charge.log` — switch log;
- `/data/adb/homeserver/charge.state` — current state (used by the hub and for monitoring).

```bash
adb shell su -c cat /data/adb/homeserver/charge.state
```
