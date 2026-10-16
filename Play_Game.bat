@echo off
cd /d "%~dp0"
set "GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"

if not exist ".godot\global_script_class_cache.cfg" (
    echo [Init] Generating Godot class cache for first run...
    "%GODOT_EXE%" --headless --import --path "%cd%"
)

start "" "%GODOT_EXE%" --path "%cd%" --position 200,50
