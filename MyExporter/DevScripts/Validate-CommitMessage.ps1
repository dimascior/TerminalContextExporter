<#
.SYNOPSIS
Pre-Commit Hook: Commit Message Format Enforcement

.DESCRIPTION
Validates commit messages meet constitutional requirements:
1. Must contain "Level N:" (N = 1, 2, or 3)
2. File count must match context level
3. Must cite CONSTITUTIONAL_AUTHORITY
4. Must reference EVIDENCE file
5. CorrelationId must be valid GUID format (optional but recommended)

This hook runs automatically before git commit succeeds.
Install with: GIT_DIR=.git && cp hooks/pre-commit-msg .git/hooks/ && chmod +x .git/hooks/pre-commit-msg

.PARAMETER CommitMessageFile
File containing commit message (provided by git)

.EXAMPLE
# Git automatically passes the commit message file
.\.git\hooks\prepare-commit-msg
#>

# Pre-commit validation - reads commit message and validates format
param(
    [string]$CommitMessageFile = $env:GIT_COMMIT_MSG,
    [bool]$StrictMode = $true
)

if ([string]::IsNullOrEmpty($CommitMessageFile) -and $args.Count -gt 0) {
    $CommitMessageFile = $args[0]
}

if (-not (Test-Path -Path $CommitMessageFile)) {
    Write-Host "[HOOK] Commit message file not found, skipping validation" -ForegroundColor Yellow
    exit 0
}

$Message = Get-Content -Path $CommitMessageFile -Raw
$Lines = $Message -split "`n"
$FirstLine = $Lines[0]

Write-Host "[PRE-COMMIT] Validating commit message format..." -ForegroundColor Cyan

# Check 1: Must have "Level N:"
$LevelMatch = $FirstLine -match "^Level\s+([123]):"
if (-not $LevelMatch) {
    Write-Host "❌ FAIL: Commit message must start with 'Level N:' (N = 1, 2, or 3)" -ForegroundColor Red
    Write-Host "   Example: Level 1: Add network interface property to SystemInfo"
    exit 1
}

$Level = [int]$matches[1]
Write-Host "✓ Level $Level declaration found" -ForegroundColor Green

# Check 2: File count must match level
$StagedFiles = git diff --cached --name-only 2>$null
$FileCount = ($StagedFiles | Measure-Object).Count

$MaxFiles = @{ 1 = 3; 2 = 7; 3 = 999 }[$Level]

if ($FileCount -gt $MaxFiles) {
    Write-Host "❌ FAIL: Level $Level allows max $MaxFiles files, but $FileCount are staged" -ForegroundColor Red
    Write-Host "   Staged files:"
    foreach ($File in $StagedFiles) {
        Write-Host "     - $File" -ForegroundColor Yellow
    }
    exit 1
}

Write-Host "✓ File count ($FileCount) within Level $Level limit ($MaxFiles)" -ForegroundColor Green

# Check 3: Must have CONSTITUTIONAL_AUTHORITY
if ($Message -notmatch "CONSTITUTIONAL_AUTHORITY:") {
    Write-Host "⚠ WARNING: Message should cite CONSTITUTIONAL_AUTHORITY" -ForegroundColor Yellow
    if ($StrictMode) {
        Write-Host "❌ FAIL: Missing CONSTITUTIONAL_AUTHORITY in strict mode" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "✓ CONSTITUTIONAL_AUTHORITY cited" -ForegroundColor Green
}

# Check 4: Must have EVIDENCE reference
if ($Message -notmatch "EVIDENCE:") {
    Write-Host "⚠ WARNING: Message should reference EVIDENCE file" -ForegroundColor Yellow
    if ($StrictMode) {
        Write-Host "❌ FAIL: Missing EVIDENCE reference in strict mode" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "✓ EVIDENCE file referenced" -ForegroundColor Green
}

# Check 5: No simulation patterns in commit message body
if ($Message -match "(Mock\s|Sentinel|Simulate|FakeData)") {
    Write-Host "❌ FAIL: Commit message contains simulation keywords (Mock, Sentinel, Simulate, FakeData)" -ForegroundColor Red
    exit 1
}

Write-Host "✓ No simulation patterns detected"

# Check 6: Optional: CorrelationId validation
if ($Message -match "CORRELATION_ID:\s*([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})") {
    Write-Host "✓ Valid CorrelationId format" -ForegroundColor Green
}
elseif ($Message -match "CORRELATION_ID:") {
    Write-Host "⚠ WARNING: CorrelationId format may be invalid" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✓ COMMIT MESSAGE VALIDATION PASSED" -ForegroundColor Green
exit 0
