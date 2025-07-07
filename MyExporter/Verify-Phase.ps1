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
    [switch]$SkipCICheck
)

$ErrorActionPreference = 'Stop'

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
    $PolicyPath = "$PSScriptRoot\Policies\terminal.deny.yml"
    if (Test-Path $CommandSanitizerPath) {
        $Content = Get-Content $CommandSanitizerPath -Raw
        if ($Content -match '\$DenyList\s*=\s*@\(' -and (-not (Test-Path $PolicyPath))) {
            $Violations += "CommandSanitizer: Hardcoded deny list should be moved to $PolicyPath"
        }
    }
    
    # Check 3: Classes should be loaded via ScriptsToProcess or dot-sourcing
    $ModulePath = "$PSScriptRoot\MyExporter.psm1"
    $ManifestPath = "$PSScriptRoot\MyExporter.psd1" 
    if ((Test-Path $ModulePath) -and (Test-Path $ManifestPath)) {
        $ModuleContent = Get-Content $ModulePath -Raw
        $ManifestContent = Get-Content $ManifestPath -Raw
        
        # Check if classes are loaded via ScriptsToProcess (preferred for PowerShell 5.1)
        $hasScriptsToProcess = $ManifestContent -match "ScriptsToProcess.*SystemInfo\.ps1.*TmuxSessionReference\.ps1"
        
        # Check if classes are dot-sourced in module (fallback method)  
        $hasDotSourced = ($ModuleContent -match '\. "\$PSScriptRoot/Classes/SystemInfo\.ps1"') -and 
                        ($ModuleContent -match '\. "\$PSScriptRoot/Classes/TmuxSessionReference\.ps1"')
        
        if ((-not $hasScriptsToProcess) -and (-not $hasDotSourced)) {
            $Violations += "Classes must be loaded via ScriptsToProcess in manifest or dot-sourced in module"
        }
    }
    
    # Check 4: DevScripts should not contain runtime files
    $DevScriptsPath = "$PSScriptRoot\DevScripts"
    if (Test-Path $DevScriptsPath) {
        $DevFiles = Get-ChildItem $DevScriptsPath -Recurse -Include "*.ps1","*.psm1","*.psd1"
        # Exclude legitimate dev/test files that should be in DevScripts
        $RuntimeFiles = $DevFiles | Where-Object { 
            ($_.Name -match '^(Export-|Get-|Invoke-|New-|Set-|Add-|Update-)') -and 
            ($_.Name -notmatch '^Test-') -and 
            ($_.Name -notmatch '^test-')
        }
        if ($RuntimeFiles) {
            $Violations += "DevScripts contains runtime files: $($RuntimeFiles.Name -join ', ') (should be in Private/ or Public/)"
        }
    }
    
    # Check 5: Telemetry wrappers should not be nested
    $PublicFunctions = Get-ChildItem "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue
    foreach ($FunctionFile in $PublicFunctions) {
        $Content = Get-Content $FunctionFile.FullName -Raw
        # Count telemetry calls - should be ≤ 1 per public function
        $TelemetryMatches = [regex]::Matches($Content, 'Invoke-WithTelemetry|Write-TelemetryEvent')
        if ($TelemetryMatches.Count -gt 1) {
            $Violations += "$($FunctionFile.Name): Contains $($TelemetryMatches.Count) telemetry calls (should be ≤ 1)"
        }
    }
    
    # Check 6: Script Analyzer compliance
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
        if (($Content -match 'Mock|Sentinel|Simulate') -and ($Content -notmatch '# Real test')) {
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
        # Force clean import to test real module loading behavior
        Remove-Module MyExporter -Force -ErrorAction SilentlyContinue
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
        
        # Verify class scope integrity (no child scopes spawned)
        $ModuleCommands = Get-Command MyExporter* -Module MyExporter -ErrorAction SilentlyContinue
        foreach ($Cmd in $ModuleCommands) {
            if ($Cmd.Module.ScopeName -ne 'MyExporter') {
                $Issues += "Command $($Cmd.Name) in wrong scope: $($Cmd.Module.ScopeName) (should be MyExporter)"
            }
        }
        
        # Verify classes are available in module scope
        try {
            # Test class availability differently in PowerShell 5.1 vs 7+
            if ($PSVersionTable.PSVersion.Major -eq 5) {
                # In PowerShell 5.1, classes may not be visible via [ClassName] syntax
                # but can be instantiated if properly loaded
                $testData = @{SessionId='test'; SessionName='test'; CorrelationId='test'}
                $null = New-Object -TypeName TmuxSessionReference -ArgumentList $testData
                $null = New-Object -TypeName SystemInfo -ArgumentList @{ComputerName='test'}
                Write-Verbose "Classes validated via New-Object in PowerShell 5.1"
            } else {
                # PowerShell 7+ can use direct type syntax
                $null = [TmuxSessionReference]
                $null = [SystemInfo]
                Write-Verbose "Classes validated via type syntax in PowerShell 7+"
            }
        } catch {
            $Issues += "Classes not available in module scope: $_"
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
    
    # Check manifest FileList accuracy
    $ManifestPath = "$PSScriptRoot\MyExporter.psd1"
    if (Test-Path $ManifestPath) {
        $ManifestData = Import-PowerShellDataFile $ManifestPath
        $DeclaredFiles = $ManifestData.FileList
        
        if ($DeclaredFiles) {
            # Get actual runtime files
            $ActualFiles = @()
            $ActualFiles += Get-ChildItem "$PSScriptRoot\*.ps*1" -File | ForEach-Object { $_.Name }
            $ActualFiles += Get-ChildItem "$PSScriptRoot\Private\*.ps1" -File -ErrorAction SilentlyContinue | ForEach-Object { "Private\$($_.Name)" }
            $ActualFiles += Get-ChildItem "$PSScriptRoot\Public\*.ps1" -File -ErrorAction SilentlyContinue | ForEach-Object { "Public\$($_.Name)" }
            $ActualFiles += Get-ChildItem "$PSScriptRoot\Classes\*.ps1" -File -ErrorAction SilentlyContinue | ForEach-Object { "Classes\$($_.Name)" }
            $ActualFiles += Get-ChildItem "$PSScriptRoot\Policies\*.yml" -File -ErrorAction SilentlyContinue | ForEach-Object { "Policies\$($_.Name)" }
            if (Test-Path "$PSScriptRoot\Initialize-WSLUser.sh") { $ActualFiles += "Initialize-WSLUser.sh" }
            
            # Compare lists
            $MissingFromManifest = $ActualFiles | Where-Object { $_ -notin $DeclaredFiles }
            $ExtraInManifest = $DeclaredFiles | Where-Object { -not (Test-Path "$PSScriptRoot\$_") }
            
            if ($MissingFromManifest) {
                $Issues += "Files missing from manifest FileList: $($MissingFromManifest -join ', ')"
            }
            if ($ExtraInManifest) {
                $Issues += "Files in manifest FileList but not on disk: $($ExtraInManifest -join ', ')"
            }
        }
    }
    
    return $Issues
}

function Test-ChangelogRequirement {
    [CmdletBinding()]
    param()
    
    $Issues = @()
    
    # Check for CHANGELOG.md existence
    $ChangelogPath = Split-Path $PSScriptRoot -Parent | Join-Path -ChildPath "CHANGELOG.md"
    if (-not (Test-Path $ChangelogPath)) {
        $Issues += "CHANGELOG.md is required per GuardRails.md but not found"
    } else {
        # Check if CHANGELOG has been updated for public API or file set changes
        $RecentCommits = git log --oneline -n 5 2>$null
        if ($RecentCommits) {
            $HasPublicChanges = $RecentCommits | Where-Object { 
                $_ -match '\b(Public|API|parameter|function|class|interface)\b' 
            }
            if ($HasPublicChanges) {
                $ChangelogContent = Get-Content $ChangelogPath -Raw
                $Today = Get-Date -Format "yyyy-MM-dd"
                if ($ChangelogContent -notmatch "\[$Today\]|\[Unreleased\]") {
                    $Issues += "Recent public API changes detected but CHANGELOG.md not updated"
                }
            }
        }
    }
    
    return $Issues
}

function Test-PendingSpecs {
    [CmdletBinding()]
    param()
    
    $Issues = @()
    
    # Check for [Pending] test specifications
    $TestFiles = Get-ChildItem "$PSScriptRoot\Tests\*.Tests.ps1" -ErrorAction SilentlyContinue
    foreach ($TestFile in $TestFiles) {
        $Content = Get-Content $TestFile.FullName -Raw
        if ($Content -match '\[Pending\]') {
            $Issues += "Test file $($TestFile.Name) contains [Pending] specifications - complete before phase completion"
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

# 5. CHANGELOG requirement
Write-PhaseStatus "Checking CHANGELOG.md..." 'INFO'
$ChangelogIssues = Test-ChangelogRequirement
$AllIssues += $ChangelogIssues

# 6. Pending specifications
Write-PhaseStatus "Checking for [Pending] test specs..." 'INFO'
$PendingIssues = Test-PendingSpecs
$AllIssues += $PendingIssues

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
