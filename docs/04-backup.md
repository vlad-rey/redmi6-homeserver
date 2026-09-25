# Бэкап данных хаба дорожки

Что сохраняется: профили (`files/profiles.json`), свои программы (`files/programs.json`), все тренировки с посекундной записью (`files/sessions/*.json`), настройки хаба (`shared_prefs/hub.xml`).

## Как работает

- Скрипт [`tools/backup-hub-data.ps1`](../tools/backup-hub-data.ps1): на телефоне через root упаковывает данные приложения в `tgz`, забирает по ADB (Wi-Fi) на PC, проверяет архив, хранит последние 90.
- Куда: `D:\Backups\treadmill-hub\` (вне git — там личные данные), журнал `backup.log` там же.
- Когда: задача Планировщика Windows **«Treadmill hub backup»** — ежедневно в 23:00; если PC был выключен — при следующем включении.
- Ручной запуск:

```bash
powershell -ExecutionPolicy Bypass -File D:\Code\redmi6-homeserver\tools\backup-hub-data.ps1
```

- Отключить автозапуск:

```bash
schtasks /Delete /TN "Treadmill hub backup" /F
```

Для надёжности стоит периодически копировать `D:\Backups\treadmill-hub\` ещё куда-нибудь (облако, другой диск).

## Восстановление

Если телефон новый или хаб переустановлен — сначала поставить хаб (`treadmill-hub/tools/deploy-hub.ps1`) и дождаться его запуска.

```bash
adb -s <IP>:5555 shell "su -c 'am force-stop io.github.vladrey.treadmillhub'"
adb -s <IP>:5555 push D:\Backups\treadmill-hub\treadmill-hub-ГГГГ-ММ-ДД_ЧЧММ.tgz /data/local/tmp/restore.tgz
adb -s <IP>:5555 shell "su -c 'tar -xzf /data/local/tmp/restore.tgz -C /data/data/io.github.vladrey.treadmillhub && chown -R $(stat -c %u:%g /data/data/io.github.vladrey.treadmillhub) /data/data/io.github.vladrey.treadmillhub/files /data/data/io.github.vladrey.treadmillhub/shared_prefs && rm /data/local/tmp/restore.tgz'"
adb -s <IP>:5555 shell "su -c 'am start-foreground-service -n io.github.vladrey.treadmillhub/.HubService'"
```

После восстановления проверить `http://<IP>:8080/api/sessions` и `/api/profiles`.
