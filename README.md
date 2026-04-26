# TerminalContextExporter

System state capture and cross-environment validation framework for complex software systems with AI agent governance.

**What it does:** Captures system state before and after execution, generating JSON evidence files as verifiable records. Enables cross-environment validation and correlation of system telemetry across local and remote machines, providing visibility into operational conditions before and after terminal environment modifications.

---

## PROJECT OVERVIEW & CORE PURPOSE

PowerShell module designed as a constitutional framework for managing complex software systems where AI agents operate as first-class participants in the development lifecycle. Engineered for codebased AI agent collaboration, with embedded governance structures, enforcement mechanisms, and anti-corruption patterns that make it suitable for large-scale, systematic development with minimal human intervention.

The system solves a critical problem: how to enable AI agents to make reliable, architecturally sound contributions to complex systems without drift, simulation, or architectural violations. Rather than relying solely on human review, enabling end to end governance loop utilizing constitutional framework opimitizations through CI/CD gates, and integrating components to specific prompting patterns.

**Project Scope:** PowerShell module for cross-platform system information export (Windows/Linux/WSL)  
**Target Users:** AI-assisted development teams, enterprises requiring deterministic software governance, teams building complex multi-platform systems  
**Language Composition:** 91.7% PowerShell, 8.3% Shell  

---


### Step 0: AI Agent Orientation (Mandatory Before Any Code Edit)

An AI agent deposited into this codebase with zero prior knowledge must read these documents in order before touching a single file:

```
1. docs/integration loop/GuardRails.md (Parts 1-3)
   - What system boundaries exist
   - What data flows across those boundaries
   - What patterns are forbidden (no mutable objects across jobs, no hardcoded deny lists)

2. docs/integration loop/CLAUDE.md (Parts 4-7)
   - How to choose context level (1=Essential, 2=Architectural, 3=Environmental)
   - Prompt templates matching complexity level
   - Bailout triggers (if more than 3 files need changing, escalate)

3. docs/TaskLoop/Isolate-Trace-Verify-Loop.md
   - How to structure work units
   - How to generate evidence files
   - What constitutes real vs. simulated validation

4. docs/TaskLoop/WorkOrders/tasksV5.md
   - Current active task list
   - Specific success criteria with byte counts/timestamps

5. docs/AssetRecords/Implementation-Status.md
   - What is already implemented
   - What blockers exist
   - What context is available from previous work
```

**Machine Enforcement:** `scripts/verify_master_context.ps1` (lines 98-138) checks that all five documents exist. If any is missing, CI fails with CONSTITUTIONAL_BAILOUT. The agent cannot proceed without this context.

**Why This Matters:** An agent loading only a task description will tend toward architectural drift (e.g., hardcoding deny lists in PowerShell instead of using YAML policy files, or passing mutable objects across job boundaries). The governance documents prevent these failure modes through mandatory reading order.

### Step 1: Work Assignment (Isolate Phase)

Work is defined in `docs/TaskLoop/WorkOrders/tasksV5.md` using a structured template:

```powershell
$WorkUnit = @{
    TaskId = "TASK-20250706-042"
    Objective = "Single sentence: what success looks like"
    RealBoundary = "Specific system call that proves it works (e.g., 'tmux session creation in WSL')"
    
    # Hard bailout constraints per GuardRails.md Part 4.3
    BailoutConditions = @(
        "More than 3 files need modification",
        "Circular dependency detected",
        "Abstraction layer becomes larger than implementations"
    )
    
    # Artifact-based success per GuardRails.md Part 5.1
    SuccessCriteria = @(
        "Evidence file with correlation ID",
        "Exit code 0 from fresh session",
        "Real data generated (no simulation)"
    )
    
    # Context level determines branch strategy
    ContextLevel = 1  # 1=Essential, 2=Architectural, 3=Environmental
}
```

**Bailout thresholds are hard constraints:** If a seemingly simple task (Level 1) requires touching more than 3 files, the agent must escalate to Level 2 context or stop and ask for human clarification. This prevents the common failure mode of cascading changes that break adjacent components.

### Step 2: Branch Strategy (Context Level Mapping)

Branches are mapped to context levels:

