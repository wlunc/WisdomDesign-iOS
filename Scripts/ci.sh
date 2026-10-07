#!/usr/bin/env bash
# iOS/Scripts/ci.sh —— 三层门禁唯一入口：pr / nightly / measure / doctor
#
# 口径（效力序）：iOS/docs/SPEC.md §1.5.1–§1.5.5 ＞ iOS/docs/DEV-PLAN.md §4 ＞ iOS/AGENTS.md §5。
#
# 【冻结值】WD_SCHEME = WisdomDesign-iOS-Package（D-19：首次跑通后固化，不再运行时猜）
#   实测 xcodebuild -list 给出的 scheme 恰为三个：wd-structure-check / WisdomDesign-iOS-Package /
#   WisdomUI。⇒ SPEC §1.5.1 的候选名 WisdomUI-Package **不存在**；包级聚合 scheme 的名字由
#   Package.swift 的包名派生（<包名>-Package），只有它同时含 WisdomUI 与 WisdomUITests 两个 target。
#   本脚本只认这一个常量，**不做"取第一个 scheme"**（B6：那会取到 wd-structure-check）。
#   换包名 ⇒ 改本常量 + README + DEV-PLAN §4.1（三处必须同步）。
#
# 【与 SPEC §1.5.1 草案的三处差异】（草案自称"替换草案"，逐条给实测依据）
#   ① 家目录钉进工作区 —— U-01 / N-2 的根因与修法
#      SwiftPM 把 manifest 缓存写在 家目录/Library/Caches/org.swift.swiftpm/manifests/…；受限环境
#      （DSH 文件沙箱 = workspace-write）下该路径不可写 ⇒ xcodebuild 直接
#      "Could not resolve package dependencies"（实测：cannot open file … Operation not permitted）。
#      修法 = 用 Foundation 的 CFFIXED_USER_HOME 把 **host 侧工具** 看到的家目录钉到 .build/home/，
#      于是 manifest 缓存 / Xcode 用户目录 / SwiftPM security 全部落在工作区内。
#      只影响 host 侧进程（xcodebuild、swift-format、simctl CLI），不影响模拟器里的测试进程。
#      顺带修好的第二处：未钉家目录时 xcresulttool get test-results summary 会报
#      "You don't have permission to save the file … in the folder TestReport"。
#      关掉 = WD_USER_HOME_PIN=0（家目录可写的 CI 上可选；本仓默认开 = 缓存不落家目录）。
#   ② -resultBundlePath 挂在**测试**阶段 —— 覆盖率数据只在测试阶段产生
#      实测：挂在 build-for-testing 的结果包 xccov 报 "No coverage data in result bundle"，
#      而同一轮 test-without-building 产出的包 hasCoverageData = true。
#      ⇒ build 阶段写 pr-build.xcresult（留构建日志），测试阶段写 pr.xcresult（测试结论 + 覆盖率）。
#      -resultBundlePath 指向已存在路径会**直接报错** ⇒ 每次先删。
#   ③ 测试"真的跑了"的断言（防假绿）
#      -only-testing:WisdomUITests 若匹配不到任何用例，xcodebuild 可能出现"成功但 0 个测试"。
#      ⇒ 跑完用 xcresulttool get test-results summary 断言 passedTests ≥ 1 且 failedTests = 0。
#      依据 = SPEC §1.5.2「批出口不使用完成度百分比，只用判据是否全绿」。
#
# 【保留 SPEC 口径】-quiet 保留但原始输出 tee 到 .build/logs/*.log（失败时打印尾部）；
# destination 按 UDID 解析（禁按设备名硬编码）；PR 只编模拟器一张编译图；PR-2 复用 PR-1 的 DerivedData。
#
# 退出码：0 = 绿；1 = 门禁红；2 = 用法 / 环境错误；3 = 前置交付物未到位（如 M1 的快照套件）。
#
# 用法：
#   Scripts/ci.sh pr                       # 每次提交必过（PR-0 host → PR-1 模拟器 → PR-2 API → 覆盖率）
#   Scripts/ci.sh nightly                  # 每批强制（设备编译 + 六态快照；demo 无障碍审计 M1 起）
#   Scripts/ci.sh measure [n] [--clean]    # 过程成本测量（分阶段计时，默认 3 次；--clean 每轮清 DerivedData）
#   Scripts/ci.sh doctor                   # 只做环境自检（工具链 / destination / scheme），不编译
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

