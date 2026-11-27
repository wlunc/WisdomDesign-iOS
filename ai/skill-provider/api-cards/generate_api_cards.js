#!/usr/bin/env node
/**
 * Generate M2 iOS API cards from the checked-in public API snapshot only.
 *
 * The symbol snapshot is pinned to the M0 baseline commit (c3c32f3). If the iOS
 * repository has advanced since then (current HEAD 64539fe), the *current* API
 * file no longer matches the pin and regeneration must be replayed from the
 * baseline snapshot; see ai/skill-provider/SNAPSHOT.md.
 *
 * Usage:
 *   node ai/skill-provider/api-cards/generate_api_cards.js [--api PATH] [--out DIR]
 *
 * Defaults:
 *   --api  api/WisdomUI.api.json (iOS repo root)
 *   --out  ai/skill-provider/api-cards
 */
"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const ROOT = path.resolve(path.dirname(fs.realpathSync(__filename)), "..", "..", "..");
const API = path.join(ROOT, "api", "WisdomUI.api.json");
const OUT = path.join(ROOT, "ai", "skill-provider", "api-cards");
const EXPECTED_API_SHA = "58fb3291f1180552994c9c0ae81331d81adcdea50b0572e8a5837628164c4ce1";
const EXPECTED_ICON_SHA = "0b2761c4d73ba7e3f5086e7e948e8944c23b9888cc44b97369052f182a6ff761";
// All cards point at the same pinned snapshot evidence (M0 baseline); the
// canonical per-card symbol evidence is the api/WisdomUI.api.json entry.
const SOURCE_REF_SNAPSHOT = "ai/skill-provider/api-cards/SOURCES.json#/baseline/apiSnapshotSha256";

