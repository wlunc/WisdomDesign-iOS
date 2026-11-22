#!/usr/bin/env python3
"""Validate the iOS Provider artifacts against the M0 schemas and recompute status.

Checks:
  1. provider.json / capabilities.json / every api-card against the frozen M0
     JSON Schemas (required keys, additionalProperties:false, types, enums,
     lengths/patterns, array limits, oneOf, if/then).
  2. index.json == card files on disk, no duplicates, exact count.
  3. Card symbol/signature traceability to api/WisdomUI.api.json and every
     sourceRef/evidenceRef resolves (JSON pointer or command id).
  4. Recompute status.effective from card/capability/verification evidence and
     require provider.json (effective, declared, computedAtBuild) to match.
  5. Snapshot provenance: baseline commit/hash, stale declaration vs current API.
  6. API-card coverage declaration (10/37 catalog components + 5 Foundation entry points).
  7. verification command reproducibility metadata (cwd, typecheck paths) and
     CI exemption registration.

Stdlib only; exits 0 on success, 1 on the first failed requirement.
"""
from __future__ import annotations
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]              # iOS repo root
PROVIDER = ROOT / "ai/skill-provider"
WORKSPACE = ROOT.parent
CONTRACT = WORKSPACE / "wisdomdesign/ai/skill/provider"
API = ROOT / "api/WisdomUI.api.json"
BASELINE = WORKSPACE / "wisdomdesign/ai/skill/m0/baseline.json"
CATALOG = WORKSPACE / "wisdomdesign/ai/skill/core/catalog/manifest.json"

EVIDENCE_ORDER = ["contract-only", "discovered", "example-compiled", "template-verified"]
EVIDENCE_RANK = {name: rank for rank, name in enumerate(EVIDENCE_ORDER)}
STATUSES = {"spec-only", "experimental", "verified", "unsupported", "incompatible"}
GROUPS = {"runtime", "navigation", "layout", "typography", "input", "accessibility", "rendering", "verification"}
COMMAND_STATUSES = {"passed", "failed", "not-run", "blocked"}
REQUIRED_COMMANDS = {
    "ios-consumer-xcodebuild-release",
    "ios-minimal-typecheck",
    "ios-scaffold-safety",
    "ios-library-gate",
    "ios-ui-matrix",
}


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fail(message: str) -> None:
    print("FAIL: " + message, file=sys.stderr)
    raise SystemExit(1)


def require(condition, message: str) -> None:
    if not condition:
        fail(message)


# ---------------------------------------------------------------------------
# Minimal JSON-Schema subset validator (covers the keywords used by M0 schemas)
# ---------------------------------------------------------------------------
def _type_ok(value, expected: str) -> bool:
    if expected == "object":
        return isinstance(value, dict)
    if expected == "array":
        return isinstance(value, list)
    if expected == "string":
        return isinstance(value, str)
    if expected == "boolean":
        return isinstance(value, bool)
    if expected == "number":
        return isinstance(value, (int, float)) and not isinstance(value, bool)
    if expected == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if expected == "null":
        return value is None
    return True


def _canonical(value) -> str:
    return json.dumps(value, sort_keys=True, ensure_ascii=False)


