#!/usr/bin/env node
/**
 * Validate the iOS Provider artifacts against the M0 schemas and recompute status.
 *
 * Checks:
 *   1. provider.json / capabilities.json / every api-card against the frozen M0
 *      JSON Schemas (required keys, additionalProperties:false, types, enums,
 *      lengths/patterns, array limits, oneOf, if/then).
 *   2. index.json == card files on disk, no duplicates, exact count.
 *   3. Card symbol/signature traceability to api/WisdomUI.api.json and every
 *      sourceRef/evidenceRef resolves (JSON pointer or command id).
 *   4. Recompute status.effective from card/capability/verification evidence and
 *      require provider.json (effective, declared, computedAtBuild) to match.
 *   5. Snapshot provenance: baseline commit/hash, stale declaration vs current API.
 *   6. API-card coverage declaration (10/37 catalog components + 5 Foundation entry points).
 *   7. verification command reproducibility metadata (cwd, typecheck paths) and
 *      CI exemption registration.
 *
 * Stdlib only; exits 0 on success, 1 on the first failed requirement.
 */
"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const ROOT = path.resolve(path.dirname(fs.realpathSync(__filename)), "..", ".."); // iOS repo root
const PROVIDER = path.join(ROOT, "ai", "skill-provider");
const WORKSPACE = path.dirname(ROOT);
const CONTRACT = path.join(WORKSPACE, "wisdomdesign", "ai", "skill", "provider");
const API = path.join(ROOT, "api", "WisdomUI.api.json");
const BASELINE = path.join(WORKSPACE, "wisdomdesign", "ai", "skill", "m0", "baseline.json");
const CATALOG = path.join(WORKSPACE, "wisdomdesign", "ai", "skill", "core", "catalog", "manifest.json");

const EVIDENCE_ORDER = ["contract-only", "discovered", "example-compiled", "template-verified"];
const EVIDENCE_RANK = Object.fromEntries(EVIDENCE_ORDER.map((name, rank) => [name, rank]));
const STATUSES = new Set(["spec-only", "experimental", "verified", "unsupported", "incompatible"]);
const GROUPS = new Set(["runtime", "navigation", "layout", "typography", "input", "accessibility", "rendering", "verification"]);
const COMMAND_STATUSES = new Set(["passed", "failed", "not-run", "blocked"]);
const REQUIRED_COMMANDS = new Set([
  "ios-consumer-xcodebuild-release",
  "ios-minimal-typecheck",
  "ios-scaffold-safety",
  "ios-library-gate",
  "ios-ui-matrix",
]);

function loadJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function sha256(filePath) {
  return crypto.createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
}

function fail(message) {
  console.error("FAIL: " + message);
  process.exit(1);
}