DD="${WD_DERIVED_DATA:-.build/dd}"
SCHEME="${WD_SCHEME:-WisdomDesign-iOS-Package}"
LOG_DIR=".build/logs"
PERF_DIR=".build/perf"
TEST_SUMMARY="$PERF_DIR/test-summary.json"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

mkdir -p "$DD" "$LOG_DIR" "$PERF_DIR"

# ── 家目录钉进工作区（差异①；见文件头）。WD_USER_HOME_PIN=0 可关。
if [ "${WD_USER_HOME_PIN:-1}" != "0" ]; then
  USER_HOME_DIR="${WD_USER_HOME:-$ROOT_DIR/.build/home}"
  mkdir -p "$USER_HOME_DIR"
  export CFFIXED_USER_HOME="$USER_HOME_DIR"
fi

# 中间产物收进 .build/（与 SPEC §1.6 的固定 DerivedData 口径一致；已有环境变量优先）。
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/module-cache}"
export SWIFT_MODULE_CACHE_PATH="${SWIFT_MODULE_CACHE_PATH:-$ROOT_DIR/.build/module-cache}"

# ── 计时（measure 的取数机关；用逗号串而不是数组，避开 bash 3.2 空数组 + set -u）
PHASE_NAMES=""
PHASE_MS=""
PHASE_NAME=""
PHASE_T0=0
now_ms() { python3 -c 'import time; print(int(time.time() * 1000))'; }
phase_begin() {
  PHASE_NAME="$1"
  PHASE_T0="$(now_ms)"
  printf '\n──────── %s\n' "$PHASE_NAME"
}
phase_end() {
  local ms
  # bash 3.2 的算术上下文不接受引号（实测："123" - x ⇒ syntax error）⇒ 这里不引号。
  ms=$(( $(now_ms) - PHASE_T0 ))
  PHASE_NAMES="${PHASE_NAMES}${PHASE_NAMES:+,}${PHASE_NAME}"
  PHASE_MS="${PHASE_MS}${PHASE_MS:+,}${ms}"
  printf '──────── %s ✓ (%.1fs)\n' "$PHASE_NAME" "$(awk -v m="$ms" 'BEGIN{print m/1000}')"
}

# run_logged <name> <cmd...>：tee 到 .build/logs/<name>.log；失败打印尾部并原样返回退出码。
run_logged() {
  local name="$1"
  shift
  local log="$LOG_DIR/$name.log"
  printf '$ %s\n' "$*" >"$log"
  if "$@" 2>&1 | tee -a "$log"; then
    return 0
  fi
  local rc="${PIPESTATUS[0]}"
  printf '\n──────── %s 失败（exit=%s）；日志尾部（%s）：\n' "$name" "$rc" "$log" >&2
  tail -n 40 "$log" >&2
  return "$rc"
}

die() { printf 'ci.sh: %s\n' "$*" >&2; exit 2; }

# ── destination：按 UDID 解析（B6）。WD_SIM_ID 可给裸 UDID 或完整 destination 串。
resolve_sim_udid() {
  xcrun simctl list -j devices available | python3 -c '
import json, sys
d = json.load(sys.stdin)
c = [(rt, x) for rt, ds in d["devices"].items() if "iOS" in rt for x in ds if x.get("isAvailable")]
c.sort(key=lambda t: (t[0], t[1]["name"]))
if not c:
    sys.exit(1)
print(c[-1][1]["udid"])'
}
normalize_dest() {
  case "$1" in
    *platform=*) printf '%s' "$1" ;;
    *) printf 'platform=iOS Simulator,id=%s' "$1" ;;
  esac
}
resolve_dest() {
  if [ -n "${WD_SIM_ID:-}" ]; then
    normalize_dest "$WD_SIM_ID"
  else
    local udid
    udid="$(resolve_sim_udid)" || die "找不到可用的 iOS 模拟器（xcrun simctl list -j devices available）"
    printf 'platform=iOS Simulator,id=%s' "$udid"
  fi
}

