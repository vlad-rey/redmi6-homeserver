# Removes packages listed in device\debloat\packages.txt for user 0 (reversible).
# Run:     powershell -ExecutionPolicy Bypass -File tools\debloat.ps1 -Serial <IP>:5555
# Restore: powershell -ExecutionPolicy Bypass -File tools\debloat.ps1 -Serial <IP>:5555 -Restore

param([string]$Serial = '', [switch]$Restore)

$Adb = 'C:\Users\vreds\AppData\Local\Android\Sdk\platform-tools\adb.exe'
$List = Join-Path (Split-Path $PSScriptRoot) 'device\debloat\packages.txt'
$A = @(); if ($Serial) { $A = @('-s', $Serial) }

$pkgs = Get-Content $List | ForEach-Object { ($_ -split '#')[0].Trim() } | Where-Object { $_ }
$present = & $Adb @A shell pm list packages | ForEach-Object { $_ -replace '^package:' }

foreach ($p in $pkgs) {
    if ($Restore) {
        $r = & $Adb @A shell cmd package install-existing $p
    } elseif ($present -contains $p) {
        $r = & $Adb @A shell pm uninstall -k --user 0 $p
    } else {
        $r = 'already removed'
    }
    '{0,-42} {1}' -f $p, ($r -join ' ')
}
