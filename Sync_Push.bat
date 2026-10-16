@echo off
cd /d "%~dp0"
echo ==================================================
echo   [IdleRPG] Backing up and pushing to GitHub...
echo ==================================================
echo.

git add -A
git status --short

set "HAS_CHANGES="
for /f "delims=" %%i in ('git status --porcelain') do set "HAS_CHANGES=1"

if defined HAS_CHANGES (
    git commit -m "Auto backup: %date% %time%"
) else (
    echo [INFO] No new local changes to commit.
)

git rev-parse --verify origin/main >nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo [SYNC] Pulling latest changes from GitHub first...
    git pull --rebase --autostash origin main
)

echo.
echo [PUSH] Uploading to GitHub (origin/main)...
git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo [OK] Backup successfully uploaded to GitHub!
) else (
    echo.
    echo [ERROR] Push failed. Please check your network or GitHub login.
)
echo.
pause