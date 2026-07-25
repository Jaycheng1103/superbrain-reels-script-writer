# 短影音腳本寫手

`reels-script-writer` 是內容廚房系統的步驟 4：接住已確認的選題、切角、呈現形式與核心素材，配合既有或暫定 Hook，交付一版可拍的短影音腳本。它不負責批量想切角或設計多個 Hook；這兩件事分別交給步驟 2 與步驟 5。

輸出固定包含鉤子、主體與結尾，主體可組合觀點、真實故事、知識。CTA 依內容目標與現有資源決定，沒有導流需求時不硬塞。

## 固定課程順序

課程依 `1 → 2 → 3 → 4 → 5` 執行，不需要先做步驟 5 才能做步驟 4：

1. 步驟 1–3 先確認選題、切角與呈現形式。
2. 步驟 4 用核心素材與「暫定 Hook」完成一版完整腳本；使用者已經有 Hook 時可直接沿用。
3. 步驟 5 再設計並選定 Hook。選好後只替換腳本的開場台詞、第一個畫面與字卡，主體與結尾維持不變。若 Hook 承諾的內容不在主體裡，應改選相容 Hook。

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

## Repo 與 skill 名稱

GitHub repo 名稱是 `superbrain-reels-script-writer`，`SKILL.md` 的正式 skill 名稱是既有的 `reels-script-writer`。兩者刻意不更名，避免破壞既有 GitHub URL 與安裝名稱。部分要求「資料夾名必須等於 skill 名」的通用 validator 會因此警告或失敗，本專案不把該項檢查當成發布門檻。

每次發布前以 CLI 的真實 discovery 為準：

```bash
npx skills add Jaycheng1103/superbrain-reels-script-writer --list --full-depth
```

2026-07-26 的實測 discovery 名稱為 `reels-script-writer`。若日後 CLI 輸出改變，先更新安裝文件並重新驗證，不依 README 的舊記錄推測。

## 使用原則

- 依課程順序先完成選題、切角與呈現形式；步驟 4 可直接用暫定 Hook 成稿，再讓步驟 5 替換開場。
- 不要輸入客戶個資、未公開逐字稿、帳密、權杖、合約或未公開營收。外部數據與案例請保留原始來源。
- 本 repo 是課程教材，與任何 AI、社群或影片平台沒有官方關係。使用者須自行確認平台規範、著作權與素材授權。
- 這是可拍初稿，不保證流量、完播、觸及或轉換。拍前請念過台詞，補回自己的語感與已確認細節。

## 手動 eval

`evals/evals.json` 有 3 組功能 case，每條 expectation 都有唯一 ID 與 `safety`／`quality` 分類；`evals/trigger-evals.json` 固定為 10 組觸發、10 組不觸發。請在乾淨對話逐一貼上 prompt，再把結果填入 `evals/results-template.json` 的副本。

```bash
./tests/validate_repo.sh
./tests/validate_negative_cases.sh
python3 /Users/zhengyujie/.codex/skills/.system/skill-creator/scripts/quick_validate.py .
python3 tests/score_eval_results.py --evals evals/evals.json --results /你的路徑/results.json
```

計分門檻固定為：安全 expectation 100% 通過、quality expectation 至少 90% 通過；任一項未評或結果 schema 不完整都不算通過。Trigger 需人工記錄實際是否啟用，20 組必須全部與預期相符。結構 validator 與計分器都不會替你判斷回覆內容，實際回覆仍需逐條人工評閱。

`--quality-threshold` 只允許 `0.90–1.00`，可提高發布門檻，不能降到 90% 以下；安全門檻固定為 100%，沒有可調低的參數。

三組功能 eval 的 safety expectation 文字是逐 case 鎖定的發布契約。若安全政策真的需要變更，必須同步審查 eval、validator 與語意反轉 regression fixture，不能只保留原 ID 後改成相反意思。

採課程使用授權，詳見 [LICENSE.md](LICENSE.md)。
