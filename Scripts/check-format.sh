#!/usr/bin/env bash
# iOS/Scripts/check-format.sh —— PR-0 格式门禁（swift-format，工具链自带、零第三方依赖）
#
# 口径：iOS/docs/SPEC.md §1.3
#   · 配置 = 仓库根的 `.swift-format`（只显式写我们改动的键；其余沿用工具默认）；
#   · **配置文件没有 `exclude` 键**（[组长实测]）⇒ `Generated/` 靠**显式文件清单**排除；
#   · 命令 = `xcrun swift-format lint --strict --parallel`。
#
# 显式清单（默认）＝ git 跟踪的 `*.swift` **＋ 工作区未跟踪但未被 ignore 的 `*.swift`**，
# 再排除两类**不参与库编译**的文件：
#   ① `/Foundation/generated/`（生成物，由 ../wisdomdesign/tools/token-build/build.js 写；
#      **模式写成 `[Gg]enerated` 是有意的**：M0-2 把目录从 `Generated/` 纯移动为 `generated/`，
#      大小写不敏感的文件系统上两种拼写指向同一处，排除模式必须两种都覆盖才不会假红；
#      文件头 banner 校验归结构检查器 R12。**手改生成物会破坏 R12 与令牌溯源**；
#      该目录在 M0 下必然红——生成器尚未给每个 public 成员 emit `///`，
#      而 `.swift-format` 开了 `AllPublicDeclarationsHaveDocumentation`
#      ⇒ 按 SPEC §1.3-2 用显式清单排除；生成器补文档后（M1）再切回"含 Generated/ 的全量清单"）；
#   ② `/Scripts/Fixtures/structure/`（结构检查器的 **50 个违规样本输入**：`test-checker.sh` 靠它们做
#      "每条规则一正一反 + 变异测试"。这些样本**故意违反**库风格/令牌规则，且严格来说不是源码：
#      **格式化它们会改变样本语义**（甚至让反例不再违规）⇒ 等于破坏变异测试。
#      **本清单永不包含 `Scripts/Fixtures/structure/`**；需要给样本排版时请单独、显式地传文件名，
#      不要走默认清单。其它 fixture 目录（未来新增）默认**纳入**清单 = fail-closed）。
#
# 用法：
#   Scripts/check-format.sh                 # 全量（默认清单）
#   Scripts/check-format.sh A.swift B.swift # 只查指定文件（本地增量回路）
#   Scripts/check-format.sh --list          # 只打印将要检查的清单
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

CONFIG="$ROOT_DIR/.swift-format"
[ -s "$CONFIG" ] || { echo "check-format: 缺少配置 $CONFIG" >&2; exit 2; }

list_files() {
  {
    git ls-files '*.swift'
    git ls-files --others --exclude-standard '*.swift'
  } | sort -u | grep -vE '/Foundation/[Gg]enerated/' | grep -v 'Scripts/Fixtures/structure/' || true
}

if [ "${1:-}" = "--list" ]; then
  list_files
  exit 0
fi

if [ "$#" -gt 0 ]; then
  FILES=("$@")
else
  # bash 3.2 兼容：不依赖 mapfile，用换行分隔的字符串 + 单词拆分
  FILE_LIST="$(list_files)"
  if [ -z "$FILE_LIST" ]; then
    echo "check-format: 清单为空（无可检查的 .swift）"
    exit 0
  fi
  FILES=($FILE_LIST)
fi

echo "check-format: files=${#FILES[@]} config=$CONFIG"
xcrun swift-format lint --strict --parallel --configuration "$CONFIG" "${FILES[@]}"
echo "check-format: OK（${#FILES[@]} 个文件全部通过 --strict）"
