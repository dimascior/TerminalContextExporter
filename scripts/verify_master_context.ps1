# verify_master_context_fixed.ps1
# Constitutional verification script (PowerShell version) - Enhanced Unicode Support
# Authority: GuardRails.md + MASTER-CONTEXT-FRAMEWORK.md
# Purpose: Validate cross-document constitutional integrity

# Enhanced console encoding setup based on MyExporter patterns
try {
    # Set encoding for PowerShell output
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    
    # Force UTF-8 console on Windows (MyExporter pattern)
    if ($PSVersionTable.PSEdition -eq 'Desktop' -or $env:OS -eq 'Windows_NT') {
        try {
            & chcp 65001 | Out-Null
        } catch {
            Write-Warning "Could not set console code page to UTF-8"
        }
    }
    
    # Test Unicode capability with fallback (MyExporter pattern)
    $unicodeSupported = $true
    try {
        # Test if console can display Unicode by attempting to write a Unicode character
        $testOutput = [char]0x2713 # ✓ character
        Write-Host $testOutput -NoNewline
        Write-Host "`b" -NoNewline  # backspace to erase test character
        
        # Define Unicode symbols as character codes to avoid parser issues
        $checkmark = [char]0x2705  # ✅
        $crossmark = [char]0x274C  # ❌ 
        $info = [char]0x1F4CB      # 📋
        $link = [char]0x1F517      # 🔗
        $shield = [char]0x1F6E1    # 🛡️
        $warning = [char]0x1F6A8   # 🚨
        $celebrate = [char]0x1F389 # 🎉
        
    } catch {
        $unicodeSupported = $false
    }
    
    if (-not $unicodeSupported) {
        # ASCII fallback
        $checkmark = "[PASS]"
        $crossmark = "[FAIL]"
        $info = "[INFO]"
        $link = "[LINK]"
        $shield = "[SHIELD]"
        $warning = "[WARNING]"
        $celebrate = "[SUCCESS]"
    }
    
} catch {
    Write-Warning "Unicode setup failed, using ASCII fallback: $($_.Exception.Message)"
    $unicodeSupported = $false
    $checkmark = "[PASS]"
    $crossmark = "[FAIL]"
    $info = "[INFO]"
    $link = "[LINK]"
    $shield = "[SHIELD]"
    $warning = "[WARNING]"
    $celebrate = "[SUCCESS]"
}

Write-Host "$warning VERIFYING MASTER CONTEXT FRAMEWORK INTEGRITY $warning" -ForegroundColor Yellow

# Check required constitutional documents exist
$RequiredDocs = @(
    "docs\integration loop\GuardRails.md",
    "docs\integration loop\CLAUDE.md", 
    "docs\TaskLoop\Isolate-Trace-Verify-Loop.md",
    "docs\MASTER-CONTEXT-FRAMEWORK.md",
    "docs\ThreeTierWorkflow.md",
    "docs\AI-Agent-Project-Navigation-Report.md"
)

Write-Host "`n$info Checking constitutional document presence..." -ForegroundColor Cyan
$AllDocsFound = $true

foreach ($doc in $RequiredDocs) {
    if (Test-Path $doc) {
        Write-Host "$checkmark Found: $doc" -ForegroundColor Green
    } else {
        Write-Host "$crossmark ERROR MISSING: $doc" -ForegroundColor Red
        $AllDocsFound = $false
    }
}

if (-not $AllDocsFound) {
    Write-Host "`n$crossmark CRITICAL: Missing constitutional documents detected!" -ForegroundColor Red
    Write-Host "Constitutional framework integrity compromised." -ForegroundColor Red
    exit 1
}

Write-Host "`n$link Validating cross-document constitutional references..." -ForegroundColor Cyan

# Check MASTER-CONTEXT-FRAMEWORK.md references GuardRails.md
$MasterContextContent = Get-Content "docs\MASTER-CONTEXT-FRAMEWORK.md" -Raw
if ($MasterContextContent -match "GuardRails\.md") {
    Write-Host "$checkmark Master context framework -> GuardRails.md reference verified" -ForegroundColor Green
} else {
    Write-Host "$crossmark ERROR: Master context framework missing GuardRails.md reference" -ForegroundColor Red
    exit 1
}

