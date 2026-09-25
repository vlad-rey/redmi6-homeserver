#!/system/bin/sh
# Сервер должен сам включаться, когда появляется питание после полного разряда.
# MediaTek в этом случае грузится в режим «зарядка при выключенном питании» (KPOC, ro.bootmode=charger)
# и показывает анимацию зарядки. Отсюда сразу перезагружаемся в Android.

mode=$(getprop ro.bootmode)
[ -z "$mode" ] && mode=$(getprop ro.boot.mode)

case "$mode" in
    charger|kpoc)
        echo "$(date '+%F %T') boot mode $mode -> reboot" >> /data/adb/homeserver/boot.log
        reboot
        ;;
esac
