# Get-TerminalContextPlatformSpecific.ps1 - TasksV4 Phase 4.1
# Created: July 6, 2025
# Framework: GuardRails.md Part 2 - Platform Strategy
# Purpose: Capability-based routing for terminal context discovery

function Get-TerminalContextPlatformSpecific {
    <#
    .SYNOPSIS
    Discovers terminal capabilities and routes to platform-specific implementations
    
    .DESCRIPTION
    Implements capability-based routing to determine available terminal features:
    - WSL availability and version detection
    - Tmux availability and session management
    - Platform-specific terminal context gathering
    - Graceful degradation when capabilities unavailable
    
    .PARAMETER CorrelationId
    Correlation ID for telemetry tracking
    
    .PARAMETER IncludeCapabilityDetails
    Whether to include detailed capability detection results
    
    .PARAMETER ForceRefresh
    Whether to force refresh of cached capability detection
    
    .EXAMPLE
    $context = Get-TerminalContextPlatformSpecific -CorrelationId "platform-discovery"
    # Returns platform-specific terminal context with capability routing
    
    .EXAMPLE
    $context = Get-TerminalContextPlatformSpecific -IncludeCapabilityDetails -ForceRefresh
    # Returns detailed capability detection with forced refresh
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CorrelationId = [guid]::NewGuid().ToString(),
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeCapabilityDetails,
        
        [Parameter(Mandatory = $false)]
        [switch]$ForceRefresh
    )
    
    begin {
        Write-Debug "[$CorrelationId] Starting platform-specific terminal context discovery"
        
        # Import required functions
        if (-not (Get-Command Test-TerminalCapabilities -ErrorAction SilentlyContinue)) {
            . (Join-Path $PSScriptRoot "Test-TerminalCapabilities.ps1")
        }
    }
    
    process {
        try {
            # Initialize result object
            $result = [PSCustomObject]@{
                Platform = $null
                TerminalType = "Unknown"
                Capabilities = @{
                    WSL = @{
                        Available = $false
                        Version = $null
                        Distributions = @()
                        DefaultDistribution = $null
                    }
                    Tmux = @{
                        Available = $false
                        Version = $null
                        SessionsAvailable = $false
                        ActiveSessions = @()
                    }
                    PowerShell = @{
                        Version = $PSVersionTable.PSVersion.ToString()
                        Edition = $PSVersionTable.PSEdition
                        Platform = $PSVersionTable.Platform
                        OS = $PSVersionTable.OS
                    }
                    Native = @{
                        CommandPrompt = $false
                        WindowsTerminal = $false
                        ConEmu = $false
                        VSCodeTerminal = $false
                    }
                }
                RoutingDecision = $null
                PlatformSpecificContext = $null
                CorrelationId = $CorrelationId
                Timestamp = Get-Date
                CacheExpiry = $null
            }
            
            # Phase 1: Platform Detection
            Write-Debug "[$CorrelationId] Phase 1: Platform detection"
            
            if ($IsWindows -or $PSVersionTable.Platform -eq "Win32NT" -or $env:OS -eq "Windows_NT") {
                $result.Platform = "Windows"
            } elseif ($IsLinux -or $PSVersionTable.Platform -eq "Unix") {
                $result.Platform = "Linux"
            } elseif ($IsMacOS -or $PSVersionTable.Platform -eq "Darwin") {
                $result.Platform = "macOS"
            } else {
                $result.Platform = "Unknown"
            }
            
            Write-Debug "[$CorrelationId] Detected platform: $($result.Platform)"
            
            # Phase 2: Capability Detection
            Write-Debug "[$CorrelationId] Phase 2: Capability detection"
            
            $capabilities = Test-TerminalCapabilities -CorrelationId $CorrelationId -ForceRefresh:$ForceRefresh
            
            # Update capability results
            $result.Capabilities.WSL = $capabilities.WSL
            $result.Capabilities.Tmux = $capabilities.Tmux
            $result.Capabilities.Native = $capabilities.Native
            
            # Phase 3: Routing Decision
            Write-Debug "[$CorrelationId] Phase 3: Routing decision"
            
            if ($result.Capabilities.WSL.Available -and $result.Capabilities.Tmux.Available) {
                $result.RoutingDecision = "WSL_TMUX"
                $result.TerminalType = "WSL with Tmux"
                Write-Debug "[$CorrelationId] Routing to WSL + Tmux implementation"
            } elseif ($result.Capabilities.WSL.Available) {
                $result.RoutingDecision = "WSL_NATIVE"
                $result.TerminalType = "WSL Native"
                Write-Debug "[$CorrelationId] Routing to WSL native implementation"
            } elseif ($result.Platform -eq "Windows" -and $result.Capabilities.Native.CommandPrompt) {
                $result.RoutingDecision = "WINDOWS_CMD"
                $result.TerminalType = "Windows Command Prompt"
                Write-Debug "[$CorrelationId] Routing to Windows CMD implementation"
            } elseif ($result.Platform -eq "Windows" -and $result.Capabilities.Native.WindowsTerminal) {
                $result.RoutingDecision = "WINDOWS_TERMINAL"
                $result.TerminalType = "Windows Terminal"
                Write-Debug "[$CorrelationId] Routing to Windows Terminal implementation"
            } else {
                $result.RoutingDecision = "POWERSHELL_FALLBACK"
                $result.TerminalType = "PowerShell Fallback"
                Write-Debug "[$CorrelationId] Routing to PowerShell fallback implementation"
            }
            
            # Phase 4: Platform-Specific Context Loading
            Write-Debug "[$CorrelationId] Phase 4: Loading platform-specific context"
            
            switch ($result.RoutingDecision) {
                "WSL_TMUX" {
                    if (Get-Command Get-TerminalContext.WSL -ErrorAction SilentlyContinue) {
                        $result.PlatformSpecificContext = Get-TerminalContext.WSL -UseTmux -CorrelationId $CorrelationId
                    }
                }
                "WSL_NATIVE" {
                    if (Get-Command Get-TerminalContext.WSL -ErrorAction SilentlyContinue) {
                        $result.PlatformSpecificContext = Get-TerminalContext.WSL -CorrelationId $CorrelationId
                    }
                }
                "WINDOWS_CMD" {
                    if (Get-Command Get-TerminalContext.Windows -ErrorAction SilentlyContinue) {
                        $result.PlatformSpecificContext = Get-TerminalContext.Windows -UseCommandPrompt -CorrelationId $CorrelationId
                    }
                }
                "WINDOWS_TERMINAL" {
                    if (Get-Command Get-TerminalContext.Windows -ErrorAction SilentlyContinue) {
                        $result.PlatformSpecificContext = Get-TerminalContext.Windows -UseWindowsTerminal -CorrelationId $CorrelationId
                    }
                }
                default {
                    Write-Debug "[$CorrelationId] Using PowerShell fallback context"
                    $result.PlatformSpecificContext = @{
                        Type = "PowerShell"
                        Features = @("Basic", "Cmdlets", "Jobs")
                        Limitations = @("No terminal multiplexing", "No session persistence")
                    }
                }
            }
            
            # Set cache expiry (5 minutes for capability detection)
            $result.CacheExpiry = (Get-Date).AddMinutes(5)
            
            # Phase 5: Include detailed capability information if requested
            if ($IncludeCapabilityDetails) {
                $result | Add-Member -NotePropertyName "DetailedCapabilities" -NotePropertyValue $capabilities
            }
            
            Write-Debug "[$CorrelationId] Platform-specific terminal context discovery completed"
            return $result
            
        } catch {
            Write-Error "[$CorrelationId] Platform-specific terminal context discovery failed: $($_.Exception.Message)"
            
            # Return fallback context on error
            return [PSCustomObject]@{
                Platform = "Unknown"
                TerminalType = "Error Fallback"
                RoutingDecision = "ERROR_FALLBACK"
                PlatformSpecificContext = @{
                    Type = "Error"
                    Message = $_.Exception.Message
                }
                CorrelationId = $CorrelationId
                Timestamp = Get-Date
                Error = $_.Exception.Message
            }
        }
    }
}

