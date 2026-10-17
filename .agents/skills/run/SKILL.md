---
name: run
description: >-
  Use this skill when the user wants to run or play the game
  (e.g. says "執行", "跑遊戲", "啟動", "玩遊戲", "run", or triggers /run).
---

# Run & Launch Game (`/run` / "執行")

When the user asks to run or play the game (e.g. inputs "執行", "啟動", "跑遊戲", or `/run`):

1. **Launch the game process directly using PowerShell**:
   ```powershell
   $godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
   if (-not (Test-Path ".godot\global_script_class_cache.cfg")) {
       & $godot --headless --import --path "$PWD"
   }
   Start-Process $godot -ArgumentList "--path `"$PWD`" --position 200,50"
   ```

2. **Report back to the user**:
   - Inform the user that the game has been launched in Traditional Chinese.
