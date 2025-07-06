# Test-TerminalCapabilities.ps1 - TasksV4 Phase 4.3
# Created: July 6, 2025
# Framework: GuardRails.md Dynamic Discovery
# Purpose: WSL/tmux availability detection with detailed capability analysis

function Test-TerminalCapabilities {
    <#
    .SYNOPSIS
    Detects available terminal capabilities and features
    
    .DESCRIPTION
    Performs comprehensive detection of terminal capabilities including:
    - WSL availability, version, and distributions
    - Tmux availability, version, and active sessions
    - Native terminal features (Windows Terminal, CMD, etc.)
    - Platform-specific capabilities
    
    .PARAMETER CorrelationId
    Correlation ID for telemetry tracking
    
    .PARAMETER ForceRefresh
    Whether to force refresh of cached detection results
    
    .PARAMETER TimeoutSeconds
    Maximum time to spend on capability detection (default: 10)
    
    .EXAMPLE
    $caps = Test-TerminalCapabilities -CorrelationId "capability-check"
    # Returns detailed capability detection results
    
    .EXAMPLE
    $caps = Test-TerminalCapabilities -ForceRefresh -TimeoutSeconds 15
    # Forces fresh detection with extended timeout
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CorrelationId = [guid]::NewGuid().ToString(),
        
        [Parameter(Mandatory = $false)]
        [switch]$ForceRefresh,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 10
    )
    
    begin {
        Write-Debug "[$CorrelationId] Starting terminal capability detection"
        
        # Use cache if available and not expired
        if (-not $ForceRefresh -and $script:CapabilityCache -and $script:CapabilityCacheExpiry -and (Get-Date) -lt $script:CapabilityCacheExpiry) {
            Write-Debug "[$CorrelationId] Using cached capability detection results"
            return $script:CapabilityCache
        }
    }
    
    process {
        try {
            # Initialize capability result object
            $capabilities = [PSCustomObject]@{
                WSL = @{
                    Available = $false
                    Version = $null
                    Distributions = @()
                    DefaultDistribution = $null
                    InstallPath = $null
                    ExecutablePath = $null
                }
                Tmux = @{
                    Available = $false
                    Version = $null
                    SessionsAvailable = $false
                    ActiveSessions = @()
                    ExecutablePath = $null
                }
                Native = @{
                    CommandPrompt = $false
                    PowerShell = $true  # Always available since we're running in it
                    WindowsTerminal = $false
                    ConEmu = $false
                    VSCodeTerminal = $false
                    Bash = $false
                    Zsh = $false
                    Fish = $false
                }
                Platform = @{
                    OS = $PSVersionTable.OS
                    Platform = $PSVersionTable.Platform
                    IsWindows = ($IsWindows -or $PSVersionTable.Platform -eq "Win32NT" -or $env:OS -eq "Windows_NT")
                    IsLinux = ($IsLinux -or $PSVersionTable.Platform -eq "Unix")
                    IsMacOS = ($IsMacOS -or $PSVersionTable.Platform -eq "Darwin")
                }
                Detection = @{
                    Timestamp = Get-Date
                    Duration = $null
                    CorrelationId = $CorrelationId
                    Errors = @()
                    Warnings = @()
                }
            }
            
            $startTime = Get-Date
            
            # Phase 1: WSL Detection
            Write-Debug "[$CorrelationId] Phase 1: WSL detection"
            
            try {
                $wslCommand = Get-Command "wsl" -ErrorAction SilentlyContinue
                if ($wslCommand) {
                    $capabilities.WSL.Available = $true
                    $capabilities.WSL.ExecutablePath = $wslCommand.Source
                    
                    # Get WSL version
                    try {
                        $wslVersionOutput = & wsl --version 2>$null | Where-Object { $_ }
                        if ($wslVersionOutput) {
                            $cleanVersion = ($wslVersionOutput | Select-Object -First 1) -replace '\x00', '' -replace '\s+', ' '
                            $capabilities.WSL.Version = $cleanVersion.Trim()
                        }
                    } catch {
                        $capabilities.Detection.Warnings += "Could not determine WSL version: $($_.Exception.Message)"
                    }
                    
                    # Get WSL distributions
                    try {
                        $wslListOutput = & wsl --list --quiet 2>$null | Where-Object { $_ }
                        if ($wslListOutput) {
                            $cleanDistributions = $wslListOutput | ForEach-Object { ($_ -replace '\x00', '').Trim() } | Where-Object { $_ }
                            $capabilities.WSL.Distributions = $cleanDistributions
                        }
                        
                        # Get default distribution
                        $wslDefaultOutput = & wsl --list --verbose 2>$null | Where-Object { $_ -match '\*' }
                        if ($wslDefaultOutput) {
                            $cleanDefault = ($wslDefaultOutput -replace '\x00', '') -split '\s+' | Where-Object { $_ } | Select-Object -Skip 1 -First 1
                            $capabilities.WSL.DefaultDistribution = $cleanDefault
                        }
                    } catch {
                        $capabilities.Detection.Warnings += "Could not enumerate WSL distributions: $($_.Exception.Message)"
                    }
                    
                    Write-Debug "[$CorrelationId] WSL detected: Version $($capabilities.WSL.Version), Distributions: $($capabilities.WSL.Distributions.Count)"
                } else {
                    Write-Debug "[$CorrelationId] WSL not detected"
                }
            } catch {
                $capabilities.Detection.Errors += "WSL detection failed: $($_.Exception.Message)"
            }
            
            # Phase 2: Tmux Detection (requires WSL or native Unix)
            Write-Debug "[$CorrelationId] Phase 2: Tmux detection"
            
            try {
                if ($capabilities.WSL.Available) {
                    # Check tmux in WSL
                    try {
                        $tmuxCheckResult = & wsl sh -c "command -v tmux" 2>$null
                        if ($tmuxCheckResult) {
                            $capabilities.Tmux.Available = $true
                            $capabilities.Tmux.ExecutablePath = $tmuxCheckResult.Trim()
                            
                            # Get tmux version
                            try {
                                $tmuxVersionOutput = & wsl tmux -V 2>$null
                                if ($tmuxVersionOutput) {
                                    $capabilities.Tmux.Version = $tmuxVersionOutput.Trim()
                                }
                            } catch {
                                $capabilities.Detection.Warnings += "Could not determine tmux version: $($_.Exception.Message)"
                            }
                            
                            # Check for active tmux sessions
                            try {
                                $tmuxSessionsOutput = & wsl tmux list-sessions 2>$null
                                if ($tmuxSessionsOutput -and -not ($tmuxSessionsOutput -match "no server running")) {
                                    $capabilities.Tmux.SessionsAvailable = $true
                                    $capabilities.Tmux.ActiveSessions = $tmuxSessionsOutput | Where-Object { $_ -and $_.Trim() }
                                }
                            } catch {
                                # No sessions available - this is normal
                                Write-Debug "[$CorrelationId] No active tmux sessions found"
                            }
                            
                            Write-Debug "[$CorrelationId] Tmux detected in WSL: Version $($capabilities.Tmux.Version)"
                        }
                    } catch {
                        Write-Debug "[$CorrelationId] Tmux not available in WSL"
                    }
                } elseif ($capabilities.Platform.IsLinux -or $capabilities.Platform.IsMacOS) {
                    # Check tmux natively on Unix platforms
                    $tmuxCommand = Get-Command "tmux" -ErrorAction SilentlyContinue
                    if ($tmuxCommand) {
                        $capabilities.Tmux.Available = $true
                        $capabilities.Tmux.ExecutablePath = $tmuxCommand.Source
                        
                        try {
                            $tmuxVersionOutput = & tmux -V 2>$null
                            if ($tmuxVersionOutput) {
                                $capabilities.Tmux.Version = $tmuxVersionOutput.Trim()
                            }
                        } catch {
                            $capabilities.Detection.Warnings += "Could not determine native tmux version: $($_.Exception.Message)"
                        }
                        
                        Write-Debug "[$CorrelationId] Native tmux detected: Version $($capabilities.Tmux.Version)"
                    }
                }
            } catch {
                $capabilities.Detection.Errors += "Tmux detection failed: $($_.Exception.Message)"
            }
            
            # Phase 3: Native Terminal Detection
            Write-Debug "[$CorrelationId] Phase 3: Native terminal detection"
            
            try {
                if ($capabilities.Platform.IsWindows) {
                    # Windows-specific terminal detection
                    
                    # Command Prompt
                    $cmdCommand = Get-Command "cmd" -ErrorAction SilentlyContinue
                    $capabilities.Native.CommandPrompt = $null -ne $cmdCommand
                    
                    # Windows Terminal (check for wt.exe)
                    $wtCommand = Get-Command "wt" -ErrorAction SilentlyContinue
                    $capabilities.Native.WindowsTerminal = $null -ne $wtCommand
                    
                    # ConEmu (check for ConEmu environment variable)
                    $capabilities.Native.ConEmu = $null -ne $env:ConEmuPID
                    
                    # VS Code Terminal (check for VSCODE environment variables)
                    $capabilities.Native.VSCodeTerminal = ($null -ne $env:VSCODE_PID) -or ($null -ne $env:TERM_PROGRAM -and $env:TERM_PROGRAM -eq "vscode")
                    
                } else {
                    # Unix-specific shell detection
                    $bashCommand = Get-Command "bash" -ErrorAction SilentlyContinue
                    $capabilities.Native.Bash = $null -ne $bashCommand
                    
                    $zshCommand = Get-Command "zsh" -ErrorAction SilentlyContinue
                    $capabilities.Native.Zsh = $null -ne $zshCommand
                    
                    $fishCommand = Get-Command "fish" -ErrorAction SilentlyContinue
                    $capabilities.Native.Fish = $null -ne $fishCommand
                }
                
                Write-Debug "[$CorrelationId] Native terminal detection completed"
                
            } catch {
                $capabilities.Detection.Errors += "Native terminal detection failed: $($_.Exception.Message)"
            }
            
            # Finalize detection results
            $endTime = Get-Date
            $capabilities.Detection.Duration = $endTime - $startTime
            
            # Cache results for 5 minutes
            $script:CapabilityCache = $capabilities
            $script:CapabilityCacheExpiry = (Get-Date).AddMinutes(5)
            
            Write-Debug "[$CorrelationId] Terminal capability detection completed in $($capabilities.Detection.Duration.TotalSeconds) seconds"
            
            return $capabilities
            
        } catch {
            Write-Error "[$CorrelationId] Terminal capability detection failed: $($_.Exception.Message)"
            
            # Return minimal fallback capabilities
            return [PSCustomObject]@{
                WSL = @{ Available = $false }
                Tmux = @{ Available = $false }
                Native = @{ PowerShell = $true }
                Platform = @{ 
                    IsWindows = ($IsWindows -or $PSVersionTable.Platform -eq "Win32NT" -or $env:OS -eq "Windows_NT")
                }
                Detection = @{
                    Timestamp = Get-Date
                    CorrelationId = $CorrelationId
                    Errors = @($_.Exception.Message)
                }
            }
        }
    }
}

