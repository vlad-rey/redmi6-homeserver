# S3. ADB по Wi-Fi и ограничение заряда

Скрипты автозапуска Magisk лежат в [`device/service.d/`](../device/service.d/) и ставятся на телефон в `/data/adb/service.d/`:

```bash
powershell -ExecutionPolicy Bypass -File tools\deploy-service-d.ps1
```

## ADB по Wi-Fi — `10-adb-wifi.sh`

После загрузки выставляет `service.adb.tcp.port=5555` и перезапускает `adbd`. USB-отладка продолжает работать параллельно.

```bash
adb connect <IP>:5555
```

IP телефона закреплён в роутере и записан в `device.local.json` (не в git). Подключиться может только компьютер, чей RSA-ключ разрешён на телефоне.

## Ограничение заряда — `20-charge-limit.sh`

Управляющий файл ядра: `/sys/class/power_supply/battery/charging_enable` (`0` — зарядка остановлена, телефон питается от батареи при подключённом USB; `1` — зарядка идёт). Проверено 2026-09-25: при `0` статус `Not charging`, ток −46 мА.

| Параметр | Значение по умолчанию |
|---|---|
| `STOP` | 80 % — выключить зарядку |
| `START` | 40 % — включить зарядку |
| `TEMP_MAX` | 450 (45,0 °C) — выключить зарядку при перегреве |
| `INTERVAL` | 60 с |

Переопределение без переустановки: `/data/adb/homeserver/charge.conf`, например:

```sh
STOP=75
START=60
```

Файлы на телефоне:

- `/data/adb/homeserver/charge.log` — журнал переключений;
- `/data/adb/homeserver/charge.state` — текущее состояние (для хаба и мониторинга).

```bash
adb shell su -c cat /data/adb/homeserver/charge.state
```