def schema_errors(schema, value, path: str = "$") -> list[dict]:
    errors: list[dict] = []
    if not isinstance(schema, dict):
        return errors

    expected = schema.get("type")
    if expected is not None:
        expected_types = expected if isinstance(expected, list) else [expected]
        if not any(_type_ok(value, t) for t in expected_types):
            return [{"path": path, "message": "expected type %r, got %r" % (expected, type(value).__name__)}]

    if "const" in schema and value != schema["const"]:
        errors.append({"path": path, "message": "must equal const %r" % (schema["const"],)})
    if "enum" in schema and value not in schema["enum"]:
        errors.append({"path": path, "message": "must be one of %r" % (schema["enum"],)})

    if isinstance(value, str):
        if "minLength" in schema and len(value) < schema["minLength"]:
            errors.append({"path": path, "message": "shorter than minLength %d" % schema["minLength"]})
        if "maxLength" in schema and len(value) > schema["maxLength"]:
            errors.append({"path": path, "message": "longer than maxLength %d" % schema["maxLength"]})
        if "pattern" in schema and not re.search(schema["pattern"], value):
            errors.append({"path": path, "message": "does not match pattern %r" % schema["pattern"]})

    if isinstance(value, list):
        if "minItems" in schema and len(value) < schema["minItems"]:
            errors.append({"path": path, "message": "fewer than minItems %d" % schema["minItems"]})
        if "maxItems" in schema and len(value) > schema["maxItems"]:
            errors.append({"path": path, "message": "more than maxItems %d" % schema["maxItems"]})
        if schema.get("uniqueItems") and len({_canonical(v) for v in value}) != len(value):
            errors.append({"path": path, "message": "items are not unique"})
        if "items" in schema:
            for index, item in enumerate(value):
                errors.extend(schema_errors(schema["items"], item, "%s[%d]" % (path, index)))

    if isinstance(value, dict):
        properties = schema.get("properties", {})
        for key in schema.get("required", []):
            if key not in value:
                errors.append({"path": path, "message": "missing required property %r" % key})
        additional = schema.get("additionalProperties", True)
        for key, item in value.items():
            child_path = "%s.%s" % (path, key)
            if key in properties:
                errors.extend(schema_errors(properties[key], item, child_path))
            elif additional is False:
                errors.append({"path": path, "message": "unknown property %r" % key})
            elif isinstance(additional, dict):
                errors.extend(schema_errors(additional, item, child_path))

    if "oneOf" in schema:
        matches = [sub for sub in schema["oneOf"] if not schema_errors(sub, value, path)]
        if len(matches) != 1:
            errors.append({"path": path, "message": "oneOf matched %d schemas" % len(matches)})
    if "anyOf" in schema:
        if not any(not schema_errors(sub, value, path) for sub in schema["anyOf"]):
            errors.append({"path": path, "message": "anyOf matched no schema"})
    for sub in schema.get("allOf", []):
        if "if" in sub:
            if not schema_errors(sub["if"], value, path) and "then" in sub:
                errors.extend(schema_errors(sub["then"], value, path))
        else:
            errors.extend(schema_errors(sub, value, path))
    if "if" in schema:
        if not schema_errors(schema["if"], value, path) and "then" in schema:
            errors.extend(schema_errors(schema["then"], value, path))
    return errors


def validate_schema(schema: dict, document, label: str) -> None:
    errors = schema_errors(schema, document)
    if errors:
        details = "; ".join("%s: %s" % (item["path"], item["message"]) for item in errors[:8])
        if len(errors) > 8:
            details += "; ... (%d more)" % (len(errors) - 8)
        fail("%s schema: %s" % (label, details))


# ---------------------------------------------------------------------------
# Reference resolution
# ---------------------------------------------------------------------------
MISSING = object()


def json_pointer(document, pointer: str):
    if pointer in ("", "/"):
        return document
    current = document
    for raw in pointer.lstrip("/").split("/"):
        token = raw.replace("~1", "/").replace("~0", "~")
        if isinstance(current, dict) and token in current:
            current = current[token]
        elif isinstance(current, list) and token.isdigit() and int(token) < len(current):
            current = current[int(token)]
        else:
            return MISSING
    return current


def resolve_file(file_part: str) -> Path | None:
    for candidate in (ROOT / file_part, WORKSPACE / file_part):
        if candidate.exists():
            return candidate
    return None


def check_ref(ref: str, command_ids: set[str], symbols: dict, api_payload: dict, label: str) -> None:
    require(isinstance(ref, str) and ref, label + ": empty ref")
    file_part, sep, fragment = ref.partition("#")
    path = resolve_file(file_part)
    require(path is not None, label + ": referenced file does not exist: " + file_part)
    if "verification.json" in file_part and fragment:
        require(fragment in command_ids, label + ": verification ref is not a command id: " + fragment)
    elif fragment.startswith("/") or file_part.endswith("SOURCES.json"):
        require(json_pointer(load_json(path), fragment) is not MISSING,
                label + ": JSON pointer does not resolve: " + ref)
    elif file_part.endswith("api/WisdomUI.api.json") and fragment:
        require(fragment in symbols or fragment in api_payload,
                label + ": api fragment is neither a symbol nor a top-level key: " + fragment)


