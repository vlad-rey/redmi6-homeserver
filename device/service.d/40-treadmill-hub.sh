#!/system/bin/sh
# Starts the treadmill hub after boot (MIUI doesn't allow apps to autostart).
# https://github.com/vlad-rey/treadmill-hub

PKG=io.github.vladrey.treadmillhub

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 5; done
sleep 10

pm path "$PKG" >/dev/null 2>&1 || exit 0
dumpsys deviceidle whitelist +"$PKG" >/dev/null
am start-foreground-service --user 0 -n "$PKG/.HubService"
