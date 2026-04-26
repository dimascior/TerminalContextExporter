#Requires -Version 5.1

<#
.SYNOPSIS
    Test evidence reproducibility: compare local vs GitHub Actions evidence
.DESCRIPTION
    Verifies that local test evidence matches GitHub Actions target evidence.
    Handles first-commit baseline establishment, different PowerShell versions,
    and machine-specific field normalization. Returns pass/fail for merge gate.
    
    Authority: README.md § Evidence Reproducibility Verification
    
.PARAMETER LocalEvidencePath
    Path to local evidence files (supports wildcards)
    
.PARAMETER MatrixLeg
    Matrix leg identifier for artifact retrieval (e.g., 'PS-7.4-Windows')
    
.PARAMETER CommitSHA
    Current commit SHA for Actions artifact lookup (default: $env:GITHUB_SHA)
    
.OUTPUTS
    Exit code 0 (PASS) or 1 (FAIL) for merge gates
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$LocalEvidencePath = (Join-Path (Split-Path $PSScriptRoot -Parent) "MyExporter/evidence-local-*.json"),
    
    [Parameter(Mandatory = $false)]
    [string]$MatrixLeg = 'PS-7.4-Windows',
    
    [Parameter(Mandatory = $false)]
    [string]$CommitSHA = $env:GITHUB_SHA
)

$ErrorActionPreference = 'Stop'

function Write-ReproducibilityStatus {
    param([string]$Message, [string]$Status = 'INFO')
    $Color = switch ($Status) {
        'PASS' { 'Green' }
        'FAIL' { 'Red' }
        'WARN' { 'Yellow' }
        default { 'Cyan' }
    }
    Write-Host "[$Status] $Message" -ForegroundColor $Color
}

# Find local evidence files
$localFiles = @(Get-Item $LocalEvidencePath -ErrorAction SilentlyContinue)

if ($localFiles.Count -eq 0) {
    Write-ReproducibilityStatus "No local evidence files found at: $LocalEvidencePath" 'WARN'
    Write-ReproducibilityStatus "Skipping reproducibility check - may be first execution" 'INFO'
    exit 0
}

Write-ReproducibilityStatus "Found $($localFiles.Count) local evidence file(s)" 'INFO'

# Create temporary directory for Actions artifacts
$tempDir = Join-Path $env:TEMP "evidence-comparison-$([guid]::NewGuid())"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    # Download Actions evidence
    Write-ReproducibilityStatus "Downloading GitHub Actions evidence for commit: $CommitSHA" 'INFO'
    
    $downloadScript = Join-Path $PSScriptRoot "download-actions-evidence.ps1"
    if (-not (Test-Path $downloadScript)) {
        throw "Download script not found: $downloadScript"
    }
    
    $downloadResult = & $downloadScript `
        -CommitSHA $CommitSHA `
        -OutputDirectory $tempDir `
        -MatrixLeg $MatrixLeg `
        -ErrorAction Stop
    
    if (-not $downloadResult.Success) {
        Write-ReproducibilityStatus "Download failed: $($downloadResult.Message)" 'FAIL'
        exit 1
    }
    
    # Handle baseline establishment (first commit)
    if ($downloadResult.Mode -eq 'baseline-establishment') {
        Write-ReproducibilityStatus "Baseline establishment mode: $($downloadResult.Message)" 'INFO'
        Write-ReproducibilityStatus "First evidence run - establishing baseline for future comparison" 'INFO'
        exit 0
    }
    
    Write-ReproducibilityStatus "Retrieved evidence from: $($downloadResult.Mode)" 'INFO'
    
    if ($downloadResult.EvidenceFiles.Count -eq 0) {
        Write-ReproducibilityStatus "No Actions evidence files retrieved" 'WARN'
        exit 0
    }
    
    # Normalize evidence files
    Write-ReproducibilityStatus "Normalizing evidence for comparison" 'INFO'
    
    $normalizeScript = Join-Path $PSScriptRoot "normalize-evidence-for-comparison.ps1"
    if (-not (Test-Path $normalizeScript)) {
        throw "Normalize script not found: $normalizeScript"
    }
    
    $normalizedLocal = @()
    foreach ($file in $localFiles) {
        $normalized = & $normalizeScript -EvidencePath $file.FullName
        $normalizedLocal += $normalized
    }
    
    $normalizedActions = @()
    foreach ($file in $downloadResult.EvidenceFiles) {
        $normalized = & $normalizeScript -EvidencePath $file
        $normalizedActions += $normalized
    }
    
    Write-ReproducibilityStatus "Normalized $($normalizedLocal.Count) local and $($normalizedActions.Count) Actions evidence files" 'INFO'
    
    # Compare evidence
    Write-ReproducibilityStatus "Comparing evidence sets" 'INFO'
    
    $compareScript = Join-Path $PSScriptRoot "compare-evidence-sets.ps1"
    if (-not (Test-Path $compareScript)) {
        throw "Compare script not found: $compareScript"
    }
    
    # For first file comparison (strict mode matching)
    $localEvidence = $normalizedLocal[0]
    $actionsEvidence = $normalizedActions[0]
    
    $comparison = & $compareScript `
        -BaselineEvidence $actionsEvidence `
        -CurrentEvidence $localEvidence
    
    # Report results
    Write-ReproducibilityStatus "Reproducibility comparison results:" 'INFO'
    Write-Host "`n--- COMPARISON SUMMARY ---" -ForegroundColor Cyan
    Write-Host "Passed tests: $($comparison.PassedTests)" -ForegroundColor Green
    Write-Host "Failed tests: $($comparison.FailedTests)" -ForegroundColor $(if ($comparison.FailedTests -gt 0) { 'Red' } else { 'Green' })
    
    if ($comparison.TestsAdded.Count -gt 0) {
        Write-Host "New tests added: $($comparison.TestsAdded -join ', ')" -ForegroundColor Yellow
    }
    
    if ($comparison.StatusChanges.Count -gt 0) {
        Write-Host "`nStatus changes detected:" -ForegroundColor Yellow
        foreach ($change in $comparison.StatusChanges) {
            Write-Host "  - $($change.TestName): $($change.Baseline) -> $($change.Current)" -ForegroundColor Red
        }
    }
    
    if ($comparison.EnvironmentMismatch.Count -gt 0) {
        Write-Host "`nEnvironment mismatches:" -ForegroundColor Yellow
        foreach ($mismatch in $comparison.EnvironmentMismatch) {
            Write-Host "  - $mismatch" -ForegroundColor Yellow
        }
    }
    
    if ($comparison.Diagnostics) {
        Write-Host "`nDiagnostics:" -ForegroundColor Gray
        Write-Host $comparison.Diagnostics -ForegroundColor Gray
    }
    
    # Exit with appropriate code
    if ($comparison.Pass) {
        Write-ReproducibilityStatus "Evidence reproducibility VERIFIED" 'PASS'
        exit 0
    } else {
        Write-ReproducibilityStatus "Evidence reproducibility FAILED - test behavior differs between environments" 'FAIL'
        exit 1
    }
    
} finally {
    # Cleanup
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
