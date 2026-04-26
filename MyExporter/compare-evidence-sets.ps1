#Requires -Version 5.1

<#
.SYNOPSIS
    Compare two normalized evidence sets for reproducibility verification
.DESCRIPTION
    Performs field-by-field comparison of normalized evidence objects,
    distinguishing between new tests added, existing tests with status changes,
    and tests removed. Returns structured comparison result.
    
    Authority: Isolate-Trace-Verify-Loop.md (comparison validation principle)
    
.PARAMETER BaselineEvidence
    Normalized evidence object from baseline/prior commit
    
.PARAMETER CurrentEvidence
    Normalized evidence object from current execution
    
.OUTPUTS
    Hashtable with Pass/Fail status, mismatches, and diagnostic details
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [object]$BaselineEvidence,
    
    [Parameter(Mandatory = $true)]
    [object]$CurrentEvidence
)

$ErrorActionPreference = 'Stop'

function Compare-Evidence {
    param(
        [object]$Baseline,
        [object]$Current
    )
    
    $result = @{
        Pass                 = $true
        PassedTests          = 0
        FailedTests          = 0
        FailureDetails       = @()
        EnvironmentMismatch  = @()
        TestsAdded           = @()
        TestsRemoved         = @()
        StatusChanges        = @()
        Diagnostics          = ""
        CommitSHAMismatch    = $false
    }
    
    # Check commit SHA - if different, indicate baseline establishment (different code)
    if ($Baseline.CommitSHA -ne $Current.CommitSHA -and $Baseline.CommitSHA -ne "no-git" -and $Current.CommitSHA -ne "no-git") {
        $result.CommitSHAMismatch = $true
        $result.Diagnostics += "Commit SHA changed: baseline=$($Baseline.CommitSHA) vs current=$($Current.CommitSHA)`n"
        $result.Diagnostics += "This comparison is across different code versions (expected after code changes)`n"
        # When commit SHAs differ, this is an expected change - not an error condition
        # but we still validate test structure hasn't broken
    }
    
    # Compare schema versions
    if ($Baseline.SchemaVersion -ne $Current.SchemaVersion) {
        $result.FailureDetails += "Schema version mismatch: baseline=$($Baseline.SchemaVersion) vs current=$($Current.SchemaVersion)"
        $result.Pass = $false
    }
    
    # Compare environment (must match for reproducibility)
    if ($Baseline.Environment.PSVersion -ne $Current.Environment.PSVersion) {
        $msg = "PowerShell version mismatch: baseline=$($Baseline.Environment.PSVersion) vs current=$($Current.Environment.PSVersion)"
        $result.EnvironmentMismatch += $msg
        $result.Pass = $false
    }
    if ($Baseline.Environment.PSEdition -ne $Current.Environment.PSEdition) {
        $msg = "PS Edition mismatch: baseline=$($Baseline.Environment.PSEdition) vs current=$($Current.Environment.PSEdition)"
        $result.EnvironmentMismatch += $msg
        $result.Pass = $false
    }
    
    # Build test name maps for comparison
    $baselineTests = @{}
    foreach ($test in $Baseline.Tests) {
        $baselineTests[$test.Name] = $test.Status
    }
    
    $currentTests = @{}
    foreach ($test in $Current.Tests) {
        $currentTests[$test.Name] = $test.Status
    }
    
    # Identify new tests
    foreach ($testName in $currentTests.Keys) {
        if ($testName -notin $baselineTests.Keys) {
            $result.TestsAdded += $testName
        }
    }
    
    # Identify removed tests (breaking change)
    foreach ($testName in $baselineTests.Keys) {
        if ($testName -notin $currentTests.Keys) {
            $result.TestsRemoved += $testName
            $result.Pass = $false
        }
    }
    
    # Compare existing tests for status changes
    foreach ($testName in $baselineTests.Keys) {
        if ($testName -in $currentTests.Keys) {
            $baselineStatus = $baselineTests[$testName]
            $currentStatus = $currentTests[$testName]
            
            if ($baselineStatus -eq $currentStatus) {
                if ($currentStatus -eq 'PASS') {
                    $result.PassedTests++
                }
            } else {
                # Status changed
                $result.StatusChanges += @{
                    TestName   = $testName
                    Baseline   = $baselineStatus
                    Current    = $currentStatus
                }
                $result.Pass = $false
            }
        }
    }
    
    # Count failed tests in current
    $result.FailedTests = @($currentTests.Values | Where-Object { $_ -eq 'FAIL' }).Count
    
    # Generate diagnostics
    if ($result.TestsAdded.Count -gt 0) {
        $result.Diagnostics += "New tests added: $($result.TestsAdded -join ', ')`n"
    }
    if ($result.TestsRemoved.Count -gt 0) {
        $result.Diagnostics += "Tests removed: $($result.TestsRemoved -join ', ')`n"
    }
    if ($result.StatusChanges.Count -gt 0) {
        $result.Diagnostics += "Status changes detected:`n"
        foreach ($change in $result.StatusChanges) {
            $result.Diagnostics += "  - $($change.TestName): $($change.Baseline) -> $($change.Current)`n"
        }
    }
    if ($result.EnvironmentMismatch.Count -gt 0) {
        $result.Diagnostics += "Environment mismatches:`n"
        foreach ($mismatch in $result.EnvironmentMismatch) {
            $result.Diagnostics += "  - $mismatch`n"
        }
    }
    
    return $result
}

# Perform comparison
$comparison = Compare-Evidence -Baseline $BaselineEvidence -Current $CurrentEvidence

# Output result
return $comparison