const CARD_SPECS = [
  ["WDButton.main","WDButton","label","WDButton.init(_:variant:size:isLoading:loadingAccessibilityText:leadingIcon:trailingIcon:action:)","unlabeled LocalizedStringKey + real labels","WDButton(\"新建\", variant: .filled, action: {})",["Three real overloads exist; this is the LocalizedStringKey overload."]],
  ["WDButton.viewBuilder","WDButton","label","WDButton.init(variant:size:isLoading:loadingAccessibilityText:leadingIcon:trailingIcon:action:label:)","@ViewBuilder label closure","WDButton(variant: .tonal) { Text(verbatim: label) }",[]],
  ["WDButton.verbatim","WDButton","label","WDButton.init(verbatim:variant:size:isLoading:loadingAccessibilityText:leadingIcon:trailingIcon:action:)","verbatim String","WDButton(verbatim: dynamicTitle, action: {})",[]],
  ["WDButtonStyle.wd","WDButton","variant","ButtonStyle.wd(_:size:)","static func wd(_ variant:size:)","ButtonStyle.wd(.filled, size: .md)",[]],
  ["WDListRow.main","WDListRow","title","WDListRow.init(title:subtitle:leading:trailing:isSelected:swipeAction:showsSeparator:action:)","title/subtitle/leading/trailing/isSelected/swipeAction/showsSeparator/action","WDListRow(title: Text(verbatim: title), trailing: .disclosure) {}",[]],
  ["WDListRowLeading.icon","WDListRow","leading","WDListRowLeading.icon(_:)","enum case icon(WDIconName)",".icon(.task)",[]],
  ["WDListRowTrailing.disclosure","WDListRow","trailing","WDListRowTrailing.disclosure","enum case disclosure",".disclosure",[]],
  ["WDListSection.noFooter","WDListSection","items","WDListSection.init(items:selection:header:headerAction:row:)","items/selection/header/headerAction/@ViewBuilder row","WDListSection(items: items, header: header) { item, ctx in }",["Generic Item: Identifiable, Row: View."]],
  ["WDListSection.withFooter","WDListSection","items","WDListSection.init(items:selection:header:headerAction:row:footer:)","items/selection/header/headerAction/@ViewBuilder row/@ViewBuilder footer","WDListSection(items: items, header: header, row: { ... }, footer: { ... })",["Generic Item: Identifiable, Row: View, Footer: View."]],
  ["WDListSectionRowContext","WDListSection","itemPattern","WDListSectionRowContext","let isSelected: Bool; let isLast: Bool","row closure receives (Item, WDListSectionRowContext)",[]],
  ["WDListSectionAction","WDListSection","headerAction","WDListSectionAction.init(label:action:)","label/action","WDListSectionAction(label: Text(verbatim: \"Clear\"), action: {})",[]],
  ["WDEmptyState.main","WDEmptyState","title","WDEmptyState.init(icon:title:message:action:)","icon/title/message/action","WDEmptyState(icon: .task, title: Text(verbatim: \"No tasks\"))",[]],
  ["WDEmptyStateAction","WDEmptyState","action","WDEmptyStateAction.init(label:isLoading:action:)","label/isLoading/action","WDEmptyStateAction(label: Text(verbatim: \"Retry\"), action: {})",[]],
  ["WDSkeleton.main","WDSkeleton","loading","WDSkeleton.init(variant:lineCount:accessibilityLabel:)","variant/lineCount/accessibilityLabel","WDSkeleton(variant: .list, lineCount: 3)",[]],
  ["WDSkeletonVariant.list","WDSkeleton","loading","WDSkeletonVariant.list","enum case list","WDSkeleton(variant: .list)",[]],
  ["WDBanner.main","WDBanner","error","WDBanner.init(isVisible:variant:message:action:dismissAccessibilityLabel:)","isVisible/variant/message/action/dismissAccessibilityLabel","WDBanner(isVisible: $errorVisible, variant: .danger, message: message)",[]],
  ["WDFAB.main","WDFAB","primaryAction","WDFAB.init(icon:accessibilityLabel:size:shape:actions:action:showsScrimWhenExpanded:avoidsTabBar:)","icon/accessibilityLabel/size/shape/actions/action/showsScrimWhenExpanded/avoidsTabBar","WDFAB(icon: .add, accessibilityLabel: label, avoidsTabBar: true, action: {})",["avoidsTabBar is the real iOS label for tab-safe-area."]],
  ["WDTextField.main","WDTextField","text","WDTextField.init(text:label:appearance:isEditable:onSubmit:onEditingChanged:)","text/label/appearance/isEditable/onSubmit/onEditingChanged","WDTextField(text: $query, label: Text(verbatim: \"Search\"))",["label is required on iOS."]],
  ["WDTextFieldAppearance","WDTextField","appearance","WDTextFieldAppearance.init(variant:placeholder:prefix:accessory:helper:isSecure:submitLabel:)","variant/placeholder/prefix/accessory/helper/isSecure/submitLabel","WDTextFieldAppearance(variant: .inset)",[]],
  ["WDFormRow.main","WDFormRow","label","WDFormRow.init(label:layout:helper:error:requiredLabel:control:)","label/layout/helper/error/requiredLabel/@ViewBuilder control","WDFormRow(label: label) { control }",["Generic Control: View."]],
  ["View.wdTheme","WDTheme","theme","View.wdTheme(_:)","wdTheme(_ theme:)","view.wdTheme(.dark)",[]],
  ["View.wdThemeScheme","WDTheme","colorScheme","View.wdTheme(scheme:)","wdTheme(scheme:)","view.wdTheme(scheme: \"dark\")",["Unknown scheme is a no-op."]],
  ["View.wdFont","WDTextStyle","typography","View.wdFont(_:)","wdFont(_ style:)","view.wdFont(WDType.body)",[]],
  ["View.wdLineBox","WDTextStyle","typography","View.wdLineBox(_:lines:)","wdLineBox(_ style:lines:)","view.wdLineBox(WDType.body, lines: 2)",[]],
  ["View.wdAnnouncer","WDSemantics","announcements","View.wdAnnouncer(_:)","wdAnnouncer(_:) closure","view.wdAnnouncer { text, priority in }",[]],
  ["View.wdPullRefresh","WDPullRefresh","refresh","View.wdPullRefresh(isRefreshing:label:onRefreshError:timeout:texts:onRefresh:)","wdPullRefresh(isRefreshing:label:onRefreshError:timeout:texts:onRefresh:)","view.wdPullRefresh(isRefreshing: $refreshing, onRefresh: {})",["onRefresh is async throws."]],
  ["View.wdEffectsBudget","WDEffectsBudget","effectsBudget","View.wdEffectsBudget(_:)","wdEffectsBudget(_:)","view.wdEffectsBudget(.minimal)",["Only lowers the current budget."]],
  ["WDEffectsBudget.default","WDEffectsBudget","effectsBudget","WDEffectsBudget.default","static let default","WDEffectsBudget.default",[]],
  ["WDGlass.resolve","WDGlass","effectResolution","WDGlass.resolve(textLevel:appearance:capabilities:budget:level:)","static func resolve(textLevel:appearance:capabilities:budget:level:)","WDGlass.resolve(textLevel: .primary, appearance: appearance, capabilities: caps, budget: budget)",[]],
  ["WDGlassCapabilities","WDGlass","capabilities","WDGlassCapabilities.init(supportsGlass:)","supportsGlass","WDGlassCapabilities(supportsGlass: true)",[]],
  ["WDSemantics.joinText","WDSemantics","announcements","WDSemantics.join(_:separator:)","static func join(_ parts: [Text], separator: Text)","WDSemantics.join([label, value], separator: Text(verbatim: \" \"))",["Text and String overloads both exist."]],
  ["WDSemantics.joinStrings","WDSemantics","announcements","WDSemantics.join(_:separator:)","static func join(_ parts: [String], separator: String)","WDSemantics.join([label, value], separator: \" \")",["Text and String overloads both exist."]],
  ["WDSemantics.positional","WDSemantics","announcements","WDSemantics.positional(label:positionText:separator:)","static func positional(label:positionText:separator:)","WDSemantics.positional(label: name, positionText: position, separator: Text(verbatim: \", \"))",[]],
  ["WDCard.main","WDCard","content","WDCard.init(style:content:)","style/@ViewBuilder content (default .elevated)","WDCard(style: .elevated) { content }",["Three init overloads: plain, action, and media."]],
  ["WDCard.action","WDCard","action","WDCard.init(style:action:content:)","style/action/@ViewBuilder content","WDCard(style: .outlined, action: { open() }) { content }",[]],
  ["WDCard.media","WDCard","media","WDCard.init(style:media:action:content:)","style/media/action/@ViewBuilder content","WDCard(style: .media, media: WDCardMedia(image), action: { open() }) { content }",["media is nil for placeholder; .media requires this init."]],
  ["WDCardMedia","WDCard","media","WDCardMedia.init(_:accessibilityLabel:)","init(_ image: Image?, accessibilityLabel: Text? = nil)","WDCardMedia(Image(systemName: \"photo\"))",[]],
  ["WDSwitch.main","WDSwitch","isOn","WDSwitch.init(isOn:label:)","isOn/label","WDSwitch(isOn: $enabled, label: Text(verbatim: \"Enable\"))",[]],
  ["WDSwitch.description","WDSwitch","description","WDSwitch.init(isOn:label:description:size:)","isOn/label/description/size","WDSwitch(isOn: $on, label: label, description: hint, size: .standard)",[]],
  ["WDSwitch.onWriteFailure","WDSwitch","onWriteFailure","WDSwitch.init(isOn:label:description:size:onWriteFailure:)","isOn/label/description/size/onWriteFailure","WDSwitch(isOn: $on, label: label, description: nil, size: .standard, onWriteFailure: nil)",[]],
  ["WDCheckbox.main","WDCheckbox","isChecked","WDCheckbox.init(isChecked:label:isIndeterminate:)","isChecked/label","WDCheckbox(isChecked: $checked, label: Text(verbatim: \"Done\"))",[]],
  ["WDCheckbox.size","WDCheckbox","size","WDCheckbox.init(isChecked:label:size:isIndeterminate:)","isChecked/label/size/isIndeterminate","WDCheckbox(isChecked: $checked, label: label, size: .standard, isIndeterminate: false)",[]],
  ["WDCheckbox.accessibility","WDCheckbox","accessibilityLabel","WDCheckbox.init(isChecked:accessibilityLabel:size:isIndeterminate:)","isChecked/accessibilityLabel/size/isIndeterminate","WDCheckbox(isChecked: $checked, accessibilityLabel: label, size: .standard, isIndeterminate: false)",["Use when there is no visible label."]],
  ["WDChip.main","WDChip","label","WDChip.init(label:leadingIcon:size:)","label/leadingIcon/size","WDChip(label: Text(verbatim: \"Filter\"))",[]],
  ["WDChip.selected","WDChip","isSelected","WDChip.init(label:isSelected:leadingIcon:size:)","label/isSelected/leadingIcon/size","WDChip(label: label, isSelected: $selected)",[]],
  ["WDChip.deletable","WDChip","onDelete","WDChip.init(label:leadingIcon:size:deleteAccessibilityLabel:onDelete:)","label/leadingIcon/size/deleteAccessibilityLabel/onDelete","WDChip(label: label, deleteAccessibilityLabel: label, onDelete: { remove() })",[]],
  ["WDSegmentedControl.main","WDSegmentedControl","selection","WDSegmentedControl.init(items:selection:style:positionText:positionSeparator:)","items/selection/style/positionText/positionSeparator","WDSegmentedControl(items: items, selection: $tab)",["selection is a String id."]],
  ["WDSlider.main","WDSlider","value","WDSlider.init(value:label:in:step:onEditingChanged:)","value/label/bounds/step/onEditingChanged","WDSlider(value: $level, label: label, in: 0...1)",[]],
  ["WDSlider.range","WDSlider","range","WDSlider.init(range:label:in:step:onEditingChanged:showsValueLabel:rangeText:lowerAccessibilityLabel:upperAccessibilityLabel:rangeAnnouncementText:)","range/label/bounds/step/onEditingChanged/showsValueLabel","WDSlider(range: $span, label: label, in: 0...1)",["Use for a two-handle range."]],
  ["WDStepper.main","WDStepper","value","WDStepper.init(value:label:in:step:size:unit:)","value/label/bounds/step/size/unit","WDStepper(value: $count, label: label, in: 1...99)",[]],
  ["WDRadio.main","WDRadio","selection","WDRadio.init(selection:label:options:)","selection/label/options","WDRadio(selection: $choice, label: label, options: options)",[]],
  ["WDAvatar.main","WDAvatar","value","WDAvatar.init(value:)","value","WDAvatar(value: .init(label: Text(verbatim: \"Mom\")))",[]],
  ["WDAvatar.size","WDAvatar","size","WDAvatar.init(value:size:isOnline:isDisabled:tone:hostColor:)","value/size/isOnline/isDisabled/tone/hostColor","WDAvatar(value: value, size: .md, isOnline: true)",[]],
  ["WDBadge.main","WDBadge","label","WDBadge.init(label:)","label","WDBadge(label: Text(verbatim: \"3\"))",[]],
  ["WDBadge.variant","WDBadge","variant","WDBadge.init(label:variant:)","label/variant","WDBadge(label: label, variant: .shared)",[]],
  ["WDBadge.value","WDBadge","value","WDBadge.init(value:)","value","WDBadge(value: .count(3))",[]],
  ["WDDivider.main","WDDivider","divider","WDDivider.init()","no arguments","WDDivider()",[]],
  ["WDDivider.style","WDDivider","style","WDDivider.init(style:)","style","WDDivider(style: .inset)",[]],
  ["WDIcon.main","WDIcon","icon","WDIcon.init(icon:size:)","icon/size","WDIcon(icon: .calendar, size: .md)",[]],
  ["WDIconButton.main","WDIconButton","icon","WDIconButton.init(icon:accessibilityLabel:variant:size:isLoading:action:)","icon/accessibilityLabel/variant/size/isLoading/action","WDIconButton(icon: .more, accessibilityLabel: label) {}",["accessibilityLabel is required."]],
  ["WDIconButton.shape","WDIconButton","shape","WDIconButton.init(icon:accessibilityLabel:variant:size:shape:isLoading:action:)","icon/accessibilityLabel/variant/size/shape/isLoading/action","WDIconButton(icon: .more, accessibilityLabel: label, shape: .circle) {}",[]],
  ["WDProgressBar.value","WDProgressBar","value","WDProgressBar.init(value:label:valueText:)","value/label/valueText","WDProgressBar(value: 0.6, label: label, valueText: valueText)",[]],
  ["WDProgressBar.segments","WDProgressBar","segments","WDProgressBar.init(segments:completed:label:valueText:)","segments/completed/label/valueText","WDProgressBar(segments: 5, completed: 3, label: label)",[]],
  ["WDProgressRing.main","WDProgressRing","value","WDProgressRing.init(value:size:label:valueText:)","value/size/label/valueText","WDProgressRing(value: 0.8, size: .standard)",[]],
  ["WDSearchField.main","WDSearchField","text","WDSearchField.init(text:placeholder:leadingIcon:clearAccessibilityLabel:onSubmit:resultCount:announcer:)","text/placeholder/leadingIcon/clearAccessibilityLabel/onSubmit","WDSearchField(text: $query, placeholder: Text(verbatim: \"Search\"), clearAccessibilityLabel: clearLabel)",[]],
  ["WDSearchField.cancel","WDSearchField","onCancel","WDSearchField.init(text:placeholder:leadingIcon:clearAccessibilityLabel:cancelLabel:onCancel:onSubmit:resultCount:announcer:)","text/placeholder/leadingIcon/clearAccessibilityLabel/cancelLabel/onCancel/onSubmit","WDSearchField(text: $query, placeholder: placeholder, clearAccessibilityLabel: clearLabel, cancelLabel: cancelLabel, onCancel: { dismiss() })",[]],
  ["WDTabBar.main","WDTabBar","selection","WDTabBar.init(items:selection:)","items/selection","WDTabBar(items: items, selection: $current)",[]],
  ["WDToolbar.main","WDToolbar","items","WDToolbar.init(items:accessibilityLabel:overflowAccessibilityLabel:showsTooltips:)","items/accessibilityLabel/overflowAccessibilityLabel/showsTooltips","WDToolbar(items: items, accessibilityLabel: label)",[]],
  ["WDNavigationBar.main","WDNavigationBar","title","WDNavigationBar.init(title:mode:style:backAccessibilityLabel:onBack:actions:followsScroll:)","title/mode/style/backAccessibilityLabel/onBack/actions","WDNavigationBar(title: Text(verbatim: \"Tasks\"), onBack: { dismiss() })",[]],
  ["WDPicker.main","WDPicker","selection","WDPicker.init(selection:label:options:placeholder:style:)","selection/label/options/placeholder/style","WDPicker(selection: $choice, label: label, options: options)",[]],
  ["WDDatePicker.main","WDDatePicker","date","WDDatePicker.init(date:label:mode:placeholder:quickOptions:in:)","date/label/mode/placeholder/quickOptions/bounds","WDDatePicker(date: $date, label: label, mode: .date)",[]],
  ["WDAvatarStack.main","WDAvatarStack","items","WDAvatarStack.init(items:accessibilityLabel:size:)","items/accessibilityLabel/size","WDAvatarStack(items: items, accessibilityLabel: label)",[]],
  ["WDAvatarStack.overflow","WDAvatarStack","onOverflowTap","WDAvatarStack.init(items:accessibilityLabel:size:onOverflowTap:)","items/accessibilityLabel/size/onOverflowTap","WDAvatarStack(items: items, accessibilityLabel: label, size: .md, onOverflowTap: { showAll() })",[]],
  ["WDBottomSheet.detents","WDBottomSheet","detents","WDBottomSheetDetents","enum all / fixed(_:)","WDBottomSheetDetents.all",["Presented through View.wdSheet, not a standalone view."]],
  ["WDBottomSheet.detent","WDBottomSheet","initialDetent","WDBottomSheetDetent","enum half / large","WDBottomSheetDetent.half",[]],
  ["View.wdSheet","WDBottomSheet","presented","View.wdSheet(isPresented:detents:initialDetent:interactiveDismissDisabled:title:closeButtonAccessibilityLabel:onCloseButtonTap:onDismiss:content:footer:)","isPresented/detents/initialDetent/interactiveDismissDisabled/title/closeButtonAccessibilityLabel/onCloseButtonTap/onDismiss/@ViewBuilder content/@ViewBuilder footer","view.wdSheet(isPresented: $showing) { sheetContent }",["Modifier on the anchor view; there is no WDBottomSheet view."]],
  ["View.wdAlert","WDAlert","presented","View.wdAlert(isPresented:title:message:actions:onDismiss:)","isPresented/title/message/actions/onDismiss","view.wdAlert(isPresented: $showing, title: title, message: message, actions: actions)",["Content overload also exists."]],
  ["View.wdActionSheet","WDActionSheet","presented","View.wdActionSheet(isPresented:title:message:items:onSelect:onCancel:)","isPresented/title/message/items/onSelect/onCancel","view.wdActionSheet(isPresented: $showing, items: items, onSelect: { item in })",[]],
  ["View.wdToast","WDToast","presented","View.wdToast(isPresented:variant:message:action:durationMilliseconds:onDismiss:)","isPresented/variant/message/action/durationMilliseconds/onDismiss","view.wdToast(isPresented: $showing, variant: .success, message: message)",[]],
];

