<#
.SYNOPSIS
Job 5: Security Constitutional Scan

.DESCRIPTION
Scans codebase for security issues and vulnerabilities.
Does NOT block merge (separate policy), but does flag issues.

Currently checks:
- PowerShell code for hardcoded credentials
- Dangerous functions usage
- Version compliance

In CI: Attempts Trivy scan if available

.EXAMPLE
.\Test-Phase5-Security.ps1
#>

[CmdletBinding()]
param()

$CommitSha = git rev-parse --short HEAD 2>$null
if (-not $CommitSha) { $CommitSha = "unknown" }

$Scan = @{
    Timestamp = Get-Date -Format 'O'
    CommitSHA = $CommitSha
    Checks = @()
    Vulnerabilities = @()
    Status = "PASS"
}

Write-Host "[PHASE-5] Security Constitutional Scan"
Write-Host ""

# Check 1: Hardcoded credentials
Write-Host "[CHECK] Scanning for hardcoded secrets..."

# Define credential patterns as array of strings (single quoted to avoid escaping issues)
$CredentialPatterns = @(
    'password\s*=\s*.',           # password = [anything]
    'api.?key\s*=\s*.',           # api_key or apikey = [anything]
    'SecureString\s*.'            # -SecureString [anything]
)

$CodeFiles = Get-ChildItem -Path "*.ps1" -Recurse -ErrorAction SilentlyContinue
$CodeFiles += Get-ChildItem -Path "Private/*.ps1" -Recurse -ErrorAction SilentlyContinue
$CodeFiles += Get-ChildItem -Path "Public/*.ps1" -Recurse -ErrorAction SilentlyContinue

$CredentialMatches = @()
foreach ($File in $CodeFiles) {
    $Content = Get-Content -Path $File.FullName -Raw -ErrorAction SilentlyContinue
    
    foreach ($Pattern in $CredentialPatterns) {
        if ($Content -match $Pattern) {
            $CredentialMatches += @{
                File = $File.Name
                Pattern = $Pattern
                Line = ($Content | Select-String -Pattern $Pattern | Select-Object -First 1).LineNumber
            }
        }
    }
}

if ($CredentialMatches.Count -gt 0) {
    Write-Host "  [WARN] Found $($CredentialMatches.Count) potential credential issue(s)" -ForegroundColor Yellow
    foreach ($Match in $CredentialMatches) {
        Write-Host "    - $($Match.File): $($Match.Pattern)" -ForegroundColor Yellow
    }
    $Scan.Vulnerabilities += $CredentialMatches
}
else {
    Write-Host "  [PASS] No hardcoded credentials detected" -ForegroundColor Green
}

$Scan.Checks += @{
    Check = "Hardcoded Credentials"
    Status = if ($CredentialMatches.Count -eq 0) { "PASS" } else { "FLAGGED" }
    ItemsFound = $CredentialMatches.Count
}

# Check 2: Dangerous functions (InvokeExpression, DownloadString, etc)
Write-Host "[CHECK] Scanning for dangerous function patterns..."

$DangerousPatterns = @(
    'Invoke-Expression',
    'DownloadString',
    'DownloadFile.*\$',  # Downloads to variable/memory
    'Get-Content.*-Raw.*\|.*Invoke'  # Piping raw content to Invoke
)

$DangerousMatches = @()
foreach ($File in $CodeFiles) {
    $Content = Get-Content -Path $File.FullName -Raw -ErrorAction SilentlyContinue
    
    foreach ($Pattern in $DangerousPatterns) {
        if ($Content -match $Pattern) {
            $DangerousMatches += @{
                File = $File.Name
                Function = $Pattern
            }
        }
    }
}

if ($DangerousMatches.Count -gt 0) {
    Write-Host "  [WARN] Found $($DangerousMatches.Count) dangerous function pattern(s)" -ForegroundColor Yellow
    foreach ($Match in $DangerousMatches) {
        Write-Host "    - $($Match.File): $($Match.Function)" -ForegroundColor Yellow
    }
    $Scan.Vulnerabilities += $DangerousMatches
}
else {
    Write-Host "  [PASS] No dangerous functions detected" -ForegroundColor Green
}

$Scan.Checks += @{
    Check = "Dangerous Functions"
    Status = if ($DangerousMatches.Count -eq 0) { "PASS" } else { "FLAGGED" }
    ItemsFound = $DangerousMatches.Count
}