# ---------------------------------------------------------------------------
# Status derivation
# ---------------------------------------------------------------------------
def derive_effective_status(cards: list, capabilities: dict, verification: dict) -> str:
    commands = verification.get("commands", [])
    statuses = {item.get("id"): item.get("status") for item in commands}
    all_passed = bool(statuses) and all(status == "passed" for status in statuses.values())
    card_rank = max((EVIDENCE_RANK[card["evidence"]] for card in cards), default=-1)
    capability_rank = max((EVIDENCE_RANK[group.get("evidence", "contract-only")]
                           for group in capabilities["groups"].values()), default=-1)
    matrix = verification.get("runtimeMatrix", {})
    matrix_clear = all(value not in ("blocked-sandbox-pseudo-terminal", "not-run") for value in matrix.values()) if matrix else True
    unverified = verification.get("unverified", [])

    # M0 status policy: verified requires template-verified evidence + the full
    # runtime matrix + no unverified items; static checks alone never qualify.
    if all_passed and matrix_clear and not unverified and card_rank >= EVIDENCE_RANK["template-verified"]:
        return "verified"
    has_public_evidence = bool(cards) or any(
        group.get("status") in ("supported", "partial") for group in capabilities["groups"].values()
    )
    has_compile_evidence = (
        any(status == "passed" for status in statuses.values())
        or card_rank >= EVIDENCE_RANK["example-compiled"]
        or capability_rank >= EVIDENCE_RANK["example-compiled"]
    )
    if has_public_evidence and (card_rank >= EVIDENCE_RANK["discovered"] or has_compile_evidence):
        return "experimental"
    return "spec-only"


