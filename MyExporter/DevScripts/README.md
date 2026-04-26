# DevScripts - Constitutional CI/CD Gates

DevScripts implements the CI/CD validation pipeline described in the main README.

## Quick Start

Run the complete 5-phase pipeline:

```powershell
cd MyExporter
.\DevScripts\Run-FullPipeline.ps1
```

This orchestrator runs all phases in sequence and stops on first failure. Exit code 0 = ready for merge.

**For individual phase testing:**

| Phase | Command | Purpose |
|-------|---------|---------|
| 1 | `.\DevScripts\Test-Phase1-Compliance.ps1` | Constitutional docs |
| 2 | `.\DevScripts\Assert-NoSimulatedTests.ps1 -TestPath ./Tests -FailOnSimulation $true` | Anti-simulation check |
| 3 | `.\DevScripts\Test-Phase3-CrossBoundary.ps1` | Matrix validation |
| 4 | `.\DevScripts\New-ComplianceFinalJson.ps1 -EvidencePath ./.artifacts/evidence/local` | Aggregation |
| 5 | `.\DevScripts\Test-Phase5-Security.ps1` | Security scan |

## Scripts Overview

### Job 1: Constitutional Verification
**File:** `Test-Phase1-Compliance.ps1`

Validates that all required constitutional documents exist. Blocks merge if any document is missing (CONSTITUTIONAL_BAILOUT).

```powershell
.\DevScripts\Test-Phase1-Compliance.ps1
```

### Job 2: Anti-Simulation Enforcement  
**File:** `Assert-NoSimulatedTests.ps1`

Zero-tolerance policy: scans test files for Mock, Sentinel, Simulate, FakeData patterns.
Any pattern found blocks merge.

```powershell
# Correct parameters (CI calling convention):
.\DevScripts\Assert-NoSimulatedTests.ps1 -TestPath ./Tests -FailOnSimulation $true
```

**Parameters:**
- `-TestPath`: Path to scan for simulated tests (required)
- `-FailOnSimulation`: Boolean - if $true, throw terminating error on detection (default: $true)

**Note:** Use `-FailOnSimulation` (not `-FailOnSimulated`)

### Job 3: Systematic Validation Matrix
**File:** `Test-Phase3-CrossBoundary.ps1`

Runs enhanced-test-bridge.ps1 as isolated matrix legs.
Supports 2 legs currently:
- Windows PS 5.1 (Desktop)
- Windows PS 7.4 (Core)

```powershell
.\DevScripts\Test-Phase3-CrossBoundary.ps1
```

### Job 4: Constitutional Compliance Verification
**File:** `New-ComplianceFinalJson.ps1`

Aggregates evidence from all matrix legs into compliance-final.json.
Final decision point: determines Ready flag for merge eligibility.

```powershell
.\DevScripts\New-ComplianceFinalJson.ps1 -EvidencePath .artifacts/evidence/local
```

### Job 5: Security Constitutional Scan
**File:** `Test-Phase5-Security.ps1`

Scans for hardcoded credentials, version compliance, and runs Trivy if available.
Does NOT block merge (separate policy), but flags issues.

```powershell
.\DevScripts\Test-Phase5-Security.ps1
```

## Utility Scripts

### Invoke-FreshSession
Spawns isolated PowerShell process for testing.

```powershell
./DevScripts/Invoke-FreshSession.ps1 -ScriptBlock { 
    Import-Module MyExporter
    Export-SystemInfo 
} -SessionTag "test-leg-1" -Wait $true
```

### Validate-CommitMessage
Pre-commit hook for validating commit message format.

```powershell
./DevScripts/Validate-CommitMessage.ps1 -CommitMessageFile .git/COMMIT_EDITMSG
```

## Running Full Pipeline Locally

Easiest way - use the orchestrator:

```powershell
cd MyExporter
.\DevScripts\Run-FullPipeline.ps1
```

Or run phases manually (useful for debugging):

```powershell
cd MyExporter

# Phase 1: Constitutional Verification
.\DevScripts\Test-Phase1-Compliance.ps1
if ($LASTEXITCODE -ne 0) { exit 1 }

# Phase 2: Anti-Simulation
.\DevScripts\Assert-NoSimulatedTests.ps1 -TestPath ./Tests -FailOnSimulation $true
if ($LASTEXITCODE -ne 0) { exit 1 }

# Phase 3: Matrix Validation
.\DevScripts\Test-Phase3-CrossBoundary.ps1
if ($LASTEXITCODE -ne 0) { exit 1 }

# Phase 4: Compliance Aggregation
.\DevScripts\New-ComplianceFinalJson.ps1 -EvidencePath ./.artifacts/evidence/local
if ($LASTEXITCODE -ne 0) { exit 1 }

# Phase 5: Security Scan
.\DevScripts\Test-Phase5-Security.ps1

echo "All gates PASSED - ready for merge"
```

## Evidence Files Generated

Each job produces evidence files in `.artifacts/`:

| Phase | Output File | Purpose |
|-------|-------------|---------|
| Job 1 | `constitutional-verification-evidence.json` | Document existence proof |
| Job 2 | `anti-simulation-report.json` | Mock/Sentinel scan results |
| Job 3 | `evidence-local-[timestamp].json` | Per-leg test results |
| Job 4 | `compliance-final.json` | Final aggregated decision |
| Job 5 | `security-scan-results.json` | Security findings |

## Parameters Reference

**Assert-NoSimulatedTests.ps1** (Job 2)
```powershell
-TestPath <string>           # Required: Path to scan for simulated tests (e.g., ./Tests)
-FailOnSimulation <bool>     # Optional: Throw error if patterns detected (default: $true)
                             # Use $true for CI, $false for warnings only
```

**New-ComplianceFinalJson.ps1** (Job 4)
```powershell
-EvidencePath <string>       # Optional: Path to evidence files (default: ./.artifacts/evidence/local)
-OutputPath <string>         # Optional: Where to write compliance-final.json (default: .)
```

**Invoke-FreshSession.ps1** (Utility)
```powershell
-ScriptBlock <scriptblock>   # Required: PowerShell code to execute in isolated session
-SessionTag <string>         # Optional: Label for job tracking
-Wait <bool>                 # Optional: Wait for job completion (default: $true)
```

**Validate-CommitMessage.ps1** (Pre-commit hook)
```powershell
-CommitMessageFile <string>  # Optional: Path to commit message (default: .git/COMMIT_EDITMSG)
```

**Run-FullPipeline.ps1** (Orchestrator)
```powershell
# No parameters - runs all 5 phases automatically
./DevScripts/Run-FullPipeline.ps1
```

**Test-Phase1-Compliance.ps1**, **Test-Phase3-CrossBoundary.ps1**, **Test-Phase5-Security.ps1**
```powershell
# No parameters required
.\DevScripts\Test-Phase1-Compliance.ps1
.\DevScripts\Test-Phase3-CrossBoundary.ps1
.\DevScripts\Test-Phase5-Security.ps1
```

## Future Enhancements

- [ ] Add Ubuntu/WSL matrix leg (requires Linux PS runtime)
- [ ] Integrate GitHub Actions CI.yml to call these scripts
- [ ] Add Trivy automated install when unavailable
- [ ] Create .git/hooks installation helper
- [ ] Add compliance report visualization dashboard
