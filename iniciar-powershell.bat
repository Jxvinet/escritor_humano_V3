@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if not exist "%~dp0escritor.ps1" (
    echo Falta escritor.ps1 en esta carpeta.
    pause
    exit /b 1
)

if not exist "%~dp0texto.txt" (
    echo Falta texto.txt en esta carpeta.
    pause
    exit /b 1
)

start "" "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0escritor.ps1"
exit /b 0
