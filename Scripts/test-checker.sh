#!/usr/bin/env bash
# iOS/Scripts/test-checker.sh —— 检查器自检（PR-0，SPEC §1.1.1 驱动③）
#
# 判据：R1–R21 每条规则**各有一正一反样本**：
#   · 正例：Scripts/Fixtures/structure/pass/ 整棵树对该规则零命中（且整树零命中）；
#   · 反例：Scripts/Fixtures/structure/fail/ 对该规则至少一条命中，且退出码与 severity 一致
#           （error ⇒ 1；warning ⇒ 0），并且命中必须落在"以规则 id 命名"的专用样本里（防串味）。
#   · 附带自证：豁免语法（有理由生效 / 无理由不生效）、生成物目录大小写两种形态都识别。
#
# 样本只被检查器读取，**不参与包编译**（SPEC §1.1.1）；布局 = 迷你仓（Sources/…、Tests/…）。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/module-cache}"
export SWIFT_MODULE_CACHE_PATH="${SWIFT_MODULE_CACHE_PATH:-$ROOT_DIR/.build/module-cache}"

PASS_DIR="$ROOT_DIR/Scripts/Fixtures/structure/pass"
FAIL_DIR="$ROOT_DIR/Scripts/Fixtures/structure/fail"
EXPECTED_RULES="R1 R2 R3 R4 R5 R6 R7 R8 R9 R10 R11 R12 R13a R13b R14 R15 R16 R17 R18 R19 R20 R21"

build_checker() {
  swift build --package-path . --product wd-structure-check "$@"
}

if ! build_output="$(build_checker 2>&1)"; then
  if grep -qE 'sandbox_apply|sandbox-exec' <<<"$build_output"; then
    echo "note: SwiftPM manifest 沙箱不可用（嵌套沙箱），回退 --disable-sandbox" >&2
    build_checker --disable-sandbox >/dev/null
  else
    printf '%s\n' "$build_output" >&2
    exit 1
  fi
fi

CHECKER="$ROOT_DIR/.build/debug/wd-structure-check"
[ -x "$CHECKER" ] || { echo "test-checker: 未构建出 $CHECKER" >&2; exit 1; }
[ -d "$PASS_DIR" ] || { echo "test-checker: 缺少正例样本目录 $PASS_DIR" >&2; exit 1; }
[ -d "$FAIL_DIR" ] || { echo "test-checker: 缺少反例样本目录 $FAIL_DIR" >&2; exit 1; }

failures=0
rule_count=0
pass_ok=0
fail_ok=0

note_failure() {
  failures=$((failures + 1))
}

# ── 0. 规则清单：必须是 R1–R21（R13 拆 R13a/R13b），共 22 条 ─────────────────────────
listed_rules="$("$CHECKER" --list-rules | cut -f1 | tr '\n' ' ' | sed 's/ *$//')"
if [ "$listed_rules" != "$EXPECTED_RULES" ]; then
  echo "FAIL 规则清单不符"
  echo "  实际：$listed_rules"
  echo "  期望：$EXPECTED_RULES"
  note_failure
fi

# ── 1. 逐规则：一正一反 ─────────────────────────────────────────────────────────────
while IFS=$'\t' read -r id severity scope _summary; do
  [ -n "${id:-}" ] || continue
  rule_count=$((rule_count + 1))

  # 正例：pass 树对该规则零命中
  pass_out="$("$CHECKER" --root "$PASS_DIR" --rule "$id" 2>&1 || true)"
  if grep -qE '^(error|warning) ' <<<"$pass_out"; then
    echo "FAIL ${id} 正例不该命中（pass 树）"
    printf '%s\n' "$pass_out" | sed 's/^/     /'
    note_failure
  else
    pass_ok=$((pass_ok + 1))
  fi

  # 反例：fail 树必须命中
  fail_status=0
  fail_out="$("$CHECKER" --root "$FAIL_DIR" --rule "$id" 2>&1)" || fail_status=$?
  if ! grep -qE "^(error|warning) ${id} " <<<"$fail_out"; then
    echo "FAIL ${id} 反例未命中（fail 树）"
    printf '%s\n' "$fail_out" | sed 's/^/     /'
    note_failure
  else
    fail_ok=$((fail_ok + 1))
  fi

  # 退出码：error ⇒ 1，warning ⇒ 0
  expected_status=0
  [ "$severity" = "error" ] && expected_status=1
  if [ "$fail_status" -ne "$expected_status" ]; then
    echo "FAIL ${id} 反例退出码 ${fail_status}（期望 ${expected_status}，severity=${severity}）"
    note_failure
  fi

  # 命中必须落在专用样本（文件名含 Rn_），tree 级规则除外
  if [ "$scope" = "file" ]; then
    stray="$(grep -E "^(error|warning) ${id} " <<<"$fail_out" | grep -v "${id}_" || true)"
    if [ -n "$stray" ]; then
      echo "FAIL ${id} 命中落在非专用样本（样本间串味）"
      printf '%s\n' "$stray" | sed 's/^/     /'
      note_failure
    fi
    pass_samples="$(find "$PASS_DIR" -name "${id}_*.swift" | wc -l | tr -d ' ')"
    fail_samples="$(find "$FAIL_DIR" -name "${id}_*.swift" | wc -l | tr -d ' ')"
    if [ "$pass_samples" -lt 1 ] || [ "$fail_samples" -lt 1 ]; then
      echo "FAIL ${id} 样本缺失（pass=${pass_samples} fail=${fail_samples}）"
      note_failure
    fi
  fi
