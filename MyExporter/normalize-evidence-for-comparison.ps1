#Requires -Version 5.1

<#
.SYNOPSIS
    Normalize evidence files for reproducibility comparison
.DESCRIPTION
    Removes non-essential fields (timestamps, machine-specific data) from evidence
    while preserving core test data needed for reproducibility verification.
    
    Authority: Isolate-Trace-Verify-Loop.md (comparison normalization principle)
    
.PARAMETER EvidencePath
    Path to evidence JSON file to normalize
    
.OUTPUTS
    Normalized evidence object with essential fields only
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$EvidencePath
)

$ErrorActionPreference = 'Stop'

function Get-NormalizedEvidence {
    param([object]$EvidenceData, [string]$Source)
    
    $normalized = @{
        Source          = $Source
        SchemaVersion   = $EvidenceData.SchemaVersion ?? '1.0'
        CommitSHA       = $EvidenceData.CommitSHA
        CorrelationId   = $EvidenceData.CorrelationId
        TestSuite       = $EvidenceData.TestSuite
        Environment     = @{
            PSVersion   = $EvidenceData.Environment.PSVersion
            PSEdition   = $EvidenceData.Environment.PSEdition
            OS          = $EvidenceData.Environment.OS
        }
        Tests           = @()
        Summary         = $null
    }
    
    # Normalize test array - compare only name and status
    if ($EvidenceData.Tests) {
        foreach ($test in $EvidenceData.Tests) {
            $normalized.Tests += @{
                Name   = $test.Name
                Status = $test.Status
            }
        }
    }
    
    # Preserve summary for statistical comparison
    if ($EvidenceData.Summary) {
        $normalized.Summary = @{
            TotalTests = $EvidenceData.Summary.TotalTests ?? $EvidenceData.Tests.Count
            PassedTests = $EvidenceData.Summary.PassedTests ?? ($EvidenceData.Tests | Where-Object { $_.Status -eq 'PASS' }).Count
            FailedTests = $EvidenceData.Summary.FailedTests ?? ($EvidenceData.Tests | Where-Object { $_.Status -eq 'FAIL' }).Count
        }
    }
    
    return $normalized
}

# Load evidence file
if (-not (Test-Path $EvidencePath)) {
    Write-Error "Evidence file not found: $EvidencePath"
    exit 1
}

try {
    $rawEvidence = Get-Content $EvidencePath -Raw | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Error "Failed to parse evidence JSON: $_"
    exit 1
}

# Normalize and output
$normalized = Get-NormalizedEvidence -EvidenceData $rawEvidence -Source $EvidencePath

# Return as object (for pipeline) and also output structured version
return $normalized
