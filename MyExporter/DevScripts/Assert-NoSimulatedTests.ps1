<#
.SYNOPSIS
Job 2: Anti-Simulation Enforcement Gate (CI Pipeline)

.DESCRIPTION
ZERO-TOLERANCE policy for Mock/Sentinel/Simulate patterns.
Scans all test files for forbidden patterns that indicate artificial test data.
Runs before Job 3 (Systematic Validation Matrix).
Any match blocks merge immediately with FAIL status.

.PARAMETER TestPath
Path to scan for test files (default: Tests/)

.PARAMETER FailOnSimulation
If true, throw terminating error on match (default: true)

.EXAMPLE
.\Assert-NoSimulatedTests.ps1 -TestPath ./Tests
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [string]$TestPath = "Tests",
    
    [bool]$FailOnSimulation = $true
)

# Forbidden patterns that indicate simulation/mocking
$ForbiddenPatterns = @(
    "Mock\s+",                  # PowerShell mock (Pester)
    "Sentinel\s*=",             # Sentinel test value
    "Simulate",                 # Explicit simulation
    "FakeData",                 # Fake data markers
    "\-MockWith",               # Pester mocking syntax
    "InModuleScope.*Mock"       # Scoped mocking
)

$GitSHA = git rev-parse --short HEAD 2>$null
if ([string]::IsNullOrEmpty($GitSHA)) { $GitSHA = "unknown" }

$ResolvedPath = if (Test-Path $TestPath) { (Resolve-Path $TestPath).Path } else { $TestPath }

$Report = @{
    Timestamp = Get-Date -Format 'O'
    CommitSHA = $GitSHA
    ScanPath = $ResolvedPath
    ForbiddenPatterns = @()
    PatternMatches = @()
    OverallStatus = "PASS"
}

# Scan test files
Write-Host "[TEST-SCANNING] Looking for forbidden patterns in $TestPath"
$TestFiles = Get-ChildItem -Path $TestPath -Filter "*.Tests.ps1" -Recurse -ErrorAction SilentlyContinue

if ($TestFiles.Count -eq 0) {
    Write-Host "[INFO] No test files found to scan (or directory doesn't exist yet)"
    $Report.OverallStatus = "PASS"
}
else {
    Write-Host "[SCANNING] Found $($TestFiles.Count) test file(s)"
    
    foreach ($File in $TestFiles) {
        $Content = Get-Content -Path $File.FullName -Raw
        $LineNumber = 0
        
        foreach ($Pattern in $ForbiddenPatterns) {
            if ($Content -match $Pattern) {
                $Report.OverallStatus = "FAIL"
                
                # Find exact line numbers
                $Lines = $Content -split "`n"
                for ($i = 0; $i -lt $Lines.Count; $i++) {
                    if ($Lines[$i] -match $Pattern) {
                        $Report.PatternMatches += @{
                            File = $File.Name
                            Line = $i + 1
                            Pattern = $Pattern
                            Content = $Lines[$i].Trim()
                        }
                    }
                }
            }
        }
    }
}

# Output report
# Ensure artifacts directory exists
$EvidenceDir = ".artifacts/evidence/local"
if (-not (Test-Path $EvidenceDir)) {
    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null
}

# Generate timestamp-based filename
$Timestamp = Get-Date -Format 'yyyy-MM-dd-HHmm'
$ReportFile = Join-Path $EvidenceDir "anti-simulation-report-$Timestamp.json"

$Report | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportFile -Encoding UTF8
Write-Host "[REPORT] Written to $ReportFile"

# Display results
if ($Report.OverallStatus -eq "FAIL") {
    Write-Host "[CRITICAL] SIMULATION PATTERNS DETECTED - CI GATE BLOCKED" -ForegroundColor Red
    Write-Host ""
    foreach ($Match in $Report.PatternMatches) {
        Write-Host "  [PATTERN] $($Match.File):$($Match.Line)" -ForegroundColor Red
        Write-Host "     Pattern: $($Match.Pattern)" -ForegroundColor Yellow
        Write-Host "     Content: $($Match.Content.Substring(0, [Math]::Min(80, $Match.Content.Length)))" -ForegroundColor Yellow
    }
    
    if ($FailOnSimulation) {
        Write-Error "Anti-simulation gate FAILED. Remove Mock/Sentinel/Simulate patterns and retry." -ErrorAction Stop
    }
}
else {
    Write-Host "[PASS] No simulation patterns detected" -ForegroundColor Green
    Write-Host "[INFO] Using real system calls and boundary testing confirmed"
}

$ExitCode = if ($Report.OverallStatus -eq "FAIL") { 1 } else { 0 }
exit $ExitCode