# Check 3: PowerShell version compliance
Write-Host "[CHECK] Verifying PowerShell 5.1+ compatibility..."

$PSVersionIssues = @()
foreach ($File in $CodeFiles) {
    $Content = Get-Content -Path $File.FullName -Raw -ErrorAction SilentlyContinue
    
    # Check for PS 7+ only operators (simple string matching, not regex to avoid parsing)
    if ($Content -and ($Content.Contains('??') -or $Content.Contains('?:'))) {
        $PSVersionIssues += @{
            File = $File.Name
            Issue = "PowerShell 7+ only operators detected"
        }
    }
}

if ($PSVersionIssues.Count -gt 0) {
    Write-Host "  [WARN] Found $($PSVersionIssues.Count) PS 7+ compatibility issue(s)" -ForegroundColor Yellow
    foreach ($Issue in $PSVersionIssues) {
        Write-Host "    - $($Issue.File): $($Issue.Issue)" -ForegroundColor Yellow
    }
    $Scan.Vulnerabilities += $PSVersionIssues
}
else {
    Write-Host "  [PASS] Compatible with PowerShell 5.1+" -ForegroundColor Green
}

$Scan.Checks += @{
    Check = "Version Compatibility"
    Status = if ($PSVersionIssues.Count -eq 0) { "PASS" } else { "FLAGGED" }
    ItemsFound = $PSVersionIssues.Count
}

# Check 4: Trivy scan (if available)
Write-Host "[CHECK] Attempting Trivy filesystem scan..."
$TrivyAvailable = Get-Command -Name trivy -ErrorAction SilentlyContinue

if ($TrivyAvailable) {
    Write-Host "  Running Trivy scan..."
    try {
        $TrivyOutput = trivy fs . 2>&1
        $Scan.Checks += @{
            Check = "Trivy"
            Status = "EXECUTED"
            HasVulnerabilities = ($TrivyOutput -match "vulnerability|CRITICAL|HIGH")
        }
        Write-Host "  [PASS] Trivy scan completed" -ForegroundColor Green
    }
    catch {
        Write-Host "  [WARN] Trivy scan failed: $_" -ForegroundColor Yellow
        $Scan.Checks += @{
            Check = "Trivy"
            Status = "ERRORED"
            Error = $_.Exception.Message
        }
    }
}
else {
    Write-Host "  [INFO] Trivy not installed (skipping advanced scan)" -ForegroundColor Yellow
    Write-Host "    Install with: choco install trivy (Windows)" -ForegroundColor Gray
    $Scan.Checks += @{
        Check = "Trivy"
        Status = "SKIPPED"
        Reason = "Not installed"
    }
}

# Determine final status
if ($Scan.Vulnerabilities.Count -gt 0) {
    $Scan.Status = "FLAGGED"
}

# Output report
Write-Host ""
Write-Host "=================================================" -ForegroundColor Yellow
Write-Host "SECURITY SCAN SUMMARY" -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Yellow
Write-Host "  Status: $($Scan.Status)"
Write-Host "  Vulnerabilities Found: $($Scan.Vulnerabilities.Count)"
Write-Host "  Checks Completed: $($Scan.Checks.Count)"
Write-Host ""
Write-Host "  * Security issues are flagged for audit but do not block merge"
Write-Host "  * This is a separate policy from constitutional verification"
Write-Host "=================================================" -ForegroundColor Yellow

# Ensure artifacts directory exists
$EvidenceDir = ".artifacts/evidence/local"
if (-not (Test-Path $EvidenceDir)) {
    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null
}

# Generate correlation ID (consistent across all phase evidence)
$CorrelationId = [guid]::NewGuid().ToString()
$Scan | Add-Member -MemberType NoteProperty -Name "CorrelationId" -Value $CorrelationId

# Generate timestamp-based filename
$Timestamp = Get-Date -Format 'yyyy-MM-dd-HHmm'
$EvidenceFile = Join-Path $EvidenceDir "security-scan-$Timestamp.json"

# Write evidence file
$Scan | ConvertTo-Json -Depth 10 | Out-File -FilePath $EvidenceFile -Encoding UTF8
Write-Host ""
Write-Host "[EVIDENCE] Written to $EvidenceFile"
Write-Host ""

# Always exit 0 - security issues flagged but don't block merge (separate policy)
exit 0