function sha256(filePath) {
  return crypto.createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
}

function compareCodePoints(a, b) {
  const left = Array.from(a);
  const right = Array.from(b);
  const length = Math.min(left.length, right.length);
  for (let index = 0; index < length; index += 1) {
    const leftCode = left[index].codePointAt(0);
    const rightCode = right[index].codePointAt(0);
    if (leftCode !== rightCode) return leftCode - rightCode;
  }
  return left.length - right.length;
}

function usage() {
  return "usage: generate_api_cards.js [-h] [--api API] [--out OUT]";
}

function printHelp() {
  console.log(usage());
  console.log("");
  console.log("Generate the 33 iOS API cards from the pinned public API snapshot.");
  console.log("");
  console.log("options:");
  console.log("  -h, --help  show this help message and exit");
  console.log("  --api API   public symbol snapshot (default: api/WisdomUI.api.json)");
  console.log("  --out OUT   output directory (default: ai/skill-provider/api-cards)");
}

function parseArgs(argv) {
  let api = API;
  let out = OUT;
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === "-h" || argument === "--help") {
      printHelp();
      process.exit(0);
    } else if (argument === "--api") {
      if (index + 1 >= argv.length) {
        console.error(usage());
        console.error("generate_api_cards.js: error: argument --api: expected one argument");
        process.exit(2);
      }
      api = argv[index + 1];
      index += 1;
    } else if (argument.startsWith("--api=")) {
      api = argument.slice("--api=".length);
    } else if (argument === "--out") {
      if (index + 1 >= argv.length) {
        console.error(usage());
        console.error("generate_api_cards.js: error: argument --out: expected one argument");
        process.exit(2);
      }
      out = argv[index + 1];
      index += 1;
    } else if (argument.startsWith("--out=")) {
      out = argument.slice("--out=".length);
    } else {
      console.error(usage());
      console.error("generate_api_cards.js: error: unrecognized arguments: " + argument);
      process.exit(2);
    }
  }
  return {api, out};
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const apiPath = path.resolve(process.cwd(), args.api);
  const outDir = path.resolve(process.cwd(), args.out);
  const apiSha = sha256(apiPath);
  const iconSha = sha256(path.join(ROOT, "Sources", "WisdomUI", "Foundation", "generated", "WDIconName.swift"));
  if (apiSha !== EXPECTED_API_SHA || iconSha !== EXPECTED_ICON_SHA) {
    console.error("public snapshot drift: api=" + apiSha + " icon=" + iconSha
      + "; regenerate from the baseline snapshot (see ai/skill-provider/SNAPSHOT.md)");
    process.exit(1);
  }
  const payload = JSON.parse(fs.readFileSync(apiPath, "utf8"));
  const byPath = new Map();
  for (const item of payload.symbols) {
    if (!byPath.has(item.path)) byPath.set(item.path, []);
    byPath.get(item.path).push(item);
  }
  const missing = CARD_SPECS.filter((spec) => !byPath.has(spec[3])).map((spec) => spec[3]);
  if (missing.length > 0) {
    console.error("missing public symbols: " + missing.join(", "));
    process.exit(1);
  }
  fs.mkdirSync(outDir, {recursive: true});
  const names = [];
  for (const [name, component, canonical, symbolPath, label, call, limits] of CARD_SPECS) {
    const found = byPath.get(symbolPath);
    const publicDecls = found.filter((item) => item.access === "public").map((item) => item.decl);
    const decls = publicDecls.length > 0 ? publicDecls : found.map((item) => item.decl);
    const card = {
      schemaVersion: "1.0",
      platform: "ios",
      component,
      canonicalParam: canonical,
      symbol: symbolPath,
      signature: decls.join(" | "),
      // iosLabel used to be a custom property; api-card.schema.json has
      // additionalProperties:false, so the label mapping lives in the
      // allowed limitations array and the exact labels stay in signature.
      callShape: call,
      evidence: "discovered",
      sourceRefs: ["api/WisdomUI.api.json#" + symbolPath, SOURCE_REF_SNAPSHOT],
      limitations: ["Public symbol graph only; overloads and associated types preserved verbatim."]
        .concat(["iOS label mapping: " + label])
        .concat(limits),
    };
    fs.writeFileSync(path.join(outDir, name + ".json"), JSON.stringify(card, null, 2) + "\n", "utf8");
    names.push(name + ".json");
  }
  const index = {
    schemaVersion: "1.0",
    platform: "ios",
    evidenceMinimum: "discovered",
    cards: names.slice().sort(compareCodePoints),
  };
  fs.writeFileSync(path.join(outDir, "index.json"), JSON.stringify(index, null, 2) + "\n", "utf8");
  console.log("wrote " + names.length + " API cards to " + path.normalize(args.out)
    + " (api sha256=" + apiSha + ")");
}

main();