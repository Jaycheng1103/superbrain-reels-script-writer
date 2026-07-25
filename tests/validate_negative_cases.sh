#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SANDBOX="$(mktemp -d /private/tmp/reels-script-writer-negative.XXXXXX)"
FAILED=0

cleanup() {
  rm -rf -- "$SANDBOX"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  FAILED=1
}

expect_pass() {
  label="$1"
  shift
  output_file="$SANDBOX/$label.log"
  if ! "$@" >"$output_file" 2>&1; then
    sed -n '1,120p' "$output_file" >&2
    fail "$label 應通過"
  fi
}

expect_fail() {
  label="$1"
  expected="$2"
  shift 2
  output_file="$SANDBOX/$label.log"
  if "$@" >"$output_file" 2>&1; then
    fail "$label 應被拒絕，但命令回傳成功"
    return
  fi
  if ! grep -Fq "$expected" "$output_file"; then
    sed -n '1,120p' "$output_file" >&2
    fail "$label 雖失敗，但未回報預期原因：$expected"
  fi
}

copy_repo() {
  target="$1"
  mkdir -p "$target"
  cp -R "$ROOT/." "$target/"
}

expect_pass baseline "$ROOT/tests/validate_repo.sh"

empty_license="$SANDBOX/empty-license"
copy_repo "$empty_license"
: >"$empty_license/LICENSE.md"
expect_fail empty-license '必要檔案不可為空：LICENSE.md' "$empty_license/tests/validate_repo.sh"

empty_reference="$SANDBOX/empty-reference"
copy_repo "$empty_reference"
: >"$empty_reference/references/萬能腳本公式.md"
expect_fail empty-reference '必要檔案不可為空：references/萬能腳本公式.md' "$empty_reference/tests/validate_repo.sh"

frontmatter_only="$SANDBOX/frontmatter-only"
copy_repo "$frontmatter_only"
printf '%s\n' \
  '---' \
  'name: reels-script-writer' \
  'description: 只剩 frontmatter 的壞版本' \
  '---' >"$frontmatter_only/SKILL.md"
expect_fail frontmatter-only 'SKILL.md 缺少必要章節：## 輸入與課程順序' "$frontmatter_only/tests/validate_repo.sh"

expect_fail trigger-all-true 'trigger eval 必須固定為 10 組 true 與 10 組 false' \
  env TRIGGER_EVALS_FILE="$ROOT/tests/fixtures/trigger-all-true.json" "$ROOT/tests/validate_repo.sh"

expect_fail misplaced-safety '功能 case full-script-with-goal-cta 缺少必要 expectation：no-fabricated-results' \
  env EVALS_FILE="$ROOT/tests/fixtures/evals-misplaced-safety.json" "$ROOT/tests/validate_repo.sh"

expect_fail inverted-safety '功能 case full-script-with-goal-cta/no-fabricated-results 的核心安全語意已改變' \
  env EVALS_FILE="$ROOT/tests/fixtures/evals-inverted-safety.json" "$ROOT/tests/validate_repo.sh"

secret_case="$SANDBOX/sk-proj-secret"
copy_repo "$secret_case"
synthetic_secret='sk''-proj-abcdefghijklmnopqrstuvwxyz0123456789'
printf '%s\n' "$synthetic_secret" >"$secret_case/synthetic-secret.txt"
expect_fail sk-proj-secret '偵測到可能的憑證內容' "$secret_case/tests/validate_repo.sh"

expect_pass scoring-all-pass \
  python3 "$ROOT/tests/score_eval_results.py" \
    --evals "$ROOT/evals/evals.json" \
    --results "$ROOT/tests/fixtures/results-all-pass.json"

expect_fail scoring-safety-fail 'SAFETY_GATE=FAIL' \
  python3 "$ROOT/tests/score_eval_results.py" \
    --evals "$ROOT/evals/evals.json" \
    --results "$ROOT/tests/fixtures/results-safety-fail.json"

expect_fail scoring-quality-fail 'QUALITY_GATE=FAIL' \
  python3 "$ROOT/tests/score_eval_results.py" \
    --evals "$ROOT/evals/evals.json" \
    --results "$ROOT/tests/fixtures/results-quality-fail.json"

expect_fail scoring-threshold-zero 'quality threshold cannot be lower than 0.90' \
  python3 "$ROOT/tests/score_eval_results.py" \
    --evals "$ROOT/evals/evals.json" \
    --results "$ROOT/tests/fixtures/results-quality-fail.json" \
    --quality-threshold 0

expect_fail scoring-threshold-just-below 'quality threshold cannot be lower than 0.90' \
  python3 "$ROOT/tests/score_eval_results.py" \
    --evals "$ROOT/evals/evals.json" \
    --results "$ROOT/tests/fixtures/results-quality-fail.json" \
    --quality-threshold 0.899

expect_pass scoring-higher-threshold \
  python3 "$ROOT/tests/score_eval_results.py" \
    --evals "$ROOT/evals/evals.json" \
    --results "$ROOT/tests/fixtures/results-all-pass.json" \
    --quality-threshold 1

if [ "$FAILED" -ne 0 ]; then
  exit 1
fi

printf 'PASS: 空檔、空工作流、eval 分布／安全語意、sk-proj 與不可降低的計分門檻皆符合預期。\n'
