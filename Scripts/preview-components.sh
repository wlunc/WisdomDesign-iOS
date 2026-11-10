#!/usr/bin/env bash
# Scripts/preview-components.sh —— 组件快照画廊（不启动 Xcode / 模拟器的快速查看方式）
#
# 读 Tests/WisdomUISnapshotTests/Baselines/ 的 8 态基线，生成一个 HTML 画廊并在浏览器打开。
# 适用场景：快速目视对比"改一个间距/颜色"前后的差异；不能替代 demo 的交互与无障碍审计。
#
# 用法：
#   Scripts/preview-components.sh              # 生成到 .build/component-gallery.html 并打开
#   Scripts/preview-components.sh /tmp/x.html  # 指定输出路径（不自动打开需 CI 环境变量 WD_NO_OPEN=1）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT="${1:-$ROOT_DIR/.build/component-gallery.html}"

python3 - "$ROOT_DIR" "$OUT" <<'PY'
import html
import os
import sys

root, out = sys.argv[1], sys.argv[2]
baseline_dir = os.path.join(root, "Tests/WisdomUISnapshotTests/Baselines")
components = [
    ("textfield", "WDTextField"),
    ("listrow", "WDListRow"),
    ("button", "WDButton"),
    ("iconbutton", "WDIconButton"),
    ("switch", "WDSwitch"),
    ("checkbox", "WDCheckbox"),
    ("badge", "WDBadge"),
    ("avatar", "WDAvatar"),
    ("divider", "WDDivider"),
    ("card", "WDCard"),
    ("icon", "WDIcon"),
]
states = ["light-default-ltr", "light-default-rtl", "light-ax3-ltr", "light-ax3-rtl",
          "dark-default-ltr", "dark-default-rtl", "dark-ax3-ltr", "dark-ax3-rtl"]

out_dir = os.path.dirname(os.path.abspath(out))
os.makedirs(out_dir, exist_ok=True)

parts = [
    "<!doctype html><html lang='zh'><meta charset='utf-8'>",
    "<title>WisdomUI · 组件 8 态快照</title>",
    "<style>",
    "body{font-family:-apple-system,BlinkMacSystemFont,'PingFang SC',sans-serif;",
    "margin:24px;background:#0f1720;color:#e6f1f6}",
    "h1{font-size:20px;margin:0 0 4px} p{color:#a4bccb;font-size:13px;margin:0 0 24px}",
    "section{margin:0 0 28px} h2{font-size:15px;color:#7ec4cf;margin:0 0 10px}",
    ".grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px}",
    "figure{margin:0;background:#132836;border-radius:12px;padding:8px}",
    "img{width:100%;display:block;border-radius:8px;background:#fff}",
    "figcaption{font-size:11px;color:#a4bccb;margin-top:6px;font-variant-numeric:tabular-nums}",
    "</style><h1>WisdomUI · M2 组件 8 态快照</h1>",
    "<p>浅/深 × 默认/AX3 × LTR/RTL（共 11 件 × 8 态）。交互与无障碍审计请用 Examples/WisdomUIDemo。</p>",
]

for prefix, name in components:
    rows = []
    for state in states:
        png = os.path.join(baseline_dir, f"{prefix}-{state}.png")
        if not os.path.exists(png):
            continue
        rel = os.path.relpath(png, out_dir)
        rows.append(
            f"<figure><img src='{html.escape(rel)}' loading='lazy'>"
            f"<figcaption>{html.escape(state)}</figcaption></figure>"
        )
    if not rows:
        continue
    parts.append(f"<section><h2>{html.escape(name)}</h2><div class='grid'>")
    parts.extend(rows)
    parts.append("</div></section>")

parts.append("</html>")
with open(out, "w", encoding="utf-8") as handle:
    handle.write("\n".join(parts))

print(f"preview-components: 已生成 {out}（组件 {len(components)} 件）")
PY

if [ "${WD_NO_OPEN:-0}" != "1" ]; then
  open "$OUT" 2>/dev/null || true
fi
