---
name: pull
description: >-
  Use this skill when the user wants to download, pull, or sync the latest project changes from GitHub
  (e.g. says "下載", "同步", "下載同步", "更新進度", "pull", or triggers /pull).
---

# Download & Sync from GitHub (`/pull`)

When the user requests to download or sync the latest progress from GitHub:

1. Run `git pull --rebase --autostash origin main` in the workspace root (with non-interactive env vars to prevent background hanging):
   ```powershell
   $env:GIT_TERMINAL_PROMPT="0"; $env:GCM_INTERACTIVE="never"; git pull --rebase --autostash origin main
   ```
2. Check the latest commit log and status:
   ```powershell
   git log -n 3 --oneline --decorate; git status -sb
   ```
3. Report the sync result and latest commit summary concisely to the user in Traditional Chinese.
   - If authentication fails (`terminal prompts disabled`), remind the user to double-click `Sync_Pull.bat` once to authorize GitHub in their browser.