list_schemes() {
  xcodebuild -list 2>/dev/null | awk '
    /^[[:space:]]*Schemes:/ { f = 1; next }
    f && /^[[:space:]]+[^[:space:]]/ { gsub(/^[[:space:]]+/, ""); print; next }
    f { exit }'
}

# ── 环境自检：工具链 + destination + scheme（scheme 不在 = 直接失败，不退化成"取第一个"）
check_env() {
  command -v xcodebuild >/dev/null 2>&1 || die "找不到 xcodebuild"
  command -v xcrun >/dev/null 2>&1 || die "找不到 xcrun"
  command -v python3 >/dev/null 2>&1 || die "找不到 python3（SPEC §1.6 IOS-14：本脚本的运行时依赖）"
  [ -d "$DEVELOPER_DIR" ] || die "DEVELOPER_DIR 不存在：$DEVELOPER_DIR（SPEC §1.5.1 I12：Xcode ≥ 26）"
  DEST="$(resolve_dest)"
  case "$DEST" in
    *id=*) [ -n "${DEST##*id=}" ] || die "destination 里没有 UDID：$DEST" ;;
  esac
  local schemes
  schemes="$(list_schemes)" || true
  if ! printf '%s\n' "$schemes" | grep -qx "$SCHEME"; then
    printf 'ci.sh: scheme "%s" 不在本包（B6：不取第一个 scheme）。实测可用：\n' "$SCHEME" >&2
    printf '%s\n' "$schemes" | sed 's/^/  - /' >&2
    printf '  提示：包级 scheme = <包名>-Package；换名后同步 README 与 DEV-PLAN §4.1。\n' >&2
    exit 2
  fi
}

# ── 测试结论断言（差异③）：结果包必须"真跑过测试且全过"。
assert_tests_passed() {
  local bundle="$1"
  [ -d "$bundle" ] || die "结果包不存在：$bundle"
  xcrun xcresulttool get test-results summary --path "$bundle" --compact >"$TEST_SUMMARY" || die "读不出测试结论：$bundle"
  python3 - "$TEST_SUMMARY" <<'PY'
import json, sys
doc = json.load(open(sys.argv[1], encoding="utf-8"))
passed = doc.get("passedTests", 0)
failed = doc.get("failedTests", 0)
skipped = doc.get("skippedTests", 0)
print("测试结论：result=%s passed=%d failed=%d skipped=%d" % (doc.get("result"), passed, failed, skipped))
for f in doc.get("testFailures", []) or []:
    print("  x %s :: %s" % (f.get("targetName", "?"), f.get("failureText", "")[:400]))
if passed < 1:
    print("假绿拦截：结果包里 0 个通过的测试（-only-testing 可能没匹配到任何用例）", file=sys.stderr)
    sys.exit(1)
if failed != 0:
    sys.exit(1)
PY
}

# ── 耗时报告：打印表格 + 写 JSON（measure 逐轮读 last-pr-timing.json）
report_timings() {
  local label="$1" out="$2"
  python3 - "$label" "$out" "$SCHEME" "${WD_MEASURE_STATE:-warm}" "$PHASE_NAMES" "$PHASE_MS" <<'PY'
import datetime, json, sys
label, out, scheme, state, names, mss = sys.argv[1:7]
ns = [x for x in names.split(",") if x]
ms = [int(x) for x in mss.split(",") if x]
phases = dict(zip(ns, ms))
total = sum(ms)
print("\n阶段耗时（label=%s state=%s scheme=%s）" % (label, state, scheme))
for n, m in phases.items():
    print("  %-28s %8.2f s" % (n, m / 1000.0))
print("  %-28s %8.2f s" % ("合计", total / 1000.0))
doc = {
    "label": label,
    "state": state,
    "scheme": scheme,
    "generatedAt": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
    "phasesSec": {n: round(m / 1000.0, 2) for n, m in phases.items()},
    "totalSec": round(total / 1000.0, 2),
}
with open(out, "w", encoding="utf-8") as fh:
    json.dump(doc, fh, ensure_ascii=False, indent=1, sort_keys=True)
    fh.write("\n")
print("耗时 JSON：%s" % out)
PY
}

