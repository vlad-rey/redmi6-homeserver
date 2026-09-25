# Бэкап данных хаба дорожки (профили, свои программы, тренировки, настройки) с телефона на PC.
# Запуск: powershell -ExecutionPolicy Bypass -File tools\backup-hub-data.ps1 [-Dest D:\Backups\treadmill-hub] [-Keep 90]
# Адрес телефона берётся из device.local.json (не в git).
# Восстановление — см. docs/04-backup.md.

param([string]$Dest = 'D:\Backups\treadmill-hub', [int]$Keep = 90)

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot
$Adb = 'C:\Users\vreds\AppData\Local\Android\Sdk\platform-tools\adb.exe'
$Pkg = 'io.github.vladrey.treadmillhub'
$Serial = (Get-Content "$Root\device.local.json" -Raw | ConvertFrom-Json).adb
$Log = Join-Path $Dest 'backup.log'
New-Item -ItemType Directory -Force $Dest | Out-Null

function Log($msg) { $line = "{0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), $msg; Add-Content -Encoding utf8 $Log $line; Write-Host $line }

try {
    & $Adb connect $Serial | Out-Null
    $name = "treadmill-hub-{0:yyyy-MM-dd_HHmm}.tgz" -f (Get-Date)

    # Скрипт на телефоне: архив данных приложения (файлы пишутся атомарно, остановка хаба не нужна)
    $sh = "tar -czf /data/local/tmp/hub-backup.tgz -C /data/data/$Pkg files shared_prefs && chmod 644 /data/local/tmp/hub-backup.tgz`n"
    $tmpSh = Join-Path $env:TEMP 'hub-backup.sh'
    [IO.File]::WriteAllText($tmpSh, $sh, (New-Object Text.UTF8Encoding $false))
    & $Adb -s $Serial push $tmpSh /data/local/tmp/hub-backup.sh | Out-Null
    & $Adb -s $Serial shell "su -c 'sh /data/local/tmp/hub-backup.sh'"
    if ($LASTEXITCODE) { throw 'не удалось создать архив на телефоне' }

    $target = Join-Path $Dest $name
    & $Adb -s $Serial pull /data/local/tmp/hub-backup.tgz $target | Out-Null
    & $Adb -s $Serial shell "su -c 'rm -f /data/local/tmp/hub-backup.tgz /data/local/tmp/hub-backup.sh'"

    # Проверка: архив читается и в нём есть профили
    $list = & tar.exe -tzf $target
    if (-not ($list -match 'files/profiles.json')) { throw "в архиве нет files/profiles.json" }
    $sessions = @($list | Where-Object { $_ -match '^files/sessions/\d+\.json$' }).Count
    Log ("OK {0} — {1:N1} КБ, тренировок: {2}" -f $name, ((Get-Item $target).Length / 1KB), $sessions)

    # Отметка на хабе: вкладка «Хаб» показывает время последнего бэкапа
    curl.exe -s -m 5 -X POST "http://$($Serial.Split(':')[0]):8080/api/hub/backup" | Out-Null

    # Храним последние $Keep архивов
    Get-ChildItem $Dest -Filter 'treadmill-hub-*.tgz' | Sort-Object Name -Descending | Select-Object -Skip $Keep | Remove-Item
}
catch {
    Log "ОШИБКА: $($_.Exception.Message)"
    exit 1
}
