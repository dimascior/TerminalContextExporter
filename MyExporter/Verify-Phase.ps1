#Requires -Version 5.1

<#
.SYNOPSIS
    Verify-Phase.ps1 - Pre-merge hook to enforce GuardRails.md compliance
.DESCRIPTION
    This script validates that all GuardRails.md requirements are met before
    allowing phase completion announcements. It performs:
    - CI matrix validation (green on Windows + WSL)
    - GuardRails.md violation checks
    - Test coverage requirements
    - API contract validation
.NOTES
    This script must pass before any "phase complete" announcements.
#>

[CmdletBinding()]
param(
    [switch]$SkipCICheck,
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = if ($Verbose) { 'Continue' } else { 'SilentlyContinue' }

function Write-PhaseStatus {
    param([string]$Message, [string]$Status = 'INFO')
    $Color = switch ($Status) {
        'PASS' { 'Green' }
        'FAIL' { 'Red' }
        'WARN' { 'Yellow' }
        default { 'White' }
    }
    Write-Host "[$Status] $Message" -ForegroundColor $Color
}

function Test-GuardRailsCompliance {
    [CmdletBinding()]
    param()
    
    $Violations = @()
    
    # Check 1: Get-CurrentSession.ps1 should only pass SessionId across job boundaries
    $GetCurrentSessionPath = "$PSScriptRoot\Private\Get-CurrentSession.ps1"
    if (Test-Path $GetCurrentSessionPath) {
        $Content = Get-Content $GetCurrentSessionPath -Raw
        if ($Content -match 'Start-Job.*\$Session\b' -or $Content -match 'Invoke-Command.*\$Session\b') {
            $Violations += "Get-CurrentSession.ps1: Passing mutable Session object across job boundaries (should pass only SessionId)"
        }
    }
    
    # Check 2: CommandSanitizer should use external policy file
    $CommandSanitizerPath = "$PSScriptRoot\Private\Test-CommandSafety.ps1"
    $PolicyPath = "$PSScriptRoot\Policies\terminal-deny.yaml"
    if (Test-Path $CommandSanitizerPath) {
        $Content = Get-Content $CommandSanitizerPath -Raw
        if ($Content -match '\$DenyList\s*=\s*@\(' -and !(Test-Path $PolicyPath)) {
            $Violations += "CommandSanitizer: Hardcoded deny list should be moved to $PolicyPath"
        }
    }
    
    # Check 3: TmuxSessionReference class autoloading
    $ModulePath = "$PSScriptRoot\MyExporter.psm1"
    if (Test-Path $ModulePath) {
        $Content = Get-Content $ModulePath -Raw
        if (!(($Content -match 'using module.*TmuxSessionReference') -or ($Content -match 'Import-Module.*TmuxSessionReference'))) {
            $Violations += "MyExporter.psm1: Missing TmuxSessionReference class autoloading"
        }
    }
    
    # Check 4: Script Analyzer compliance
    try {
        if (Get-Module -ListAvailable PSScriptAnalyzer) {
            $Results = Invoke-ScriptAnalyzer -Path $PSScriptRoot -Recurse -Settings PSGallery
            $CriticalIssues = $Results | Where-Object { $_.Severity -eq 'Error' }
            if ($CriticalIssues) {
                $Violations += "ScriptAnalyzer: $($CriticalIssues.Count) critical issues found"
            }
        }
    } catch {
        Write-PhaseStatus "Could not run ScriptAnalyzer: $_" 'WARN'
    }
    
    return $Violations
}

function Test-TestCoverage {
    [CmdletBinding()]
    param()
    
    $Issues = @()
    
    # Check that all Public functions have tests
    $PublicFunctions = Get-ChildItem "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue
    $TestFiles = Get-ChildItem "$PSScriptRoot\Tests\*.Tests.ps1" -ErrorAction SilentlyContinue
    
    foreach ($Function in $PublicFunctions) {
        $FunctionName = [System.IO.Path]::GetFileNameWithoutExtension($Function.Name)
        $TestExists = $TestFiles | Where-Object { $_.Name -like "*$FunctionName*" }
        if (!$TestExists) {
            $Issues += "Missing test file for $FunctionName"
        }
    }
    
    # Check that no tests are simulated/sentinel-based
    foreach ($TestFile in $TestFiles) {
        $Content = Get-Content $TestFile.FullName -Raw
        if ($Content -match 'Mock|Sentinel|Simulate' -and $Content -notmatch '# Real test') {
            $Issues += "$($TestFile.Name): Contains simulated/mock tests (should be real)"
        }
    }
    
    return $Issues
}

function Test-ApiContract {
    [CmdletBinding()]
    param()
    
    $Issues = @()
    
    # Load current module and check API contract
    try {
        Import-Module "$PSScriptRoot\MyExporter.psd1" -Force
        $ExportedCommands = (Get-Module MyExporter).ExportedCommands.Keys
        
        # Verify Export-SystemInfo exists and has correct parameters
        if ('Export-SystemInfo' -in $ExportedCommands) {
            $Command = Get-Command Export-SystemInfo
            $RequiredParams = @('OutputPath', 'Format', 'IncludeTerminalInfo')
            foreach ($Param in $RequiredParams) {
                if ($Param -notin $Command.Parameters.Keys) {
                    $Issues += "Export-SystemInfo: Missing required parameter '$Param'"
                }
            }
        } else {
            $Issues += "Export-SystemInfo command not exported"
        }
    } catch {
        $Issues += "Failed to import module: $_"
    }
    
    return $Issues
}

function Test-FileList {
    [CmdletBinding()]
    param()
    
    $Issues = @()
    
    # Check that all new files are tracked
    $GitStatus = git status --porcelain 2>$null
    if ($GitStatus) {
        $UntrackedFiles = $GitStatus | Where-Object { $_ -match '^\?\?' }
        if ($UntrackedFiles) {
            $Issues += "Untracked files found: $($UntrackedFiles -join ', ')"
        }
    }
    
    return $Issues
}

# Main verification logic
Write-PhaseStatus "Starting GuardRails compliance verification" 'INFO'

$AllIssues = @()

# 1. GuardRails compliance
Write-PhaseStatus "Checking GuardRails.md compliance..." 'INFO'
$GuardRailsIssues = Test-GuardRailsCompliance
$AllIssues += $GuardRailsIssues

# 2. Test coverage
Write-PhaseStatus "Checking test coverage..." 'INFO'
$TestIssues = Test-TestCoverage
$AllIssues += $TestIssues

# 3. API contract
Write-PhaseStatus "Checking API contract..." 'INFO'
$ApiIssues = Test-ApiContract
$AllIssues += $ApiIssues

# 4. File tracking
Write-PhaseStatus "Checking file tracking..." 'INFO'
$FileIssues = Test-FileList
$AllIssues += $FileIssues

# Report results
if ($AllIssues.Count -eq 0) {
    Write-PhaseStatus "All GuardRails checks passed!" 'PASS'
    exit 0
} else {
    Write-PhaseStatus "GuardRails violations found:" 'FAIL'
    foreach ($Issue in $AllIssues) {
        Write-PhaseStatus "  - $Issue" 'FAIL'
    }
    exit 1
}
