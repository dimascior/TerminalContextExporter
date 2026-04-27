<#
.SYNOPSIS
Full CI/CD Pipeline Orchestration (5 Phases)

.DESCRIPTION
Complete constitutional compliance verification pipeline.
Runs all 5 gates in sequence, stopping on first failure.

.EXAMPLE
.\DevScripts\Run-FullPipeline.ps1
#>

[CmdletBinding()]
param()

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "CONSTITUTIONAL CI/CD PIPELINE" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

$PipelineStart = Get-Date
$DevScriptsPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $DevScriptsPath)
$DocsPath = Join-Path $ProjectRoot "docs"

$PhaseResults = @()

# ============================================================================
# Phase 1: Constitutional Verification
# ============================================================================
Write-Host "[PHASE 1/5] Constitutional Verification" -ForegroundColor Yellow
Write-Host "-----" -ForegroundColor Yellow

$Phase1Start = Get-Date
& "$DevScriptsPath\Test-Phase1-Compliance.ps1" -DocsPath $DocsPath
$Phase1Exit = $LASTEXITCODE
$Phase1Duration = ((Get-Date) - $Phase1Start).TotalSeconds

if ($Phase1Exit -ne 0) {
    Write-Host ""
    Write-Host "[BAILOUT] Phase 1 failed" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Phase 1 PASS" -ForegroundColor Green
Write-Host ""

$PhaseResults += @{
    Phase = "1-Constitutional"
    Duration = $Phase1Duration
    Status = "PASS"
}

# ============================================================================
# Phase 2: Anti-Simulation Enforcement
# ============================================================================
Write-Host "[PHASE 2/5] Anti-Simulation Enforcement" -ForegroundColor Yellow
Write-Host "-----" -ForegroundColor Yellow

$Phase2Start = Get-Date
$TestPath = Join-Path $ProjectRoot "MyExporter\Tests"
$EvidencePath = Join-Path $ProjectRoot "MyExporter\.artifacts\evidence\local"
& "$DevScriptsPath\Assert-NoSimulatedTests.ps1" -TestPath $TestPath -EvidencePath $EvidencePath -FailOnSimulation $true
$Phase2Exit = $LASTEXITCODE
$Phase2Duration = ((Get-Date) - $Phase2Start).TotalSeconds

if ($Phase2Exit -ne 0) {
    Write-Host ""
    Write-Host "[REJECT] Phase 2 failed" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Phase 2 PASS" -ForegroundColor Green
Write-Host ""

$PhaseResults += @{
    Phase = "2-AntiSimulation"
    Duration = $Phase2Duration
    Status = "PASS"
}

# ============================================================================
# Phase 3: Systematic Validation Matrix
# ============================================================================
Write-Host "[PHASE 3/5] Systematic Validation Matrix" -ForegroundColor Yellow
Write-Host "-----" -ForegroundColor Yellow

$Phase3Start = Get-Date
& "$DevScriptsPath\Test-Phase3-CrossBoundary.ps1"
$Phase3Exit = $LASTEXITCODE
$Phase3Duration = ((Get-Date) - $Phase3Start).TotalSeconds

if ($Phase3Exit -ne 0) {
    Write-Host ""
    Write-Host "[FAILED] Phase 3 failed" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Phase 3 PASS" -ForegroundColor Green
Write-Host ""

$PhaseResults += @{
    Phase = "3-Matrix"
    Duration = $Phase3Duration
    Status = "PASS"
}

# ============================================================================
# Phase 4: Constitutional Compliance Verification
# ============================================================================
Write-Host "[PHASE 4/5] Constitutional Compliance Verification" -ForegroundColor Yellow
Write-Host "-----" -ForegroundColor Yellow

$Phase4Start = Get-Date
$OutputFile = Join-Path $EvidencePath "compliance-final.json"
& "$DevScriptsPath\New-ComplianceFinalJson.ps1" -DocsPath $DocsPath -EvidencePath $EvidencePath -OutputFile $OutputFile
$Phase4Exit = $LASTEXITCODE
$Phase4Duration = ((Get-Date) - $Phase4Start).TotalSeconds

if ($Phase4Exit -ne 0) {
    Write-Host ""
    Write-Host "[BLOCKED] Phase 4 failed" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Phase 4 PASS" -ForegroundColor Green
Write-Host ""

$PhaseResults += @{
    Phase = "4-Compliance"
    Duration = $Phase4Duration
    Status = "PASS"
}

# ============================================================================
# Phase 5: Security Constitutional Scan
# ============================================================================
Write-Host "[PHASE 5/5] Security Constitutional Scan" -ForegroundColor Yellow
Write-Host "-----" -ForegroundColor Yellow

$Phase5Start = Get-Date
& "$DevScriptsPath\Test-Phase5-Security.ps1" -EvidencePath $EvidencePath
$Phase5Exit = $LASTEXITCODE
$Phase5Duration = ((Get-Date) - $Phase5Start).TotalSeconds

Write-Host "[OK] Phase 5 COMPLETE" -ForegroundColor Green
Write-Host ""

$PhaseResults += @{
    Phase = "5-Security"
    Duration = $Phase5Duration
    Status = "PASS"
}

# ============================================================================
# FINAL SUMMARY
# ============================================================================
$PipelineEnd = Get-Date
$TotalDuration = ($PipelineEnd - $PipelineStart).TotalSeconds

Write-Host "=================================================" -ForegroundColor Green
Write-Host "PIPELINE SUMMARY" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

foreach ($Result in $PhaseResults) {
    $Duration = [Math]::Round($Result.Duration, 1)
    Write-Host ("  Phase " + $Result.Phase + ": " + $Result.Status + " (" + $Duration + "s)") -ForegroundColor Green
}

Write-Host ""
$Total = [Math]::Round($TotalDuration, 1)
Write-Host ("Total Duration: " + $Total + " seconds")
Write-Host ""
Write-Host "[SUCCESS] All gates PASSED - READY FOR MERGE" -ForegroundColor Green
Write-Host ""
Write-Host "Evidence files generated (centralized in .artifacts/evidence/local/):"
Write-Host "  - constitutional-verification-TIMESTAMP.json (Phase 1)"
Write-Host "  - anti-simulation-report-TIMESTAMP.json (Phase 2)"
Write-Host "  - evidence-local-TIMESTAMP.json (Phase 3)"
Write-Host "  - test-evidence-TIMESTAMP.json (Phase 3 bridge)"
Write-Host "  - compliance-final.json (Phase 4)"
Write-Host "  - security-scan-TIMESTAMP.json (Phase 5)"
Write-Host ""

exit 0
