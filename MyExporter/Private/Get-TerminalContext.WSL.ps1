# Get-TerminalContext.WSL.ps1 - TasksV4 Phase 4.2
# Created: July 6, 2025
# Framework: GuardRails.md Part 2 - Platform Strategy
# Purpose: WSL-specific terminal context implementation

function Get-TerminalContext.WSL {
    <#
    .SYNOPSIS
    Gets WSL-specific terminal context and capabilities
    
    .DESCRIPTION
    Implements WSL-specific terminal context discovery including:
    - WSL distribution information and environment
    - Tmux session management (if available)
    - Path translation between Windows and WSL
    - Environment variable propagation
    - User and permission context
    
    .PARAMETER UseTmux
    Whether to include tmux session management
    
    .PARAMETER Distribution
    Specific WSL distribution to use (uses default if not specified)
    
    .PARAMETER CorrelationId
    Correlation ID for telemetry tracking
    
    .PARAMETER IncludeEnvironment
    Whether to include detailed environment information
    
    .EXAMPLE
    $context = Get-TerminalContext.WSL -UseTmux -CorrelationId "wsl-context"
    # Returns WSL context with tmux session management
    
    .EXAMPLE
    $context = Get-TerminalContext.WSL -Distribution "Ubuntu" -IncludeEnvironment
    # Returns Ubuntu-specific context with environment details
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$UseTmux,
        
        [Parameter(Mandatory = $false)]
        [string]$Distribution,
        
        [Parameter(Mandatory = $false)]
        [string]$CorrelationId = [guid]::NewGuid().ToString(),
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeEnvironment
    )
    
    begin {
        Write-Debug "[$CorrelationId] Starting WSL-specific terminal context discovery"
        
        # Verify WSL availability
        $wslAvailable = $null -ne (Get-Command "wsl" -ErrorAction SilentlyContinue)
        if (-not $wslAvailable) {
            throw "[$CorrelationId] WSL not available on this system"
        }
    }
    
    process {
        try {
            # Initialize WSL context object
            $context = [PSCustomObject]@{
                Type = "WSL"
                Platform = "Linux"
                Distribution = @{
                    Name = $null
                    Version = $null
                    DefaultUser = $null
                    InstallLocation = $null
                    State = $null
                }
                Environment = @{
                    Shell = $null
                    HomeDirectory = $null
                    WorkingDirectory = $null
                    PathTranslation = @{
                        WindowsToWSL = @{}
                        WSLToWindows = @{}
                    }
                    Variables = @{}
                }
                Tmux = @{
                    Available = $false
                    Version = $null
                    Sessions = @()
                    DefaultSession = $null
                }
                Capabilities = @{
                    FileSystem = @{
                        WindowsAccess = $false
                        NetworkDrives = $false
                        Permissions = $null
                    }
                    Networking = @{
                        HostAccess = $false
                        InternetAccess = $false
                        Localhost = $false
                    }
                    Interop = @{
                        WindowsExecution = $false
                        PathTranslation = $false
                        EnvironmentSharing = $false
                    }
                }
                CorrelationId = $CorrelationId
                Timestamp = Get-Date
                Errors = @()
                Warnings = @()
            }
            
            # Phase 1: Distribution Discovery
            Write-Debug "[$CorrelationId] Phase 1: WSL distribution discovery"
            
            try {
                # Get available distributions
                $distributionList = & wsl --list --verbose 2>$null
                if ($distributionList) {
                    # Parse distribution information
                    $distributions = @()
                    foreach ($line in $distributionList) {
                        # Clean up Unicode null characters and extra whitespace
                        $cleanLine = ($line -replace '\x00', '').Trim()
                        
                        # Skip header line and empty lines
                        if ($cleanLine -match '^NAME\s+STATE\s+VERSION' -or [string]::IsNullOrWhiteSpace($cleanLine)) {
                            continue
                        }
                        
                        # Parse distribution line: [*] NAME STATE VERSION
                        if ($cleanLine -match '^\s*([*\s])\s*([^\s]+)\s+([^\s]+)\s+(\d+)') {
                            $isDefault = $matches[1].Trim() -eq '*'
                            $distName = $matches[2].Trim()
                            $state = $matches[3].Trim()
                            $version = $matches[4].Trim()
                            
                            $distributions += [PSCustomObject]@{
                                Name = $distName
                                IsDefault = $isDefault
                                State = $state
                                Version = $version
                            }
                            
                            if ($isDefault -and -not $Distribution) {
                                $Distribution = $distName
                            }
                        }
                    }
                    
                    # Use specified or default distribution
                    $targetDist = $distributions | Where-Object { $_.Name -eq $Distribution } | Select-Object -First 1
                    if ($targetDist) {
                        $context.Distribution.Name = $targetDist.Name
                        $context.Distribution.Version = $targetDist.Version
                        $context.Distribution.State = $targetDist.State
                        
                        Write-Debug "[$CorrelationId] Using WSL distribution: $($targetDist.Name) (Version: $($targetDist.Version), State: $($targetDist.State))"
                    } else {
                        $context.Errors += "Specified distribution '$Distribution' not found"
                        return $context
                    }
                } else {
                    $context.Errors += "No WSL distributions found"
                    return $context
                }
            } catch {
                $context.Errors += "Failed to discover WSL distributions: $($_.Exception.Message)"
                return $context
            }
            
            # Phase 2: Environment Discovery
            Write-Debug "[$CorrelationId] Phase 2: WSL environment discovery"
            
            try {
                # Get shell information
                $shellInfo = & wsl -d $Distribution sh -c "echo `$SHELL; echo `$HOME; pwd" 2>$null
                if ($shellInfo -and $shellInfo.Count -ge 3) {
                    $context.Environment.Shell = $shellInfo[0]
                    $context.Environment.HomeDirectory = $shellInfo[1]
                    $context.Environment.WorkingDirectory = $shellInfo[2]
                }
                
                # Get default user
                $userInfo = & wsl -d $Distribution whoami 2>$null
                if ($userInfo) {
                    $context.Distribution.DefaultUser = $userInfo.Trim()
                }
                
                # Test capabilities
                $context.Capabilities.FileSystem.WindowsAccess = Test-WSLCapability -Distribution $Distribution -Capability "WindowsFileAccess" -CorrelationId $CorrelationId
                $context.Capabilities.Networking.HostAccess = Test-WSLCapability -Distribution $Distribution -Capability "HostNetworking" -CorrelationId $CorrelationId
                $context.Capabilities.Interop.WindowsExecution = Test-WSLCapability -Distribution $Distribution -Capability "WindowsInterop" -CorrelationId $CorrelationId
                
                Write-Debug "[$CorrelationId] WSL environment discovered - User: $($context.Distribution.DefaultUser), Shell: $($context.Environment.Shell)"
                
            } catch {
                $context.Warnings += "Partial environment discovery failure: $($_.Exception.Message)"
            }
            
            # Phase 3: Tmux Integration (if requested)
            if ($UseTmux) {
                Write-Debug "[$CorrelationId] Phase 3: Tmux integration discovery"
                
                try {
                    # Check if tmux is available
                    $tmuxAvailable = & wsl -d $Distribution sh -c "command -v tmux" 2>$null
                    if ($tmuxAvailable) {
                        $context.Tmux.Available = $true
                        
                        # Get tmux version
                        $tmuxVersion = & wsl -d $Distribution tmux -V 2>$null
                        if ($tmuxVersion) {
                            $context.Tmux.Version = $tmuxVersion.Trim()
                        }
                        
                        # Get active sessions
                        $tmuxSessions = & wsl -d $Distribution tmux list-sessions 2>$null
                        if ($tmuxSessions -and -not ($tmuxSessions -match "no server running")) {
                            $context.Tmux.Sessions = $tmuxSessions | Where-Object { $_ -and $_.Trim() }
                        }
                        
                        # Set or get default session
                        if ($context.Tmux.Sessions.Count -eq 0) {
                            $context.Tmux.DefaultSession = "myexporter-default"
                            Write-Debug "[$CorrelationId] No active tmux sessions, will create default: $($context.Tmux.DefaultSession)"
                        } else {
                            $context.Tmux.DefaultSession = ($context.Tmux.Sessions[0] -split ':')[0]
                            Write-Debug "[$CorrelationId] Using existing tmux session: $($context.Tmux.DefaultSession)"
                        }
                        
                        Write-Debug "[$CorrelationId] Tmux available in WSL: Version $($context.Tmux.Version), Sessions: $($context.Tmux.Sessions.Count)"
                    } else {
                        $context.Warnings += "Tmux not available in WSL distribution: $Distribution"
                    }
                } catch {
                    $context.Warnings += "Tmux discovery failed: $($_.Exception.Message)"
                }
            }
            
            # Phase 4: Path Translation Setup
            Write-Debug "[$CorrelationId] Phase 4: Path translation setup"
            
            try {
                # Common Windows to WSL path translations
                $context.Environment.PathTranslation.WindowsToWSL = @{
                    "C:\" = "/mnt/c/"
                    "D:\" = "/mnt/d/"
                    "$env:USERPROFILE" = "/mnt/c/Users/$env:USERNAME"
                    "$env:TEMP" = "/tmp"
                    "$PSScriptRoot" = Convert-WindowsPathToWSL -Path $PSScriptRoot
                }
                
                # WSL to Windows translations
                $context.Environment.PathTranslation.WSLToWindows = @{
                    "/mnt/c/" = "C:\"
                    "/tmp" = "$env:TEMP"
                    "/home/$($context.Distribution.DefaultUser)" = "/mnt/c/Users/$env:USERNAME"
                }
                
                $context.Capabilities.Interop.PathTranslation = $true
                
            } catch {
                $context.Warnings += "Path translation setup failed: $($_.Exception.Message)"
            }
            
            # Phase 5: Environment Variables (if requested)
            if ($IncludeEnvironment) {
                Write-Debug "[$CorrelationId] Phase 5: Environment variable discovery"
                
                try {
                    $envOutput = & wsl -d $Distribution sh -c "env" 2>$null
                    if ($envOutput) {
                        foreach ($line in $envOutput) {
                            if ($line -match '^([^=]+)=(.*)$') {
                                $context.Environment.Variables[$matches[1]] = $matches[2]
                            }
                        }
                        
                        Write-Debug "[$CorrelationId] Captured $($context.Environment.Variables.Count) environment variables"
                    }
                } catch {
                    $context.Warnings += "Environment variable discovery failed: $($_.Exception.Message)"
                }
            }
            
            Write-Debug "[$CorrelationId] WSL-specific terminal context discovery completed"
            return $context
            
        } catch {
            Write-Error "[$CorrelationId] WSL terminal context discovery failed: $($_.Exception.Message)"
            
            $context.Errors += $_.Exception.Message
            return $context
        }
    }
}

