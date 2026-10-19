@echo off
cd /d "%~dp0"
set "GODOT_DIR=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe"
set "GODOT_EXE=%GODOT_DIR%\Godot_v4.7.2-stable_win64.exe"
set "GODOT_CONSOLE=%GODOT_DIR%\Godot_v4.7.2-stable_win64_console.exe"

if not exist ".godot\global_script_class_cache.cfg" (
    echo [Init] Scanning scripts and importing assets...
    "%GODOT_CONSOLE%" --headless --editor --quit --path "%cd%"
)

start "" "%GODOT_EXE%" --path "%cd%" --position 200,50
