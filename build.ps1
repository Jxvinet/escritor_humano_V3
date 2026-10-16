# Compila el .exe y deja la carpeta lista en dist\
# Necesitas AutoHotkey v2. Si no tienes Ahk2Exe, lo descarga solo.

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

$Ahk = @(
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
    "${env:ProgramFiles(x86)}\AutoHotkey\v2\AutoHotkey64.exe",
    "$env:LocalAppData\Programs\AutoHotkey\v2\AutoHotkey64.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $Ahk) { throw "No encuentro AutoHotkey v2." }

$Tools = Join-Path $Root "tools\Ahk2Exe"
$Ahk2Exe = Join-Path $Tools "Ahk2Exe.exe"
if (-not (Test-Path $Ahk2Exe)) {
    New-Item -ItemType Directory -Force -Path $Tools | Out-Null
    $Zip = Join-Path $env:TEMP "Ahk2Exe-build.zip"
    $Url = "https://github.com/AutoHotkey/Ahk2Exe/releases/download/Ahk2Exe1.1.37.02a2/Ahk2Exe1.1.37.02a2.zip"
    Invoke-WebRequest -Uri $Url -OutFile $Zip -UseBasicParsing
    Expand-Archive -Path $Zip -DestinationPath $Tools -Force
}

$Dist = Join-Path $Root "dist"
$Pack = Join-Path $Dist "escritor_humano_V3"
New-Item -ItemType Directory -Force -Path $Dist | Out-Null
New-Item -ItemType Directory -Force -Path $Pack | Out-Null

$In = Join-Path $Root "escritor_humano_V3.ahk"
$Out = Join-Path $Dist "escritor_humano_V3.exe"
$Ico = Join-Path $Root "icono-j.ico"

& $Ahk2Exe /in $In /out $Out /base $Ahk /icon $Ico /compress 0
if (-not (Test-Path $Out)) { throw "No se pudo compilar." }

$Copy = @(
    "puente-navegador.ps1",
    "fijar-icono-aviso.ps1",
    "icono-j.ico",
    "icono.ico",
    "icono.png",
    "ayuda.png",
    "texto.txt",
    "ajustes.ini",
    "INSTRUCCIONES.txt",
    "README.md"
)
Copy-Item $Out (Join-Path $Pack "escritor_humano_V3.exe") -Force
foreach ($f in $Copy) {
    $src = Join-Path $Root $f
    if (Test-Path $src) { Copy-Item $src (Join-Path $Pack $f) -Force }
}

$ZipOut = Join-Path $Dist "escritor_humano_V3-windows.zip"
if (Test-Path $ZipOut) { Remove-Item $ZipOut -Force }
Compress-Archive -Path $Pack -DestinationPath $ZipOut -Force

Write-Host "Listo: $Out"
Write-Host "Zip: $ZipOut"
