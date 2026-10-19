@echo off
cd /d "%~dp0"
where git >nul 2>&1
if %errorlevel% neq 0 (
    if exist "C:\Program Files\Git\cmd\git.exe" set "PATH=%PATH%;C:\Program Files\Git\cmd"
)

echo ==================================================
echo   [IdleRPG] Pulling latest progress from GitHub...
echo ==================================================
echo.

git pull --rebase --autostash origin main

if %errorlevel% equ 0 (
    echo.
    echo [SYNC] Refreshing Godot class cache and assets...
    if exist ".godot\global_script_class_cache.cfg" del /f /q ".godot\global_script_class_cache.cfg"
    set "GODOT_CONSOLE=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
    if exist "%GODOT_CONSOLE%" (
        "%GODOT_CONSOLE%" --headless --editor --quit --path "%cd%" >nul 2>&1
    )
    echo [OK] Successfully updated to the latest version!
) else (
    echo.
    echo [ERROR] Pull failed. Please check your network or file conflicts.
)
echo.
pause