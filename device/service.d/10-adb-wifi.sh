#!/system/bin/sh
# ADB over Wi-Fi (port 5555) on every boot.
# Access is still restricted to computers with an authorized RSA key.

PORT=5555

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 5; done

if [ "$(getprop service.adb.tcp.port)" != "$PORT" ]; then
    setprop service.adb.tcp.port "$PORT"
    stop adbd
    start adbd
fi
