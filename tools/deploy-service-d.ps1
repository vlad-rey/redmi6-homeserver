# Installs the scripts from device\service.d to /data/adb/service.d on the phone (requires root).
# Run: powershell -ExecutionPolicy Bypass -File tools\deploy-service-d.ps1 [-Serial <IP>:5555]

param([string]$Serial = '')

$ErrorActionPreference = 'Stop'
$Adb = 'C:\Users\vreds\AppData\Local\Android\Sdk\platform-tools\adb.exe'
$Src = Join-Path (Split-Path $PSScriptRoot) 'device\service.d'
$A = @(); if ($Serial) { $A = @('-s', $Serial) }

foreach ($f in Get-ChildItem $Src -Filter *.sh) {
    # Ensure LF line endings, otherwise sh on the phone won't run the script
    $tmp = Join-Path $env:TEMP $f.Name
    $text = [IO.File]::ReadAllText($f.FullName) -replace "`r`n", "`n"
    [IO.File]::WriteAllText($tmp, $text, (New-Object Text.UTF8Encoding $false))

    & $Adb @A push $tmp "/data/local/tmp/$($f.Name)" | Out-Null
    & $Adb @A shell "su -c 'cp /data/local/tmp/$($f.Name) /data/adb/service.d/ && chmod 0755 /data/adb/service.d/$($f.Name)'"
    Write-Host "installed $($f.Name)"
}
& $Adb @A shell "su -c 'ls -l /data/adb/service.d/'"
