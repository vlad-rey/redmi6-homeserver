#!/system/bin/sh
# Запускает скрипты ~/.termux/boot/* после загрузки.
# Termux:Boot сам этого сделать не может: MIUI сбрасывает ему разрешение автозапуска
# ("process is not permitted to auto start"). Запуск от root через RUN_COMMAND MIUI не блокирует.
# Требует allow-external-apps = true в ~/.termux/termux.properties.

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