# Check ThreeTierWorkflow.md has constitutional banner
$ThreeTierContent = Get-Content "docs\ThreeTierWorkflow.md" -Raw
if ($ThreeTierContent -match "CONSTITUTIONAL GUARDRAIL BANNER") {
    Write-Host "$checkmark ThreeTierWorkflow.md constitutional banner verified" -ForegroundColor Green
} else {
    Write-Host "$crossmark ERROR: ThreeTierWorkflow.md missing constitutional banner" -ForegroundColor Red
    exit 1
}

# Check AI Agent Report has master context version
$AIReportContent = Get-Content "docs\AI-Agent-Project-Navigation-Report.md" -Raw
if ($AIReportContent -match "MASTER CONTEXT VERSION") {
    Write-Host "$checkmark AI Agent Report master context version verified" -ForegroundColor Green
} else {
    Write-Host "$crossmark ERROR: AI Agent Report missing master context version stamp" -ForegroundColor Red
    exit 1
}

# Check for bailout triggers in ThreeTierWorkflow
if ($ThreeTierContent -match "BAILOUT_IF") {
    Write-Host "$checkmark ThreeTierWorkflow.md bailout triggers verified" -ForegroundColor Green
} else {
    Write-Host "$crossmark ERROR: ThreeTierWorkflow.md missing bailout triggers" -ForegroundColor Red
    exit 1
}

# Check for execution bridge paths
if ($ThreeTierContent -match "MyExporter/DevScripts/claude-") {
    Write-Host "$checkmark Execution bridge paths verified" -ForegroundColor Green
} else {
    Write-Host "$crossmark ERROR: ThreeTierWorkflow.md missing full execution bridge paths" -ForegroundColor Red
    exit 1
}

# Check TaskLoop documents for constitutional headers
$TaskLoopFiles = @(
    "docs\TaskLoop\Isolate-Trace-Verify-Loop.md",
    "docs\TaskLoop\build-suite-discipline.md"
)

foreach ($file in $TaskLoopFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        if ($content -match "CONSTITUTIONAL GUARDRAIL BANNER") {
            Write-Host "$checkmark $file constitutional banner verified" -ForegroundColor Green
        } else {
            Write-Host "$crossmark ERROR: $file missing constitutional banner" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "$crossmark ERROR: $file not found" -ForegroundColor Red
        exit 1
    }
}

# Check for PROCEED CHECKLIST in navigation report
if ($AIReportContent -match "PROCEED CHECKLIST") {
    Write-Host "$checkmark Navigation report proceed checklist verified" -ForegroundColor Green
} else {
    Write-Host "$crossmark ERROR: Navigation report missing proceed checklist" -ForegroundColor Red
    exit 1
}

Write-Host "`n$checkmark MASTER CONTEXT FRAMEWORK INTEGRITY VERIFIED" -ForegroundColor Green
Write-Host "$shield Constitutional authority chain intact" -ForegroundColor Green  
Write-Host "$link Cross-document correlation validated" -ForegroundColor Green
Write-Host "$info All required constitutional documents present" -ForegroundColor Green

Write-Host "`n$warning CONSTITUTIONAL REMINDER:" -ForegroundColor Yellow
Write-Host "   1. GuardRails.md Parts 1-3 are IMMUTABLE foundation" -ForegroundColor White
Write-Host "   2. All work must derive authority from constitutional framework" -ForegroundColor White
Write-Host "   3. Evidence-based validation is MANDATORY" -ForegroundColor White
Write-Host "   4. Anti-simulation boundaries are CONSTITUTIONAL LAW" -ForegroundColor White

Write-Host "`n$celebrate CONSTITUTIONAL VALIDATION PASSED" -ForegroundColor Green
Write-Host "Ready to proceed with constitutional compliance" -ForegroundColor Green

# Evidence logging (MyExporter pattern) - UTF-8 file output
$evidenceLog = @{
    Timestamp = Get-Date
    ValidationResult = "PASSED"
    DocumentsChecked = $RequiredDocs.Count
    ConstitutionalChecks = @{
        GuardRailsReference = $true
        ConstitutionalBanners = $true
        BailoutTriggers = $true
        ExecutionBridges = $true
        ProceedChecklist = $true
    }
    UnicodeSupport = $unicodeSupported
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
}

try {
    $evidenceLog | ConvertTo-Json -Depth 3 | Out-File "scripts\constitutional-verification-evidence.json" -Encoding UTF8
    Write-Host "`n$info Evidence logged to: scripts\constitutional-verification-evidence.json" -ForegroundColor Gray
} catch {
    Write-Warning "Could not write evidence log: $($_.Exception.Message)"
}
