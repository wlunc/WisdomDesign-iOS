#!/usr/bin/env bash
# iOS/Scripts/dump-api.sh —— PR-2：API 冻结（规范化符号快照入库 + 重跑零 diff）
#
# 口径：iOS/docs/SPEC.md §1.5.3（规范化器 + `api/WisdomUI.api.json`）+ §1.5.1 四条纪律第 1 条：
#   **复用 PR-1 的 DerivedData，不额外编译**（本脚本只读上一步 `build-for-testing` 产出的
#   `WisdomUI.swiftmodule`，不产生第二张编译图）。
#
# 用法：
#   Scripts/dump-api.sh            # 校验模式（默认）：重跑必须与基线零 diff，否则 exit 1
#   Scripts/dump-api.sh --update   # 有意变更基线时使用（按 SPEC §1.5.3：规范化器变更/API 变更 = 单独 PR）
#   Scripts/dump-api.sh --help
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

DD="${WD_DERIVED_DATA:-.build/dd}"
MODULE="${WD_API_MODULE:-WisdomUI}"
TARGET="${WD_API_TARGET:-arm64-apple-ios17.0-simulator}"
RAW_DIR=".build/api-raw"
BASELINE="api/WisdomUI.api.json"
SCHEME_HINT="${WD_SCHEME:-WisdomDesign-iOS-Package}"

MODE=check
case "${1:-}" in
  --update) MODE=update ;;
  --check|"") MODE=check ;;
  --help|-h)
    sed -n '2,14p' "${BASH_SOURCE[0]}"
    exit 0
    ;;
  *) echo "dump-api: 未知参数 '$1'（--help）" >&2; exit 2 ;;
esac

# 中间产物收进 .build/（与 SPEC §1.6 的固定 DerivedData 口径一致；已有环境变量优先）。
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/module-cache}"
export SWIFT_MODULE_CACHE_PATH="${SWIFT_MODULE_CACHE_PATH:-$ROOT_DIR/.build/module-cache}"

# ① 复用 PR-1 的产物：优先模拟器图（与 TARGET 三元组一致），退化时再全量查找。
MOD_PATH="$(find "$DD/Build/Products/Debug-iphonesimulator" -maxdepth 1 -name "$MODULE.swiftmodule" 2>/dev/null | head -1 || true)"
if [ -z "$MOD_PATH" ]; then
  MOD_PATH="$(find "$DD/Build/Products" -maxdepth 3 -name "$MODULE.swiftmodule" 2>/dev/null | head -1 || true)"
fi
if [ -z "$MOD_PATH" ]; then
  echo "dump-api: 找不到 ${MODULE}.swiftmodule（${DD}）。先跑 PR-1 的 build-for-testing，例如：" >&2
  echo "  xcodebuild build-for-testing -scheme $SCHEME_HINT -destination 'platform=iOS Simulator,id=<UDID>' -derivedDataPath $DD" >&2
  exit 1
fi

mkdir -p "$RAW_DIR" api
rm -f "$RAW_DIR/$MODULE.symbols.json" "$RAW_DIR/$MODULE"@*.symbols.json

# ② 抽取公开面符号图（只读 .swiftmodule，不编译）。
xcrun swift-symbolgraph-extract \
  -module-name "$MODULE" \
  -I "$(dirname "$MOD_PATH")" \
  -target "$TARGET" \
  -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  -minimum-access-level public \
  -output-dir "$RAW_DIR" \
  -pretty-print

# `swift-symbolgraph-extract` 把"本模块声明"与"对其它模块类型的扩展"分成两个文件：
#   <Module>.symbols.json（自有类型） + <Module>@<ExtendedModule>.symbols.json（扩展 API，如 View.wdShadow）
# 扩展文件必须一并入库，否则基线不覆盖 `.wdSheet`/`.wdShadow` 这类公开面。
RAW_INPUTS=()
if [ -s "$RAW_DIR/$MODULE.symbols.json" ]; then
  RAW_INPUTS+=("$RAW_DIR/$MODULE.symbols.json")
fi
for extended in "$RAW_DIR/$MODULE"@*.symbols.json; do
  if [ -s "$extended" ]; then
    RAW_INPUTS+=("$extended")
  fi
done
[ "${#RAW_INPUTS[@]}" -gt 0 ] || { echo "dump-api: swift-symbolgraph-extract 未产出符号图（$RAW_DIR）" >&2; exit 1; }

# ③ 规范化（字段白名单 + 合并扩展图 + 排序 + 工具链 manifest）。
# `--exclude-source`：PR-1 的 build-for-testing 带 `WD_API_SMOKE`（签名冒烟），而 PR-2 **复用同一份
# DerivedData 且不额外编译** ⇒ 该模块里含冒烟声明；冒烟不是发布面，必须按源文件剔除，否则基线漂移。
NEW="$RAW_DIR/$MODULE.api.json"
SMOKE_SOURCE="Sources/WisdomUI/APISurface/WDAPISurface.swift"
swift "$SCRIPT_DIR/canonicalize-api.swift" "${RAW_INPUTS[@]}" \
  --module "$MODULE" --target "$TARGET" \
  --source-root "Sources/$MODULE" --exclude-source "$SMOKE_SOURCE" > "$NEW"
[ -s "$NEW" ] || { echo "dump-api: 规范化输出为空" >&2; exit 1; }

# ④ 自证：规范化输出不得残留 usr/location 等易漂移字段（SPEC §1.5.3）。
for banned in '"usr"' '"location"' '"docComment"' '"mixins"' '"relationships"' '"accessibility"' '"spi"' '"preciseIdentifier"'; do
  if grep -q -- "$banned" "$NEW"; then
    echo "dump-api: 规范化输出仍含易漂移字段 $banned" >&2
    exit 1
  fi
done

# ⑤ 与既有基线比对：重跑必须零 diff；基线缺失 = 首次落地。
if [ "$MODE" = "update" ]; then
  cp "$NEW" "$BASELINE"
  echo "dump-api: 已更新基线 ${BASELINE}（按 SPEC §1.5.3，基线变更需单独 PR + CHANGELOG）"
else
  if [ -f "$BASELINE" ]; then
    if ! diff -u "$BASELINE" "$NEW"; then
      echo "dump-api: API 基线漂移（确认是有意变更后跑 Scripts/dump-api.sh --update）" >&2
      exit 1
    fi
    echo "dump-api: 与基线零 diff（symbols=$(grep -c '"kind"' "$NEW")）"
  else
    cp "$NEW" "$BASELINE"
    echo "dump-api: 基线首次生成 ${BASELINE}（symbols=$(grep -c '"kind"' "$NEW")）"
  fi
fi

# ⑥ SPEC §1.5.3 的原始检查命令（基线已跟踪时等价）。
if git ls-files --error-unmatch "$BASELINE" >/dev/null 2>&1; then
  git diff --exit-code -- "$BASELINE" >/dev/null || {
    echo "dump-api: git diff 检出基线变更：${BASELINE}" >&2
    exit 1
  }
fi
echo "dump-api: OK（target=$TARGET module=$MODULE baseline=${BASELINE} mode=${MODE}）"