cmd_pr() {
  # 每次调用复位计时累加器：measure 会在同一进程里连跑多轮，不复位会把上一轮的耗时算进合计。
  PHASE_NAMES=""
  PHASE_MS=""
  check_env
  printf 'scheme=%s\ndestination=%s\nxcode=%s\npin=%s\n' \
    "$SCHEME" "$DEST" "$(xcodebuild -version | head -1)" "${CFFIXED_USER_HOME:-<off>}"

  phase_begin "PR-0 host 规则 + 格式 + 令牌溯源（秒级，不需要 Xcode）"
  Scripts/check-structure.sh
  Scripts/check-format.sh
  # 跨仓同批自证（SPEC §1.5.4-3）：读设计仓的 dist/tokens.manifest.json 断言 sha12 == 生成物；
  # manifest 缺失 = fail（不 skip）。路径可用 WD_TOKENS_MANIFEST 覆盖。
  Scripts/check-structure.sh --tokens-trace
  phase_end

  phase_begin "PR-1a build-for-testing（含 WD_API_SMOKE 签名冒烟；只编模拟器一张图）"
  rm -rf "$DD/pr-build.xcresult"
  run_logged pr-build xcodebuild build-for-testing \
    -scheme "$SCHEME" -destination "$DEST" -derivedDataPath "$DD" -quiet \
    -resultBundlePath "$DD/pr-build.xcresult" \
    SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) WD_API_SMOKE'
  phase_end

  phase_begin "PR-1b test-without-building（WisdomUITests）+ 覆盖率采集"
  rm -rf "$DD/pr.xcresult"
  run_logged pr-test xcodebuild test-without-building \
    -scheme "$SCHEME" -destination "$DEST" -derivedDataPath "$DD" \
    -only-testing:WisdomUITests \
    -test-timeouts-enabled YES -default-test-execution-time-allowance 60 \
    -enableCodeCoverage YES -resultBundlePath "$DD/pr.xcresult"
  assert_tests_passed "$DD/pr.xcresult"
  phase_end

  phase_begin "PR-2 API 冻结（复用 PR-1 的 DerivedData，不额外编译）"
  Scripts/dump-api.sh
  if git ls-files --error-unmatch api/WisdomUI.api.json >/dev/null 2>&1; then
    git diff --exit-code -- api/WisdomUI.api.json
  else
    printf 'note: api/WisdomUI.api.json 尚未入库（untracked）⇒ git diff --exit-code 这一步当前为空转；\n' >&2
    printf '      M0 出口④要求该文件入库，入库后本步才真正生效。\n' >&2
  fi
  phase_end

  phase_begin "覆盖率报告（xccov；只打印不拦，M3 起转门槛）"
  xcrun xccov view --report --json "$DD/pr.xcresult" >"$PERF_DIR/coverage.json"
  python3 - "$PERF_DIR/coverage.json" <<'PY'
import json, sys
doc = json.load(open(sys.argv[1], encoding="utf-8"))
targets = doc.get("targets", [])
if not targets:
    print("覆盖率报告为空（xccov 没有可用输入）", file=sys.stderr)
    sys.exit(1)
print("覆盖率目标数：%d" % len(targets))
for t in targets:
    cov = t.get("lineCoverage")
    if cov is None:
        continue
    print("  %-24s %6.2f%%" % (t.get("name", "?"), cov * 100))
PY
  phase_end

  local stamp
  stamp="ci-timing-$(date +%Y%m%d).json"
  report_timings "pr" "$PERF_DIR/$stamp"
  cp "$PERF_DIR/$stamp" "$PERF_DIR/last-pr-timing.json"
  printf '\nci.sh pr: 全绿\n'
}