# Helper function for quick capability checks
function Test-SpecificCapability {
    <#
    .SYNOPSIS
    Tests for a specific terminal capability
    
    .DESCRIPTION
    Provides quick check for individual capabilities without full detection
    
    .PARAMETER Capability
    The capability to test (WSL, Tmux, WindowsTerminal, etc.)
    
    .PARAMETER CorrelationId
    Correlation ID for tracking
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("WSL", "Tmux", "WindowsTerminal", "CommandPrompt", "Bash", "VSCode")]
        [string]$Capability,
        
        [Parameter(Mandatory = $false)]
        [string]$CorrelationId = [guid]::NewGuid().ToString()
    )
    
    switch ($Capability) {
        "WSL" { 
            return $null -ne (Get-Command "wsl" -ErrorAction SilentlyContinue)
        }
        "Tmux" {
            $wslAvailable = $null -ne (Get-Command "wsl" -ErrorAction SilentlyContinue)
            if ($wslAvailable) {
                try {
                    $tmuxResult = & wsl sh -c "command -v tmux" 2>$null
                    return $null -ne $tmuxResult
                } catch {
                    return $false
                }
            }
            return $null -ne (Get-Command "tmux" -ErrorAction SilentlyContinue)
        }
        "WindowsTerminal" {
            return $null -ne (Get-Command "wt" -ErrorAction SilentlyContinue)
        }
        "CommandPrompt" {
            return $null -ne (Get-Command "cmd" -ErrorAction SilentlyContinue)
        }
        "Bash" {
            return $null -ne (Get-Command "bash" -ErrorAction SilentlyContinue)
        }
        "VSCode" {
            return ($null -ne $env:VSCODE_PID) -or ($null -ne $env:TERM_PROGRAM -and $env:TERM_PROGRAM -eq "vscode")
        }
        default {
            return $false
        }
    }
}

# Cache variables
$script:CapabilityCache = $null
$script:CapabilityCacheExpiry = $null

# Functions available for testing when called from module context
# Export-ModuleMember -Function Test-TerminalCapabilities, Test-SpecificCapability
