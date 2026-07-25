# 短影音腳本寫手

`reels-script-writer` 是內容廚房系統的步驟 4：接住已確認的選題、切角、呈現形式、核心素材與選用 Hook，交付一版可拍的短影音腳本。它不負責批量想切角或設計多個 Hook；這兩件事分別交給步驟 2 與步驟 5。

輸出固定包含鉤子、主體與結尾，主體可組合觀點、真實故事、知識。CTA 依內容目標與現有資源決定，沒有導流需求時不硬塞。

## 安裝、更新與移除

預設安裝到目前專案：

```bash
npx skills add Jaycheng1103/superbrain-reels-script-writer --skill reels-script-writer --full-depth
npx skills update --project reels-script-writer
npx skills remove reels-script-writer --yes
```

若要安裝成全域副本，三個指令都要加上 `--global`：

```bash
npx skills add Jaycheng1103/superbrain-reels-script-writer --skill reels-script-writer --full-depth --global
npx skills update --global reels-script-writer
npx skills remove --global reels-script-writer --yes
```

專案與全域安裝是兩份獨立副本，不會自動同步。手動安裝時，保留整個資料夾與 `references/`，再放到支援 `SKILL.md` 的 skill 目錄。詳細使用方式見 [如何使用.md](如何使用.md)。

## 使用原則

- 最好先完成內容廚房的選題、切角、呈現形式與 Hook；缺少其中幾項時，本 skill 會標示暫定決定並提供一版保守腳本。
- 不要輸入客戶個資、未公開逐字稿、帳密、權杖、合約或未公開營收。外部數據與案例請保留原始來源。
- 本 repo 是課程教材，與任何 AI、社群或影片平台沒有官方關係。使用者須自行確認平台規範、著作權與素材授權。
- 這是可拍初稿，不保證流量、完播、觸及或轉換。拍前請念過台詞，補回自己的語感與已確認細節。

## 手動 eval

`evals/evals.json` 有 3 組功能 case，`evals/trigger-evals.json` 有 20 組觸發／不觸發 case。請在乾淨對話逐一貼上 prompt，逐條檢查 expectations；所有安全 expectation 必須通過、其餘至少 90% 通過，且 20 組 trigger 都需相符。結構 validator 通過不代表語意或事實已通過人工審核。

```bash
./tests/validate_repo.sh
python3 /Users/zhengyujie/.codex/skills/.system/skill-creator/scripts/quick_validate.py .
```

採課程使用授權，詳見 [LICENSE.md](LICENSE.md)。