# ---------------------------------------------------------------------------
def main() -> None:
    provider = load_json(PROVIDER / "provider.json")
    capabilities = load_json(PROVIDER / "capabilities.json")
    index = load_json(PROVIDER / "api-cards/index.json")
    verification = load_json(PROVIDER / "verification.json")
    sources = load_json(PROVIDER / "api-cards/SOURCES.json")
    baseline = load_json(BASELINE)
    catalog = load_json(CATALOG)
    api_payload = load_json(API)
    api_symbols: dict[str, list] = {}
    for symbol in api_payload["symbols"]:
        api_symbols.setdefault(symbol["path"], []).append(symbol)

    provider_schema = load_json(CONTRACT / "provider.schema.json")
    capabilities_schema = load_json(CONTRACT / "capabilities.schema.json")
    card_schema = load_json(CONTRACT / "api-card.schema.json")

    # 1. Schema conformance (catches custom properties such as the removed iosLabel).
    validate_schema(provider_schema, provider, "provider.json")
    validate_schema(capabilities_schema, capabilities, "capabilities.json")

    # 2. Index/file equality and exact card count.
    require(index.get("schemaVersion") == "1.0" and index.get("platform") == "ios", "index header")
    require(index.get("evidenceMinimum") in EVIDENCE_RANK, "index evidenceMinimum")
    listed = index.get("cards")
    require(isinstance(listed, list) and listed, "index cards must be a non-empty list")
    require(len(set(listed)) == len(listed), "index cards contain duplicates")
    disk = sorted(path.name for path in (PROVIDER / "api-cards").glob("*.json")
                  if path.name not in ("index.json", "SOURCES.json"))
    require(sorted(listed) == disk, "index cards != card files on disk")
    require(listed == sorted(listed), "index cards must be sorted")

    # 3. Per-card schema, traceability and references.
    command_ids = {item.get("id") for item in verification.get("commands", [])}
    card_components = set()
    for filename in listed:
        card = load_json(PROVIDER / "api-cards" / filename)
        validate_schema(card_schema, card, filename)
        require(card["platform"] == "ios" and card["schemaVersion"] == "1.0", filename + ": header")
        require(card["evidence"] in EVIDENCE_RANK, filename + ": evidence")
        require(bool(card.get("canonicalParam")), filename + ": canonicalParam missing")
        require(card["symbol"] in api_symbols, filename + ": missing public symbol")
        require(any(item.get("access") == "public" for item in api_symbols[card["symbol"]]),
                filename + ": symbol is not public")
        for declaration in card["signature"].split(" | "):
            require(any(declaration == item["decl"] for item in api_symbols[card["symbol"]]),
                    filename + ": signature drift")
        # iOS labels must live in an allowed field; keep the migration explicit.
        require(any(str(note).startswith("iOS label mapping: ") for note in card.get("limitations", [])),
                filename + ": missing allowed-field iOS label mapping")
        for ref in card["sourceRefs"]:
            check_ref(ref, command_ids, api_symbols, api_payload, filename)
        card_components.add(card["component"])

    # 4. Provider / capabilities evidence references resolve.
    for ref in provider["status"].get("evidenceRefs", []):
        check_ref(ref, command_ids, api_symbols, api_payload, "provider.status.evidenceRefs")
    for group_name, group in capabilities["groups"].items():
        for ref in group.get("sourceRefs", []):
            check_ref(ref, command_ids, api_symbols, api_payload, "capabilities." + group_name)

    # 5. Status metadata and evidence-based recomputation.
    require(provider["status"]["effective"] in STATUSES, "provider.status.effective enum")
    require(provider["status"]["declared"] in STATUSES, "provider.status.declared enum")
    require(provider["status"].get("computedAtBuild") is True, "provider.status.computedAtBuild must be true")
    derived = derive_effective_status([load_json(PROVIDER / "api-cards" / name) for name in listed],
                                      capabilities, verification)
    require(provider["status"]["effective"] == derived,
            "provider.status.effective (%s) != recomputed (%s)" % (provider["status"]["effective"], derived))
    require(provider["status"]["declared"] == derived,
            "provider.status.declared (%s) != recomputed (%s)" % (provider["status"]["declared"], derived))
    computation = verification.get("statusComputation", {})
    require(computation.get("derivedEffective") == derived,
            "verification.statusComputation.derivedEffective != recomputed status")
    require("validate_provider.py" in str(computation.get("computedBy", "")),
            "verification.statusComputation.computedBy must name validate_provider.py")
    require(computation.get("computedAt"), "verification.statusComputation.computedAt missing")
    require(verification.get("ciIntegration", {}).get("status") == "exempt-registered",
            "verification.ciIntegration.status must be exempt-registered")
    require(verification.get("ciIntegration", {}).get("validator", "").endswith("validate_provider.py"),
            "verification.ciIntegration.validator must point at validate_provider.py")

    # 6. Snapshot provenance: baseline pin, current API hash and stale declaration.
    ios_baseline = baseline["repositories"]["ios"]
    require(provider["source"]["commit"] == ios_baseline["commit"], "provider source commit != M0 baseline")
    require(provider["source"]["dirty"] is True, "provider source must declare the dirty baseline")
    require(set(provider["source"].get("dirtyFiles", [])) == set(ios_baseline["dirtyFiles"]),
            "provider source dirtyFiles drift")
    require(provider["source"]["contentHash"] == ios_baseline.get("trackedContentHash"),
            "provider source contentHash != baseline trackedContentHash")
    snapshot = verification.get("snapshot", {})
    require(snapshot.get("baselineCommit") == ios_baseline["commit"], "verification.snapshot.baselineCommit mismatch")
    require(snapshot.get("baselineApiSnapshotSha256") == sources["baseline"]["apiSnapshotSha256"],
            "verification.snapshot baseline API hash != SOURCES.json baseline")
    current_api_sha = sha256(API)
    require(snapshot.get("currentApiSnapshotSha256") == current_api_sha,
            "verification.snapshot.currentApiSnapshotSha256 != actual api file hash")
    if current_api_sha == snapshot.get("baselineApiSnapshotSha256"):
        require(snapshot.get("status") == "current", "snapshot status must be current when hashes match")
    else:
        require(snapshot.get("status") == "stale",
                "snapshot status must be stale when current API hash differs from baseline")
        require(snapshot.get("currentRepoHead"), "stale snapshot must record currentRepoHead")
        require(snapshot.get("replayExitCode") == 0, "stale snapshot must record replayExitCode=0")
    generator_source = (PROVIDER / "api-cards/generate_api_cards.py").read_text(encoding="utf-8")
    pin = re.search(r'EXPECTED_API_SHA = "([0-9a-f]{64})"', generator_source)
    require(pin is not None and pin.group(1) == sources["baseline"]["apiSnapshotSha256"],
            "generator EXPECTED_API_SHA != SOURCES.json baseline hash")
    require(sources["baseline"].get("stale") is True and sources["baseline"].get("currentRepoHead"),
            "SOURCES.json baseline must declare stale + currentRepoHead")

    # 7. Coverage declaration (10/37 catalog components + 5 Foundation entry points).
    catalog_ids = [component["id"] for component in catalog["components"]]
    covered = sorted(card_components & set(catalog_ids))
    coverage = verification.get("apiCardCoverage", {})
    require(coverage.get("cards") == len(listed), "apiCardCoverage.cards != index count")
    require(coverage.get("catalogComponentsTotal") == len(catalog_ids), "apiCardCoverage.catalogComponentsTotal mismatch")
    require(coverage.get("catalogComponentsWithCards") == len(covered), "apiCardCoverage.withCards count mismatch")
    require(set(coverage.get("withCards", [])) == set(covered), "apiCardCoverage.withCards set mismatch")
    require(set(coverage.get("withoutCards", [])) == set(catalog_ids) - set(covered),
            "apiCardCoverage.withoutCards set mismatch")
    require(coverage.get("foundationEntryPoints") == len(card_components - set(catalog_ids)),
            "apiCardCoverage.foundationEntryPoints mismatch")
    component_coverage = capabilities.get("componentCoverage", {})
    require(set(component_coverage.get("experimental", [])) == set(covered),
            "capabilities.componentCoverage.experimental != components with cards")
    require(not component_coverage.get("verified") and not component_coverage.get("unsupported"),
            "capabilities.componentCoverage verified/unsupported must be empty for this slice")

    # 8. Verification command metadata and reproducibility (F3).
    commands = verification.get("commands", [])
    by_id = {item.get("id"): item for item in commands}
    require(set(by_id) == REQUIRED_COMMANDS, "verification commands must be exactly: " + ", ".join(sorted(REQUIRED_COMMANDS)))
    for command_id, item in by_id.items():
        require(item.get("status") in COMMAND_STATUSES, command_id + ": invalid status")
        require(item.get("cwd") in (".", "iOS"), command_id + ": cwd must be recorded as '.' or 'iOS'")
        require(isinstance(item.get("command"), str) and item["command"], command_id + ": command missing")
    typecheck = by_id["ios-minimal-typecheck"]
    require(typecheck["cwd"] == ".", "ios-minimal-typecheck must be recorded with cwd='.'")
    for token in (
        "iOS/AIStarter/AIStarter/AIStarterApp.swift",
        "iOS/AIStarter/AIStarter/ContentView.swift",
        "iOS/AIStarter/AIStarter/APIMinimalExample.swift",
        "iOS/AIStarter/AIStarter/TaskListView.swift",
        "-I iOS/.build/dd-ai-starter-rel/Build/Products/Release-iphonesimulator",
        "-module-cache-path iOS/.build/module-cache",
    ):
        require(token in typecheck["command"], "ios-minimal-typecheck command missing token: " + token)
    require(by_id["ios-ui-matrix"]["status"] == "blocked" and by_id["ios-ui-matrix"].get("exitCode") == 65,
            "ios-ui-matrix must stay blocked with the observed exit 65")
    require(verification.get("runtimeMatrix", {}).get("loading") == "blocked-sandbox-pseudo-terminal",
            "runtimeMatrix loading must stay blocked")
    require(any(item.get("status") == "not-run" for item in commands),
            "verification must preserve at least one not-run command")
    require(any(item.get("status") == "passed" for item in commands),
            "verification must contain at least one passed command")

    # 9. UI-test target configuration and final matrix report (F5/F7).
    ui_target = verification.get("uiMatrixTarget", {})
    require(ui_target.get("productType") == "com.apple.product-type.bundle.ui-testing",
            "verification.uiMatrixTarget.productType must be bundle.ui-testing")
    require(ui_target.get("testTargetName") == "AIStarter", "verification.uiMatrixTarget.testTargetName")
    pbxproj = (ROOT / "AIStarter/AIStarter.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
    require('productType = "com.apple.product-type.bundle.ui-testing";' in pbxproj,
            "GoldenPageMatrixTests must be a bundle.ui-testing target")
    require("TEST_TARGET_NAME = AIStarter;" in pbxproj, "GoldenPageMatrixTests must set TEST_TARGET_NAME")
    require("PBXTargetDependency" in pbxproj and "2A00000000000000000000E1" in pbxproj,
            "GoldenPageMatrixTests must depend on the AIStarter app target")
    matrix_report = load_json(ROOT / "AIStarter/GoldenPageMatrixReport.json")
    final_attempts = [attempt for attempt in matrix_report.get("attempts", []) if attempt.get("status") == "blocked"]
    require(bool(final_attempts), "GoldenPageMatrixReport.json must record the blocked final attempt")
    require(any("Pseudo Terminal" in attempt.get("reason", "") for attempt in final_attempts),
            "blocked attempt must record the Pseudo Terminal blocker")
    require(any(attempt.get("simulator", {}).get("udid") == "CE28D919-7BEB-46B2-86A7-1D063E54303F"
                for attempt in final_attempts),
            "blocked attempt must record the final simulator UDID")

    print("M2 iOS provider validation passed: %d cards, recomputed status=%s, snapshot=%s, coverage=%d/%d" % (
        len(listed), derived, snapshot.get("status"), len(covered), len(catalog_ids)))


if __name__ == "__main__":
    main()
