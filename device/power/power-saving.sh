#!/system/bin/sh
# Экономия энергии для телефона-сервера (запуск от root, один раз; настройки сохраняются).
# Сотовая связь выключена режимом полёта, Wi-Fi и Bluetooth остаются включены.
# Если Wi-Fi после включения режима полёта не подключится за 20 с — всё возвращается обратно.

LOG=/data/adb/homeserver/power.log
log() { echo "$(date '+%F %T') $*" >> "$LOG"; }

# Режим полёта отключает только сотовую связь
settings put global airplane_mode_radios cell
settings put global airplane_mode_toggleable_radios bluetooth,wifi,nfc
settings put global mobile_data 0

# Экран серверу не нужен: гаснет через 15 с, минимальная яркость
settings put system screen_off_timeout 15000
settings put system screen_brightness_mode 0
settings put system screen_brightness 10

# Фоновые сканирования и геолокация не нужны (адрес дорожки известен)
settings put global wifi_scan_always_enabled 0
settings put global ble_scan_always_enabled 0
settings put secure location_mode 0
# Wi-Fi не засыпает при выключенном экране
settings put global wifi_sleep_policy 2

if [ "$(settings get global airplane_mode_on)" != 1 ]; then
    settings put global airplane_mode_on 1
    am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true >/dev/null
    log "режим полёта включён (только сотовая связь)"
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
        log "Wi-Fi не поднялся в режиме полёта — режим полёта отменён"
        exit 1
    fi
    log "Wi-Fi в режиме полёта работает"
fi
