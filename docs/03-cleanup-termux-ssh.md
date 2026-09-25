# S4. Очистка, Termux и SSH

## Очистка MIUI

Список: [`device/debloat/packages.txt`](../device/debloat/packages.txt) — 56 пакетов (реклама, аналитика, Facebook, лишние приложения MIUI и Google, логгеры MediaTek). Удаляются для пользователя 0, системные APK остаются:

```bash
powershell -ExecutionPolicy Bypass -File tools\debloat.ps1 -Serial <IP>:5555
powershell -ExecutionPolicy Bypass -File tools\debloat.ps1 -Serial <IP>:5555 -Restore
```

Восемь сторонних предустановок (Facebook, WPS, Joom и т. п.) были обычными приложениями — при `-Restore` они не вернутся, их надо ставить заново.

Результат (2026-09-25): вылеты `com.facebook.katana` каждые ~30 с прекратились, свободно ~2,6 ГБ RAM из 3,9 ГБ.

## Termux + SSH

- Termux `v0.118.3` (`armeabi-v7a`) и Termux:Boot `v0.8.1` — сборки с GitHub (подпись должна совпадать у обоих). Установка: `adb push` + `su -c pm install`.
- Сборка GitHub — debuggable, поэтому команды внутри Termux выполняются через `adb shell run-as com.termux sh <скрипт>` в правильном SELinux-контексте.
- OpenSSH, порт **8022**, вход **только по ключу** (`PasswordAuthentication no`). Настройка: [`device/termux/setup-sshd.sh`](../device/termux/setup-sshd.sh).
- На PC отдельный ключ `~/.ssh/redmi6_ed25519` и алиас в `~/.ssh/config`:

```
Host redmi6
    HostName <IP>
    Port 8022
    IdentityFile ~/.ssh/redmi6_ed25519
    IdentitiesOnly yes
```

## Автозапуск при загрузке

MIUI **сбрасывает разрешение автозапуска** (appop `10008`) при каждой перезагрузке, и Termux:Boot получает `process is not permitted to auto start`. Поэтому скрипты `~/.termux/boot/*` запускает Magisk: [`device/service.d/30-termux-boot.sh`](../device/service.d/30-termux-boot.sh) через `RunCommandService` (`RUN_COMMAND`). Для этого в `~/.termux/termux.properties`: `allow-external-apps = true`.

[`device/termux/boot/10-sshd.sh`](../device/termux/boot/10-sshd.sh) берёт `termux-wake-lock` и запускает `sshd`.

Проверено перезагрузкой на зарядке: Wi-Fi через ~45 с, SSH через ~60 с, wake lock `termux:service-wakelock` удерживается.

## Wi-Fi и зарядка

Redmi 6 работает только в 2,4 ГГц. С одним из кабелей зарядки телефон после загрузки не мог подключиться к Wi-Fi (`ASSOC-REJECT status_code=16`) — помехи. С другим кабелем — подключается сразу. Если проблема вернётся: другой блок/кабель, блок подальше от телефона, канал 2,4 ГГц 6 или 11, ширина 20 МГц.