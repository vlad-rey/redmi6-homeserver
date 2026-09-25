# Treadmill hub data backup

What's saved: profiles (`files/profiles.json`), custom programs (`files/programs.json`), all workouts with per-second logging (`files/sessions/*.json`), hub settings (`shared_prefs/hub.xml`).

## How it works

- Script [`tools/backup-hub-data.ps1`](../tools/backup-hub-data.ps1): on the phone, packs the app data into a `tgz` as root, pulls it over ADB (Wi-Fi) to the PC, verifies the archive, keeps the last 90.
- Destination: `D:\Backups\treadmill-hub\` (outside git — it holds personal data), with a `backup.log` log alongside it.
- Schedule: Windows Task Scheduler task **"Treadmill hub backup"** — daily at 23:00; if the PC was off, it runs on next startup.
- Manual run:

```bash
powershell -ExecutionPolicy Bypass -File D:\Code\redmi6-homeserver\tools\backup-hub-data.ps1
```

- Disable autorun:

```bash
schtasks /Delete /TN "Treadmill hub backup" /F
```

For extra safety, periodically copy `D:\Backups\treadmill-hub\` elsewhere as well (cloud, another disk).

## Restore

If the phone is new or the hub was reinstalled — first install the hub (`treadmill-hub/tools/deploy-hub.ps1`) and wait for it to start.

```bash
adb -s <IP>:5555 shell "su -c 'am force-stop io.github.vladrey.treadmillhub'"
adb -s <IP>:5555 push D:\Backups\treadmill-hub\treadmill-hub-YYYY-MM-DD_HHMM.tgz /data/local/tmp/restore.tgz
adb -s <IP>:5555 shell "su -c 'tar -xzf /data/local/tmp/restore.tgz -C /data/data/io.github.vladrey.treadmillhub && chown -R $(stat -c %u:%g /data/data/io.github.vladrey.treadmillhub) /data/data/io.github.vladrey.treadmillhub/files /data/data/io.github.vladrey.treadmillhub/shared_prefs && rm /data/local/tmp/restore.tgz'"
adb -s <IP>:5555 shell "su -c 'am start-foreground-service -n io.github.vladrey.treadmillhub/.HubService'"
```

After restoring, check `http://<IP>:8080/api/sessions` and `/api/profiles`.
