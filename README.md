# redmi6-homeserver

Turning a Xiaomi Redmi 6 (4/64, `cereus`, MediaTek Helio P22) into a home mini-server that runs around the clock on charger power.

The server's main job is the treadmill hub, [treadmill-hub](https://github.com/vlad-rey/treadmill-hub). Other services must not get in its way.

> Status: **planning**. See [docs/PLAN.md](docs/PLAN.md).

## What's here

- Instructions: firmware backup, bootloader unlock, root (Magisk).
- Battery charge limiting (ACC, 40-80%).
- ADB over Wi-Fi right after boot.
- Termux: SSH, services, autostart.
- MIUI configuration for server operation.

## ⚠️ Warning

Unlocking the bootloader wipes all data on the phone. Firmware operations can brick the device. Everything is done at your own risk and only after a full backup.

## License

MIT.
