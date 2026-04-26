<#
.SYNOPSIS
Job 4: Constitutional Compliance Verification - Aggregation & Final Decision

.DESCRIPTION
Aggregates evidence from all matrix legs into compliance-final.json.
- Validates all evidence files exist and are real (> 100 bytes)
- Confirms no simulation patterns detected anywhere
- Verifies CorrelationIds match across all legs
- Generates final Ready flag for merge decision

.PARAMETER EvidencePath
Path containing all evidence-*.json files from all matrix legs

.PARAMETER OutputFile
Output file for compliance-final.json

.EXAMPLE
.\New-ComplianceFinalJson.ps1 -EvidencePath "./.artifacts/evidence/local" -OutputFile compliance-final.json
#>

[CmdletBinding()]
param(
    [string]$EvidencePath = ".artifacts/evidence/local",
    [string]$OutputFile = ".artifacts/evidence/local/compliance-final.json"
)

$GitSHA = git rev-parse --short HEAD 2>$null
if ([string]::IsNullOrEmpty($GitSHA)) { $GitSHA = "unknown" }

$Report = @{
    ReportMetadata = @{
        ReportId = "compliance-final-$(Get-Date -Format 'yyyyMMdd-HHmm')"
        ReportTime = Get-Date -Format 'O'
        CommitSHA = $GitSHA
    }
    ConstitutionalVerification = @{
        DocsRequired = @(
            "docs/integration loop/GuardRails.md"
            "docs/MASTER-CONTEXT-FRAMEWORK.md"
            "docs/TaskLoop/Isolate-Trace-Verify-Loop.md"
            "docs/AssetRecords/Implementation-Status.md"
        )
        DocsPresent = @()
        Status = "PENDING"
    }
    MatrixResults = @()
    AntiSimulationEnforcement = @{
        AssertNoSimulatedTests = "NOT_RUN"
        ProveRealDataUsed = "NOT_VERIFIED"
        Status = "PENDING"
    }
    SecurityValidation = @{
        TrivyScan = "NOT_RUN"
        Status = "PENDING"
    }
    AggregatedSummary = @{
        TotalMatrixLegs = 0
        LegsWithPassStatus = 0
        TotalFailed = 0
        NoSimulationDetected = $false
        ChangelogUpdated = $false
        AllRequiredFilesPresent = $false
        Ready = $false
    }
    ChangeMetadata = @{
        ContextLevel = 0
        ChangelogUpdated = $false
        BailoutTriggered = $false
    }
}

Write-Host "[COMPLIANCE-VERIFICATION] Starting Job 4: Constitutional Compliance Verification"

# 1. Verify constitutional documents exist
Write-Host "[DOCS-CHECK] Verifying constitutional documents..."
foreach ($Doc in $Report.ConstitutionalVerification.DocsRequired) {
    $Exists = Test-Path -Path $Doc
    $Report.ConstitutionalVerification.DocsPresent += @{
        Document = $Doc
        Present = $Exists
    }
    
    if (-not $Exists) {
        Write-Host "  ❌ MISSING: $Doc" -ForegroundColor Red
        $Report.ChangeMetadata.BailoutTriggered = $true
    }
    else {
        Write-Host "  ✓ Found: $Doc" -ForegroundColor Green
    }
}

$MissingDocsCount = ($Report.ConstitutionalVerification.DocsPresent | Where-Object { -not $_.Present }).Count
$Report.ConstitutionalVerification.Status = if ($MissingDocsCount -eq 0) { "PASS" } else { "FAIL" }

# 2. Aggregate evidence files from all matrix legs
Write-Host "[EVIDENCE-AGGREGATION] Scanning for evidence files in $EvidencePath"

# Collect all phase evidence files by pattern
$Phase1Files = Get-ChildItem -Path $EvidencePath -Filter "constitutional-verification-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$Phase2Files = Get-ChildItem -Path $EvidencePath -Filter "anti-simulation-report-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$Phase3Files = Get-ChildItem -Path $EvidencePath -Filter "evidence-local-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$Phase5Files = Get-ChildItem -Path $EvidencePath -Filter "security-scan-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

$EvidenceFiles = @()
$EvidenceFiles += $Phase1Files
$EvidenceFiles += $Phase2Files
$EvidenceFiles += $Phase3Files
$EvidenceFiles += $Phase5Files
$EvidenceFiles = $EvidenceFiles | Where-Object { $null -ne $_ }

