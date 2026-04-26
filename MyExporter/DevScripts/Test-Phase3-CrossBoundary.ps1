<#
.SYNOPSIS
Job 3: Systematic Validation Matrix (Phase 3) - Cross-Boundary Testing

.DESCRIPTION
Runs enhanced-test-bridge.ps1 as isolated matrix legs.
Currently supports 2 legs (Windows PS 5.1 and PS 7.4).
In future: add Ubuntu/WSL leg when Windows-hosted Linux testing available.

Each leg generates isolated evidence-[leg-id]-[timestamp].json

.PARAMETER MatrixLegs
Array of matrix leg configurations

.EXAMPLE
.\Test-Phase3-CrossBoundary.ps1
#>

[CmdletBinding()]
param()

$CommitSHA = git rev-parse --short HEAD 2>$null
if ([string]::IsNullOrEmpty($CommitSHA)) { $CommitSHA = "unknown" }

$MatrixConfig = @{
    Timestamp = Get-Date -Format 'O'
    CommitSHA = $CommitSHA
    Legs = @(
        @{
            Name = "Windows-PS51-Desktop"
            PSVersion = "5.1"
            Edition = "Desktop"
            Platform = "Windows"
            Enabled = $PSVersionTable.PSVersion.Major -eq 5
        }
        @{
            Name = "Windows-PS74-Core"
            PSVersion = "7.4+"
            Edition = "Core"
            Platform = "Windows"
            Enabled = $PSVersionTable.PSVersion.Major -ge 7
        }
    )
}

Write-Host "[PHASE-3] Systematic Validation Matrix Starting"
Write-Host "[INFO] Current environment: PS $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"
Write-Host ""

$Results = @()
$PassedLegs = 0
$FailedLegs = 0

foreach ($Leg in $MatrixConfig.Legs) {
    # Only run legs that match current environment
    if (-not $Leg.Enabled) {
        Write-Host "⊘ Skipped: $($Leg.Name) (not in current environment)" -ForegroundColor Gray
        continue
    }
    
    Write-Host "[LEG] Starting: $($Leg.Name)"
    Write-Host "  PS Version: $($Leg.PSVersion)"
    Write-Host "  Edition: $($Leg.Edition)"
    Write-Host ""
    
    try {
        # Run enhanced-test-bridge for this leg
        # Script is in MyExporter/DevScripts, so bridge is at MyExporter/enhanced-test-bridge.ps1
        $DevScriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        $MyExporterRoot = Split-Path -Parent $DevScriptsDir
        $BridgePath = Join-Path $MyExporterRoot "enhanced-test-bridge.ps1"
        
        if (-not (Test-Path $BridgePath)) {
            Write-Host "  ❌ enhanced-test-bridge.ps1 not found at $BridgePath" -ForegroundColor Red
            $FailedLegs++
            $Results += @{
                Leg = $Leg.Name
                Status = "FAIL"
                Error = "Test script not found"
                EvidenceFile = $null
            }
            continue
        }
        
        # Execute test bridge
        Write-Host "  Executing: .$BridgePath"
        $Output = & $BridgePath -CaptureEvidence 2>&1
        
        # Look for generated evidence file
        $EvidenceFiles = Get-ChildItem -Path ".artifacts/evidence/local" -Filter "evidence-local-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        
        if ($EvidenceFiles) {
            $EvidenceFile = $EvidenceFiles.Name
            $Evidence = Get-Content -Path $EvidenceFiles.FullName | ConvertFrom-Json
            
            if ($Evidence.Summary.Overall -eq "PASS") {
                Write-Host "  ✓ Tests PASSED" -ForegroundColor Green
                Write-Host "    Evidence: $EvidenceFile ($($EvidenceFiles.Length) bytes)" -ForegroundColor Green
                $PassedLegs++
                
                $Results += @{
                    Leg = $Leg.Name
                    Status = "PASS"
                    EvidenceFile = $EvidenceFile
                    TestCount = $Evidence.Summary.TotalTests
                    PassedCount = $Evidence.Summary.PassedTests
                    CorrelationId = $Evidence.CorrelationId
                }
            }
            else {
                Write-Host "  ❌ Tests FAILED" -ForegroundColor Red
                Write-Host "    Evidence: $EvidenceFile" -ForegroundColor Red
                $FailedLegs++
                
                $Results += @{
                    Leg = $Leg.Name
                    Status = "FAIL"
                    EvidenceFile = $EvidenceFile
                    Error = $Evidence.Summary.Overall
                }
            }
        }
        else {
            Write-Host "  ❌ No evidence file generated" -ForegroundColor Red
            $FailedLegs++
            $Results += @{
                Leg = $Leg.Name
                Status = "FAIL"
                Error = "Evidence not generated"
            }
        }
    }
    catch {
        Write-Host "  ❌ Exception: $_" -ForegroundColor Red
        $FailedLegs++
        $Results += @{
            Leg = $Leg.Name
            Status = "FAIL"
            Error = $_.Exception.Message
        }
    }
    
    Write-Host ""
}

# Summary
Write-Host "═══════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "MATRIX SUMMARY" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  Legs Passed: $PassedLegs"
Write-Host "  Legs Failed: $FailedLegs"
Write-Host ""

if ($FailedLegs -eq 0) {
    Write-Host "✓ ALL MATRIX LEGS PASSED" -ForegroundColor Green
    Write-Host "  Proceeding to Job 4: Constitutional Compliance Verification"
}
else {
    Write-Host "❌ MATRIX FAILED" -ForegroundColor Red
    Write-Host "  Review failed leg evidence files for details"
}

Write-Host "═══════════════════════════════════════════" -ForegroundColor Yellow

if ($FailedLegs -eq 0) {
    exit 0
}
else {
    exit 1
}