| Branch | Trigger | Context Level | CI Pipeline |
|--------|---------|---------------|-------------|
| feature/* | Manual PR | Level 1 | No automatic trigger |
| dev/develop | Push | Level 2 | CI + cross-platform |
| main | Push | Level 3 | Full CI + scheduled |

**GuardRails Authority:** CI jobs check that commit messages carry a "Level N:" declaration matching the scope of changes. A commit with 27+ files staged but missing a Level 3 declaration is rejected by the pre-commit hook (README.md L316-325).

### Step 3: Making the Change (Trace Phase)

An agent executes work in a fresh, isolated session:

```powershell
.\MyExporter\DevScripts\Invoke-FreshSession.ps1 `
    -ScriptPath ".\Execute-TaskUnit.ps1" `
    -SessionTag $WorkUnit.TaskId `
    -Wait
```

This fresh session isolation prevents stale module definitions from interfering and ensures that every test has a clean environment baseline.

**Key file modification zones and their rules:**

| Zone | Files | Rules | GuardRails Authority |
|------|-------|-------|---------------------|
| Classes | Classes/*.ps1 | Dot-sourced at top of .psm1; no $ExecutionContext shadowing | Part 11.1 |
| Private | Private/*.ps1 | Verb-Noun-Platform naming; job-safe functions; no mutable types | Part 11.2 |
| Public | Public/Export-SystemInfo.ps1 | Only ONE Invoke-WithTelemetry call; must have FastPath escape | Part 11.3 |
| Policies | Policies/*.yaml | YAML only; no PowerShell hardcoding | Part 9 |
| Tests | Tests/*.Tests.ps1 | Pester only; NO Mock/Sentinel patterns | Part 7 |

**Correlation IDs Threading:** Every agent-triggered operation produces a GUID correlation ID at `Get-ExecutionContext.ps1` L19. This ID propagates through function parameters, job arguments, telemetry events, output files, and CI artifacts. When an operation fails, the correlation ID lets you trace exactly which branch, job, and invocation caused the failure across WSL process boundaries and background jobs.

### Step 4: Pre-Commit Verification (Local Gate)

Before committing, the agent runs:

```powershell
.\MyExporter\Verify-Phase.ps1
```

This runs 6 compliance checks (Verify-Phase.ps1 L327-360):

| Check | What It Validates | Failure Blocks |
|-------|------------------|-----------------|
| Test-GuardRailsCompliance | No mutable objects across jobs; classes dot-sourced; no telemetry nesting | Commit |
| Test-TestCoverage | Every Public function has *.Tests.ps1 file; no Mock patterns | Commit |
| Test-ApiContract | Export-SystemInfo has required params; classes instantiable | Commit |
| Test-FileList | No untracked git files; manifest FileList matches disk | Commit |
| Test-ChangelogRequirement | CHANGELOG.md updated within 7 days | Commit |
| Test-PendingSpecs | No -Pending {} blocks in Pester tests | Commit |

Exit code non-zero blocks the commit entirely. The project's pre-commit git hook wires this directly: commits staged without proper context level declaration are rejected.

### Step 5: Push Triggers CI

On push to main or dev, two GitHub Actions workflows fire in sequence.

**ci.yml Primary Pipeline (5 Sequential Job Stages):**

**Job 1: constitutional-verification**
- `scripts/verify_master_context.ps1` checks 6 required docs exist and cross-link
- Validates docs/integration loop/, TaskLoop/, AssetRecords/ structure
- If any doc missing: CONSTITUTIONAL_BAILOUT

**Job 2: anti-simulation-enforcement** (needs: Job 1)
- `MyExporter/DevScripts/Assert-NoSimulatedTests.ps1` rejects Mock/Sentinel patterns
- Scans all test files for simulation patterns
- Zero tolerance policy: any Mock/Sentinel blocks CI immediately

**Job 3: systematic-validation-matrix** (needs: Jobs 1+2)
- Matrix: [windows PS5.1] x [windows PS7.4] x [ubuntu PS7.4+WSL+tmux]
- For each matrix combination:
  - Test-ModuleManifest psd1 validity
  - MyExporter/Verify-Phase.ps1 (all 6 local checks)
  - Invoke-ScriptAnalyzer -Settings PSGallery
  - Invoke-Pester Tests/*.Tests.ps1
  - MyExporter/DevScripts/Test-Phase*.ps1 (phase-specific Windows tests)
  - enhanced-test-bridge.ps1 -TestScenario All -CaptureEvidence
  - WSL integration tests (Ubuntu leg only)

**Job 4: constitutional-compliance-verification** (needs: Job 3)
- Re-runs verify_master_context.ps1 + Verify-Phase.ps1 as final gate
- Aggregates evidence from all matrix runs
- Blocks merge if any evidence missing or inconsistent

**Job 5: security-constitutional-scan** (needs: Job 3)
- Trivy filesystem scan uploads SARIF to GitHub Security tab
- Integrates security validation into constitutional framework

**cross-platform-validation.yml - Deep WSL Pipeline:**
- Runs daily at 06:00 UTC plus on push to main/develop
- Dedicated WSL leg with tmux binary availability check
- Test-Phase5-Functionality runs real tmux session management tests
- No simulation allowed: all terminal operations use actual tmux/wsl binaries

### Step 6: Evidence Collection & Organization

Every test run produces JSON evidence files organized in `.artifacts/` structure:

**Directory Organization:**
```
MyExporter/.artifacts/
├── evidence/
│   ├── local/           # Local development evidence (excluded from VCS)
│   │   └── evidence-local-[timestamp].json
│   └── baseline/        # GitHub Actions baseline evidence
│       └── evidence-baseline-[leg]-[commit].json
└── test-results/        # Test execution details (excluded from VCS)
    └── test-evidence-[timestamp].json
```

**Evidence Types & Retention Policy:**

| Evidence Type | Location | Purpose | Retention | Tracked |
|---------------|----------|---------|-----------|---------|
| evidence-local-*.json | `.artifacts/evidence/local/` | Local test evidence with correlation IDs, commit SHAs, timestamps | 365 days (1 year local retention) | No (.gitignore) |
| evidence-baseline-*.json | `.artifacts/evidence/baseline/` | GitHub Actions baseline for reproducibility comparison | Indefinite | No (.gitignore) |
| test-evidence-*.json | `.artifacts/test-results/` | Enhanced test bridge results with system context | 365 days (1 year local retention) | No (.gitignore) |

**Evidence Generation Process:**

The `enhanced-test-bridge.ps1` script generates evidence during execution:
- Captures full commit SHA (40-character hash)
- PowerShell version and edition (5.1/7.x, Desktop/Core)
- Operating system detection (Windows/Linux/macOS)
- Correlation ID (GUID for end-to-end tracing)
- Per-test pass/fail status with real system data
- Evidence strings like "JSON file created: output.json (390 bytes), Computer: DESKTOP-T3NJDBQ"

**Reproducibility Workflow:**

1. **Local Development:** Developer runs `enhanced-test-bridge.ps1 -CaptureEvidence`
   - Generates `evidence-local-[timestamp].json` in `.artifacts/evidence/local/`
   - Contains current commit SHA and test results

2. **CI/CD Pipeline:** GitHub Actions also generates evidence for PS 7.4 Windows matrix leg
   - Stored as GitHub Actions artifact
   - Retrieved by reproducibility verification script

3. **Verification:** `test-evidence-reproducibility-verification.ps1` compares:
   - Local evidence vs. GitHub Actions baseline
   - Handles first commit (baseline establishment)
   - Recognizes code changes (SHA mismatch = expected)
   - Blocks environment mismatches (reproducibility violation)

### Step 7: Pull Request to main

PR triggers the same full CI pipeline on the PR head. Merge requires:
- All 5 CI jobs pass
- Commit message carries correct "Level N:" declaration
- No unresolved -Pending Pester tests
- CHANGELOG.md updated within 7 days
- Evidence artifacts present and non-empty
- Reproducibility verification passes (or baseline establishment)

---

## HOW THE AGENTIC SYSTEM INTEGRATION WORKS

This repository treats AI agents as first-class participants in the SDLC with specific architectural accommodations:

### A. Context Level Tiering (Anti-Drift Architecture)

CLAUDE.md defines 3 context tiers that map directly to commit types:

| Level | Scope | Max Files | Bailout Trigger | Example |
|-------|-------|-----------|-----------------|---------|
| Level 1 Essential | Single function / bug fix | ≤3 files | Modification creep | Fix a single private function |
| Level 2 Architectural | Component changes, API updates | ≤7 files | Cross-component dependencies | Add new parameter to public cmdlet |
| Level 3 Environmental | Cross-platform / CI changes | No limit | Constitutional violations | Update WSL/tmux detection logic |

An agent operating at Level 1 that discovers it needs to touch 8 files must stop and escalate to Level 2—documented in Isolate-Trace-Verify-Loop.md L62. This prevents the classic AI failure mode of "fixing one thing breaks three others, so I'll fix those too."

### C. The FastPath Pattern (Anti-Tail-Chasing)

Export-SystemInfo.ps1 has a FastPath escape hatch (L19-24):

```powershell
if ($env:MYEXPORTER_FAST_PATH) {
    # Skip jobs, telemetry, job-safe loading
    # Direct synchronous execution
    Write-Warning "FastPath mode enabled - bypassing full architectural compliance"
}
```

This exists specifically for AI agents during iterative development. The agent sets `$env:MYEXPORTER_FAST_PATH=1`, makes a change, immediately runs the function synchronously, gets real output. Without FastPath, every test would require waiting for background jobs, making the feedback loop too slow for AI-driven iteration. However, FastPath is only for development—production code must pass the full architecture.

### D. Correlation IDs Threading Through Everything

Every agent-triggered operation produces a GUID at `Get-ExecutionContext.ps1` L19:

```powershell
$context.CorrelationId = ([guid]::NewGuid()).ToString()
```

This ID propagates through: function parameters → job arguments → telemetry events → output files → CI artifacts. When an agent's run fails, trace the correlation ID to find exactly which branch, run, and invocation caused the failure.

### E. Evidence-Based Completion Gates

A task is not "done" until evidence files exist. `tasksV5.md` L40-48 defines specific bytes-on-disk as proof:

```
final-test-fastpath.csv    (226 bytes) ← Real Windows system data
final-test-fastpath.json   (288 bytes) ← Valid JSON with correlation ID
final-test-normal.csv      (306 bytes) ← Normal mode output
final-test-normal.json     (390 bytes) ← Full execution data
```

This prevents agents from declaring work complete based on "it looked good in my session." CI downloads all evidence artifacts and aggregates them into compliance-final.json.

### F. Anti-Simulation Constitutional Law

`Assert-NoSimulatedTests.ps1` (called in both CI workflows before code runs) actively rejects code containing Mock, Sentinel, or Simulate patterns in test files. This is a hard boundary preventing agents from writing tests that pretend to call WSL/tmux instead of actually calling them.

**Practical Effect:** An agent cannot "cheat" CI by mocking the WSL boundary. All WSL/tmux tests must use the real wsl.exe / tmux binary.

---

## CORE ARCHITECTURAL PATTERNS

### a) FastPath Escape Hatch

**Files:** Export-SystemInfo.ps1 L19-24, Add-TerminalContextToSystemInfo.ps1 L39  
**Purpose:** Bypass complex job architecture during feature work iteration  
**Pattern:** When $env:MYEXPORTER_FAST_PATH is set, synchronous execution replaces background job management  
**Anti-Drift Effect:** Prevents developers from getting stuck fixing architecture problems during feature development

### b) Job-Safe Function Injection

**Files:** Export-SystemInfo.ps1 L89-95  
**Purpose:** PowerShell background jobs run in isolated runspaces without access to parent scope functions  
**Pattern:** Module reads its own source files as strings and Invoke-Expressions them inside the job scope  
**GuardRails Authority:** GuardRails.md Part 11.3 (documented pattern)  
**Implementation:** All functions required in background jobs are serialized as text, transmitted via -ArgumentList, and re-hydrated in the job context

### c) Context-First Execution

**Files:** _Initialize.ps1, Get-ExecutionContext.ps1  
**Purpose:** Detect platform, WSL presence, and PowerShell edition once at module import  
**Pattern:** Every subsequent function receives a $Context hashtable or reads module-scoped $script:* variables  
**Benefit:** Prevents repeated, expensive environment probing; enables deterministic behavior  
**Immutability:** Context is read-only after initialization, preventing state corruption

### d) $ExecutionContext Collision Avoidance

**Files:** Get-SystemInfoPlatformSpecific.ps1 L22  
**Purpose:** PowerShell has a built-in automatic variable $ExecutionContext  
**Pattern:** Module renames its context object to $jobContext / $myExporterContext in job scope  
**Avoidance Mechanism:** Explicit parameter passing instead of relying on automatic variables  
**Risk Mitigation:** Prevents silent shadowing bugs where automatic variable clobbers module context

### e) Capability-Based Routing

**Files:** Get-TerminalContextPlatformSpecific.ps1 L122-178  
**Purpose:** Rather than hardcoding platform checks everywhere  
**Pattern:** Single routing function probes capabilities (WSL? tmux? WindowsTerminal?) and returns routing key  
**Routing Keys:** WSL_TMUX, WSL_NATIVE, WINDOWS_CMD, etc.  
**Downstream Dispatch:** Routing key drives which platform-specific implementation runs  
**Maintainability:** Changes to platform detection logic affect only one file

### f) Immutable Session Reference

**Files:** TmuxSessionReference.ps1 L130-133  
**Purpose:** Support functional/immutable patterns in class-based OO system  
**Pattern:** WithUpdatedActivity() returns a new instance rather than mutating the existing one  
**Benefit:** Prevents accidental state corruption across parallel threads; enables safe job passing  
**Job-Safety:** Can be passed via -ArgumentList without mutable reference concerns

### g) Versioned State Schema with Migration

**Files:** Update-StateFileSchema.ps1 L56-66  
**Purpose:** Maintain backward compatibility during schema evolution  
**Pattern:** JSON state file has SchemaVersion field; module migrates v1.0 → v2.0 on startup  
**Durability:** Existing deployments upgrade automatically without manual intervention  
**Validation:** Migration preserves all data while adding new fields with sensible defaults

### h) Telemetry Batching

**Files:** TerminalTelemetryBatcher.ps1 L41-47  
**Purpose:** Telemetry isn't written per-operation; overhead becomes prohibitive at scale  
**Pattern:** Items accumulate in $script:TelemetryBatch and flush when either threshold is reached  
**Thresholds:** Size (50 items) or time (5 minutes)  
**Benefit:** Reduces I/O overhead; enables correlation of related operations in single batch

### i) Capability Caching

**Files:** Test-TerminalCapabilities.ps1 L52-55  
**Purpose:** WSL/tmux detection is expensive (external process calls)  
**Pattern:** Results cached for 5 minutes in $script:CapabilityCache  
**Performance Impact:** First call ~500ms (process startup); subsequent calls <1ms  
**Invalidation:** Manual refresh via -Force flag or automatic expiry

---

## MANIFEST AS CONSTITUTIONAL CONTRACT

The file `MyExporter.psd1` is the single source of truth for:

- **Semantic Versioning:** ModuleVersion field is the official version
- **Platform Gates:** PowerShellVersion (5.1) and CompatiblePSEditions (Desktop, Core)
- **Dependency Injection:** RequiredModules, PrerequisiteModules lists
- **API Contract:** FunctionsToExport defines the only public surface
- **Compliance Metadata:** FileList enumerates every shipping file; CI rejects commits with untracked files

**AI Agent Rule:** An AI agent must treat this manifest as immutable. When adding new parameters to public cmdlets, the manifest FileList must be updated immediately, or Verify-Phase.ps1 L224-270 detects the mismatch and blocks the commit.

---

## DATA FLOW AND PROCESSING PIPELINE

### System Information Export Flow

```
User: Export-SystemInfo -ComputerName 'localhost','WIN-DC01' -OutputPath '~/report.csv'
  |
  ├─ FASTPATH CHECK: if $env:MYEXPORTER_FAST_PATH, skip jobs
  │
  ├─ CONTEXT ESTABLISHMENT: Get-ExecutionContext detects Windows/WSL/PowerShell edition
  │  Correlation ID generated (GUID)
  │
  ├─ PATH VALIDATION: Assert-ContextPath normalizes ~/report.csv to POSIX format
  │
  ├─ PARALLEL EXECUTION (Per ComputerName):
  │  ├─ Thread 1 (localhost): Direct call to Get-SystemInfo.Linux via platform dispatcher
  │  │   ├─ Wrapped in Invoke-WithTelemetry (adds timing, error handling, correlation ID)
  │  │   └─ Returns SystemInfo object with CorrelationId threaded
  │  │
  │  └─ Thread 2 (WIN-DC01): Remote execution via Invoke-Command + WinRM
  │      ├─ Function definitions injected into job scope (job-safe loading)
  │      ├─ SystemInfo class serialized as CLIXML
  │      ├─ Correlation ID passed via -ArgumentList
  │      ├─ Transmitted over WinRM to WIN-DC01
  │      ├─ Deserialized back in calling PowerShell
  │      └─ Returns SystemInfo object with matching CorrelationId
  │
  ├─ AGGREGATION: ArrayList collects all SystemInfo objects
  │
  ├─ TELEMETRY BATCHING: Invoke-WithTelemetry wraps each operation
  │  ├─ Event: { CorrelationId, EventName, Duration, Status }
  │  ├─ Batches accumulate in $script:TelemetryBatch
  │  └─ Flushes when: 50 items threshold OR 5 minutes elapsed
  │
  ├─ OUTPUT: Convert to CSV/JSON and write to file
  │  └─ File includes CorrelationId for traceability
  │
  └─ EVIDENCE GENERATION: JSON evidence file created
     ├─ Filename: evidence-[CorrelationId].json OR evidence-[Timestamp].json
     ├─ Contents: TestSuite, CorrelationId, CommitSHA, Environment, Tests[], Summary
     └─ Validation: CI gates check JSON structure per schema

EVIDENCE FLOW:
  ├─ enhanced-test-bridge.ps1 generates evidence-*.json files locally
  ├─ GitHub Actions CI downloads evidence files as artifacts
  ├─ Job 4 aggregates all evidence into compliance-final.json
  └─ Merge decision: compliance-final.json.Ready must be true
```

### Cross-Platform Data Normalization

```
Windows (CIM) → [SystemInfo] → JSON {paths: POSIX format}
  |
  ├─ Get-CimInstance Win32_OperatingSystem
  ├─ Wrapped: FromCim() static method converts to SystemInfo
  └─ Properties normalized: ComputerName, Platform, OS, Version, CorrelationId

Linux (native) → [SystemInfo] → JSON {paths: POSIX format}
  |
  ├─ uname -a, lsb_release -d, or /etc/os-release
  ├─ Wrapped: Direct constructor call with normalized data
  └─ Properties: ComputerName, Platform, OS, Version, CorrelationId

WSL Interop Boundary:
  ├─ Windows PowerShell (host process)
  ├─ Assert-ContextPath detects WSL via $env:WSL_DISTRO_NAME
  ├─ Path translation: C:\path → /mnt/c/path via wslpath
  └─ Calls wslpath for bidirectional POSIX ↔ Windows conversion
```

---

## CI/CD EVIDENCE VALIDATION: JSON SCHEMA SPECIFICATIONS

The CI/CD pipeline validates changes through **five sequential gates**, each enforcing specific JSON schema requirements for evidence files. These are not optional—they are **hard requirements** for merge. The system uses JSON evidence as the single source of truth for proving that changes meet constitutional requirements.

### 1. PRIMARY EVIDENCE SCHEMA: TASKSV5-ENHANCED-EVIDENCE

**Location & Naming Convention:**
```
MyExporter/evidence-[CorrelationId].json
MyExporter/evidence-[Timestamp].json
Example: MyExporter/evidence-2025-07-06-1430.json
```

**Required JSON Structure:**
```json
{
  "TestSuite": "TasksV5-Enhanced-Evidence",
  "Timestamp": "2025-07-06T14:30:22.1234567-07:00",
  "CommitSHA": "abc12345def67890",
  "CorrelationId": "0aa9f484-8203-47fa-a5ec-46e109c2e11f",
  "Environment": {
    "PSVersion": "7.4.0",
    "PSEdition": "Core",
    "OS": "Windows",
    "WorkingDirectory": "C:\\dev\\TerminalContextExporter\\MyExporter",
    "Computer": "DESKTOP-dimascior",
    "User": "dimascior"
  },
  "Tests": [
    {
      "Name": "Export-SystemInfo Parameter Count",
      "Status": "PASS",
      "Evidence": "6 parameters detected",
      "Details": {
        "ParameterNames": ["ComputerName", "OutputPath", "Format", "UseSSH", "AsJson", "IncludeTerminalInfo"],
        "ParameterCount": 6
      },
      "Timestamp": "2025-07-06T14:30:22.5234567-07:00"
    },
    {
      "Name": "SystemInfo Class Instantiation",
      "Status": "PASS",
      "Evidence": "Class created: TEST-COMPUTER with all properties valid",
      "Details": {
        "ComputerName": "TEST-COMPUTER",
        "Platform": "Windows",
        "CorrelationId": "0aa9f484-8203-47fa-a5ec-46e109c2e11f"
      },
      "Timestamp": "2025-07-06T14:30:23.1234567-07:00"
    },
    {
      "Name": "Export-SystemInfo Execution",
      "Status": "PASS",
      "Evidence": "JSON file created: test-evidence-2025-07-06-1430.json (390 bytes) with real system data",
      "Details": {
        "OutputFile": "test-evidence-2025-07-06-1430.json",
        "FileSize": 390,
        "Format": "JSON",
        "Records": 1,
        "HasRealData": true,
        "DataSample": {
          "ComputerName": "DESKTOP-dimascior",
          "Platform": "Windows",
          "OS": "Windows 10 Pro",
          "Version": "22H2"
        }
      },
      "Timestamp": "2025-07-06T14:30:25.7234567-07:00"
    }
  ],
  "Summary": {
    "TotalTests": 3,
    "PassedTests": 3,
    "FailedTests": 0,
    "ExecutionTime": "3.6 seconds",
    "Overall": "PASS"
  }
}
```

**Field Validation Requirements (Per CI Gate):**

| Field | Type | Required | CI Check | Validation Rule |
|-------|------|----------|----------|-----------------|
| TestSuite | string | Yes | Job 3 | Must equal "TasksV5-Enhanced-Evidence" |
| Timestamp | ISO8601 datetime | Yes | Job 4 | Must be within execution window (±5 min from CI run) |
| CommitSHA | string | Yes | Job 4 | Must match `git rev-parse --short HEAD` |
| CorrelationId | UUID string | Yes | Job 4 | Must be valid GUID format |
| Environment.PSVersion | string | Yes | Job 3 | Must match matrix version (5.1, 7.4) |
| Environment.PSEdition | string | Yes | Job 3 | Must be "Core" or "Desktop" |
| Environment.OS | string | Yes | Job 3 | Must match matrix OS (Windows, Linux) |
| Tests[].Name | string | Yes | Job 3 | Must reference actual test identifier |
| Tests[].Status | string | Yes | Job 3 | Must be "PASS"; any "FAIL" blocks merge |
| Tests[].Evidence | string | Yes | Job 3 | Must NOT contain "simulated", "mock", "sentinel" |
| Tests[].Timestamp | ISO8601 datetime | Yes | Job 4 | Must be after parent Timestamp |
| Summary.Overall | string | Yes | Job 4 | Must equal "PASS" for merge |

---

### 2. TEST EVIDENCE SCHEMA: ENHANCED TEST BRIDGE OUTPUT

**Location & Naming Convention:**
```
MyExporter/test-evidence-[Timestamp].json
Example: MyExporter/test-evidence-2025-07-06-1430.json
```

**Required JSON Structure:**
```json
{
  "TestSession": {
    "StartTime": "2025-07-06T14:30:22.1234567-07:00",
    "EndTime": "2025-07-06T14:30:25.7234567-07:00",
    "Duration": "3.6 seconds",
    "Status": "SUCCESS"
  },
  "ExecutionEnvironment": {
    "PowerShellVersion": "7.4.0",
    "Edition": "Core",
    "Platform": "Windows",
    "OSVersion": "Windows 10 22H2",
    "ProcessId": 12345,
    "WorkingDirectory": "C:\\dev\\TerminalContextExporter\\MyExporter"
  },
  "TestResults": [
    {
      "TestName": "BasicFunctionality.Export-SystemInfo Parameter Count",
      "Category": "FUNCTIONAL",
      "Result": "PASS",
      "Evidence": "6 parameters detected: ComputerName, OutputPath, Format, UseSSH, AsJson, IncludeTerminalInfo",
      "Details": {
        "ExpectedCount": 6,
        "ActualCount": 6,
        "MatchStatus": "EXACT"
      }
    }
  ],
  "SimulationCheckResults": {
    "MockPatternDetected": false,
    "SentinelPatternDetected": false,
    "SimulatePatternDetected": false,
    "FakeDataDetected": false,
    "OverallStatus": "REAL_DATA_CONFIRMED"
  },
  "ComplianceStatus": {
    "AllTestsPassed": true,
    "NoSimulationDetected": true,
    "RealBoundariesTested": true,
    "EvidenceValid": true,
    "Ready": true
  }
}
```

**Field Validation Requirements:**

| Field | Type | Required | CI Check | Validation Rule |
|-------|------|----------|----------|-----------------|
| TestSession.Status | string | Yes | Job 3 | Must be "SUCCESS" |
| ExecutionEnvironment.PowerShellVersion | string | Yes | Job 3 | Must match matrix version |
| TestResults[].Result | string | Yes | Job 3 | Must be "PASS" for all tests |
| TestResults[].Evidence | string | Yes | Job 3 | Must contain real data evidence |
| SimulationCheckResults.OverallStatus | string | Yes | Job 2 | Must be "REAL_DATA_CONFIRMED" |
| ComplianceStatus.AllTestsPassed | boolean | Yes | Job 4 | Must be true |
| ComplianceStatus.NoSimulationDetected | boolean | Yes | Job 2 | Must be true |
| ComplianceStatus.Ready | boolean | Yes | Job 4 | Must be true for merge |

---

### 3. COMPLIANCE REPORT SCHEMA: AGGREGATED ACROSS MATRIX

**Location & Naming Convention:**
```
GitHub Actions Artifact: compliance-final.json
Downloaded during Job 4: constitutional-compliance-verification
```

**Required JSON Structure:**
```json
{
  "ReportMetadata": {
    "ReportId": "compliance-final-20250706-1430",
    "GeneratedAt": "2025-07-06T14:35:00.0000000-07:00",
    "CIRunId": 1234567890,
    "Repository": "dimascior/TerminalContextExporter",
    "Branch": "main",
    "CommitSHA": "abc12345def67890"
  },
  "ConstitutionalVerification": {
    "DocsPresent": {
      "GuardRails.md": true,
      "MASTER-CONTEXT-FRAMEWORK.md": true,
      "Isolate-Trace-Verify-Loop.md": true,
      "Implementation-Status.md": true,
      "Status": "PASS"
    }
  },
  "MatrixResults": [
    {
      "MatrixId": "windows-latest-ps51",
      "OS": "windows-latest",
      "PowerShellVersion": "5.1",
      "Edition": "Desktop",
      "Status": "PASS",
      "TestCount": 3,
      "PassedCount": 3,
      "FailedCount": 0,
      "SimulationDetected": false
    },
    {
      "MatrixId": "ubuntu-latest-ps74-wsl",
      "OS": "ubuntu-latest",
      "PowerShellVersion": "7.4",
      "Edition": "Core",
      "WSLEnabled": true,
      "TmuxInstalled": true,
      "Status": "PASS",
      "TestCount": 5,
      "PassedCount": 5,
      "FailedCount": 0,
      "SimulationDetected": false
    }
  ],
  "AntiSimulationEnforcement": {
    "AssertNoSimulatedTests": "PASS",
    "MockPatterns": 0,
    "SentinelPatterns": 0,
    "Status": "ENFORCED"
  },
  "SecurityValidation": {
    "TrivyScan": "PASS",
    "Vulnerabilities": 0,
    "Warnings": 0,
    "Status": "SECURE"
  },
  "AggregatedSummary": {
    "TotalMatrixLegs": 3,
    "PassedLegs": 3,
    "FailedLegs": 0,
    "TotalTests": 11,
    "TotalPassed": 11,
    "TotalFailed": 0,
    "AllEvidencePresent": true,
    "NoSimulationDetected": true,
    "ConstitutionalCompliance": "PASS",
    "Ready": true
  },
  "ChangeMetadata": {
    "ContextLevel": 1,
    "FilesChanged": 3,
    "CommitMessage": "Level 1: Add network interface monitoring to SystemInfo",
    "ChangelogUpdated": true,
    "BailoutTriggered": false
  }
}
```

**Field Validation Requirements (Per CI Gate):**

| Field | Type | Required | CI Check | Validation Rule |
|-------|------|----------|----------|-----------------|
| ConstitutionalVerification.DocsPresent.Status | string | Yes | Job 1 | Must be "PASS" |
| MatrixResults[].Status | string | Yes | Job 3 | All must be "PASS" |
| MatrixResults[].SimulationDetected | boolean | Yes | Job 2 | All must be false |
| AntiSimulationEnforcement.Status | string | Yes | Job 2 | Must be "ENFORCED" |
| SecurityValidation.Status | string | Yes | Job 5 | Must be "SECURE" |
| AggregatedSummary.Ready | boolean | Yes | Job 4 | Must be true for merge |
| ChangeMetadata.ContextLevel | integer | Yes | Pre-commit | Must match commit message |
| ChangeMetadata.ChangelogUpdated | boolean | Yes | Job 4 | Must be true |

---

### 4. CORRELATION ID THREADING: TRACEABILITY PATTERN

Every operation produces a GUID that propagates through the entire execution:

```
CorrelationId = "0aa9f484-8203-47fa-a5ec-46e109c2e11f"
  |
  ├─ Function Parameters: -CorrelationId "0aa9f484-8203-47fa-a5ec-46e109c2e11f"
  ├─ Job Arguments: $correlationId passed via -ArgumentList to Invoke-Command
  ├─ Telemetry Events: Every event includes CorrelationId field
  ├─ Output Files: JSON evidence files named with CorrelationId
  ├─ Evidence JSON: CorrelationId stored in root and all nested Test records
  ├─ CI Artifacts: evidence-[CorrelationId].json uploaded by Job 3
  ├─ GitHub Actions: Correlation ID visible in CI logs for root cause analysis
  └─ Merge Decision: Traceability from PR to evidence to test results to commit enabled
```

**Telemetry Batch JSON Format:**
```json
{
  "BatchId": "telemetry-batch-20250706-143000",
  "Timestamp": "2025-07-06T14:30:00.0000000-07:00",
  "Events": [
    {
      "CorrelationId": "0aa9f484-8203-47fa-a5ec-46e109c2e11f",
      "EventName": "Export-SystemInfo-Begin",
      "EventTime": "2025-07-06T14:30:22.1234567-07:00",
      "Duration": 0,
      "Status": "START"
    },
    {
      "CorrelationId": "0aa9f484-8203-47fa-a5ec-46e109c2e11f",
      "EventName": "Export-SystemInfo-End",
      "EventTime": "2025-07-06T14:30:25.7234567-07:00",
      "Duration": 3600,
      "Status": "SUCCESS"
    }
  ]
}
```

---

## PROJECT STRUCTURE: FILE ORGANIZATION & RELATIONSHIPS

### Classes/ - Data Contracts

**SystemInfo.ps1:** PowerShell 5.1 compatible class with:
- Properties: ComputerName, Platform, OS, Version, Source, Timestamp, CorrelationId
- Constructor: Defensive property access; validates ComputerName is present
- Static Factory: FromCim() for CIM object conversion
- Custom ToString methods: ToString(), ToTableString(), ToJsonString()

**TmuxSessionReference.ps1:** Immutable reference class for tmux session state:
- Properties: SessionId, SessionName, IsActive, LastActivity
- Methods: WithUpdatedActivity() returns new instance (functional update pattern)
- Purpose: Enable safe passing via job boundaries without mutable reference concerns

### Private/ - Implementation Layer

**_Initialize.ps1:** Runs first; establishes module context
- Platform detection (Windows/Linux/macOS) using $PSVersionTable
- WSL interop detection ($env:WSL_DISTRO_NAME)
- Sets script-scoped variables: $script:IsWindows, $script:IsLinux, $script:MyExporterContext

**Get-ExecutionContext.ps1:** Comprehensive environment discovery
- Correlation ID generation
- PowerShell edition detection (Desktop vs. Core)
- WSL detection and capability probing
- Cached for performance (5-minute TTL)

**Get-SystemInfo.Windows.ps1:** Windows-specific implementation
- Uses Get-CimInstance Win32_OperatingSystem (modern, WinRM-capable)
- Fallback to Get-WmiObject for older systems
- Returns SystemInfo object

**Get-SystemInfo.Linux.ps1:** Linux-specific implementation
- Uses native commands: uname, lsb_release, /etc/os-release
- SSH support via -UseSSH parameter
- Returns SystemInfo object

**Get-SystemInfoPlatformSpecific.ps1:** Router/dispatcher
- Detects target platform
- Routes to appropriate implementation (Windows/Linux)
- Handles remote execution via Invoke-Command

**Get-TerminalContextPlatformSpecific.ps1:** Terminal capability detection
- Probes for WSL, tmux, WindowsTerminal
- Returns capability routing key
- Cached for 5 minutes

**Invoke-WithTelemetry.ps1:** Wrapper for all operations
- Adds correlation ID to execution context
- Wraps execution time with Stopwatch
- Captures structured errors
- Batches telemetry events (flushes at 50 items or 5 min)

**Assert-ContextPath.ps1:** Cross-platform path normalization
- Detects WSL interop context
- Calls wslpath for Windows path → POSIX conversion
- Normalizes JSON paths to POSIX format
- Prevents path-related errors before execution

**Test-TerminalCapabilities.ps1:** Capability caching layer
- Expensive external process calls (wsl.exe, tmux)
- Results cached 5 minutes
- Manual invalidation via -Force

**Update-StateFileSchema.ps1:** Schema migration
- JSON state file with SchemaVersion
- Automatic v1.0 → v2.0 migration on module load
- Preserves existing data while adding new fields

### Public/ - API Gateway

**Export-SystemInfo.ps1:** Single public entry point
- Parameters: ComputerName (array), OutputPath, Format, UseSSH, AsJson, IncludeTerminalInfo
- Output: CSV or JSON file with SystemInfo objects
- Features: FastPath escape hatch, job-safe loading, correlation ID threading, telemetry integration
- Orchestration: Parameter validation only; delegates to private implementations

### Tests/ - Pester Test Suite

**Export-SystemInfo.Tests.ps1:** Covers public API
- Real execution (no mocks)
- FastPath mode testing
- Normal mode testing
- JSON/CSV output validation

**ClassLoading.Tests.ps1:** Validates class instantiation
- SystemInfo constructor validation
- Property access testing
- JSON round-trip serialization

**TelemetryCompliance.Tests.ps1:** Verifies telemetry patterns
- Correlation ID propagation
- Batching threshold testing
- No telemetry nesting (single Invoke-WithTelemetry per operation)

**TmuxSessionReference.Tests.ps1:** Immutable pattern validation
- WithUpdatedActivity() returns new instance
- Original instance unchanged
- Safe for job passing

### DevScripts/ - CI/Development Only

**Invoke-FreshSession.ps1:** Isolated execution environment
- Spawns fresh PowerShell process
- SessionTag for logging
- -Wait for synchronous execution

**Assert-NoSimulatedTests.ps1:** CI gate blocking mocks
- Scans test files for Mock, Sentinel, Simulate patterns
- Zero tolerance policy
- Prevents cheating the CI pipeline

**Test-Phase1-Compliance.ps1:** Compliance verification
- Manifest validation
- FileList consistency
- Class instantiation

**Test-Phase3-CrossBoundary.ps1:** Cross-process boundary testing
- Job scope testing
- WSL interop testing
- Function injection validation

**Test-Phase5-Functionality.ps1:** Real system testing
- Export-SystemInfo execution
- File output validation
- Data structure validation

### Verification & CI Integration

**Verify-Phase.ps1:** Pre-commit gate (6 checks)
- Test-GuardRailsCompliance: Architecture patterns
- Test-TestCoverage: Public functions have tests
- Test-ApiContract: Module contracts
- Test-FileList: Git tracking, manifest consistency
- Test-ChangelogRequirement: Documentation updated
- Test-PendingSpecs: No pending tests

**enhanced-test-bridge.ps1:** Evidence generation
- Tests all four scenarios: FastPath/Normal × CSV/JSON
- Generates evidence JSON files
- Correlates with commit SHA
- Captures system context (PowerShell version, OS, computer name)

---

## EXTERNAL DEPENDENCIES AND PACKAGES

### Required Modules

The manifest lists no external required modules (RequiredModules = @()).

**Why:** The module is designed for maximum portability and works with built-in PowerShell cmdlets:
- Get-CimInstance (Windows)
- Get-WmiObject (fallback)
- Native commands (Linux): uname, lsb_release, ssh

### Soft Dependencies (Optional)

- **Pester 5.3.0+**: Required for test execution (dev environment only, not shipped)
- **PSScriptAnalyzer**: Required for linting validation (CI environment only)
- **Invoke-Build**: Optional for build task orchestration

### External Commands (Probed at Runtime)

- **wsl.exe**: WSL command on Windows
- **wslpath**: Path conversion utility in WSL
- **tmux**: Terminal multiplexer for session management
- **ssh**: Remote execution when -UseSSH flag used
- **uname, lsb_release**: Linux system info queries

All external command dependencies are probed at runtime via Get-ExecutionContext and Test-TerminalCapabilities. If not found, graceful degradation occurs (fallback implementations or capability flags).

---

## ARCHITECTURAL DESIGN PATTERNS

### 1. Manifest-Driven Architecture

The .psd1 file is the source of truth. All code must conform to:
- PowerShell version floor (5.1)
- Edition compatibility (Desktop, Core)
- Public API contracts (FunctionsToExport)
- Dependency requirements (RequiredModules)
- File enumeration (FileList)

### 2. Platform Dispatcher Pattern

Single routing point (Get-SystemInfoPlatformSpecific) based on capability detection, enabling:
- Easy addition of new platforms
- Centralized platform detection logic
- Isolation of platform-specific code

### 3. Job-Safe Function Loading

Functions aren't serialized across job boundaries. Solution: read source as text, Invoke-Expression in job scope.

Constraints:
- Functions must be deterministic (no external state dependencies)
- Classes must be re-instantiable in job scope
- No mutable objects via -ArgumentList (instead stringify/re-hydrate)

### 4. Immutable Data Contracts

SystemInfo and TmuxSessionReference use immutable patterns:
- Constructors validate and set properties
- Methods return new instances (WithUpdatedActivity)
- No internal state mutation

Benefits:
- Safe to serialize and pass across boundaries
- Predictable behavior in parallel/concurrent scenarios
- Simplifies debugging

### 5. Context-First Initialization

Platform context established once at module load, cached for entire session:
- Eliminates repeated environment probing
- Enables deterministic behavior
- Simplifies parameter passing (context is implicit)

### 6. Correlation ID Threading

Every operation gets a GUID that propagates through:
- Function parameters
- Job arguments
- Telemetry events
- Output files

Enables end-to-end tracing across process/scope boundaries.

### 7. Capability Caching

Expensive external process calls (wsl.exe, tmux) cached with TTL:
- First call: ~500ms (process startup)
- Cached calls: <1ms
- Manual invalidation: -Force flag
- Automatic expiry: 5 minutes

### 8. Telemetry Batching

Telemetry events aren't written immediately. Instead:
- Accumulate in $script:TelemetryBatch
- Flush when size threshold (50 items) or time threshold (5 min) reached
- Reduces I/O overhead at scale

### 9. FastPath Escape Hatch

For development iteration, bypass complex architecture:
- Set $env:MYEXPORTER_FAST_PATH=1
- Skip job management, use synchronous execution
- Trade architectural compliance for development speed
- Production code must pass full architecture

### 10. Anti-Simulation Constitutional Enforcement

Zero-tolerance policy for Mock/Sentinel patterns:
- CI gate Assert-NoSimulatedTests runs before any code
- Rejects any test file with Mock/Sentinel/Simulate keywords
- Prevents cheating the validation framework
- Forces real boundary testing

---

### Primary Users

1. **AI-Assisted Development Teams:** Teams using Claude, Copilot, or other AI agents as collaborative development partners. The framework provides governance structures that enable AI contributions without architectural drift.

2. **Enterprise Development Organizations:** Teams building complex, multi-platform systems requiring deterministic governance and auditability. The constitutional framework provides a model for other languages/platforms.

3. **Cross-Platform System Administrators:** Teams managing heterogeneous environments (Windows, Linux, WSL) needing unified system information collection and reporting.

4. **PowerShell Module Publishers:** Organizations publishing public PowerShell modules to PowerShell Gallery and needing robust cross-edition testing (5.1 and 7.x).

5. **CI/CD Infrastructure Engineers:** Teams implementing enforcement gates and governance automation. This project serves as a reference implementation.

### Use Cases

1. **System Inventory Collection:** Collect and export system configuration from Windows and Linux hosts in unified format.

2. **Compliance Reporting:** Generate audit trails with correlation IDs enabling traceability across system boundaries.

3. **Multi-Platform Monitoring:** Aggregate terminal context information from WSL, Windows PowerShell, and Linux environments.

4. **AI Collaboration Reference:** Demonstrate how to structure a codebase for reliable AI agent contributions without architectural degradation.

5. **CI/CD Template:** Use as a template for implementing constitutional governance in other projects/languages.

---

## AGENTIC SYSTEM INTEGRATION: HOW IT WORKS END-TO-END

### The Three-Phase Handoff

**Phase 1: Constitutional Orientation (30 minutes)**

A new AI agent enters the repository and MUST read in order:
```
1. docs/integration loop/GuardRails.md (Parts 1-3)
   - System boundaries and what patterns are forbidden
   
2. docs/integration loop/CLAUDE.md (Parts 4-7)
   - How to choose context level (1=Essential, 2=Architectural, 3=Environmental)
   - Bailout triggers: if more than 3 files need changing, escalate

3. docs/TaskLoop/Isolate-Trace-Verify-Loop.md
   - How to structure work units
   - What constitutes real vs. simulated validation

4. docs/AssetRecords/Implementation-Status.md
   - What is already implemented
   - What context is available from previous work
```

Machine enforcement: `scripts/verify_master_context.ps1` (lines 98-138) checks all five documents exist. If any is missing, CI fails with CONSTITUTIONAL_BAILOUT. The agent cannot proceed.

**Phase 2: Work Assignment (5 minutes)**

A human or higher-level system provides work in structured format:
```powershell
$WorkUnit = @{
    TaskId = "TASK-20250706-042"
    Objective = "Add CPU monitoring to SystemInfo"
    ContextLevel = 1  # Essential
    BailoutConditions = @("More than 3 files", "API contract changes")
    SuccessCriteria = @(
        "evidence file generated",
        "exit code 0",
        "real system data only",
        "CorrelationId threaded"
    )
    MaxExecutionTime = "90 minutes"
}
```

The agent acknowledges understanding of bailout thresholds and success criteria.

**Phase 3: Systematic Execution (60-90 minutes)**

```
1. ISOLATE: Agent analyzes scope
   ├─ Read: Current implementation of related functions
   ├─ Identify: Affected files (must be ≤3 for Level 1)
   ├─ Check: No API contract changes needed
   └─ Decision: Level 1 sufficient? If not, escalate to Level 2

2. TRACE: Agent implements changes
   ├─ Modify: Only files identified in Isolate phase
   ├─ Follow: Architectural patterns from GuardRails.md
   ├─ Thread: CorrelationId through all operations
   ├─ Run Locally: $env:MYEXPORTER_FAST_PATH=1 for rapid iteration
   └─ Validate: Run Verify-Phase.ps1 locally (must exit 0)

3. VERIFY: Agent generates evidence
   ├─ Run: enhanced-test-bridge.ps1 -TestScenario "All" -CaptureEvidence
   ├─ Generate: evidence-[CorrelationId].json with real system data
   ├─ Check: Summary.Overall = "PASS"
   ├─ Inspect: All tests use real system calls (no mocks)
   └─ Confirm: Files meet JSON schema requirements

4. RECORD: Agent commits with proper context
   ├─ Message: Includes "Level N:" declaration
   ├─ Body: Explains what, why, and how
   ├─ Authority: References GuardRails.md section
   ├─ Evidence: Names generated evidence file
   └─ Example: "Level 1: Add CPU core count to SystemInfo
               CONSTITUTIONAL_AUTHORITY: GuardRails.md Parts 1-3
               EVIDENCE: evidence-2025-07-06-1430.json (390 bytes)"

5. PUSH: Agent pushes to feature branch
   ├─ Branch: feature/[task-name]
   ├─ Push: git push origin feature/[task-name]
   └─ Trigger: GitHub Actions CI pipeline fires immediately
```

**Phase 4: CI Validation (10 minutes total across 5 jobs)**

CI jobs execute sequentially, each validating JSON evidence:

```
Job 1: Constitutional Verification
  ├─ Input: Repository documents
  ├─ Validate: All governance docs exist
  ├─ Output: constitutional-verification-evidence.json
  └─ Block: CONSTITUTIONAL_BAILOUT if any doc missing

Job 2: Anti-Simulation Enforcement
  ├─ Input: Staged test files
  ├─ Validate: No Mock/Sentinel/Simulate patterns
  ├─ Output: anti-simulation-report.json
  └─ Block: Any simulation pattern → FAIL

Job 3: Systematic Validation Matrix (3 legs)
  ├─ Windows PS 5.1:
  │  ├─ Run: enhanced-test-bridge.ps1
  │  ├─ Generate: evidence-windows-51-[timestamp].json
  │  └─ Validate: All tests PASS, real data confirmed
  ├─ Windows PS 7.4:
  │  ├─ Run: enhanced-test-bridge.ps1
  │  └─ Validate: Same as 5.1 leg
  └─ Ubuntu PS 7.4 + WSL + tmux:
     ├─ Run: enhanced-test-bridge.ps1 + real WSL/tmux tests
     ├─ Generate: evidence-ubuntu-74-[timestamp].json
     └─ Validate: 5 tests (includes terminal capability tests)

Job 4: Constitutional Compliance Verification
  ├─ Input: All evidence from Job 3 (3 files)
  ├─ Process: Aggregate into compliance-final.json
  ├─ Validate:
  │  ├─ All matrix legs PASS
  │  ├─ TotalFailed = 0
  │  ├─ NoSimulationDetected = true
  │  ├─ All CorrelationIds valid
  │  └─ Ready flag = true
  ├─ Output: compliance-final.json uploaded as artifact
  └─ Result: AggregatedSummary.Ready determines merge eligibility

Job 5: Security Constitutional Scan
  ├─ Input: All code files
  ├─ Scan: Trivy filesystem security scan
  ├─ Output: SARIF report to GitHub Security tab
  └─ Flag: Vulnerabilities noted but don't block merge (separate policy)
```

**Phase 5: Human Review & Merge (varies)**

Human reviewer knows:
- Constitutional framework was followed (CI enforced it)
- Evidence exists with real data (not simulation)
- All tests passed across 3 platform matrix legs
- CorrelationId enables end-to-end tracing
- 1-year artifact retention for root cause analysis

```
Review Checklist:
  ✓ Commit message has "Level N:" declaration
  ✓ compliance-final.json.Ready = true
  ✓ No architecture drift detected
  ✓ CHANGELOG.md updated appropriately
  ✓ Evidence files contain actual system data
  ✓ Bailout conditions NOT triggered

Merge Gate (Automatic GitHub Enforcement):
  ✓ All 5 CI jobs PASS
  ✓ All required status checks pass
  ✓ At least 1 approval received
  ✓ No merge conflicts
  ✓ Branch protection rules satisfied
  → MERGE BUTTON ENABLED
```

### Key Anti-Corruption Mechanisms

1. **Mandatory Constitutional Reading + CI Enforcement**
   - Agent cannot proceed without reading governance documents
   - CI validates doc presence at Job 1
   - CONSTITUTIONAL_BAILOUT blocks merge if any doc missing

2. **Context Level Tiering (Anti-Drift Architecture)**
   - Level 1 max 3 files: Essential bug fixes
   - Level 2 max 7 files: Architectural changes
   - Level 3 unlimited: Cross-platform/CI changes
   - Escalation rule: If Level 1 discovers 8 files needed, STOP and escalate

3. **Fresh Session Isolation**
   - Every test runs in clean PowerShell process
   - Prevents stale module definitions from interfering
   - Each matrix leg gets isolated session

4. **Real Boundary Testing (Anti-Simulation)**
   - Assert-NoSimulatedTests blocks Mock/Sentinel patterns at Job 2
   - Zero tolerance policy
   - All WSL/tmux tests use real binaries, not simulation

5. **Evidence-Based Completion Gates**
   - Work not "done" until evidence files exist with real data
   - JSON schema validation at every CI gate
   - Byte counts, timestamps, and CorrelationIds immutable for audit trail

6. **Correlation ID Threading for Traceability**
   - Every operation gets GUID at Get-ExecutionContext.ps1
   - ID propagates through: functions → jobs → telemetry → files → CI artifacts
   - Enables root cause analysis across process boundaries

7. **Immutable Data Structures**
   - SystemInfo and TmuxSessionReference use immutable patterns
   - Safe to pass across job boundaries
   - Prevents concurrent mutation bugs

8. **Capability Caching**
   - Expensive environment probes cached 5 minutes
   - First call ~500ms, subsequent calls <1ms
   - Enables rapid iteration without external process overhead

### Failure Recovery Flowchart

```
Agent runs: enhanced-test-bridge.ps1
  |
  ├─ PASS → evidence-[CorrelationId].json generated
  │   └─ git add . && git commit && git push
  │       └─ GitHub Actions triggered
  │           ├─ Job 1: PASS
  │           ├─ Job 2: PASS
  │           ├─ Job 3: PASS
  │           │   └─ compliance-final.json generated
  │           │       └─ Ready = true → MERGE ALLOWED
  │           └─ Merge to main successful
  │
  └─ FAIL → Tests failed, Summary.Overall != "PASS"
      ├─ Check: test-evidence-[timestamp].json for details
      ├─ Identify: Which test failed in ComplianceStatus
      ├─ Debug Using: CorrelationId to trace execution
      ├─ Fix: Modify code based on test failure
      ├─ Re-run: enhanced-test-bridge.ps1 with new CorrelationId
      └─ Loop: Until all tests PASS
```
---

## PUSHING CHANGES: COMPLETE PUSH-TO-MERGE VALIDATION FLOW

### Phase 1: Local Pre-Push Validation

```powershell
# 1. Make code changes to module
Edit-Item MyExporter/Private/Get-SystemInfo.Windows.ps1

# 2. Run local compliance check
.\MyExporter\Verify-Phase.ps1
# Exit code must be 0; checks 6 gates:
#   - Guardrait compliance patterns
#   - Test coverage validation
#   - API contract validation
#   - Git file tracking
#   - CHANGELOG recency
#   - No pending test blocks

# 3. Generate evidence files locally
.\MyExporter\enhanced-test-bridge.ps1 -TestScenario "All" -CaptureEvidence
# Output: evidence-[timestamp].json, test-evidence-[timestamp].json
# CorrelationId auto-generated and threaded through all operations

# 4. Verify evidence JSON structure
$evidenceFile = Get-ChildItem -Path . -Filter "evidence-*.json" | Select-Object -First 1
$evidence = Get-Content $evidenceFile.FullName | ConvertFrom-Json
if ($evidence.TestSuite -ne "TasksV5-Enhanced-Evidence") {
    throw "TestSuite mismatch"
}
if ($evidence.Summary.Overall -ne "PASS") {
    throw "Evidence indicates test failure"
}
Write-Host "Evidence valid: $($evidenceFile.Name)"
Write-Host "  CorrelationId: $($evidence.CorrelationId)"
Write-Host "  Tests passed: $($evidence.Summary.PassedTests)/$($evidence.Summary.TotalTests)"
```

### Phase 2: Git Commit with Proper Context Level

```bash
# 1. Stage changes
git add .

# 2. Pre-commit hook validation runs automatically
# Checks:
#   - Commit message contains "Level N:" (N = 1, 2, or 3)
#   - File count matches context level
#   - No simulation patterns in staged files

# 3. Commit with level declaration
git commit -m "Level 1: Add network interface property to SystemInfo

Added NetworkInterfaces array to support interface enumeration.
Follows CorrelationId threading pattern for traceability.
Real system data validated in test evidence.

CONSTITUTIONAL_AUTHORITY: GuardRails.md Parts 1-3
EVIDENCE: evidence-2025-07-06-1430.json (390 bytes)"

# 4. Verify commit
git log -1 --oneline
# Output: abc12345 (Level 1: Add network interface...)
```

### Phase 3: Push to Remote

```bash
# 1. Create feature branch (if not already created)
git checkout -b feature/network-interface

# 2. Push to GitHub
git push origin feature/network-interface
# This triggers GitHub Actions CI pipeline immediately
```

### Phase 4: CI/CD Pipeline Execution (5 Sequential Jobs)

**Job 1: Constitutional Verification (2-3 min)**
```
Input: Repository files
Process:
  ├─ Check: docs/integration\ loop/GuardRails.md exists
  ├─ Check: docs/MASTER-CONTEXT-FRAMEWORK.md exists
  ├─ Check: docs/TaskLoop/Isolate-Trace-Verify-Loop.md exists
  └─ Check: docs/AssetRecords/Implementation-Status.md exists
Output: constitutional-verification-evidence.json
Status: PASS → Continue to Job 2; FAIL → BAILOUT
```

**Job 2: Anti-Simulation Enforcement (1-2 min)**
```
Input: Changed test files
Process:
  ├─ Scan for Mock patterns
  ├─ Scan for Sentinel patterns
  ├─ Scan for Simulate patterns
  └─ Scan for FakeData patterns
Output: anti-simulation-report.json
Status: Any pattern found → REJECT & FAIL
        No patterns → Continue to Job 3
```

**Job 3: Systematic Validation Matrix (5-8 min per leg, 3 legs total)**
```
Matrix Configuration:
  ├─ Leg 1: Windows PS 5.1 (Desktop edition)
  ├─ Leg 2: Windows PS 7.4 (Core edition)
  └─ Leg 3: Ubuntu + PS 7.4 + WSL + tmux (for terminal tests)

Per-Leg Process:
  ├─ enhanced-test-bridge.ps1 -TestScenario "All"
  ├─ Generate: evidence-windows-51-[timestamp].json
  ├─ Validate: All tests PASS, real system data confirmed
  └─ Compare: Results against baseline

Output: evidence-[matrix-id]-[timestamp].json for each leg
Status: All legs PASS → Continue to Job 4
        Any leg FAIL → Matrix fails, blocks merge
```

**Job 4: Constitutional Compliance Verification (2-3 min)**
```
Input: All evidence files from Job 3
Process:
  ├─ Aggregate all evidence files
  ├─ Create: compliance-final.json
  ├─ Validate:
  │   ├─ All matrix legs present and PASS
  │   ├─ No simulation detected anywhere
  │   ├─ All real data confirmed
  │   ├─ CorrelationIds valid and traceable
  │   ├─ CHANGELOG.md updated
  │   └─ CommitSHA matches current HEAD
  ├─ Upload: compliance-final.json as artifact
  └─ Generate: compliance summary for GitHub check status

Output: compliance-final.json with AggregatedSummary
Status: Ready == true → Continue to Job 5
        Ready == false → Blocks merge
```

**Job 5: Security Constitutional Scan (3-4 min)**
```
Input: All code files
Process:
  ├─ Trivy filesystem scan
  ├─ Check for vulnerable dependencies
  ├─ Generate SARIF report
  └─ Upload to GitHub Security tab

Output: SARIF report, security-scan-results.json
Status: Vulnerabilities found → Flag but don't block
        All secure → PASS
```

### Phase 5: GitHub Checks & Status

After all 5 jobs complete, GitHub Actions reports:
```
Commit Status Checks:
  ✓ constitutional-verification (PASS)
  ✓ anti-simulation-enforcement (PASS)
  ✓ systematic-validation-matrix (PASS - 3 legs)
  ✓ constitutional-compliance-verification (PASS)
  ✓ security-constitutional-scan (PASS)

Branch Protection Rules Check:
  ✓ All required status checks pass
  ✓ All evidence artifacts present
  ✓ compliance-final.json.Ready = true
  ✓ No merge conflicts
  → MERGE BUTTON ENABLED
```

### Phase 6: Pull Request & Code Review

```
PR Details:
  ├─ Title: (auto-generated from commit message)
  ├─ Description: (auto-generated from commit body)
  ├─ CI Status: All jobs PASS (visible as green checkmark)
  ├─ Evidence Link: compliance-final.json available in artifacts
  ├─ Reviewers: Assigned based on code ownership
  └─ Changes: 3 files changed, 24 insertions

Review Checklist:
  ├─ Code changes follow architectural patterns
  ├─ Tests are real (not mocked)
  ├─ Evidence files show real data
  ├─ CorrelationIds threaded correctly
  ├─ CHANGELOG updated appropriately
  └─ No architectural drift detected

Reviewer Approval:
  ├─ Requires minimum 1 approval (configurable)
  └─ No changes requested (or changes resolved)
```

### Phase 7: Merge to Main

```bash
# 1. GitHub merge strategy: Squash & Rebase (enforced by branch protection)
git merge --squash feature/network-interface

# 2. Final commit message includes "Level N:" declaration
# Squash ensures single, clean commit to main

# 3. Post-merge validation: CI runs again on main
# Ensures merged state is valid

# 4. Artifact retention: evidence-*.json artifacts kept for 365 days (1 year)
# Enables root cause analysis if issues arise post-merge
```

### Evidence Files: Complete Reference

| File | Purpose | Generated By | Contents |
|------|---------|--------------|----------|
| evidence-[CorrelationId].json | Primary evidence | enhanced-test-bridge.ps1 | TestSuite, CorrelationId, Tests[], Summary |
| test-evidence-[Timestamp].json | Detailed test results | enhanced-test-bridge.ps1 | TestSession, TestResults[], SimulationCheckResults |
| compliance-final.json | Aggregated compliance | Job 4 CI | MatrixResults[], AggregatedSummary, Ready flag |
| constitutional-verification-evidence.json | Doc verification | Job 1 CI | DocsPresent[], CrossReferences |
| anti-simulation-report.json | Simulation scan | Job 2 CI | MockPatterns, SentinelPatterns, Status |
| security-scan-results.json | Security scan | Job 5 CI | Vulnerabilities, Warnings, SARIF report |

### Failure Scenarios & JSON Error Structures

**Simulation Detected Error:**
```json
{
  "Error": {
    "Code": "SIMULATION_DETECTED",
    "Severity": "CRITICAL",
    "Message": "Anti-simulation gate blocked CI execution",
    "Details": {
      "Pattern": "Mock",
      "File": "Tests/Export-SystemInfo.Tests.ps1",
      "Line": 42,
      "Content": "Mock Get-CimInstance -MockWith $mockData"
    },
    "Action": "REJECT - Remove Mock patterns and use real system calls"
  }
}
```

**Evidence File Missing Error:**
```json
{
  "Error": {
    "Code": "EVIDENCE_MISSING",
    "Severity": "CRITICAL",
    "Message": "No evidence files generated for matrix leg",
    "Details": {
      "MatrixLeg": "windows-latest-ps74",
      "Expected": "evidence-windows-74-[timestamp].json",
      "Found": 0
    },
    "Action": "BAILOUT - Run enhanced-test-bridge.ps1 locally to debug"
  }
}
```

**Correlation ID Mismatch Error:**
```json
{
  "Error": {
    "Code": "CORRELATION_MISMATCH",
    "Severity": "CRITICAL",
    "Message": "Correlation ID not threaded through execution",
    "Details": {
      "Expected": "0aa9f484-8203-47fa-a5ec-46e109c2e11f",
      "Problem": "Different GUIDs across test results"
    },
    "Action": "BAILOUT - Ensure CorrelationId passed to all functions"
  }
}
```

### Quick Reference: Minimum JSON Evidence Checklist

**Before Pushing:**
```
[ ] evidence-[timestamp].json generated locally
[ ] TestSuite = "TasksV5-Enhanced-Evidence"
[ ] All Tests[].Status = "PASS"
[ ] No Tests[].Evidence contains ("mock" | "simulated" | "sentinel")
[ ] Summary.Overall = "PASS"
[ ] CorrelationId is valid GUID
[ ] File size > 100 bytes (ensures real data)
```

**For Merge Decision:**
```
[ ] compliance-final.json created by CI
[ ] MatrixResults all have Status = "PASS"
[ ] AggregatedSummary.Ready = true
[ ] TotalFailed = 0 across all legs
[ ] NoSimulationDetected = true
[ ] ConstitutionalCompliance = "PASS"
[ ] Commit message has "Level N:" declaration
[ ] CHANGELOG.md updated within last 7 days
```

### JSON Fields That Block Merge

| Field | Blocks If | Reason | Resolution |
|-------|-----------|--------|------------|
| Tests[].Status | Any except "PASS" | Test failed | Debug test locally, fix, re-push |
| Tests[].Evidence | Contains simulation keywords | Cheating CI | Rewrite test using real system calls |
| SimulationCheckResults.OverallStatus | Anything except "REAL_DATA_CONFIRMED" | Not real data | Remove Mock/Sentinel, use real binaries |
| AggregatedSummary.Ready | false | Not ready | Check compliance-final.json for details |
| ConstitutionalCompliance | Anything except "PASS" | Constitutional violation | Review GuardRails.md, check CHANGELOG |
| MatrixResults[].Status | Any "FAIL" | Platform test failed | Review evidence-[platform].json for errors |
| SecurityValidation.Status | Anything except "SECURE" | Security issue | Trivy scan found vulnerability |

---

## PUSHING CHANGES: MECHANICAL SUMMARY

### ** Root Directory Architecture**

```
WorkflowDynamics/                    # Master Framework Implementation
├── .gitignore                       # Git exclusions (test outputs, temp files)
├── README.md                        # Framework documentation and usage guide
├── scripts/                         # CONSTITUTIONAL ENFORCEMENT AUTOMATION
│   ├── verify_master_context.ps1    # PowerShell constitutional verification (enhanced Unicode)
│   ├── verify_master_context.sh     # POSIX-compliant constitutional verification
│   └── constitutional-verification-evidence.json # Validation evidence & audit trail
├── docs/                            # Framework Knowledge Base & Analysis (Modular Organization)
│   ├── MASTER-CONTEXT-FRAMEWORK.md  # Full-spectrum project awareness & constitutional unity
│   ├── ThreeTierWorkflow.md         # Progressive context anchoring system with bailout triggers
│   ├── integration loop/            # CONSTITUTIONAL FOUNDATION LAYER
│   │   ├── GuardRails.md            # PRIMARY FRAMEWORK SPECIFICATION (Parts 1-3)
│   │   ├── CLAUDE.md                # AI collaboration framework (Parts 4-7)
│   │   └── Claude_Prompting_Templates.md # Prompt engineering templates
│   ├── TaskLoop/                    # WORK EXECUTION DISCIPLINE LAYER
│   │   ├── Isolate-Trace-Verify-Loop.md # Implementation execution discipline
│   │   ├── build-suite-discipline.md    # Architectural build discipline
│   │   └── WorkOrders/              # Task state tracking & evolution
│   │       └── tasksV5.md               # Current active task list (single source of truth)
│   ├── AssetRecords/                # PROGRESS TRACKING & EVIDENCE LAYER
│   │   ├── Implementation-Status.md     # Current state tracking
│   │   └── CHANGELOG.md                 # Historical tracking & evidence correlation
│   └── AgenticContextTools/         # AI COLLABORATION ANALYSIS
│       ├── MCD.md                   # Model-Centric Design patterns & anti-over-engineering
│       └── GuardRail.md             # Additional guardrail patterns
└── MyExporter/                      #  REFERENCE IMPLEMENTATION MODULE
    ├── MyExporter.psd1              # Constitutional Layer - Immutable contracts (manifest)
    ├── MyExporter.psm1              # Architectural Layer - Module orchestration root
    ├── .artifacts/                  # Build artifacts and evidence (excluded from VCS .gitignore)
    │   ├── evidence/
    │   │   ├── local/               # Local development evidence
    │   │   │   └── evidence-local-*.json
    │   │   └── baseline/            # GitHub Actions baseline evidence (historical archive)
    │   │       ├── evidence-2025-07-06-2319.json
    │   │       ├── evidence-2025-07-06-2322.json
    │   │       ├── evidence-2025-07-06-2325.json
    │   │       ├── evidence-2025-07-06-2326.json
    │   │       └── evidence-2025-07-06-2327.json
    │   └── test-results/            # Test execution artifacts
    │       ├── evidence-local-*.json # Historical local evidence
    │       ├── test-evidence-*.json  # Test output files
    │       └── test-output.json
    ├── Classes/                     # Data Contract Layer (strong typing)
    │   ├── SystemInfo.ps1           # PowerShell 5.1 compatible class
    │   └── TmuxSessionReference.ps1 # Immutable tmux session state class
    ├── Private/                     # Implementation Layer - Internal functions (30 files)
    │   ├── _Initialize.ps1          # Context establishment ($script scope)
    │   ├── Add-TerminalContextToSystemInfo.ps1 # Helper for terminal data enrichment
    │   ├── Assert-ContextPath.ps1   # Cross-platform path validation
    │   ├── Assert-ContextualPath.ps1 # Legacy function (superseded)
    │   ├── Get-CurrentSession.ps1   # Current execution session detection
    │   ├── Get-ExecutionContext.ps1 # Environmental context discovery
    │   ├── Get-SystemInfo.Windows.ps1 # Windows-specific system info
    │   ├── Get-SystemInfo.Linux.ps1 # Linux-specific system info
    │   ├── Get-SystemInfoPlatformSpecific.ps1 # Platform router/dispatcher
    │   ├── Get-TerminalContext.WSL.ps1 # WSL terminal capability detection
    │   ├── Get-TerminalContextPlatformSpecific.ps1 # Terminal capability router
    │   ├── Get-TerminalOutput.WSL.ps1 # WSL terminal output capture
    │   ├── Invoke-WithTelemetry.ps1 # Correlation ID threading wrapper
    │   ├── Invoke-WslTmuxCommand.ps1 # WSL tmux integration
    │   ├── New-TmuxArgumentList.ps1 # Tmux argument builder
    │   ├── TerminalTelemetryBatcher.ps1 # Telemetry event batching
    │   ├── Test-CommandSafety.ps1   # Command safety validation
    │   ├── Test-TerminalCapabilities.ps1 # Terminal capability probing
    │   └── Update-StateFileSchema.ps1 # Schema migration for state files
    ├── Public/                      # Public API Layer - single entry point
    │   └── Export-SystemInfo.ps1    # Main cmdlet (FastPath + job-safe execution)
    ├── Policies/                    # Security policy definitions
    │   ├── terminal.deny.yml        # Terminal access deny policy
    │   └── terminal-deny.yaml       # Terminal access deny policy (alt format)
    ├── Tests/                       # Pester test suite (7 test files)
    │   ├── ClassAvailability.Tests.ps1 # Class loading validation
    │   ├── ClassLoading.Tests.ps1   # PowerShell 5.1 class compatibility
    │   ├── Export-SystemInfo.Tests.ps1 # Public API functional tests
    │   ├── Initialize-WSLUser.bats  # Bash Automated Testing Suite
    │   ├── TelemetryCompliance.Tests.ps1 # Correlation ID threading
    │   ├── Test-TmuxArgumentList.ps1 # Tmux argument builder tests
    │   └── TmuxSessionReference.Tests.ps1 # Immutable pattern validation
    ├── compare-evidence-sets.ps1    # Evidence comparison (SHA mismatch handling)
    ├── download-actions-evidence.ps1 # GitHub Actions artifact download
    ├── enhanced-test-bridge.ps1     # Evidence generation with real tests
    ├── Initialize-WSLUser.sh        # WSL user initialization script
    ├── normalize-evidence-for-comparison.ps1 # Evidence normalization
    ├── test-evidence-analysis.ps1   # Evidence interpretation framework
    ├── test-evidence-reproducibility-verification.ps1 # Reproducibility gate (local vs. Actions)
    ├── Test-TmuxAvailability.ps1    # Tmux capability verification
    └── Verify-Phase.ps1             # Pre-commit validation (8 gates)
```

---

##  **Framework Layer**

### **1. Constitutional Foundation Layer (docs/integration loop/)**
**Primary Files:** `GuardRails.md`, `CLAUDE.md`, constitutional verification scripts

| File | GuardRails Function | Framework Purpose |
|------|-------------------|------------------|
| **docs/integration loop/GuardRails.md** | **PRIMARY CONSTITUTION** | Immutable foundation (Parts 1-3). All system boundaries and constitutional law. |
| **docs/integration loop/CLAUDE.md** | **AI Collaboration Framework** | Level 1-3 context anchoring, prompt templates, collaboration discipline. |
| **scripts/verify_master_context.ps1/.sh** | **Constitutional Enforcement** | Automated validation of cross-document constitutional integrity. |
| **docs/MASTER-CONTEXT-FRAMEWORK.md** | **Full-Spectrum Unity Restorer** | Bridges modular organization to prevent context fragmentation. |

**Core Principle:** These files establish the **non-negotiable constitutional foundation** that all other layers must respect.

### **2. Work Execution Discipline Layer (docs/TaskLoop/)**
**Primary Files:** Isolate-Trace-Verify methodology, build discipline, task evolution

| Component | GuardRails Pattern | Architecture Purpose |
|-----------|-------------------|---------------------|
| **Isolate-Trace-Verify-Loop.md** | **Implementation Discipline** | Systematic work execution methodology. Evidence-based validation loops. |
| **build-suite-discipline.md** | **Architectural Discipline** | Build system patterns and architectural compliance enforcement. |
| **WorkOrders/tasksV5.md** | **Project Manager Persistence** | Active task state tracking. Work achievement clarity and continuity. |
| **WorkOrders/tasks.md → tasksV5.md** | **Task Evolution Tracking** | Historical progression of task definitions and completion evidence. |

**Core Principle:** Work discipline **prevents tail-chasing** and maintains **evidence-based progress** tracking.

### **3. Progress Tracking & Evidence Layer (docs/AssetRecords/)**
**Primary Files:** Implementation status, constitutional enforcement evidence, historical tracking

| File | GuardRails Section | Implementation Purpose |
|------|-------------------|----------------------|
| **Implementation-Status.md** | **State Tracking** | Current implementation state, root cause analysis, progress correlation. |
| **Constitutional-Hooks-Implementation-Summary.md** | **Anti-Drift Evidence** | Constitutional hook implementation status, enforcement mechanism validation. |
| **status.md** | **Real-Time Progress** | Live development status tracking with cross-document correlation. |
| **CHANGELOG.md** | **Historical Evidence** | Complete audit trail of all changes with constitutional compliance validation. |
| **operation-context.xml** | **Complex Task Context** | Operation manifests for complex multi-boundary tasks. |

### **4. AI Collaboration Tools Layer (docs/AgenticContextTools/)**  
**Primary Files:** AI interaction patterns, analysis tools, anti-pattern guidance

| Component | GuardRails Section | Collaboration Purpose |
|-----------|-------------------|---------------------|
| **CCSummary.md** | **Cross-Platform Context** | Platform-specific awareness and boundary management. |
| **MCD.md** | **Anti-Pattern Guidance** | Prevents over-engineering, maintains pragmatic focus. |
| **ChatgptDeepRe*.md** | **Deep Analysis Evolution** | Iterative analysis patterns (V1/V2/V3) for complex problems. |
| **GuardRail.md** | **Additional Patterns** | Supplementary guardrail patterns and enforcement mechanisms. |

### **5. Constitutional Enforcement Infrastructure**
**Primary Files:** Automated validation, pre-commit hooks, evidence correlation

| Component | Constitutional Function | Enforcement Purpose |
|-----------|------------------------|-------------------|
| **scripts/verify_master_context.ps1** | **PowerShell Constitutional Gate** | Enhanced Unicode support, Windows-compatible validation. |
| **scripts/verify_master_context.sh** | **POSIX Constitutional Gate** | BusyBox/Dash compatible, cross-platform enforcement. |
| **constitutional-verification-evidence.json** | **Audit Trail** | Evidence logging with timestamps, correlation IDs, validation status. |
| **MyExporter/Pre-commit integration** | **Git-Level Enforcement** | Prevents commits without constitutional compliance validation. |

### **2. Architectural Layer (GuardRails.md Part 2)**  
**Files:** `MyExporter.psm1`, `/Classes/`, `/Private/`, `/Public/` directory structure

| Component | GuardRails Pattern | Architecture Purpose |
|-----------|-------------------|---------------------|
| **MyExporter.psm1** | **Module Orchestration** | Root module loader implementing deterministic loading sequence. Controls scope boundaries. |
| **/Classes/** | **Data Contract Enforcer** | Strong typing with PowerShell 5.1 compatibility. Self-validating data structures. |
| **/Private/** | **Implementation Isolation** | Verb-noun-platform naming. Platform-specific logic separation. Job-safe function definitions. |
| **/Public/** | **API Gateway** | Single entry point (`Export-SystemInfo`). Parameter validation and orchestration only. |

**Core Principle:** Directory topology **reveals architectural intent**. Structure is self-documenting.

### **3. Implementation Layer (GuardRails.md Part 3)**
**Files:** All `.ps1` files in `/Private/` and `/Public/`

#### **Critical Implementation Files:**

| File | GuardRails Section | Implementation Purpose |
|------|-------------------|----------------------|
| **Export-SystemInfo.ps1** | **11.3 Job-Safe Loading** | Public API with FastPath escape hatch. Implements job-safe function injection. |
| **Get-SystemInfoPlatformSpecific.ps1** | **Platform Dispatcher** | Routes to platform-specific implementations. Avoids `$ExecutionContext` collision. |
| **Get-SystemInfo.Windows.ps1** | **Platform Implementation** | Windows-specific system information collection via CIM/WinRM. |
| **Get-SystemInfo.Linux.ps1** | **Platform Implementation** | Linux-specific collection via native commands and SSH support. |
| **Invoke-WithTelemetry.ps1** | **Selective Telemetry** | Correlation ID propagation. Avoids telemetry-everywhere anti-pattern. |
| **Get-ExecutionContext.ps1** | **Environmental Discovery** | Cross-platform context detection (WSL/Windows/PowerShell editions). |
| **Assert-ContextPath.ps1** | **Path Validation** | Cross-platform path normalization. POSIX compliance for JSON output. |

### **4. Adaptive Collaboration Layer (GuardRails.md Part 4)**
**Files:** `/docs/CLAUDE.md`, execution bridges, test files

#### **AI Collaboration Infrastructure:**

| Component | GuardRails Section | Collaboration Purpose |
|-----------|-------------------|---------------------|
| **CLAUDE.md** | **4.1 Progressive Context Anchoring** | Prompt templates for Level 1/2/3 complexity management. |
| **claude-powershell-bridge.bat** | **12.2 Dynamic Path Resolution** | WSL→Windows PowerShell execution bridge. Implements Part 10 operational flow. |
| **claude-wsl-launcher.sh** | **Cross-Platform Orchestration** | Linux script orchestrating Windows PowerShell execution. |
| **claude-direct-test.sh** | **Simplified Testing** | Direct command execution for rapid validation. |
| **operation-context.xml** | **5.1 Artifact-Based Context** | Operation manifest preventing context loss during complex tasks. |

---

##  **Core Workflow Patterns (LLM + GuardRails.md Integration)**

### **Pattern 1: Level 1 (Essential) Development Workflow**

```powershell
# CLAUDE PROMPT TEMPLATE:
CONTEXT: MyExporter Dynamic & Adaptive Architecture project
CONSTITUTIONAL_AUTHORITY: docs/integration loop/GuardRails.md Parts 1-3
MASTER_CONTEXT: docs/MASTER-CONTEXT-FRAMEWORK.md (mandatory reading)
TASK: [specific objective]
FASTPATH: Use $env:MYEXPORTER_FAST_PATH=true for quick testing
EXECUTE: Use claude-powershell-bridge.bat for validation

# IMPLEMENTATION FLOW:
0. Constitutional Validation: .\scripts\verify_master_context.ps1
1. Edit MyExporter files (following GuardRails.md patterns)
2. Execute: ./claude-powershell-bridge.bat
3. Validate: FastPath mode testing with correlation IDs
4. Verify: Output files contain expected data structure
5. Evidence: Check constitutional-verification-evidence.json
```

### **Pattern 2: Level 2 (Architectural) Development Workflow**

```powershell
# CLAUDE PROMPT TEMPLATE:
CONTEXT: MyExporter GuardRails.md Level 2 (Architectural)
CONSTITUTIONAL_READING: docs/integration loop/GuardRails.md → docs/integration loop/CLAUDE.md → docs/TaskLoop/Isolate-Trace-Verify-Loop.md
MASTER_CONTEXT: Full-spectrum awareness via docs/MASTER-CONTEXT-FRAMEWORK.md
TASK: [complex objective involving multiple components]
PATTERNS: Apply GuardRails.md [specific section] methodology
ISOLATE-TRACE-VERIFY: Use systematic component analysis
BAILOUT_IF: More than 3 files need modification
EXECUTE: Full testing via claude-wsl-launcher.sh

# IMPLEMENTATION FLOW:
1. ISOLATE: Target specific component set (e.g., job execution)
2. TRACE: Follow dependency chain through module boundaries
3. VERIFY: Registry validation (Get-Module vs manifest)
4. INTEGRATE: Apply changes with telemetry correlation
5. VALIDATE: All four test scenarios (FastPath/Normal × CSV/JSON)
```

### **Pattern 3: Level 3 (Environmental) Development Workflow**

```powershell
# CLAUDE PROMPT TEMPLATE:
CONTEXT: MyExporter cross-platform execution (WSL2/Windows/PowerShell 5.1+7.x)
TASK: [platform-specific objective]
WSL_PATHS: Handle path translation between Linux and Windows
EXECUTION_BRIDGE: Use claude-powershell-bridge.bat for cross-interpreter testing
TELEMETRY: Ensure correlation IDs propagate through scope boundaries
VALIDATE: Test across all target environments

# IMPLEMENTATION FLOW:
1. Environmental Context Discovery (Get-ExecutionContext)
2. Cross-Platform Path Normalization (Assert-ContextPath)
3. Platform-Specific Implementation (Get-SystemInfo.*.ps1)
4. Job-Safe Function Loading (GuardRails.md 11.3)
5. End-to-End Validation across WSL/Windows/PowerShell editions
```

---

##  **Framework Classes & Core Components**

### **SystemInfo Class (Constitutional Data Contract)**
```powershell
# Location: /Classes/SystemInfo.ps1
# GuardRails Section: Part 3.1 - Data Contracts and Strong Typing

class SystemInfo {
    [string]$ComputerName    # Mandatory field with validation
    [string]$Platform        # Windows/Linux/macOS detection
    [string]$OS             # Operating system details
    [string]$Version        # OS version information
    [string]$Source         # Collection method (CIM/WinRM/SSH/Direct)
    [datetime]$Timestamp    # Collection timestamp
    [string]$CorrelationId  # End-to-end telemetry tracking
    
    # PowerShell 5.1 compatible constructor with defensive property access
    SystemInfo([hashtable]$data) {
        # Implements GuardRails.md constitutional validation patterns
    }
}
```

### **Export-SystemInfo Cmdlet (Public API Gateway)**
```powershell
# Location: /Public/Export-SystemInfo.ps1
# GuardRails Section: Part 11.3 - Job-Safe Function Loading

function Export-SystemInfo {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)] [string[]]$ComputerName,
        [Parameter(Mandatory)] [string]$OutputPath,
        [switch]$UseSSH,
        [switch]$AsJson
    )
    
    # FASTPATH ESCAPE HATCH (GuardRails.md 4.2)
    if ($env:MYEXPORTER_FAST_PATH) {
        # Direct execution bypassing job architecture
    }
    
    # ARCHITECTURAL PATTERN (GuardRails.md 11.1)
    $forward = @{
        UseSSH = $UseSSH
        Context = Get-ExecutionContext  # Renamed to avoid $ExecutionContext collision
    }
    
    # JOB-SAFE FUNCTION LOADING (GuardRails.md 11.3)
    Start-Job -ScriptBlock {
        param($functionDefs)
        Invoke-Expression $functionDefs  # Re-hydrate functions in job context
    }
}
```

### **Execution Bridge Infrastructure (Cross-Platform Orchestration)**
```batch
REM Location: claude-powershell-bridge.bat
REM GuardRails Section: Part 10 - Operational Flow

@echo off
REM Implements GuardRails.md Part 10 operational flow from WSL environment
REM Tests all four scenarios: FastPath/Normal × CSV/JSON
REM Validates correlation ID propagation and telemetry integration
REM Provides evidence files for TasksV3 completion validation
```

---


##  **Framework Success Evidence & Validation**

### **Constitutional Enforcement Evidence**
All constitutional validation demonstrates successful anti-drift implementation:

| File | Purpose | Constitutional Validation |
|------|---------|--------------------------|
| **scripts/constitutional-verification-evidence.json** | Automated constitutional compliance audit | Cross-document correlation validated |
| **docs/AssetRecords/Constitutional-Hooks-Implementation-Summary.md** | Anti-drift enforcement status | Constitutional hooks active across all docs |
| **scripts/verify_master_context.ps1/.sh** | Constitutional integrity validation | GuardRails.md authority chain intact |

### **Artifacts**
All validation files demonstrate successful GuardRails.md implementation:

| File | Size | Purpose | GuardRails Validation |
|------|------|---------|---------------------|
| **final-test-fastpath.csv** | 226 bytes | FastPath CSV output | Anti-tail-chasing pattern working |
| **final-test-fastpath.json** | 288 bytes | FastPath JSON output | Escape hatch operational |
| **final-test-normal.csv** | 306 bytes | Normal mode CSV | Job-safe function loading working |
| **final-test-normal.json** | 390 bytes | Normal mode JSON | Correlation ID telemetry successful |

### **Framework Methodology Validation**
- **Constitutional Foundation**: GuardRails.md authority established across modular organization
- **Modular Unity**: MASTER-CONTEXT-FRAMEWORK.md prevents fragmentation, maintains full-spectrum awareness
- **Work Execution Discipline**: TaskLoop/ methodology enforces Isolate-Trace-Verify evidence-based validation
- **Progress Tracking**: AssetRecords/ provides comprehensive state tracking and audit trails
- **AI Collaboration Tools**: AgenticContextTools/ maintains systematic AI interaction patterns
- **Constitutional Enforcement**: Automated scripts ensure cross-document constitutional integrity
- **Anti-Drift Mechanisms**: Constitutional hooks active, organizational modularity serving project goals

---