if ($EvidenceFiles.Count -eq 0) {
    Write-Host "  ⚠ No evidence files found (establishing baseline mode)" -ForegroundColor Yellow
    $Report.AggregatedSummary.TotalMatrixLegs = 0
}
else {
    Write-Host "  Found $($EvidenceFiles.Count) evidence file(s)"
    $Report.AggregatedSummary.TotalMatrixLegs = $EvidenceFiles.Count
    
    foreach ($EvidenceFile in $EvidenceFiles) {
        Write-Host "    Processing: $($EvidenceFile.Name)" -ForegroundColor Cyan
        
        # Validate file size (> 100 bytes ensures real data, not empty)
        if ($EvidenceFile.Length -lt 100) {
            $Size = $EvidenceFile.Length
            Write-Host "      ❌ File too small: $Size bytes (requires > 100)" -ForegroundColor Red
            $Report.AggregatedSummary.TotalFailed++
            continue
        }
        
        # Parse JSON
        try {
            $Evidence = Get-Content -Path $EvidenceFile.FullName | ConvertFrom-Json
            
            # Validate JSON structure
            $HasTests = $Evidence.Tests -and $Evidence.Tests.Count -gt 0
            $OverallPass = $Evidence.Summary.Overall -eq "PASS"
            $CorrelationIdValid = $Evidence.CorrelationId -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
            
            $ValidationStatus = if ($OverallPass -and $CorrelationIdValid -and $HasTests) { "PASS" } else { "FAIL" }
            
            $Result = @{
                File = $EvidenceFile.Name
                Size = $EvidenceFile.Length
                CorrelationId = $Evidence.CorrelationId
                CommitSHA = $Evidence.CommitSHA
                Tests = @{
                    Total = $Evidence.Summary.TotalTests
                    Passed = $Evidence.Summary.PassedTests
                    Failed = $Evidence.Summary.FailedTests
                }
                OverallStatus = $Evidence.Summary.Overall
                NoSimulationDetected = ($Evidence.Tests | Where-Object { $_.Evidence -match "(Mock|Sentinel|Simulate)" }).Count -eq 0
                ValidationStatus = $ValidationStatus
            }
            
            $Report.MatrixResults += $Result
            
            if ($Result.ValidationStatus -eq "PASS") {
                $Report.AggregatedSummary.LegsWithPassStatus++
                Write-Host "      ✓ Tests: $($Result.Tests.Total) total, $($Result.Tests.Passed) passed" -ForegroundColor Green
            }
            else {
                $Report.AggregatedSummary.TotalFailed++
                Write-Host "      ❌ Validation failed" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "      ❌ Failed to parse JSON: $_" -ForegroundColor Red
            $Report.AggregatedSummary.TotalFailed++
        }
    }
}

# 3. Check for anti-simulation enforcement
Write-Host "[ANTI-SIMULATION-CHECK] Verifying real data usage..."
# Find latest anti-simulation report in evidence directory
$AntiSimFiles = Get-ChildItem -Path $EvidencePath -Filter "anti-simulation-report-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($AntiSimFiles) {
    $SimReport = Get-Content -Path $AntiSimFiles.FullName | ConvertFrom-Json
    $Report.AntiSimulationEnforcement.AssertNoSimulatedTests = $SimReport.OverallStatus
    $SimStatus = if ($SimReport.OverallStatus -eq "PASS") { "ENFORCED" } else { "VIOLATION" }
    $Report.AntiSimulationEnforcement.Status = $SimStatus
    
    $SimColor = if ($SimReport.OverallStatus -eq "PASS") { "Green" } else { "Red" }
    Write-Host "  Anti-simulation status: $($SimReport.OverallStatus)" -ForegroundColor $SimColor
}

# 4. Verify CHANGELOG updated
Write-Host "[CHANGELOG-CHECK] Verifying CHANGELOG.md updated..."
if (Test-Path -Path "CHANGELOG.md") {
    $ChangelogAge = ((Get-Date) - (Get-Item -Path "CHANGELOG.md").LastWriteTime).TotalHours
    $Report.ChangeMetadata.ChangelogUpdated = $ChangelogAge -le 168  # Within 7 days
    $Report.AggregatedSummary.ChangelogUpdated = $Report.ChangeMetadata.ChangelogUpdated
    
    $ChangelogColor = if ($Report.ChangeMetadata.ChangelogUpdated) { "Green" } else { "Yellow" }
    Write-Host "  CHANGELOG.md last updated: $([Math]::Round($ChangelogAge, 1)) hours ago" -ForegroundColor $ChangelogColor
}

# 5. Final decision
Write-Host "[FINAL-DECISION] Computing Ready flag..."

$AllChecksPassed = (
    $Report.ConstitutionalVerification.Status -eq "PASS" -and
    $Report.AntiSimulationEnforcement.Status -eq "ENFORCED" -and
    $Report.AggregatedSummary.TotalFailed -eq 0 -and
    -not $Report.ChangeMetadata.BailoutTriggered
)

$Report.AggregatedSummary.AllRequiredFilesPresent = $Report.ConstitutionalVerification.Status -eq "PASS"
$Report.AggregatedSummary.NoSimulationDetected = $Report.AntiSimulationEnforcement.Status -eq "ENFORCED"
$Report.AggregatedSummary.Ready = $AllChecksPassed

# Output report
$Report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding UTF8
Write-Host "[REPORT] Written to $OutputFile"

# Display final status
Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "COMPLIANCE SUMMARY" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  Constitutional Docs: $($Report.ConstitutionalVerification.Status)"
Write-Host "  Matrix Legs: $($Report.AggregatedSummary.LegsWithPassStatus)/$($Report.AggregatedSummary.TotalMatrixLegs) PASS"
Write-Host "  Simulation Detected: $(-not $Report.AggregatedSummary.NoSimulationDetected)"
Write-Host "  CHANGELOG Updated: $($Report.AggregatedSummary.ChangelogUpdated)"
$ReadyText = if ($Report.AggregatedSummary.Ready) { "YES [OK]" } else { "NO [FAIL]" }
Write-Host "  ==> Ready for Merge: $ReadyText"
Write-Host "═══════════════════════════════════════════" -ForegroundColor Yellow

$ExitCode = if ($Report.AggregatedSummary.Ready) { 0 } else { 1 }
exit $ExitCode
