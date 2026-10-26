@echo off
REM update_and_play.bat - double-click to pull the latest changes and launch the game.
REM Pass "edit" (or use update_and_edit.bat) to open the Godot editor instead.
setlocal
cd /d "%~dp0"

set "GODOT=D:\Downloads folder till May15th\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe"
set "BRANCH=main-sk5b0g"

if not exist "%GODOT%" (
    echo Godot was not found at:
    echo   %GODOT%
    echo Edit the GODOT line near the top of this file to point at your Godot .exe.
    pause
    exit /b 1
)

echo [1/3] Getting the latest changes from GitHub (%BRANCH%)...
git fetch origin %BRANCH%
if errorlevel 1 goto fail_net

for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD') do set "CURRENT=%%b"
if /i not "%CURRENT%"=="%BRANCH%" (
    git checkout %BRANCH%
    if errorlevel 1 goto fail_local
)
git pull --ff-only origin %BRANCH%
if errorlevel 1 goto fail_local

echo [2/3] Refreshing Godot imports and script classes...
"%GODOT%" --headless --path "%~dp0." --import >nul 2>&1

if /i "%~1"=="edit" (
    echo [3/3] Opening the Godot editor...
    start "" "%GODOT%" --path "%~dp0." -e
) else (
    echo [3/3] Launching the game...
    start "" "%GODOT%" --path "%~dp0."
)
exit /b 0

:fail_net
echo.
echo Could not reach GitHub. Check your internet connection and try again.
pause
exit /b 1

:fail_local
echo.
echo Git could not update this folder, usually because files were changed locally.
echo Nothing was overwritten. Copy the message above and send it to Claude.
pause
exit /b 1
