#!/system/bin/sh
# Charge limiting: charging turns off at >= STOP%, turns on at <= START%.
# Charging turns off regardless of level if battery temperature >= TEMP_MAX.
# Override thresholds via: /data/adb/homeserver/charge.conf (e.g. STOP=70).

STOP=80
START=40
TEMP_MAX=450        # tenths of a degree C
INTERVAL=30         # seconds

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
        # The MediaTek controller resumes charging on its own while the flag still reads 0 — trust the status, not the flag
        echo 0 > $B/charging_enable
        log "controller resumed charging while flag was 0 — turning it off again (cap=$cap%)"
    fi

    echo "enable=$want cap=$cap temp=$temp status=$(cat $B/status) ts=$(date +%s)" > "$STATE"
    sleep "$INTERVAL"
done
