# Clones mtkclient into D:\Code\tools\mtkclient and sets up an environment on Python 3.12.
# Run: powershell -ExecutionPolicy Bypass -File tools\setup-mtkclient.ps1

$ErrorActionPreference = 'Stop'
$Dir = 'D:\Code\tools\mtkclient'

& py -3.12 --version
if ($LASTEXITCODE -ne 0) {
    throw 'Python 3.12 not found. Install with: winget install Python.Python.3.12'
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
    throw 'Failed to install dependencies. See docs\01-backup-and-unlock.md, part B.'
}

& "$Dir\.venv\Scripts\python.exe" "$Dir\mtk.py" -h | Select-Object -First 5
Write-Host "`nmtkclient ready: $Dir" -ForegroundColor Green
