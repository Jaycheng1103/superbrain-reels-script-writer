#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  FAILED=1
}

require_file() {
  [ -f "$ROOT/$1" ] || fail "缺少必要檔案：$1"
}

for file in \
  SKILL.md README.md 如何使用.md LICENSE.md \
  references/萬能腳本公式.md references/四種內容類型.md references/輸出模板.md references/範例.md \
  evals/evals.json evals/trigger-evals.json tests/validate_repo.sh; do
  require_file "$file"
done

if [ -f "$ROOT/SKILL.md" ]; then
  [ "$(sed -n '1p' "$ROOT/SKILL.md")" = '---' ] || fail 'SKILL.md 缺少 YAML frontmatter 起始符'
  grep -qx 'name: reels-script-writer' "$ROOT/SKILL.md" || fail 'SKILL.md 的 name 必須是 reels-script-writer'
  grep -q '^description: ' "$ROOT/SKILL.md" || fail 'SKILL.md 缺少 description'
  lines="$(wc -l < "$ROOT/SKILL.md" | tr -d ' ')"
  [ "$lines" -lt 100 ] || fail "SKILL.md 必須少於 100 行，實際為 $lines 行"
fi

check_json() {
  json_file="$1"
  kind="$2"
  [ -f "$json_file" ] || return
  python3 - "$json_file" "$kind" <<'PY' || FAILED=1
import json
import sys

path, kind = sys.argv[1:]
try:
    with open(path, encoding='utf-8') as handle:
        payload = json.load(handle)
    if payload.get('schema_version') != 1:
        raise ValueError('schema_version 必須是 1')
    if payload.get('skill_name') != 'reels-script-writer':
        raise ValueError('skill_name 必須是 reels-script-writer')
    cases = payload.get('cases')
    if not isinstance(cases, list):
        raise ValueError('cases 必須是陣列')
    if kind == 'functional':
        expected_ids = ['full-script-with-goal-cta', 'standalone-safe-fallback', 'story-and-claim-boundaries']
        if [case.get('id') for case in cases] != expected_ids:
            raise ValueError('功能 case 必須保留指定的三組案例與順序')
        for case in cases:
            if not isinstance(case.get('prompt'), str) or not case['prompt'].strip():
                raise ValueError(f"功能 case {case.get('id')} 缺少 prompt")
            expectations = case.get('expectations')
            if not isinstance(expectations, list) or not expectations or not all(isinstance(item, str) and item.strip() for item in expectations):
                raise ValueError(f"功能 case {case.get('id')} 缺少可評閱 expectations")
        text = '\n'.join(item for case in cases for item in case['expectations'])
        required = ['一版可拍腳本', '鉤子、主體、結尾', 'CTA 依內容目標決定', '不硬塞導流', '不虛構第一人稱故事', '未證實數字標待查證', '主體可組合觀點、故事、知識']
        missing = [item for item in required if item not in text]
        if missing:
            raise ValueError('功能 expectations 缺少必要語意：' + '、'.join(missing))
    else:
        if len(cases) != 20:
            raise ValueError('trigger cases 必須剛好有 20 組')
        for index, case in enumerate(cases, 1):
            if not isinstance(case.get('prompt'), str) or not case['prompt'].strip():
                raise ValueError(f'trigger case {index} 缺少 prompt')
            if not isinstance(case.get('should_trigger'), bool):
                raise ValueError(f'trigger case {index} 的 should_trigger 必須是 boolean')
except (OSError, json.JSONDecodeError, ValueError) as error:
    print(f'FAIL: {path}: {error}', file=sys.stderr)
    raise SystemExit(1)
PY
}

check_json "${EVALS_FILE:-$ROOT/evals/evals.json}" functional
check_json "${TRIGGER_EVALS_FILE:-$ROOT/evals/trigger-evals.json}" trigger

if grep -RInE --exclude='validate_repo.sh' --exclude-dir='.git' \
  '(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xoxb-[0-9]+-[A-Za-z0-9-]{20,}|AIza[0-9A-Za-z_-]{35}|rk_live_[A-Za-z0-9]{16,}|sk_live_[A-Za-z0-9]{16,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY)' \
  "$ROOT" >/dev/null 2>&1; then
  fail '偵測到可能的憑證內容，請移除後再提交'
fi

if [ "$FAILED" -ne 0 ]; then
  printf 'Repository validation failed. Credential scanning is only a reminder; perform human review.\n' >&2
  exit 1
fi

printf 'PASS: 結構、frontmatter、行數、eval schema 與憑證掃描皆通過。\n'
printf '提醒：自動掃描不能取代人工的事實、來源、授權與安全確認。\n'