function requireCondition(condition, message) {
  if (!condition) {
    fail(message);
  }
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function typeName(value) {
  if (value === null) return "NoneType";
  if (Array.isArray(value)) return "list";
  switch (typeof value) {
    case "object":
      return "dict";
    case "string":
      return "str";
    case "boolean":
      return "bool";
    case "number":
      return Number.isInteger(value) ? "int" : "float";
    default:
      return typeof value;
  }
}

function pyRepr(value) {
  if (value === null) return "None";
  if (typeof value === "string") {
    return "'" + value.replace(/\\/g, "\\\\").replace(/'/g, "\\'") + "'";
  }
  if (typeof value === "boolean") return value ? "True" : "False";
  if (Array.isArray(value)) return "[" + value.map(pyRepr).join(", ") + "]";
  if (isPlainObject(value)) {
    return "{" + Object.entries(value).map(([key, item]) => pyRepr(key) + ": " + pyRepr(item)).join(", ") + "}";
  }
  return String(value);
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

function sortedCopy(values) {
  return values.slice().sort(compareCodePoints);
}

function arraysEqual(left, right) {
  return left.length === right.length && left.every((value, index) => value === right[index]);
}

function setsEqual(left, right) {
  const leftSet = new Set(left);
  const rightSet = new Set(right);
  if (leftSet.size !== rightSet.size) return false;
  return [...rightSet].every((value) => leftSet.has(value));
}

function canonical(value) {
  if (Array.isArray(value)) {
    return "[" + value.map(canonical).join(", ") + "]";
  }
  if (isPlainObject(value)) {
    return "{" + Object.keys(value).sort(compareCodePoints)
      .map((key) => JSON.stringify(key) + ": " + canonical(value[key])).join(", ") + "}";
  }
  return JSON.stringify(value);
}

function deepEqual(left, right) {
  return canonical(left) === canonical(right);
}

// ---------------------------------------------------------------------------
// Minimal JSON-Schema subset validator (covers the keywords used by M0 schemas)
// ---------------------------------------------------------------------------
function typeOk(value, expected) {
  switch (expected) {
    case "object":
      return isPlainObject(value);
    case "array":
      return Array.isArray(value);
    case "string":
      return typeof value === "string";
    case "boolean":
      return typeof value === "boolean";
    case "number":
      return typeof value === "number" && !Number.isNaN(value);
    case "integer":
      return typeof value === "number" && Number.isInteger(value);
    case "null":
      return value === null;
    default:
      return true;
  }
}

function schemaErrors(schema, value, instancePath = "$") {
  const errors = [];
  if (!isPlainObject(schema)) return errors;

  const expected = schema.type;
  if (expected !== undefined) {
    const expectedTypes = Array.isArray(expected) ? expected : [expected];
    if (!expectedTypes.some((type) => typeOk(value, type))) {
      return [{
        path: instancePath,
        message: "expected type " + pyRepr(expected) + ", got '" + typeName(value) + "'",
      }];
    }
  }

  if (Object.hasOwn(schema, "const") && !deepEqual(value, schema.const)) {
    errors.push({ path: instancePath, message: "must equal const " + pyRepr(schema.const) });
  }
  if (Object.hasOwn(schema, "enum") && !schema.enum.some((item) => deepEqual(value, item))) {
    errors.push({ path: instancePath, message: "must be one of " + pyRepr(schema.enum) });
  }

  if (typeof value === "string") {
    if (Object.hasOwn(schema, "minLength") && Array.from(value).length < schema.minLength) {
      errors.push({ path: instancePath, message: "shorter than minLength " + schema.minLength });
    }
    if (Object.hasOwn(schema, "maxLength") && Array.from(value).length > schema.maxLength) {
      errors.push({ path: instancePath, message: "longer than maxLength " + schema.maxLength });
    }
    if (Object.hasOwn(schema, "pattern") && !new RegExp(schema.pattern).test(value)) {
      errors.push({ path: instancePath, message: "does not match pattern " + pyRepr(schema.pattern) });
    }
  }

  if (Array.isArray(value)) {
    if (Object.hasOwn(schema, "minItems") && value.length < schema.minItems) {
      errors.push({ path: instancePath, message: "fewer than minItems " + schema.minItems });
    }
    if (Object.hasOwn(schema, "maxItems") && value.length > schema.maxItems) {
      errors.push({ path: instancePath, message: "more than maxItems " + schema.maxItems });
    }
    if (schema.uniqueItems && new Set(value.map(canonical)).size !== value.length) {
      errors.push({ path: instancePath, message: "items are not unique" });
    }
    if (Object.hasOwn(schema, "items")) {
      value.forEach((item, index) => {
        errors.push(...schemaErrors(schema.items, item, instancePath + "[" + index + "]"));
      });
    }
  }

  if (isPlainObject(value)) {
    const properties = schema.properties ?? {};
    for (const key of schema.required ?? []) {
      if (!Object.hasOwn(value, key)) {
        errors.push({ path: instancePath, message: "missing required property " + pyRepr(key) });
      }
    }
    const additional = Object.hasOwn(schema, "additionalProperties") ? schema.additionalProperties : true;
    for (const [key, item] of Object.entries(value)) {
      const childPath = instancePath + "." + key;
      if (Object.hasOwn(properties, key)) {
        errors.push(...schemaErrors(properties[key], item, childPath));
      } else if (additional === false) {
        errors.push({ path: instancePath, message: "unknown property " + pyRepr(key) });
      } else if (isPlainObject(additional)) {
        errors.push(...schemaErrors(additional, item, childPath));
      }
    }
  }

  if (Array.isArray(schema.oneOf)) {
    const matches = schema.oneOf.filter((sub) => schemaErrors(sub, value, instancePath).length === 0);
    if (matches.length !== 1) {
      errors.push({ path: instancePath, message: "oneOf matched " + matches.length + " schemas" });
    }
  }
  if (Array.isArray(schema.anyOf)) {
    if (!schema.anyOf.some((sub) => schemaErrors(sub, value, instancePath).length === 0)) {
      errors.push({ path: instancePath, message: "anyOf matched no schema" });
    }
  }
  for (const sub of schema.allOf ?? []) {
    if (Object.hasOwn(sub, "if")) {
      if (schemaErrors(sub.if, value, instancePath).length === 0 && Object.hasOwn(sub, "then")) {
        errors.push(...schemaErrors(sub.then, value, instancePath));
      }
    } else {
      errors.push(...schemaErrors(sub, value, instancePath));
    }
  }
  if (Object.hasOwn(schema, "if")) {
    if (schemaErrors(schema.if, value, instancePath).length === 0 && Object.hasOwn(schema, "then")) {
      errors.push(...schemaErrors(schema.then, value, instancePath));
    }
  }
  return errors;
}

function validateSchema(schema, document, label) {
  const errors = schemaErrors(schema, document);
  if (errors.length > 0) {
    let details = errors.slice(0, 8).map((item) => item.path + ": " + item.message).join("; ");
    if (errors.length > 8) {
      details += "; ... (" + (errors.length - 8) + " more)";
    }
    fail(label + " schema: " + details);
  }
}

// ---------------------------------------------------------------------------
// Reference resolution
// ---------------------------------------------------------------------------
const MISSING = Symbol("missing");

function jsonPointer(document, pointer) {
  if (pointer === "" || pointer === "/") return document;
  let current = document;
  for (const raw of pointer.replace(/^\/+/, "").split("/")) {
    const token = raw.replace(/~1/g, "/").replace(/~0/g, "~");
    if (isPlainObject(current) && Object.hasOwn(current, token)) {
      current = current[token];
    } else if (Array.isArray(current) && /^\d+$/.test(token) && Number(token) < current.length) {
      current = current[Number(token)];
    } else {
      return MISSING;
    }
  }
  return current;
}

function resolveFile(filePart) {
  for (const base of [ROOT, WORKSPACE]) {
    const candidate = path.isAbsolute(filePart) ? filePart : path.join(base, filePart);
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

function checkRef(ref, commandIds, symbols, apiPayload, label) {
  requireCondition(typeof ref === "string" && ref.length > 0, label + ": empty ref");
  const hashIndex = ref.indexOf("#");
  const filePart = hashIndex === -1 ? ref : ref.slice(0, hashIndex);
  const fragment = hashIndex === -1 ? "" : ref.slice(hashIndex + 1);
  const resolvedPath = resolveFile(filePart);
  requireCondition(resolvedPath !== null, label + ": referenced file does not exist: " + filePart);
  if (filePart.includes("verification.json") && fragment) {
    requireCondition(commandIds.has(fragment), label + ": verification ref is not a command id: " + fragment);
  } else if (fragment.startsWith("/") || filePart.endsWith("SOURCES.json")) {
    requireCondition(jsonPointer(loadJson(resolvedPath), fragment) !== MISSING,
      label + ": JSON pointer does not resolve: " + ref);
  } else if (filePart.endsWith("api/WisdomUI.api.json") && fragment) {
    requireCondition(symbols.has(fragment) || Object.hasOwn(apiPayload, fragment),
      label + ": api fragment is neither a symbol nor a top-level key: " + fragment);
  }
}

// ---------------------------------------------------------------------------
// Status derivation
// ---------------------------------------------------------------------------
function deriveEffectiveStatus(cards, capabilities, verification) {
  const commands = verification.commands ?? [];
  const statuses = new Map(commands.map((item) => [item.id, item.status]));
  const allPassed = statuses.size > 0 && [...statuses.values()].every((status) => status === "passed");
  const groups = Object.values(capabilities.groups);
  const cardRank = cards.reduce((rank, card) => Math.max(rank, EVIDENCE_RANK[card.evidence]), -1);
  const capabilityRank = groups.reduce(
    (rank, group) => Math.max(rank, EVIDENCE_RANK[group.evidence ?? "contract-only"]),
    -1,
  );
  const matrix = verification.runtimeMatrix ?? {};
  const matrixClear = Object.values(matrix).every(
    (value) => value !== "blocked-sandbox-pseudo-terminal" && value !== "not-run",
  );
  const unverified = verification.unverified ?? [];

  // M0 status policy: verified requires template-verified evidence + the full
  // runtime matrix + no unverified items; static checks alone never qualify.
  if (allPassed && matrixClear && unverified.length === 0
      && cardRank >= EVIDENCE_RANK["template-verified"]) {
    return "verified";
  }
  const hasPublicEvidence = cards.length > 0
    || groups.some((group) => group.status === "supported" || group.status === "partial");
  const hasCompileEvidence = [...statuses.values()].some((status) => status === "passed")
    || cardRank >= EVIDENCE_RANK["example-compiled"]
    || capabilityRank >= EVIDENCE_RANK["example-compiled"];
  if (hasPublicEvidence && (cardRank >= EVIDENCE_RANK["discovered"] || hasCompileEvidence)) {
    return "experimental";
  }
  return "spec-only";
}

// ---------------------------------------------------------------------------
function main() {
  const provider = loadJson(path.join(PROVIDER, "provider.json"));
  const capabilities = loadJson(path.join(PROVIDER, "capabilities.json"));
  const index = loadJson(path.join(PROVIDER, "api-cards", "index.json"));
  const verification = loadJson(path.join(PROVIDER, "verification.json"));
  const sources = loadJson(path.join(PROVIDER, "api-cards", "SOURCES.json"));
  const baseline = loadJson(BASELINE);
  const catalog = loadJson(CATALOG);
  const apiPayload = loadJson(API);
  const apiSymbols = new Map();
  for (const symbol of apiPayload.symbols) {
    if (!apiSymbols.has(symbol.path)) apiSymbols.set(symbol.path, []);
    apiSymbols.get(symbol.path).push(symbol);
  }

  const providerSchema = loadJson(path.join(CONTRACT, "provider.schema.json"));
  const capabilitiesSchema = loadJson(path.join(CONTRACT, "capabilities.schema.json"));
  const cardSchema = loadJson(path.join(CONTRACT, "api-card.schema.json"));

  // 1. Schema conformance (catches custom properties such as the removed iosLabel).
  validateSchema(providerSchema, provider, "provider.json");
  validateSchema(capabilitiesSchema, capabilities, "capabilities.json");

  // 2. Index/file equality and exact card count.
  requireCondition(index.schemaVersion === "1.0" && index.platform === "ios", "index header");
  requireCondition(Object.hasOwn(EVIDENCE_RANK, index.evidenceMinimum), "index evidenceMinimum");
  const listed = index.cards;
  requireCondition(Array.isArray(listed) && listed.length > 0, "index cards must be a non-empty list");
  requireCondition(new Set(listed).size === listed.length, "index cards contain duplicates");
  const disk = sortedCopy(fs.readdirSync(path.join(PROVIDER, "api-cards"))
    .filter((name) => name.endsWith(".json") && name !== "index.json" && name !== "SOURCES.json"));
  requireCondition(arraysEqual(sortedCopy(listed), disk), "index cards != card files on disk");
  requireCondition(arraysEqual(listed, sortedCopy(listed)), "index cards must be sorted");

  // 3. Per-card schema, traceability and references.
  const commandIds = new Set((verification.commands ?? []).map((item) => item.id));
  const cardComponents = new Set();
  for (const filename of listed) {
    const card = loadJson(path.join(PROVIDER, "api-cards", filename));
    validateSchema(cardSchema, card, filename);
    requireCondition(card.platform === "ios" && card.schemaVersion === "1.0", filename + ": header");
    requireCondition(Object.hasOwn(EVIDENCE_RANK, card.evidence), filename + ": evidence");
    requireCondition(Boolean(card.canonicalParam), filename + ": canonicalParam missing");
    requireCondition(apiSymbols.has(card.symbol), filename + ": missing public symbol");
    requireCondition(apiSymbols.get(card.symbol).some((item) => item.access === "public"),
      filename + ": symbol is not public");
    for (const declaration of card.signature.split(" | ")) {
      requireCondition(apiSymbols.get(card.symbol).some((item) => declaration === item.decl),
        filename + ": signature drift");
    }
    // iOS labels must live in an allowed field; keep the migration explicit.
    requireCondition((card.limitations ?? []).some(
      (note) => String(note).startsWith("iOS label mapping: "),
    ), filename + ": missing allowed-field iOS label mapping");
    for (const ref of card.sourceRefs) {
      checkRef(ref, commandIds, apiSymbols, apiPayload, filename);
    }
    cardComponents.add(card.component);
  }

  // 4. Provider / capabilities evidence references resolve.
  for (const ref of provider.status.evidenceRefs ?? []) {
    checkRef(ref, commandIds, apiSymbols, apiPayload, "provider.status.evidenceRefs");
  }
  for (const [groupName, group] of Object.entries(capabilities.groups)) {
    for (const ref of group.sourceRefs ?? []) {
      checkRef(ref, commandIds, apiSymbols, apiPayload, "capabilities." + groupName);
    }
  }

  // 5. Status metadata and evidence-based recomputation.
  requireCondition(STATUSES.has(provider.status.effective), "provider.status.effective enum");
  requireCondition(STATUSES.has(provider.status.declared), "provider.status.declared enum");
  requireCondition(provider.status.computedAtBuild === true, "provider.status.computedAtBuild must be true");
  const derived = deriveEffectiveStatus(
    listed.map((name) => loadJson(path.join(PROVIDER, "api-cards", name))),
    capabilities,
    verification,
  );
  requireCondition(provider.status.effective === derived,
    "provider.status.effective (" + provider.status.effective + ") != recomputed (" + derived + ")");
  requireCondition(provider.status.declared === derived,
    "provider.status.declared (" + provider.status.declared + ") != recomputed (" + derived + ")");
  const computation = verification.statusComputation ?? {};
  requireCondition(computation.derivedEffective === derived,
    "verification.statusComputation.derivedEffective != recomputed status");
  requireCondition(String(computation.computedBy ?? "").includes("validate_provider.js"),
    "verification.statusComputation.computedBy must name validate_provider.js");
  requireCondition(computation.computedAt, "verification.statusComputation.computedAt missing");
  requireCondition((verification.ciIntegration ?? {}).status === "exempt-registered",
    "verification.ciIntegration.status must be exempt-registered");
  requireCondition(String((verification.ciIntegration ?? {}).validator ?? "").endsWith("validate_provider.js"),
    "verification.ciIntegration.validator must point at validate_provider.js");

  // 6. Snapshot provenance: baseline pin, current API hash and stale declaration.
  const iosBaseline = baseline.repositories.ios;
  requireCondition(provider.source.commit === iosBaseline.commit, "provider source commit != M0 baseline");
  // The baseline may be captured clean (after committing) or dirty (isolated WIP).
  // What must never drift is the declared state vs the baseline record.
  requireCondition(provider.source.dirty === iosBaseline.dirty,
    "provider source dirty flag != M0 baseline dirty flag");
  requireCondition(setsEqual(provider.source.dirtyFiles ?? [], iosBaseline.dirtyFiles),
    "provider source dirtyFiles drift");
  requireCondition(provider.source.contentHash === iosBaseline.trackedContentHash,
    "provider source contentHash != baseline trackedContentHash");
  const snapshot = verification.snapshot ?? {};
  requireCondition(snapshot.baselineCommit === iosBaseline.commit, "verification.snapshot.baselineCommit mismatch");
  requireCondition(snapshot.baselineApiSnapshotSha256 === sources.baseline.apiSnapshotSha256,
    "verification.snapshot baseline API hash != SOURCES.json baseline");
  const currentApiSha = sha256(API);
  requireCondition(snapshot.currentApiSnapshotSha256 === currentApiSha,
    "verification.snapshot.currentApiSnapshotSha256 != actual api file hash");
  if (currentApiSha === snapshot.baselineApiSnapshotSha256) {
    requireCondition(snapshot.status === "current", "snapshot status must be current when hashes match");
  } else {
    requireCondition(snapshot.status === "stale",
      "snapshot status must be stale when current API hash differs from baseline");
    requireCondition(snapshot.currentRepoHead, "stale snapshot must record currentRepoHead");
    requireCondition(snapshot.replayExitCode === 0, "stale snapshot must record replayExitCode=0");
  }
  const generatorSource = fs.readFileSync(
    path.join(PROVIDER, "api-cards", "generate_api_cards.js"),
    "utf8",
  );
  const pin = /EXPECTED_API_SHA = "([0-9a-f]{64})"/.exec(generatorSource);
  requireCondition(pin !== null && pin[1] === sources.baseline.apiSnapshotSha256,
    "generator EXPECTED_API_SHA != SOURCES.json baseline hash");
  requireCondition(typeof sources.baseline.stale === "boolean" && Boolean(sources.baseline.currentRepoHead),
    "SOURCES.json baseline must declare stale flag + currentRepoHead");
  requireCondition(sources.baseline.stale === (sources.baseline.apiSnapshotSha256 !== currentApiSha),
    "SOURCES.json stale flag must match the actual snapshot comparison");

  // 7. Coverage declaration (10/37 catalog components + 5 Foundation entry points).
  const catalogIds = catalog.components.map((component) => component.id);
  const covered = sortedCopy([...cardComponents].filter((component) => catalogIds.includes(component)));
  const coverage = verification.apiCardCoverage ?? {};
  requireCondition(coverage.cards === listed.length, "apiCardCoverage.cards != index count");
  requireCondition(coverage.catalogComponentsTotal === catalogIds.length,
    "apiCardCoverage.catalogComponentsTotal mismatch");
  requireCondition(coverage.catalogComponentsWithCards === covered.length,
    "apiCardCoverage.withCards count mismatch");
  requireCondition(setsEqual(coverage.withCards ?? [], covered), "apiCardCoverage.withCards set mismatch");
  requireCondition(setsEqual(coverage.withoutCards ?? [], catalogIds.filter((component) => !cardComponents.has(component))),
    "apiCardCoverage.withoutCards set mismatch");
  requireCondition(coverage.foundationEntryPoints === cardComponents.size - covered.length,
    "apiCardCoverage.foundationEntryPoints mismatch");
  const componentCoverage = capabilities.componentCoverage ?? {};
  requireCondition(setsEqual(componentCoverage.experimental ?? [], covered),
    "capabilities.componentCoverage.experimental != components with cards");
  requireCondition((componentCoverage.verified ?? []).length === 0
    && (componentCoverage.unsupported ?? []).length === 0,
    "capabilities.componentCoverage verified/unsupported must be empty for this slice");

  // 8. Verification command metadata and reproducibility (F3).
  const commands = verification.commands ?? [];
  const byId = new Map(commands.map((item) => [item.id, item]));
  requireCondition(setsEqual([...byId.keys()], [...REQUIRED_COMMANDS]),
    "verification commands must be exactly: " + sortedCopy([...REQUIRED_COMMANDS]).join(", "));
  for (const [commandId, item] of byId) {
    requireCondition(COMMAND_STATUSES.has(item.status), commandId + ": invalid status");
    requireCondition(item.cwd === "." || item.cwd === "iOS", commandId + ": cwd must be recorded as '.' or 'iOS'");
    requireCondition(typeof item.command === "string" && item.command.length > 0, commandId + ": command missing");
  }
  const typecheck = byId.get("ios-minimal-typecheck");
  requireCondition(typecheck.cwd === ".", "ios-minimal-typecheck must be recorded with cwd='.'");
  for (const token of [
    "iOS/AIStarter/AIStarter/AIStarterApp.swift",
    "iOS/AIStarter/AIStarter/ContentView.swift",
    "iOS/AIStarter/AIStarter/APIMinimalExample.swift",
    "iOS/AIStarter/AIStarter/TaskListView.swift",
    "-I iOS/.build/dd-ai-starter-rel/Build/Products/Release-iphonesimulator",
    "-module-cache-path iOS/.build/module-cache",
  ]) {
    requireCondition(typecheck.command.includes(token), "ios-minimal-typecheck command missing token: " + token);
  }
  // The matrix status is evidence-driven, not pinned: a passed run must be exit 0 and
  // every runtimeMatrix entry must be passed; a blocked run must keep exit 65 and at
  // least one blocked entry. This prevents both silent downgrades and fake greens.
  const matrixCommand = byId.get("ios-ui-matrix");
  const matrixEntries = Object.entries(verification.runtimeMatrix ?? {});
  // Entries covered by this automated matrix. Interaction and device items
  // (systemBack / safeAreaTab / keyboardScroll / voiceOver) are separate manual
  // checks and must stay not-run here; they are listed in verification.unverified.
  const AUTOMATED_MATRIX_ENTRIES = [
    "loading", "content", "empty", "error", "light", "dark", "AX3", "shortText", "longText",
  ];
  const MANUAL_MATRIX_ENTRIES = ["systemBack", "safeAreaTab", "keyboardScroll", "voiceOver"];
  if (matrixCommand.status === "passed") {
    requireCondition(matrixCommand.exitCode === 0, "passed ios-ui-matrix must record exitCode 0");
    const notPassed = AUTOMATED_MATRIX_ENTRIES.filter((key) => (verification.runtimeMatrix ?? {})[key] !== "passed");
    requireCondition(notPassed.length === 0,
      "passed ios-ui-matrix requires automated entries passed; still not passed: " + notPassed.join(", "));
    const wronglyClaimed = MANUAL_MATRIX_ENTRIES.filter((key) => (verification.runtimeMatrix ?? {})[key] === "passed");
    requireCondition(wronglyClaimed.length === 0,
      "manual matrix entries must not be claimed as passed: " + wronglyClaimed.join(", "));
  } else if (matrixCommand.status === "blocked") {
    requireCondition(matrixCommand.exitCode === 65, "blocked ios-ui-matrix must record exit 65");
    requireCondition(matrixEntries.some(([, value]) => value === "blocked-sandbox-pseudo-terminal"),
      "blocked ios-ui-matrix requires at least one blocked runtimeMatrix entry");
  } else {
    requireCondition(false, "ios-ui-matrix status must be passed or blocked, got " + matrixCommand.status);
  }
  requireCondition(commands.some((item) => item.status === "passed"),
    "verification must contain at least one passed command");
  // What must never disappear is the honest declaration of what was NOT verified.
  requireCondition((verification.unverified ?? []).length > 0,
    "verification.unverified must stay non-empty: some checks are manual or environment-dependent");

  // 9. UI-test target configuration and final matrix report (F5/F7).
  const uiTarget = verification.uiMatrixTarget ?? {};
  requireCondition(uiTarget.productType === "com.apple.product-type.bundle.ui-testing",
    "verification.uiMatrixTarget.productType must be bundle.ui-testing");
  requireCondition(uiTarget.testTargetName === "AIStarter", "verification.uiMatrixTarget.testTargetName");
  const pbxproj = fs.readFileSync(path.join(ROOT, "AIStarter", "AIStarter.xcodeproj", "project.pbxproj"), "utf8");
  requireCondition(pbxproj.includes('productType = "com.apple.product-type.bundle.ui-testing";'),
    "GoldenPageMatrixTests must be a bundle.ui-testing target");
  requireCondition(pbxproj.includes("TEST_TARGET_NAME = AIStarter;"), "GoldenPageMatrixTests must set TEST_TARGET_NAME");
  requireCondition(pbxproj.includes("PBXTargetDependency") && pbxproj.includes("2A00000000000000000000E1"),
    "GoldenPageMatrixTests must depend on the AIStarter app target");
  const matrixReport = loadJson(path.join(ROOT, "AIStarter", "GoldenPageMatrixReport.json"));
  const finalAttempts = (matrixReport.attempts ?? []).filter((attempt) => attempt.status === "blocked");
  requireCondition(finalAttempts.length > 0, "GoldenPageMatrixReport.json must record the blocked final attempt");
  requireCondition(finalAttempts.some((attempt) => String(attempt.reason ?? "").includes("Pseudo Terminal")),
    "blocked attempt must record the Pseudo Terminal blocker");
  requireCondition(finalAttempts.some(
    (attempt) => (attempt.simulator ?? {}).udid === "CE28D919-7BEB-46B2-86A7-1D063E54303F",
  ), "blocked attempt must record the final simulator UDID");

  console.log("M2 iOS provider validation passed: " + listed.length + " cards, recomputed status="
    + derived + ", snapshot=" + snapshot.status + ", coverage=" + covered.length + "/" + catalogIds.length);
}

main();
