---
name: push
description: >-
  Use this skill when the user wants to upload, backup, or push local project changes to GitHub
  (e.g. says "上傳", "備份", "上傳備份", "push", or triggers /push).
---

# Upload & Backup to GitHub (`/push`)

When the user requests to upload or back up the project:

1. Check current repository status in `c:\IdleRPG_Prototype` (or workspace root):
   ```powershell
   git status --short
   ```
2. Stage all changes and create a commit if there are any uncommitted files (summarize the changes in the commit message, or use `Auto backup: <timestamp>`):
   ```powershell
   git add -A
   git commit -m "<summary of changes>"
   ```
3. Sync and push to `origin main` (disable interactive prompts so it never hangs in the background if unauthenticated):
   ```powershell
   $env:GIT_TERMINAL_PROMPT="0"; $env:GCM_INTERACTIVE="never"; git pull --rebase --autostash origin main; git push -u origin main
   ```
4. Verify the push succeeded (`git status -sb`) and report the commit ID and synced file summary concisely to the user in Traditional Chinese.
   - If authentication fails (`terminal prompts disabled`), remind the user to double-click `Sync_Push.bat` once to authorize GitHub in their browser.
