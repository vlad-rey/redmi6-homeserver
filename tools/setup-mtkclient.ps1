# Клонирует mtkclient в D:\Code\tools\mtkclient и создаёт окружение на Python 3.12.
# Запуск: powershell -ExecutionPolicy Bypass -File tools\setup-mtkclient.ps1

$ErrorActionPreference = 'Stop'
$Dir = 'D:\Code\tools\mtkclient'

& py -3.12 --version
if ($LASTEXITCODE -ne 0) {
    throw 'Python 3.12 не найден. Установите: winget install Python.Python.3.12'
}

if (Test-Path $Dir) {
    git -C $Dir pull --ff-only
} else {
    New-Item -ItemType Directory -Force (Split-Path $Dir) | Out-Null
    git clone https://github.com/bkerler/mtkclient $Dir
}

if (-not (Test-Path "$Dir\.venv")) {
    & py -3.12 -m venv "$Dir\.venv"
}

& "$Dir\.venv\Scripts\python.exe" -m pip install --upgrade pip
& "$Dir\.venv\Scripts\python.exe" -m pip install -r "$Dir\requirements.txt"
if ($LASTEXITCODE -ne 0) {
    throw 'Не удалось установить зависимости. См. docs\01-backup-and-unlock.md, часть B.'
}

& "$Dir\.venv\Scripts\python.exe" "$Dir\mtk.py" -h | Select-Object -First 5
Write-Host "`nmtkclient готов: $Dir" -ForegroundColor Green
