#!/system/bin/sh
# Power saving for the server phone (run once as root; settings persist).
# Cellular is turned off via airplane mode; Wi-Fi and Bluetooth stay on.
# If Wi-Fi doesn't reconnect within 20 s of enabling airplane mode, everything is reverted.

LOG=/data/adb/homeserver/power.log
log() { echo "$(date '+%F %T') $*" >> "$LOG"; }

# Airplane mode disables cellular only
settings put global airplane_mode_radios cell
settings put global airplane_mode_toggleable_radios bluetooth,wifi,nfc
settings put global mobile_data 0

# No screen needed on a server: turns off after 15 s, minimum brightness
settings put system screen_off_timeout 15000
settings put system screen_brightness_mode 0
settings put system screen_brightness 10

# Background scanning and location are not needed (the treadmill's location is known)
settings put global wifi_scan_always_enabled 0
settings put global ble_scan_always_enabled 0
settings put secure location_mode 0
# Wi-Fi doesn't sleep when the screen is off
settings put global wifi_sleep_policy 2

if [ "$(settings get global airplane_mode_on)" != 1 ]; then
    settings put global airplane_mode_on 1
    am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true >/dev/null
    log "airplane mode enabled (cellular only)"
    sleep 5
    svc wifi enable
    svc bluetooth enable
    ok=0
    for i in 1 2 3 4; do
        sleep 5
        dumpsys wifi | grep -q 'Supplicant state: COMPLETED' && { ok=1; break; }
    done
    if [ "$ok" != 1 ]; then
        settings put global airplane_mode_on 0
        am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false >/dev/null
        svc wifi enable
        log "Wi-Fi did not come up in airplane mode — airplane mode reverted"
        exit 1
    fi
    log "Wi-Fi works in airplane mode"
fi
