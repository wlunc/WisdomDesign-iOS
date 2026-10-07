#!/usr/bin/env bash
# iOS/Scripts/check-structure.sh —— PR-0 唯一强制入口：R1–R21（host，秒级，不需要 Xcode）
#
# 口径：iOS/docs/SPEC.md §1.1.1「唯一入口 + 三种驱动」①：本地与 CI 都只认本脚本。
# 驱动②（build tool plugin）M0 不启用（Package.swift 不声明 plugin）；驱动③ = Scripts/test-checker.sh。
#
# 用法：
#   Scripts/check-structure.sh                 # 扫本仓（--root .）
#   Scripts/check-structure.sh --rule R1       # 只跑单条规则（透传给检查器）
#   Scripts/check-structure.sh --list-rules    # 列规则
#   Scripts/check-structure.sh --tokens-trace  # 跨仓同批自证：读设计仓 dist/tokens.manifest.json 断言 sha12（缺失 = fail）
#
# 注：令牌溯源已由 I-M0-g 落地（--tokens-trace，跨仓自证，SPEC §1.5.4-3）；
#     契约清单断言仍待设计仓的 contracts/dist/*.json（M0-5）。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

# 中间产物收进 .build/（与 SPEC §1.6 的固定 DerivedData 口径一致；已有环境变量优先）。
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/module-cache}"
export SWIFT_MODULE_CACHE_PATH="${SWIFT_MODULE_CACHE_PATH:-$ROOT_DIR/.build/module-cache}"

build_checker() {
  swift build --package-path . --product wd-structure-check "$@"
}

# SwiftPM 的 manifest 沙箱走 sandbox-exec，在嵌套沙箱/受限环境里会 sandbox_apply 失败
# （实测：`sandbox-exec: sandbox_apply: Operation not permitted`）⇒ 只在该错误上回退一次。
if ! build_output="$(build_checker 2>&1)"; then
  if grep -qE 'sandbox_apply|sandbox-exec' <<<"$build_output"; then
    echo "note: SwiftPM manifest 沙箱不可用（嵌套沙箱），回退 --disable-sandbox" >&2
    build_checker --disable-sandbox >/dev/null
  else
    printf '%s\n' "$build_output" >&2
    exit 1
  fi
fi

exec "$ROOT_DIR/.build/debug/wd-structure-check" --root . "$@"
