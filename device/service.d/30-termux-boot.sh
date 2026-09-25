#!/system/bin/sh
# Runs the ~/.termux/boot/* scripts after boot.
# Termux:Boot can't do this on its own: MIUI resets its autostart permission
# ("process is not permitted to auto start"). MIUI doesn't block launching as root via RUN_COMMAND.
# Requires allow-external-apps = true in ~/.termux/termux.properties.

BOOT=/data/data/com.termux/files/home/.termux/boot

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 5; done
sleep 15

for f in "$BOOT"/*; do
    [ -f "$f" ] || continue
    am start-foreground-service --user 0 \
        -n com.termux/com.termux.app.RunCommandService \
        -a com.termux.RUN_COMMAND \
        --es com.termux.RUN_COMMAND_PATH "$f" \
        --ez com.termux.RUN_COMMAND_BACKGROUND true
done