# Cache for capability detection results
$script:TerminalCapabilityCache = @{}
$script:TerminalCacheExpiry = $null

function Get-CachedTerminalContext {
    <#
    .SYNOPSIS
    Gets cached terminal context if available and not expired
    
    .DESCRIPTION
    Provides caching layer for terminal context discovery to improve performance
    
    .PARAMETER CorrelationId
    Correlation ID for tracking
    
    .PARAMETER ForceRefresh
    Whether to force refresh of cache
    #>
    
    [CmdletBinding()]
    param(
        [string]$CorrelationId,
        [switch]$ForceRefresh
    )
    
    if ($ForceRefresh -or -not $script:TerminalCacheExpiry -or (Get-Date) -gt $script:TerminalCacheExpiry) {
        Write-Debug "[$CorrelationId] Terminal context cache expired or refresh forced"
        
        $context = Get-TerminalContextPlatformSpecific -CorrelationId $CorrelationId
        $script:TerminalCapabilityCache = $context
        $script:TerminalCacheExpiry = $context.CacheExpiry
        
        return $context
    } else {
        Write-Debug "[$CorrelationId] Using cached terminal context"
        return $script:TerminalCapabilityCache
    }
}

# Functions available for testing when called from module context
# Export-ModuleMember -Function Get-TerminalContextPlatformSpecific, Get-CachedTerminalContext