cmd_nightly() {
  check_env
  # 六态快照套件是 M1 交付物（Package.swift 目前只声明 3 个 target）⇒ 前置缺失 = 明确失败，不静默跳过。
  if [ ! -d Tests/WisdomUISnapshotTests ]; then
    printf 'ci.sh: nightly 的前置交付物未到位 —— Tests/WisdomUISnapshotTests（六态快照，M1 交付物）。\n' >&2
    printf '      本仓当前只有 WisdomUITests；nightly 在 M1 前不可绿（DEV-PLAN §4.2 标注 "M1 起"）。\n' >&2
    exit 3
  fi

  phase_begin "nightly-1a 设备编译（generic/platform=iOS；设备图只在 nightly）"
  run_logged nightly-device-build xcodebuild build \
    -scheme "$SCHEME" -destination 'generic/platform=iOS' -derivedDataPath "$DD" -quiet
  phase_end

  phase_begin "nightly-1b 六态快照（WisdomUISnapshotTests）"
  rm -rf "$DD/nightly.xcresult"
  run_logged nightly-snapshots xcodebuild test \
    -scheme "$SCHEME" -destination "$DEST" -derivedDataPath "$DD" \
    -only-testing:WisdomUISnapshotTests -resultBundlePath "$DD/nightly.xcresult"
  assert_tests_passed "$DD/nightly.xcresult"
  phase_end

  # demo 无障碍审计（4 类目）按 DEV-PLAN §4.2 = "M1 起"：不存在时**明示跳过**（不伪装成绿）。
  if [ -d Examples/WisdomUIDemo/WisdomUIDemo.xcodeproj ]; then
    phase_begin "nightly-2 demo 无障碍审计（contrast / hitRegion / textClipped / dynamicType）"
    run_logged nightly-demo-a11y xcodebuild test \
      -project Examples/WisdomUIDemo/WisdomUIDemo.xcodeproj -scheme WisdomUIDemo \
      -destination "$DEST" -only-testing:WisdomUIDemoUITests
    phase_end
  else
    printf '\n【未验证】nightly-2 demo 无障碍审计：Examples/WisdomUIDemo 尚未交付（M1 交付物）——本次未跑。\n'
    printf '          DEV-PLAN §4.2 标注该项 "M1 起"，回填责任 = ios-dev，时点 = M1 出口。\n'
  fi

  report_timings "nightly" "$PERF_DIR/ci-timing-nightly-$(date +%Y%m%d).json"
  printf '\nci.sh nightly: 绿\n'
}

# measure：过程成本测量（IOS-16：cold / warm / clean 三态各跑 N 次取中位数）
#   Scripts/ci.sh measure [次数] [--states=warm,clean,cold]
#   --clean 是 --states=warm,clean 的旧写法（兼容）
# 三态定义：warm = 复用现有缓存；clean = 每轮删 DerivedData；cold = 连 SwiftPM manifest 缓存与
# module-cache 一起删（真正的冷启动）。**只测模拟器相对量，作为预算；不做质量门槛**（SPEC §1.5.2）。
cmd_measure() {
  local runs=3
  local states="warm"
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --clean) states="warm,clean" ;;
      --states=*) states="${1#--states=}" ;;
      ''|*[!0-9]*) die "measure 的参数只接受次数 / --states=… / --clean（收到 '$1'）" ;;
      *) runs="$1" ;;
    esac
    shift
  done
  [ "$runs" -ge 1 ] || die "measure 次数必须 ≥ 1"

  local state
  for state in $(printf '%s' "$states" | tr ',' ' '); do
    case "$state" in
      warm|clean|cold) ;;
      *) die "measure 只认 warm / clean / cold 三态（收到 '$state'）" ;;
    esac
  done

  local out="$PERF_DIR/ci-measure-$(date +%Y%m%d).json"
  for state in $(printf '%s' "$states" | tr ',' ' '); do
    local dir="$PERF_DIR/measure-$state"
    mkdir -p "$dir"
    rm -f "$dir"/run-*.json
    local i=1
    while [ "$i" -le "$runs" ]; do
      printf '\n════ measure state=%s 第 %d/%d 轮\n' "$state" "$i" "$runs"
      reset_build_state "$state"
      WD_MEASURE_STATE="$state" cmd_pr
      cp "$PERF_DIR/last-pr-timing.json" "$dir/run-$i.json"
      i=$((i + 1))
    done
  done

  python3 - "$PERF_DIR" "$out" "$runs" "$states" <<'PY'
