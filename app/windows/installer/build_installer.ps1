# Builds the Windows installer (build\installer\OrdoSetup-<version>.exe) in one go:
#   1. flutter build windows --release
#   2. copies the Visual C++ runtime next to the app (app-local, so it runs on a Windows without it)
#   3. compiles tarefas.iss with Inno Setup 6
# Run from the app folder:  powershell -ExecutionPolicy Bypass -File windows\installer\build_installer.ps1
#   -KeepIconFonts: skips shrinking the icon fonts (font-subset.exe), for a machine whose Smart App
#   Control blocks that tool; the app is about 1.6 MB bigger.
param([switch]$KeepIconFonts)

$ErrorActionPreference = 'Stop'
$app = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $app

# Windows PowerShell mangles a "--flag" splatted from an array: each call spelled out.
if ($KeepIconFonts) { flutter build windows --release '--no-tree-shake-icons' } else { flutter build windows --release }
if ($LASTEXITCODE -ne 0) { throw 'flutter build windows failed' }

# The newest x64 CRT from any Visual Studio 2022 install (the redistributable Microsoft allows to ship).
$crt = Get-ChildItem -Directory -Path @(
    'C:\Program Files\Microsoft Visual Studio\2022\*\VC\Redist\MSVC\*\x64\Microsoft.VC143.CRT',
    'C:\Program Files (x86)\Microsoft Visual Studio\2022\*\VC\Redist\MSVC\*\x64\Microsoft.VC143.CRT'
) -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1
if (-not $crt) { throw 'Visual C++ redistributable (Microsoft.VC143.CRT) not found; install Visual Studio 2022 with C++.' }
$release = Join-Path $app 'build\windows\x64\runner\Release'
foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
    Copy-Item (Join-Path $crt.FullName $dll) $release -Force
}

$iscc = @(
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
    'C:\Program Files\Inno Setup 6\ISCC.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 not found (winget install JRSoftware.InnoSetup).' }
& $iscc (Join-Path $PSScriptRoot 'tarefas.iss')
if ($LASTEXITCODE -ne 0) { throw 'Inno Setup failed' }
Get-ChildItem (Join-Path $app 'build\installer') | Select-Object Name, Length
