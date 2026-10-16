---
name: pull
description: >-
  Use this skill when the user wants to download, pull, or sync the latest project changes from GitHub
  (e.g. says "下載", "同步", "下載同步", "更新進度", "pull", or triggers /pull).
---

# Download & Sync from GitHub (`/pull`)

When the user requests to download or sync the latest progress from GitHub:

1. **Ensure `git` is in `PATH` and pull latest changes** in the workspace root (with non-interactive env vars to prevent background hanging):
   ```powershell
   if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $env:Path += ";C:\Program Files\Git\cmd" }
   $env:GIT_TERMINAL_PROMPT="0"; $env:GCM_INTERACTIVE="never"; git pull --rebase --autostash origin main
   ```

2. **Check the latest commit log and status**:
   ```powershell
   if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $env:Path += ";C:\Program Files\Git\cmd" }
   git log -n 3 --oneline --decorate; git status -sb
   ```

3. **Read Cross-Machine Context (`PROGRESS.md`)**:
   - View `PROGRESS.md` in the workspace root to load the latest conversation summary, recent changes, and next steps from the previous computer.

4. **Report to the User**:
   - Report the sync result, latest commit summary, and a brief summary of the current progress/next steps from `PROGRESS.md` in Traditional Chinese.
   - If authentication fails (`terminal prompts disabled`), remind the user to double-click `Sync_Pull.bat` once to authorize GitHub in their browser.
