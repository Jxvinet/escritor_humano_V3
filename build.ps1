# Compila el .exe y deja UNA carpeta lista en dist\escritor_humano_V3\
# Necesitas AutoHotkey v2. Si falta Ahk2Exe, lo descarga.

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
if (Test-Path $Dist) { Remove-Item $Dist -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Pack | Out-Null

$In = Join-Path $Root "escritor_humano_V3.ahk"
$Out = Join-Path $Pack "escritor_humano_V3.exe"
$Ico = Join-Path $Root "icono-j.ico"

& $Ahk2Exe /in $In /out $Out /base $Ahk /icon $Ico /compress 0
if (-not (Test-Path $Out)) { throw "No se pudo compilar." }

# Solo lo que el .exe necesita al lado (sin duplicar el README ni el codigo fuente)
$Copy = @(
    "puente-navegador.ps1",
    "fijar-icono-aviso.ps1",
    "icono-j.ico",
    "ayuda.png",
    "texto.txt",
    "ajustes.ini"
)
foreach ($f in $Copy) {
    Copy-Item (Join-Path $Root $f) (Join-Path $Pack $f) -Force
}

Write-Host "Listo: $Pack"
