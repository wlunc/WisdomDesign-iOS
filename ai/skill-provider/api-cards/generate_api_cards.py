#!/usr/bin/env python3
"""Generate M2 iOS API cards from the checked-in public API snapshot only.

The symbol snapshot is pinned to the M0 baseline commit (c3c32f3). If the iOS
repository has advanced since then (current HEAD 64539fe), the *current* API
file no longer matches the pin and regeneration must be replayed from the
baseline snapshot; see ai/skill-provider/SNAPSHOT.md.

Usage:
  python3 ai/skill-provider/api-cards/generate_api_cards.py [--api PATH] [--out DIR]

Defaults:
  --api  api/WisdomUI.api.json (iOS repo root)
  --out  ai/skill-provider/api-cards
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
API = ROOT / "api/WisdomUI.api.json"
OUT = ROOT / "ai/skill-provider/api-cards"
EXPECTED_API_SHA = "123136bdf1f5299d740e1e220c7973eb82914c5df53eb093053ac51469158c34"
EXPECTED_ICON_SHA = "0b2761c4d73ba7e3f5086e7e948e8944c23b9888cc44b97369052f182a6ff761"
# All cards point at the same pinned snapshot evidence (M0 baseline); the
# canonical per-card symbol evidence is the api/WisdomUI.api.json entry.
SOURCE_REF_SNAPSHOT = "ai/skill-provider/api-cards/SOURCES.json#/baseline/apiSnapshotSha256"

CARD_SPECS = [
  ("WDButton.main","WDButton","label","WDButton.init(_:variant:size:isLoading:loadingAccessibilityText:leadingIcon:trailingIcon:action:)","unlabeled LocalizedStringKey + real labels","WDButton(\"新建\", variant: .filled, action: {})",["Three real overloads exist; this is the LocalizedStringKey overload."]),
  ("WDButton.viewBuilder","WDButton","label","WDButton.init(variant:size:isLoading:loadingAccessibilityText:leadingIcon:trailingIcon:action:label:)","@ViewBuilder label closure","WDButton(variant: .tonal) { Text(verbatim: label) }",[]),
  ("WDButton.verbatim","WDButton","label","WDButton.init(verbatim:variant:size:isLoading:loadingAccessibilityText:leadingIcon:trailingIcon:action:)","verbatim String","WDButton(verbatim: dynamicTitle, action: {})",[]),
  ("WDButtonStyle.wd","WDButton","variant","ButtonStyle.wd(_:size:)","static func wd(_ variant:size:)","ButtonStyle.wd(.filled, size: .md)",[]),
  ("WDListRow.main","WDListRow","title","WDListRow.init(title:subtitle:leading:trailing:isSelected:swipeAction:showsSeparator:action:)","title/subtitle/leading/trailing/isSelected/swipeAction/showsSeparator/action","WDListRow(title: Text(verbatim: title), trailing: .disclosure) {}",[]),
  ("WDListRowLeading.icon","WDListRow","leading","WDListRowLeading.icon(_:)","enum case icon(WDIconName)",".icon(.task)",[]),
  ("WDListRowTrailing.disclosure","WDListRow","trailing","WDListRowTrailing.disclosure","enum case disclosure",".disclosure",[]),
  ("WDListSection.noFooter","WDListSection","items","WDListSection.init(items:selection:header:headerAction:row:)","items/selection/header/headerAction/@ViewBuilder row","WDListSection(items: items, header: header) { item, ctx in }",["Generic Item: Identifiable, Row: View."]),
  ("WDListSection.withFooter","WDListSection","items","WDListSection.init(items:selection:header:headerAction:row:footer:)","items/selection/header/headerAction/@ViewBuilder row/@ViewBuilder footer","WDListSection(items: items, header: header, row: { ... }, footer: { ... })",["Generic Item: Identifiable, Row: View, Footer: View."]),
  ("WDListSectionRowContext","WDListSection","itemPattern","WDListSectionRowContext","let isSelected: Bool; let isLast: Bool","row closure receives (Item, WDListSectionRowContext)",[]),
  ("WDListSectionAction","WDListSection","headerAction","WDListSectionAction.init(label:action:)","label/action","WDListSectionAction(label: Text(verbatim: \"Clear\"), action: {})",[]),
  ("WDEmptyState.main","WDEmptyState","title","WDEmptyState.init(icon:title:message:action:)","icon/title/message/action","WDEmptyState(icon: .task, title: Text(verbatim: \"No tasks\"))",[]),
  ("WDEmptyStateAction","WDEmptyState","action","WDEmptyStateAction.init(label:isLoading:action:)","label/isLoading/action","WDEmptyStateAction(label: Text(verbatim: \"Retry\"), action: {})",[]),
  ("WDSkeleton.main","WDSkeleton","loading","WDSkeleton.init(variant:lineCount:accessibilityLabel:)","variant/lineCount/accessibilityLabel","WDSkeleton(variant: .list, lineCount: 3)",[]),
  ("WDSkeletonVariant.list","WDSkeleton","loading","WDSkeletonVariant.list","enum case list","WDSkeleton(variant: .list)",[]),
  ("WDBanner.main","WDBanner","error","WDBanner.init(isVisible:variant:message:action:dismissAccessibilityLabel:)","isVisible/variant/message/action/dismissAccessibilityLabel","WDBanner(isVisible: $errorVisible, variant: .danger, message: message)",[]),
  ("WDFAB.main","WDFAB","primaryAction","WDFAB.init(icon:accessibilityLabel:size:shape:actions:action:showsScrimWhenExpanded:avoidsTabBar:)","icon/accessibilityLabel/size/shape/actions/action/showsScrimWhenExpanded/avoidsTabBar","WDFAB(icon: .add, accessibilityLabel: label, avoidsTabBar: true, action: {})",["avoidsTabBar is the real iOS label for tab-safe-area."]),
  ("WDTextField.main","WDTextField","text","WDTextField.init(text:label:appearance:isEditable:onSubmit:onEditingChanged:)","text/label/appearance/isEditable/onSubmit/onEditingChanged","WDTextField(text: $query, label: Text(verbatim: \"Search\"))",["label is required on iOS."]),
  ("WDTextFieldAppearance","WDTextField","appearance","WDTextFieldAppearance.init(variant:placeholder:prefix:accessory:helper:isSecure:submitLabel:)","variant/placeholder/prefix/accessory/helper/isSecure/submitLabel","WDTextFieldAppearance(variant: .inset)",[]),
  ("WDFormRow.main","WDFormRow","label","WDFormRow.init(label:layout:helper:error:requiredLabel:control:)","label/layout/helper/error/requiredLabel/@ViewBuilder control","WDFormRow(label: label) { control }",["Generic Control: View."]),
  ("View.wdTheme","WDTheme","theme","View.wdTheme(_:)","wdTheme(_ theme:)","view.wdTheme(.dark)",[]),
  ("View.wdThemeScheme","WDTheme","colorScheme","View.wdTheme(scheme:)","wdTheme(scheme:)","view.wdTheme(scheme: \"dark\")",["Unknown scheme is a no-op."]),
  ("View.wdFont","WDTextStyle","typography","View.wdFont(_:)","wdFont(_ style:)","view.wdFont(WDType.body)",[]),
  ("View.wdLineBox","WDTextStyle","typography","View.wdLineBox(_:lines:)","wdLineBox(_ style:lines:)","view.wdLineBox(WDType.body, lines: 2)",[]),
  ("View.wdAnnouncer","WDSemantics","announcements","View.wdAnnouncer(_:)","wdAnnouncer(_:) closure","view.wdAnnouncer { text, priority in }",[]),
  ("View.wdPullRefresh","WDPullRefresh","refresh","View.wdPullRefresh(isRefreshing:label:onRefreshError:timeout:texts:onRefresh:)","wdPullRefresh(isRefreshing:label:onRefreshError:timeout:texts:onRefresh:)","view.wdPullRefresh(isRefreshing: $refreshing, onRefresh: {})",["onRefresh is async throws."]),
  ("View.wdEffectsBudget","WDEffectsBudget","effectsBudget","View.wdEffectsBudget(_:)","wdEffectsBudget(_:)","view.wdEffectsBudget(.minimal)",["Only lowers the current budget."]),
  ("WDEffectsBudget.default","WDEffectsBudget","effectsBudget","WDEffectsBudget.default","static let default","WDEffectsBudget.default",[]),
  ("WDGlass.resolve","WDGlass","effectResolution","WDGlass.resolve(textLevel:appearance:capabilities:budget:level:)","static func resolve(textLevel:appearance:capabilities:budget:level:)","WDGlass.resolve(textLevel: .primary, appearance: appearance, capabilities: caps, budget: budget)",[]),
  ("WDGlassCapabilities","WDGlass","capabilities","WDGlassCapabilities.init(supportsGlass:)","supportsGlass","WDGlassCapabilities(supportsGlass: true)",[]),
  ("WDSemantics.joinText","WDSemantics","announcements","WDSemantics.join(_:separator:)","static func join(_ parts: [Text], separator: Text)","WDSemantics.join([label, value], separator: Text(verbatim: \" \"))",["Text and String overloads both exist."]),
  ("WDSemantics.joinStrings","WDSemantics","announcements","WDSemantics.join(_:separator:)","static func join(_ parts: [String], separator: String)","WDSemantics.join([label, value], separator: \" \")",["Text and String overloads both exist."]),
  ("WDSemantics.positional","WDSemantics","announcements","WDSemantics.positional(label:positionText:separator:)","static func positional(label:positionText:separator:)","WDSemantics.positional(label: name, positionText: position, separator: Text(verbatim: \", \"))",[]),
]

def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()

def main() -> None:
    parser = argparse.ArgumentParser(description="Generate the 33 iOS API cards from the pinned public API snapshot.")
    parser.add_argument("--api", default=str(API), help="public symbol snapshot (default: api/WisdomUI.api.json)")
    parser.add_argument("--out", default=str(OUT), help="output directory (default: ai/skill-provider/api-cards)")
    args = parser.parse_args()
    api_path = Path(args.api)
    out_dir = Path(args.out)
    api_sha = sha(api_path)
    icon_sha = sha(ROOT / "Sources/WisdomUI/Foundation/generated/WDIconName.swift")
    if api_sha != EXPECTED_API_SHA or icon_sha != EXPECTED_ICON_SHA:
        raise SystemExit(
            "public snapshot drift: api=%s icon=%s; regenerate from the baseline snapshot "
            "(see ai/skill-provider/SNAPSHOT.md)" % (api_sha, icon_sha)
        )
    payload = json.loads(api_path.read_text(encoding="utf-8"))
    by_path = {}
    for item in payload["symbols"]:
        by_path.setdefault(item["path"], []).append(item)
    missing = [p for _, _, _, p, _, _, _ in CARD_SPECS if p not in by_path]
    if missing:
        raise SystemExit("missing public symbols: " + ", ".join(missing))
    out_dir.mkdir(parents=True, exist_ok=True)
    names = []
    for name, component, canonical, path, label, call, limits in CARD_SPECS:
        found = by_path[path]
        decls = [s["decl"] for s in found if s.get("access") == "public"] or [s["decl"] for s in found]
        card = {
            "schemaVersion": "1.0",
            "platform": "ios",
            "component": component,
            "canonicalParam": canonical,
            "symbol": path,
            "signature": " | ".join(decls),
            # iosLabel used to be a custom property; api-card.schema.json has
            # additionalProperties:false, so the label mapping lives in the
            # allowed limitations array and the exact labels stay in signature.
            "callShape": call,
            "evidence": "discovered",
            "sourceRefs": ["api/WisdomUI.api.json#" + path, SOURCE_REF_SNAPSHOT],
            "limitations": ["Public symbol graph only; overloads and associated types preserved verbatim."]
                           + ["iOS label mapping: " + label]
                           + limits,
        }
        (out_dir / (name + ".json")).write_text(json.dumps(card, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        names.append(name + ".json")
    (out_dir / "index.json").write_text(
        json.dumps({"schemaVersion": "1.0", "platform": "ios", "evidenceMinimum": "discovered", "cards": sorted(names)},
                   ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print("wrote %d API cards to %s (api sha256=%s)" % (len(names), out_dir, api_sha))

if __name__ == "__main__":
    main()
