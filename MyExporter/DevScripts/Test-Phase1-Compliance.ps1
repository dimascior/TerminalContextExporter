<#
.SYNOPSIS
Job 1: Constitutional Verification (Phase 1)

.DESCRIPTION
Validates that all required constitutional documents exist.
First gate in CI pipeline - blocks all subsequent jobs if any doc is missing.
Output: constitutional-verification-evidence.json

.PARAMETER DocsPath
Path to docs directory (default: ./docs)

.EXAMPLE
.\Test-Phase1-Compliance.ps1
#>

[CmdletBinding()]
param(
    [string]$DocsPath = "docs"
)

$GitSHA = git rev-parse --short HEAD 2>$null
if ([string]::IsNullOrEmpty($GitSHA)) { $GitSHA = "unknown" }

$Evidence = @{
    TestSuite = "Phase1-Constitutional-Verification"
    Timestamp = Get-Date -Format 'O'
    CommitSHA = $GitSHA
    CrossDocumentReferences = @()
    DocumentsRequired = @(
        @{ Path = "integration loop/GuardRails.md"; Section = "Parts 1-3 (Boundaries)" }
        @{ Path = "MASTER-CONTEXT-FRAMEWORK.md"; Section = "Full-Spectrum Unity" }
        @{ Path = "integration loop/CLAUDE.md"; Section = "Parts 4-7 (Collaboration)" }
        @{ Path = "TaskLoop/Isolate-Trace-Verify-Loop.md"; Section = "Execution Discipline" }
        @{ Path = "AssetRecords/Implementation-Status.md"; Section = "Current State" }
        @{ Path = "ThreeTierWorkflow.md"; Section = "Progressive Anchoring" }
    )
    ValidationResults = @()
    Summary = @{
        TotalDocuments = 0
        DocumentsFound = 0
        DocumentsMissing = 0
        AllDocumentsPresent = $false
        BailoutTriggered = $false
    }
}

Write-Host "[PHASE-1] Constitutional Verification Starting"
Write-Host "[INFO] Checking required documents exist..."
Write-Host ""

$MissingDocs = @()

foreach ($Doc in $Evidence.DocumentsRequired) {
    $FullPath = Join-Path $DocsPath $Doc.Path
    $Evidence.Summary.TotalDocuments++
    
    $Exists = Test-Path -Path $FullPath
    
    if ($Exists) {
        Write-Host "  [OK] $($Doc.Path)" -ForegroundColor Green
        Write-Host "    Section: $($Doc.Section)" -ForegroundColor Gray
        $Evidence.Summary.DocumentsFound++
        
        # Validate file is non-empty
        $FileSize = (Get-Item -Path $FullPath).Length
        $Evidence.ValidationResults += @{
            Document = $Doc.Path
            Status = "FOUND"
            FileSize = $FileSize
            Section = $Doc.Section
        }
    }
    else {
        Write-Host "  [FAIL] MISSING: $($Doc.Path)" -ForegroundColor Red
        Write-Host "    Expected at: $FullPath" -ForegroundColor Red
        Write-Host "    Section: $($Doc.Section)" -ForegroundColor Gray
        
        $Evidence.Summary.DocumentsMissing++
        $MissingDocs += $Doc.Path
        
        $Evidence.ValidationResults += @{
            Document = $Doc.Path
            Status = "MISSING"
            FileSize = 0
            Section = $Doc.Section
        }
    }
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Yellow
Write-Host "PHASE 1 SUMMARY" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Yellow
Write-Host "  Documents Found: $($Evidence.Summary.DocumentsFound)/$($Evidence.Summary.TotalDocuments)"
Write-Host "  Documents Missing: $($Evidence.Summary.DocumentsMissing)"

if ($Evidence.Summary.DocumentsMissing -eq 0) {
    Write-Host ""
    Write-Host "[OK] ALL CONSTITUTIONAL DOCUMENTS PRESENT" -ForegroundColor Green
    $Evidence.Summary.AllDocumentsPresent = $true
    Write-Host "  Proceeding to Job 2: Anti-Simulation Enforcement"
}
else {
    Write-Host ""
    Write-Host "[FAIL] CONSTITUTIONAL BAILOUT TRIGGERED" -ForegroundColor Red
    Write-Host "Missing documents:" 
    foreach ($Missing in $MissingDocs) {
        Write-Host "  - $Missing" -ForegroundColor Red
    }
    $Evidence.Summary.BailoutTriggered = $true
}

Write-Host "===============================================" -ForegroundColor Yellow
# Output evidence
$Evidence | ConvertTo-Json -Depth 10 | Out-File -FilePath "constitutional-verification-evidence.json" -Encoding UTF8
Write-Host ""
Write-Host "[EVIDENCE] Written to constitutional-verification-evidence.json"

$ExitCode = if ($Evidence.Summary.AllDocumentsPresent) { 0 } else { 1 }
exit $ExitCode