done < <("$CHECKER" --list-rules)

# ── 2. 整树：pass 全绿；fail 必须覆盖全部 22 条规则 ─────────────────────────────────
whole_pass_status=0
whole_pass="$("$CHECKER" --root "$PASS_DIR" 2>&1)" || whole_pass_status=$?
if [ "$whole_pass_status" -ne 0 ] || grep -qE '^(error|warning) ' <<<"$whole_pass"; then
  echo "FAIL pass 树整树跑不该有任何命中"
  printf '%s\n' "$whole_pass" | sed 's/^/     /'
  note_failure
fi

whole_fail="$("$CHECKER" --root "$FAIL_DIR" 2>&1 || true)"
covered="$(grep -oE '^(error|warning) R[0-9]+[ab]?' <<<"$whole_fail" | awk '{print $2}' | sort -u | tr '\n' ' ' | sed 's/ *$//')"
expected_sorted="$(printf '%s\n' $EXPECTED_RULES | sort | tr '\n' ' ' | sed 's/ *$//')"
if [ "$covered" != "$expected_sorted" ]; then
  echo "FAIL fail 树整树跑未覆盖全部规则"
  echo "  实际：$covered"
  echo "  期望：$expected_sorted"
  note_failure
fi

# ── 3. 豁免语法：有理由生效 / 无理由不生效 ──────────────────────────────────────────
if ! grep -q 'wd-structure-check:disable R1 —' \
  "$PASS_DIR/Sources/WisdomUI/Foundation/R1_exempt_directive.swift" 2>/dev/null; then
  echo "FAIL 正例缺少带理由的豁免指令样本"
  note_failure
fi
if ! grep -q 'R1_exempt_without_reason' <<<"$("$CHECKER" --root "$FAIL_DIR" --rule R1 2>&1 || true)"; then
  echo "FAIL 无理由的豁免指令应不生效（R1 仍须命中该样本）"
  note_failure
fi

# ── 4. 生成物目录大小写：Generated/ 与 generated/ 都必须被判为生成物 ────────────────
r12_out="$("$CHECKER" --root "$FAIL_DIR" --rule R12 2>&1 || true)"
for sample in "Generated/R12_no_banner_uppercase.swift" "generated/R12_no_banner_lowercase.swift"; do
  if ! grep -q "$sample" <<<"$r12_out"; then
    echo "FAIL 生成物目录形态 '$sample' 未被识别为生成物（R12 未命中）"
    note_failure
  fi
done

# ── 5. 剥离纪律：注释里的词不得当代码、字符串里的词不得当代码 ─────────────────────────
# R11 正例的**注释**里写着 `.font(.system(` 与 `WDType.`（R10/R11 若未剥离注释就会命中）。
if ! grep -q 'WDType\.' \
  "$PASS_DIR/Sources/WisdomUI/Components/Primitives/WDButton/R11_positive.swift" 2>/dev/null; then
  echo "FAIL 剥离纪律样本缺失（R11 正例注释里应出现 WDType.）"
  note_failure
fi
for probe in R10 R11; do
  if grep -qE "^(error|warning) ${probe} " <<<"$("$CHECKER" --root "$PASS_DIR" --rule "$probe" 2>&1 || true)"; then
    echo "FAIL ${probe} 命中了注释里的词（注释剥离纪律失效）"
    note_failure
  fi
done
# R13a 正例的**字符串字面量**里写着 "AnyView"（未剥离字符串就会命中）。
if ! grep -q '"AnyView"' \
  "$PASS_DIR/Sources/WisdomUI/Foundation/R13a_positive.swift" 2>/dev/null; then
  echo "FAIL 剥离纪律样本缺失（R13a 正例字符串里应出现 AnyView）"
  note_failure
fi
if grep -qE '^(error|warning) R13a ' <<<"$("$CHECKER" --root "$PASS_DIR" --rule R13a 2>&1 || true)"; then
  echo "FAIL R13a 命中了字符串字面量里的词（字符串剥离纪律失效）"
  note_failure
fi

# ── 汇总 ────────────────────────────────────────────────────────────────────────────
if [ "$failures" -ne 0 ]; then
  echo "test-checker: rules=$rule_count pass_ok=$pass_ok fail_ok=$fail_ok failures=$failures result=failed"
  exit 1
fi
echo "test-checker: rules=$rule_count pass_ok=$pass_ok fail_ok=$fail_ok failures=0 result=ok"
exit 0