import datetime, glob, json, os, statistics, sys

perf, out, runs, states = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4].split(",")
result = {}
for state in states:
    paths = sorted(glob.glob(os.path.join(perf, "measure-" + state, "run-*.json")))
    docs = [json.load(open(p, encoding="utf-8")) for p in paths]
    if len(docs) != runs:
        print("measure: state=%s 期望 %d 轮、实际 %d 轮" % (state, runs, len(docs)), file=sys.stderr)
        sys.exit(1)
    phases = sorted({k for d in docs for k in d["phasesSec"]})
    result[state] = {
        "runs": len(docs),
        "medianSec": {p: round(statistics.median([d["phasesSec"].get(p, 0.0) for d in docs]), 2) for p in phases},
        "medianTotalSec": round(statistics.median([d["totalSec"] for d in docs]), 2),
        "minTotalSec": round(min(d["totalSec"] for d in docs), 2),
        "maxTotalSec": round(max(d["totalSec"] for d in docs), 2),
        "runsRaw": docs,
    }

phases = sorted({p for s in result.values() for p in s["medianSec"]})
print("\n中位数（每态 n=%d）；单位 = 秒" % runs)
print("%-34s" % "阶段" + "".join("%10s" % s for s in states))
for p in phases:
    print("%-34s" % p[:34] + "".join("%10.2f" % result[s]["medianSec"].get(p, 0.0) for s in states))
print("%-34s" % "合计" + "".join("%10.2f" % result[s]["medianTotalSec"] for s in states))
doc = {
    "runs": runs,
    "states": result,
    "generatedAt": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
    "scheme": open("Scripts/ci.sh", encoding="utf-8").read().split('SCHEME="${WD_SCHEME:-')[1].split("}")[0],
}
with open(out, "w", encoding="utf-8") as fh:
    json.dump(doc, fh, ensure_ascii=False, indent=1, sort_keys=True)
    fh.write("\n")
print("\n测量结果：%s" % out)
PY
  printf '\n注：预算 = 上表的中位数；回填到 README 与 docs/SPEC.md §1.5.2（I-M0-k）。**未测不写预算**。\n'
}

# 按状态重置构建缓存（cold 连 SwiftPM manifest 缓存一起清 = 真正的冷启动）
reset_build_state() {
  case "$1" in
    warm) ;;
    clean) rm -rf "$DD" ;;
    cold) rm -rf "$DD" "$ROOT_DIR/.build/home" "$ROOT_DIR/.build/module-cache" ;;
  esac
}

cmd_doctor() {
  check_env
  printf 'root=%s\n' "$ROOT_DIR"
  printf 'xcode=%s\n' "$(xcodebuild -version | head -1)"
  printf 'sdk=%s\n' "$(xcrun --sdk iphonesimulator --show-sdk-version)"
  printf 'scheme=%s\n' "$SCHEME"
  printf 'destination=%s\n' "$DEST"
  printf 'derivedData=%s\n' "$DD"
  printf 'userHomePin=%s\n' "${CFFIXED_USER_HOME:-<off>}"
  printf 'schemes:\n'
  list_schemes | sed 's/^/  - /'
  printf 'simulators:\n'
  xcrun simctl list devices available | awk -F'[()]' '/^ +/ && NF>=2 {print "  - " $1}' | head -8
  printf 'doctor: OK\n'
}

usage() { sed -n '2,30p' "${BASH_SOURCE[0]}"; }

# 允许被 source 做单点验证（source 时只定义函数、不执行子命令）：
#   bash -c 'source Scripts/ci.sh; assert_tests_passed <bundle>'   ← 判据的"一正一反"样本靠它跑。
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-pr}" in
    pr) shift || true; cmd_pr "$@" ;;
    nightly) shift || true; cmd_nightly "$@" ;;
    measure) shift || true; cmd_measure "$@" ;;
    doctor) shift || true; cmd_doctor "$@" ;;
    --help|-h|help) usage ;;
    *) die "未知子命令 '$1'（pr / nightly / measure / doctor）" ;;
  esac
fi
