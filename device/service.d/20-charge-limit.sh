#!/system/bin/sh
# Ограничение заряда: при >= STOP % зарядка выключается, при <= START % включается.
# При температуре батареи >= TEMP_MAX зарядка выключается независимо от уровня.
# Переопределить пороги: /data/adb/homeserver/charge.conf (например, STOP=70).

STOP=80
START=40
TEMP_MAX=450        # десятые доли °C
INTERVAL=30         # секунды

B=/sys/class/power_supply/battery
DIR=/data/adb/homeserver
LOG=$DIR/charge.log
STATE=$DIR/charge.state

mkdir -p "$DIR"

log() {
    echo "$(date '+%F %T') $*" >> "$LOG"
    if [ "$(wc -c < "$LOG")" -gt 200000 ]; then
        tail -n 500 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
    fi
}

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 5; done
log "start STOP=$STOP START=$START TEMP_MAX=$TEMP_MAX"

want=1
while true; do
    [ -f "$DIR/charge.conf" ] && . "$DIR/charge.conf"

    cap=$(cat $B/capacity)
    temp=$(cat $B/temp)
    cur=$(cat $B/charging_enable | tr -dc '01')

    if [ "$temp" -ge "$TEMP_MAX" ]; then
        want=0
    elif [ "$cap" -ge "$STOP" ]; then
        want=0
    elif [ "$cap" -le "$START" ]; then
        want=1
    fi

    status=$(cat $B/status)
    if [ "$cur" != "$want" ]; then
        echo "$want" > $B/charging_enable
        log "charging_enable $cur -> $want (cap=$cap% temp=$temp)"
    elif [ "$want" = 0 ] && [ "$status" = "Charging" ]; then
        # Контроллер MediaTek сам возобновляет зарядку, а флаг остаётся 0 — верим статусу, не флагу
        echo 0 > $B/charging_enable
        log "контроллер возобновил зарядку при флаге 0 — отключаю снова (cap=$cap%)"
    fi

    echo "enable=$want cap=$cap temp=$temp status=$(cat $B/status) ts=$(date +%s)" > "$STATE"
    sleep "$INTERVAL"
done
