@echo off
cd /d "%~dp0"
echo ==================================================
echo   [IdleRPG] Pulling latest progress from GitHub...
echo ==================================================
echo.

git pull --rebase --autostash origin main

if %errorlevel% equ 0 (
    echo.
    echo [OK] Successfully updated to the latest version!
) else (
    echo.
    echo [ERROR] Pull failed. Please check your network or file conflicts.
)
echo.
pause