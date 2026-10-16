---
name: push
description: >-
  Use this skill when the user wants to upload, backup, or push local project changes to GitHub
  (e.g. says "上傳", "備份", "上傳備份", "push", or triggers /push).
---

# Upload & Backup to GitHub (`/push`)

When the user requests to upload or back up the project:

1. **Update Cross-Machine Context (`PROGRESS.md`)**:
   - Summarize the progress, architectural decisions, completed tasks, and next steps from the current conversation and update `PROGRESS.md` in the workspace root so the next machine/session has full context.

2. **Ensure `git` is in `PATH` and check repository status**:
   ```powershell
   if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $env:Path += ";C:\Program Files\Git\cmd" }
   git status --short
   ```

3. **Stage all changes and create a commit** if there are any uncommitted files (summarize the changes in the commit message, or use `Auto backup: <timestamp>`):
   ```powershell
   if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $env:Path += ";C:\Program Files\Git\cmd" }
   git add -A
   git commit -m "<summary of changes>"
   ```

4. **Sync and push to `origin main`** (disable interactive prompts so it never hangs in the background if unauthenticated):
   ```powershell
   if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $env:Path += ";C:\Program Files\Git\cmd" }
   $env:GIT_TERMINAL_PROMPT="0"; $env:GCM_INTERACTIVE="never"; git pull --rebase --autostash origin main; git push -u origin main
   ```

5. **Verify and Report**:
   - Check `git status -sb` and report the commit ID, synced file summary, and `PROGRESS.md` handoff status concisely to the user in Traditional Chinese.
   - If authentication fails (`terminal prompts disabled`), remind the user to double-click `Sync_Push.bat` once to authorize GitHub in their browser.
