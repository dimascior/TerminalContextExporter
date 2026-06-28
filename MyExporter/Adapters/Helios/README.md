# Helios Integrity Bridge — TCE Adapter

TerminalContextExporter adapter that provides envelope integrity verification for the Helios command-gate system.

## Purpose

Helios gates shell commands via PreToolUse/PostToolUse hooks but cannot prove its own enforcement files were intact when the gate decision was made. This adapter gives Helios a local integrity witness: it hashes protected files, compares them against a durable manifest and session baseline, and writes structured evidence for every command.

## Envelope Model

### Protected Enforcement Envelope

Files that **must not change** during gated execution:

| Relative Path | Role |
|---|---|
| `hooks/gate_check.ps1` | Command validation logic |
| `hooks/evidence_capture.ps1` | PostToolUse/PostToolUseFailure evidence |
| `hooks/tier_classifier.ps1` | Command tier classification |
| `hooks/helios_pretooluse.ps1` | Front controller (integrity check before policy load) |
| `hooks/lib/HeliosIntegrityBridge.ps1` | Vendored copy of this adapter |
| `policy/command-policy.json` | Tier patterns and gate policy |

### Mutable Runtime Envelope

Directories that **must change** as part of the gate lifecycle:

- `pending/` — gates awaiting execution
- `inflight/` — gates currently executing
- `evidence/` — completed gate records
- `blocked/` — denied command records

## Trust Model

### Durable Manifest

`manifest/helios-envelope.json` — contains expected SHA256 hashes for all protected files.
`manifest/helios-envelope.sha256` — SHA256 of the manifest JSON (sidecar, avoids self-hash).

The manifest is the root of trust. It is valid only if created by a human rebaseline step and has not drifted since.

### Session Baseline

`evidence/integrity/sessions/<session_id>/baseline.json` — snapshot of protected hashes at session start, created only after verifying against the durable manifest. Provides session continuity evidence.

### Dual Comparison

Every PreToolUse check compares current state against **both**:
1. Durable manifest — "Does the envelope match the known-good install state?"
2. Session baseline — "Has anything changed since this session started clean?"

If either comparison fails, Helios denies.

## Per-Command Evidence Layout

```
evidence/integrity/sessions/<session_id>/
  baseline.json
  commands/
    <tool_use_id>.before.json    — pre-command protected snapshot
    <tool_use_id>.decision.json  — allow/deny/integrity_failure verdict
    <tool_use_id>.after.json     — post-command snapshot (if executed)
    <tool_use_id>.compare.json   — protected + runtime comparison (if executed)
```

## Bridge API

All functions are self-contained (no module imports). PowerShell 5.1+ compatible.

| Function | Purpose |
|---|---|
| `Get-FileSha256` | Raw-byte SHA256 of a file, lowercase hex |
| `Get-HeliosEnvelopeSnapshot` | Hash protected files, capture mutable dir state |
| `Compare-HeliosProtectedEnvelope` | Compare snapshot against manifest and/or baseline |
| `Compare-HeliosRuntimeTransition` | Lifecycle-aware comparison of mutable dirs |
| `New-HeliosSessionBaseline` | Create baseline after verifying manifest integrity |
| `Test-HeliosIntegrity` | Quick pass/fail: current files vs manifest hashes |
| `Write-HeliosIntegrityEvidence` | Write before/decision/after/compare JSON files |

### Expected Mutation Profiles

`Compare-HeliosRuntimeTransition` takes an `ExpectedMutationProfile` parameter:

- `ALLOW_PRETOOL` — pending loses gate, inflight gains gate
- `ALLOW_POSTTOOL` — inflight loses gate, evidence gains result
- `DENY_PRETOOL` — all dirs stable, blocked gains record
- `INTEGRITY_FAILURE` — all dirs stable

## Sync Model

TCE owns the source bridge at `Adapters/Helios/HeliosIntegrityBridge.ps1`.
Helios consumes a vendored copy at `.command-gate/hooks/lib/HeliosIntegrityBridge.ps1`.

Sync process:
1. Run `tools/Sync-HeliosBridge.ps1` to copy source to vendored location.
2. Verify byte-identity between source and destination.
3. Run `tools/New-HeliosEnvelopeManifest.ps1` to rebaseline the manifest.
4. Verify with `tools/Test-HeliosEnvelopeIntegrity.ps1`.

## Rebaseline

When any protected file changes (including the vendored bridge after sync):
1. Run `New-HeliosEnvelopeManifest.ps1 -HeliosGateRoot <path> -RebaselinedBy human`.
2. Verify: `Test-HeliosEnvelopeIntegrity.ps1 -HeliosGateRoot <path>`.
3. The manifest JSON and sidecar hash are regenerated.

## Phase 4+ Lock Handoff

