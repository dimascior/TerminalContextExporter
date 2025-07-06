# MyExporter/Private/Get-ExecutionContext.ps1

<#
.SYNOPSIS
    Discovers and establishes the execution context for the module.
.DESCRIPTION
    Implements the Environment Context Discovery Framework described in the architecture.
    This function probes the environment and creates a comprehensive context object.
    Compatible with Windows PowerShell 5.1+.
#>
function Get-ExecutionContext {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    begin {
        $context = @{
            Timestamp = Get-Date
            CorrelationId = ([guid]::NewGuid()).ToString()
        }
    }
    
    process {
        # Platform Detection - PowerShell 5.1 compatible
        $context.Platform = @{
            IsWindows = if ($PSVersionTable.PSEdition -eq 'Desktop') { 
                $true 
            } else { 
                if (Get-Variable -Name 'IsWindows' -ErrorAction SilentlyContinue) { 
                    $IsWindows 
                } else { 
                    $true 
                }
            }
            IsLinux = if (Get-Variable -Name 'IsLinux' -ErrorAction SilentlyContinue) { 
                $IsLinux 
            } else { 
                $false 
            }
            IsMacOS = if (Get-Variable -Name 'IsMacOS' -ErrorAction SilentlyContinue) { 
                $IsMacOS 
            } else { 
                $false 
            }
            IsWSL = $false
            Architecture = if ([System.Environment]::Is64BitOperatingSystem) { 'X64' } else { 'X86' }
        }
        
        # WSL Detection (Windows PowerShell 5.1 compatible)
        if ($context.Platform.IsLinux -or (Test-Path '/proc/version' -ErrorAction SilentlyContinue)) {
            try {
                $wslVersion = Get-Content -Path '/proc/version' -ErrorAction SilentlyContinue
                if ($wslVersion -match 'Microsoft|WSL') {
                    $context.Platform.IsWSL = $true
                    $context.Platform.WSLVersion = if ($wslVersion -match 'WSL2') { '2' } else { '1' }
                }
            }
            catch {
                # Not critical if we can't detect WSL
                Write-Debug "Could not detect WSL version: $_"
            }
        }
        
        # PowerShell Environment (5.1 compatible)
        $context.PowerShell = @{
            Version = $PSVersionTable.PSVersion
            Edition = $PSVersionTable.PSEdition
            Host = $Host.Name
            ExecutionPolicy = Get-ExecutionPolicy
            ModulePath = $env:PSModulePath -split ';'
        }
        
        # Path Context
        $context.Paths = @{
            WorkingDirectory = (Get-Location).Path
            ScriptRoot = $PSScriptRoot
            ModuleRoot = Split-Path $PSScriptRoot -Parent
            TempPath = [System.IO.Path]::GetTempPath()
            UserProfile = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
        }
        
        # Environment Variables of Interest
        $context.Environment = @{
            PS7_PARALLEL_LIMIT = if ($env:PS7_PARALLEL_LIMIT) { $env:PS7_PARALLEL_LIMIT } else { '4' }
            MYEXPORTER_HOST = $env:MYEXPORTER_HOST
            PATH = $env:PATH
        }
        
        # Virtual Environment Detection
        $context.VirtualEnvironments = @{
            Python = @{
                VirtualEnv = $env:VIRTUAL_ENV
                CondaEnv = $env:CONDA_DEFAULT_ENV
                CondaPrefix = $env:CONDA_PREFIX
            }
            Node = @{
                NodeVersion = $env:NODE_VERSION
                NpmPrefix = $env:npm_config_prefix
            }
        }
        
        # Available Commands (Phase 6.2: Enhanced with terminal capabilities)
        $context.Commands = @{}
        $commonCommands = @('git', 'docker', 'python', 'python3', 'node', 'npm')
        
        # Phase 6.2: Terminal-specific command detection
        $terminalCommands = @('bash', 'tmux', 'wsl', 'screen')
        $allCommands = $commonCommands + $terminalCommands
        
        foreach ($cmd in $allCommands) {
            try {
                $cmdInfo = Get-Command $cmd -ErrorAction SilentlyContinue
                if ($cmdInfo) {
                    $context.Commands[$cmd] = @{
                        Available = $true
                        Path = $cmdInfo.Source
                        Version = try { & $cmd --version 2>$null } catch { 'Unknown' }
                    }
                } else {
                    $context.Commands[$cmd] = @{ Available = $false }
                }
            }
            catch {
                $context.Commands[$cmd] = @{ Available = $false; Error = $_.Exception.Message }
            }
        }
        
        # Phase 6.2: Terminal Capabilities Assessment
        $context.TerminalCapabilities = @{
            HasBash = $context.Commands.bash.Available
            HasTmux = $context.Commands.tmux.Available
            HasWSL = $context.Commands.wsl.Available -or $context.Platform.IsWSL
            HasScreen = $context.Commands.screen.Available
            CanUsePersistentSessions = $false
            Platform = "None"
            Reason = "No terminal capabilities detected"
        }
        
        # Determine best terminal platform
        if ($context.Platform.IsWSL -and $context.Commands.tmux.Available) {
            $context.TerminalCapabilities.CanUsePersistentSessions = $true
            $context.TerminalCapabilities.Platform = "WSL"
            $context.TerminalCapabilities.Reason = "WSL with tmux available"
        } elseif ($context.Platform.IsLinux -and $context.Commands.tmux.Available) {
            $context.TerminalCapabilities.CanUsePersistentSessions = $true
            $context.TerminalCapabilities.Platform = "Linux"
            $context.TerminalCapabilities.Reason = "Linux with tmux available"
        } elseif ($context.Platform.IsWindows -and $context.Commands.wsl.Available) {
            # Check if WSL has tmux
            try {
                $wslTmuxCheck = & wsl which tmux 2>$null
                if ($wslTmuxCheck) {
                    $context.TerminalCapabilities.CanUsePersistentSessions = $true
                    $context.TerminalCapabilities.Platform = "WSL"
                    $context.TerminalCapabilities.Reason = "Windows with WSL+tmux available"
                } else {
                    $context.TerminalCapabilities.Platform = "WSL-Basic"
                    $context.TerminalCapabilities.Reason = "Windows with WSL (no tmux)"
                }
            } catch {
                $context.TerminalCapabilities.Platform = "WSL-Unknown"
                $context.TerminalCapabilities.Reason = "Windows with WSL (tmux status unknown)"
            }
        } elseif ($context.Commands.screen.Available) {
            $context.TerminalCapabilities.CanUsePersistentSessions = $true
            $context.TerminalCapabilities.Platform = "Screen"
            $context.TerminalCapabilities.Reason = "GNU Screen available"
        }
        
        return $context
    }
}
