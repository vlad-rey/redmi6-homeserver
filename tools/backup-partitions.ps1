# Полная резервная копия разделов Redmi 6 через mtkclient (кроме userdata).
# Телефон выключен. После появления "Waiting for device" зажать обе кнопки громкости и подключить USB.
# Запуск: powershell -ExecutionPolicy Bypass -File tools\backup-partitions.ps1

$ErrorActionPreference = 'Stop'
$Mtk = 'D:\Code\tools\mtkclient'
$Py = "$Mtk\.venv\Scripts\python.exe"
$Out = Join-Path (Split-Path $PSScriptRoot) ("backup\" + (Get-Date -Format 'yyyy-MM-dd_HHmm'))

if (-not (Test-Path $Py)) { throw 'mtkclient не установлен. Сначала tools\setup-mtkclient.ps1' }
New-Item -ItemType Directory -Force $Out | Out-Null

Write-Host "1/2 Таблица разделов -> $Out\gpt.txt" -ForegroundColor Cyan
Write-Host 'Зажмите обе кнопки громкости на выключенном телефоне и подключите USB.' -ForegroundColor Yellow
& $Py "$Mtk\mtk.py" printgpt | Tee-Object "$Out\gpt.txt"
if ($LASTEXITCODE -ne 0) { throw 'printgpt не удался' }

Write-Host "`n2/2 Чтение всех разделов, кроме userdata -> $Out" -ForegroundColor Cyan
Write-Host 'Если телефон перезагрузился: снова выключите его, зажмите обе кнопки громкости и подключите USB.' -ForegroundColor Yellow
& $Py "$Mtk\mtk.py" rl $Out --skip userdata
if ($LASTEXITCODE -ne 0) { throw 'rl не удался' }

Write-Host "`nГотово. Проверка ключевых разделов:" -ForegroundColor Green
foreach ($p in 'boot','recovery','nvram','nvdata','protect1','protect2','seccfg','lk','vbmeta') {
    $f = Get-ChildItem $Out -Filter "$p.bin" -ErrorAction SilentlyContinue
    if ($f) { '{0,-10} {1,8:N1} МБ' -f $p, ($f.Length / 1MB) } else { '{0,-10} нет' -f $p }
}