After this adapter contract is stable, Phase 4 adds OS-native filesystem locks:

- Windows: `icacls` read-only ACL on protected files
- Linux: `chattr +i` immutable attribute
- macOS: `chflags uchg` user immutable flag
- POSIX fallback: `chmod a-w`

The lock workflow: unlock → rebaseline → relock. TCE owns the lock/unlock tooling.

## Schemas

See `schemas/` for JSON Schema definitions of:

- `helios-envelope.v1` — durable manifest
- `helios-baseline.v1` — session baseline
- `helios-command-evidence.v1` — before, decision, after, compare evidence

## Packaging

### Distribution

The adapter is distributed from the `helios-integrity-adapter` branch. TCE main is preserved without adapter entries.

**Development:**
```bash
git clone -b helios-integrity-adapter https://github.com/<owner>/TerminalContextExporter.git
```

**Release artifact:**
```bash
gh release download v0.3.98 --repo <owner>/TerminalContextExporter
```

### Package Tools

| Tool | Purpose |
|---|---|
| `tools/New-HeliosAdapterPackage.ps1` | Build a distributable TCE adapter package |
| `tools/Test-HeliosAdapterPackage.ps1` | Verify adapter package contents and checksums |
| `tools/New-HeliosRuntimeBundle.ps1` | Build a distributable Helios runtime bundle |
| `tools/Test-HeliosRuntimeBundle.ps1` | Verify runtime bundle contents, checksums, BOM safety |
| `tools/New-HeliosCombinedInstallPlan.ps1` | Generate full install plan from both packages |
| `tools/Test-HeliosEndToEndInstallPlan.ps1` | Simulate install in temp directory |
| `tools/New-HeliosInstallPlan.ps1` | Generate adapter-only install plan |

### Install Flow

1. Pull adapter package and runtime bundle.
2. Verify both: `Test-HeliosAdapterPackage.ps1` and `Test-HeliosRuntimeBundle.ps1`.
3. Generate combined install plan: `New-HeliosCombinedInstallPlan.ps1`.
4. Copy runtime files, sync bridge, generate BOM-free local manifest.
5. Verify envelope: `Test-HeliosEnvelopeIntegrity.ps1 -HeliosGateRoot <path>`.
6. Review and approve hook activation in `settings.json`.
7. Run smoke tests.

See `docs/install-sequence.md` for the complete procedure and `docs/package-architecture.md` for the two-package model.

## Current Status

**Phase:** 3.99.1 — package validation, manifest hardening, end-to-end execution proof.

| Component | Status |
|---|---|
| Bridge implementation (7 functions) | Complete |
| Sync, manifest, integrity tools | Complete |
| Pester test suite (18 tests) | Complete |
| Schemas (3 JSON Schema files) | Complete |
| TCE adapter spec | Complete — `docs/tce-helios-integrity-adapter-spec.md` |
| Orchestration workflow | Complete — `tools/Invoke-HeliosGapTest.ps1` |
| Evidence parser/normalizer | Complete — `tools/ConvertFrom-HeliosEvidence.ps1` |
| Gap-test matrix (12 tests) | Complete — `evidence/gap-tests/` |
| Phase 4 lock requirements | Complete — `docs/phase4-lock-requirements-from-gap-tests.md` |
| Package architecture | Complete — `docs/package-architecture.md` |
| Adapter package tools (3) | Complete — build, verify, install-plan |
| Runtime bundle tools (2) | Complete — build, verify |
| Combined installer | Complete — `tools/New-HeliosCombinedInstallPlan.ps1` |
| End-to-end simulation | Complete — `tools/Test-HeliosEndToEndInstallPlan.ps1` |
| BOM hardening | Complete — manifest/sidecar writes BOM-free, integrity check includes BOM detection |
| Package validation (3.99.1) | Complete — adapter verifier BOM checks, runtime manifest completeness, e2e execution |
| Install sequence | Complete — `docs/install-sequence.md` |
| TCE main preservation | Preserved — main has no adapter entries |

### Branch Ownership

- **helios-integrity-adapter** — active implementation branch for adapter work
- **main** — preserved clean public-facing MyExporter module (no Adapters/Helios)

### Phase Roadmap

| Phase | Status |
|---|---|
| Phase 0-3.96 | Complete (Helios runtime + TCE bridge) |
| Phase 3.97 | Complete (TCE gap-tests + lock derivation) |
| Phase 3.98 | Complete (packaging architecture + install tooling) |
| Phase 3.99 | Complete (runtime bundle + BOM hardening + e2e simulation) |
| Phase 3.99.1 | Complete (package validation + manifest hardening + execution proof) |
| Phase 4 | Requirements derived — implementation not started |
| Phase 5 | Future — helios-lock package |
| Phase 6 | Future — lock verification evidence |
