@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if not exist "%~dp0escritor_humano_V3.ahk" (
    echo Falta escritor_humano_V3.ahk en esta carpeta.
    pause
    exit /b 1
)

set "AHK="
if exist "%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe" set "AHK=%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe"
if not defined AHK if exist "%ProgramFiles%\AutoHotkey\v2\AutoHotkey32.exe" set "AHK=%ProgramFiles%\AutoHotkey\v2\AutoHotkey32.exe"
if not defined AHK if exist "%LocalAppData%\Programs\AutoHotkey\v2\AutoHotkey64.exe" set "AHK=%LocalAppData%\Programs\AutoHotkey\v2\AutoHotkey64.exe"
if not defined AHK if exist "%LocalAppData%\Programs\AutoHotkey\v2\AutoHotkey32.exe" set "AHK=%LocalAppData%\Programs\AutoHotkey\v2\AutoHotkey32.exe"
if not defined AHK if exist "%ProgramFiles(x86)%\AutoHotkey\v2\AutoHotkey64.exe" set "AHK=%ProgramFiles(x86)%\AutoHotkey\v2\AutoHotkey64.exe"
if not defined AHK if exist "%ProgramFiles(x86)%\AutoHotkey\v2\AutoHotkey32.exe" set "AHK=%ProgramFiles(x86)%\AutoHotkey\v2\AutoHotkey32.exe"

if not defined AHK call :BuscarRegistro HKLM
if not defined AHK call :BuscarRegistro HKCU

if not defined AHK (
    echo No se encontro AutoHotkey 2.0.
    echo Instalalo desde https://www.autohotkey.com/  elige la version 2.0
    echo Mientras tanto puedes usar iniciar-powershell.bat
    echo.
    pause
    exit /b 1
)

rem Crea/actualiza el acceso directo con el icono de la J
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ahk=$env:AHK; if(-not $ahk){$ahk='%~dp0'}; $ahk='%AHK%'; $src='%~dp0escritor_humano_V3.ahk'; $ico='%~dp0icono-j.ico'; $lnk='%~dp0escritor_humano_V3.lnk'; $s=(New-Object -ComObject WScript.Shell).CreateShortcut($lnk); $s.TargetPath=$ahk; $s.Arguments=[char]34+$src+[char]34; $s.WorkingDirectory='%~dp0'; if(Test-Path $ico){$s.IconLocation=$ico}; $s.Description='escritor_humano_V3'; $s.Save()"

if exist "%~dp0escritor_humano_V3.lnk" (
    start "" "%~dp0escritor_humano_V3.lnk"
) else (
    start "" "%AHK%" "%~dp0escritor_humano_V3.ahk"
)
exit /b 0

:BuscarRegistro
set "AHKDIR="
for /f "skip=2 tokens=1,2*" %%A in ('reg query "%~1\SOFTWARE\AutoHotkey" /v InstallDir 2^>nul') do (
    if /I "%%A"=="InstallDir" set "AHKDIR=%%C"
)
if not defined AHKDIR goto :eof
if exist "%AHKDIR%\v2\AutoHotkey64.exe" set "AHK=%AHKDIR%\v2\AutoHotkey64.exe"
if not defined AHK if exist "%AHKDIR%\v2\AutoHotkey32.exe" set "AHK=%AHKDIR%\v2\AutoHotkey32.exe"
goto :eof
