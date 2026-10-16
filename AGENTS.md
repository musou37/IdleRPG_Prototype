# Project Rules & Custom Commands (IdleRPG_Prototype)

## 專案雲端同步指令 (GitHub Sync Commands)

當使用者在對話中輸入以下簡短指令時，請直接為使用者執行對應的 Git 操作，無須再次詢問確認：

1. **「上傳」/「備份」/「上傳備份」/ `/push`**：
   - 自動執行 `git add -A`，根據變更內容產生清楚的 Commit 訊息並提交（若無新變更則略過 commit）。
   - 執行 `$env:GIT_TERMINAL_PROMPT="0"; $env:GCM_INTERACTIVE="never"; git pull --rebase --autostash origin main; git push -u origin main` 將最新進度推送至 GitHub (`https://github.com/musou37/IdleRPG_Prototype.git`)。
   - 回報上傳結果與目前的 Commit ID。

2. **「下載」/「同步」/「下載同步」/ `/pull`**：
   - 自動執行 `$env:GIT_TERMINAL_PROMPT="0"; $env:GCM_INTERACTIVE="never"; git pull --rebase --autostash origin main` 從 GitHub 拉取最新進度。
   - 回報更新狀態與最新的 Commit 紀錄。
