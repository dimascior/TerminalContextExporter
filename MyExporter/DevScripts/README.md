# DevScripts - Constitutional CI/CD Gates

DevScripts implements the CI/CD validation pipeline described in the main README.

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
.\DevScripts\Assert-NoSimulatedTests.ps1 -TestPath ./Tests
```

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

```powershell
cd MyExporter

# Phase 1: Constitutional Verification
.\DevScripts\Test-Phase1-Compliance.ps1
if ($LASTEXITCODE -ne 0) { exit 1 }

# Phase 2: Anti-Simulation
.\DevScripts\Assert-NoSimulatedTests.ps1
if ($LASTEXITCODE -ne 0) { exit 1 }

# Phase 3: Matrix Validation
.\DevScripts\Test-Phase3-CrossBoundary.ps1
if ($LASTEXITCODE -ne 0) { exit 1 }

# Phase 4: Compliance Aggregation
.\DevScripts\New-ComplianceFinalJson.ps1
if ($LASTEXITCODE -ne 0) { exit 1 }

# Phase 5: Security Scan
.\DevScripts\Test-Phase5-Security.ps1

echo "✓ ALL GATES PASSED"
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

## Future Enhancements

- [ ] Add Ubuntu/WSL matrix leg (requires Linux PS runtime)
- [ ] Integrate GitHub Actions CI.yml to call these scripts
- [ ] Add Trivy automated install when unavailable
- [ ] Create .git/hooks installation helper
- [ ] Add compliance report visualization dashboard
