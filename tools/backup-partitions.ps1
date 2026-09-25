# Full backup of Redmi 6 partitions via mtkclient (except userdata).
# The phone is off. Once "Waiting for device" appears, hold both volume buttons and connect USB.
# Run: powershell -ExecutionPolicy Bypass -File tools\backup-partitions.ps1

$ErrorActionPreference = 'Stop'
$Mtk = 'D:\Code\tools\mtkclient'
$Py = "$Mtk\.venv\Scripts\python.exe"
$Out = Join-Path (Split-Path $PSScriptRoot) ("backup\" + (Get-Date -Format 'yyyy-MM-dd_HHmm'))

if (-not (Test-Path $Py)) { throw 'mtkclient is not installed. Run tools\setup-mtkclient.ps1 first' }
New-Item -ItemType Directory -Force $Out | Out-Null

Write-Host "1/2 Partition table -> $Out\gpt.txt" -ForegroundColor Cyan
Write-Host 'Hold both volume buttons on the powered-off phone and connect USB.' -ForegroundColor Yellow
& $Py "$Mtk\mtk.py" printgpt | Tee-Object "$Out\gpt.txt"
if ($LASTEXITCODE -ne 0) { throw 'printgpt failed' }

Write-Host "`n2/2 Reading all partitions except userdata -> $Out" -ForegroundColor Cyan
Write-Host 'Reconnect the phone: disconnect USB, hold power for ~10 s (the phone will turn off), then hold both volume buttons again and connect USB.' -ForegroundColor Yellow
& $Py "$Mtk\mtk.py" rl $Out --skip userdata
if ($LASTEXITCODE -ne 0) { throw 'rl failed' }

Write-Host "`nDone. Checking key partitions:" -ForegroundColor Green
foreach ($p in 'boot','recovery','nvram','nvdata','protect1','protect2','seccfg','lk','vbmeta') {
    $f = Get-ChildItem $Out -Filter "$p.bin" -ErrorAction SilentlyContinue
    if ($f) { '{0,-10} {1,8:N1} MB' -f $p, ($f.Length / 1MB) } else { '{0,-10} missing' -f $p }
}
