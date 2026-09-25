#!/system/bin/sh
# ADB по Wi-Fi (порт 5555) при каждой загрузке.
# Доступ по-прежнему только для компьютеров с разрешённым RSA-ключом.

PORT=5555

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 5; done

if [ "$(getprop service.adb.tcp.port)" != "$PORT" ]; then
    setprop service.adb.tcp.port "$PORT"
    stop adbd
    start adbd
fi
