# Энергопотребление и автовключение

## Экономия (2026-09-25)

Скрипт [`device/power/power-saving.sh`](../device/power/power-saving.sh), запуск один раз от root (настройки сохраняются):

- режим полёта **только для сотовой связи** (`airplane_mode_radios=cell`) — Wi-Fi и Bluetooth работают; если Wi-Fi после включения не поднялся за 20 с, режим полёта откатывается;
- экран гаснет через 15 с, минимальная яркость;
- фоновые сканирования Wi-Fi/Bluetooth и геолокация выключены (адрес дорожки известен);
- Google Play Store удалён для пользователя 0 (в фоне занимал ~24 % CPU), см. `device/debloat/packages.txt`.

Замер потребления при остановленной зарядке и выключенном экране: **≈ 57–63 мА** (~0,2 Вт). Хаб ≈ 8 % одного ядра. Wake lock процессора и Wi-Fi high-perf оставлены: без high-perf скорость Wi-Fi падала до ~70 КБ/с при той же потребляемой мощности.

### Ограничитель заряда

Контроллер MediaTek сам возобновляет зарядку, а флаг `charging_enable` продолжает показывать `0`. Поэтому [`20-charge-limit.sh`](../device/service.d/20-charge-limit.sh) ориентируется на фактический `status` (`Charging`) и при необходимости пишет `0` снова; проверка каждые 30 с.

## Автовключение после полного разряда

Когда батарея села, а питание вернулось, MediaTek грузится в режим «зарядка при выключенном питании» (KPOC, `ro.bootmode=charger`). Скрипты Magisk (`post-fs-data.d`, `service.d`) в этом режиме **не выполняются** — проверено.

Решение — правило init в ramdisk через штатный механизм Magisk `overlay.d` ([`device/boot-overlay/autoboot.rc`](../device/boot-overlay/autoboot.rc)):

```
on charger
    exec_background u:r:magisk:s0 root root -- /system/bin/sh -c "sleep 30; /system/bin/reboot"
```

Проверено 2026-09-25: `reboot -p` при подключённом питании → через **91 с** Android загрузился сам.

### Как собрано и прошито

1. Текущий `boot` (с Magisk) снят с телефона: `dd if=/dev/block/by-name/boot`.
2. `magiskboot unpack` → `magiskboot cpio ramdisk.cpio "mkdir 0750 overlay.d" "add 0644 overlay.d/autoboot.rc autoboot.rc"` → `magiskboot repack`.
3. **Раздел `boot` из Android не записывается** (`dd` возвращает успех, но данные не меняются — защита eMMC). Прошивка — только из fastboot по USB: `fastboot flash boot boot-magisk-autoboot.img`.

Образы (не в git): `backup/patched/boot-magisk-autoboot.img` (текущий, SHA-1 `aa05a01a…`), `backup/patched/magisk_patched-30700_YhUGg.img` (Magisk без автовключения), `backup/<дата>/boot.bin` (стоковый).

⚠️ Переустановка/обновление Magisk через приложение перепатчит `boot` из стокового образа — правило `overlay.d` пропадёт, его нужно добавить заново по шагам выше.