# Helper function to test WSL capabilities
function Test-WSLCapability {
    <#
    .SYNOPSIS
    Tests specific WSL capabilities
    
    .PARAMETER Distribution
    WSL distribution to test
    
    .PARAMETER Capability
    Capability to test
    
    .PARAMETER CorrelationId
    Correlation ID for tracking
    #>
    
    [CmdletBinding()]
    param(
        [string]$Distribution,
        [string]$Capability,
        [string]$CorrelationId
    )
    
    try {
        switch ($Capability) {
            "WindowsFileAccess" {
                $result = & wsl -d $Distribution sh -c "test -d /mnt/c && echo 'true' || echo 'false'" 2>$null
                return $result -eq "true"
            }
            "HostNetworking" {
                $result = & wsl -d $Distribution sh -c "ping -c 1 -W 1 host.docker.internal >/dev/null 2>&1 && echo 'true' || echo 'false'" 2>$null
                return $result -eq "true"
            }
            "WindowsInterop" {
                $result = & wsl -d $Distribution sh -c "cmd.exe /c echo test >/dev/null 2>&1 && echo 'true' || echo 'false'" 2>$null
                return $result -eq "true"
            }
            default {
                return $false
            }
        }
    } catch {
        Write-Debug "[$CorrelationId] WSL capability test failed for $Capability`: $($_.Exception.Message)"
        return $false
    }
}

# Helper function to convert Windows paths to WSL paths
function Convert-WindowsPathToWSL {
    <#
    .SYNOPSIS
    Converts Windows path to WSL path format
    
    .PARAMETER Path
    Windows path to convert
    #>
    
    [CmdletBinding()]
    param([string]$Path)
    
    if ($Path -match '^([A-Za-z]):(.*)$') {
        $drive = $matches[1].ToLower()
        $remainder = $matches[2] -replace '\\', '/'
        return "/mnt/$drive$remainder"
    } else {
        return $Path -replace '\\', '/'
    }
}

# Functions available for testing when called from module context
# Export-ModuleMember -Function Get-TerminalContext.WSL, Test-WSLCapability, Convert-WindowsPathToWSL
