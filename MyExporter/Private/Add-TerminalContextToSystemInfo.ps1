#requires -version 5.1

<#
.SYNOPSIS
    Integrate terminal context data into system information output
.DESCRIPTION
    Implements GuardRails.md Part 11.1 Parameter Flow patterns.
    Adds terminal context without breaking existing data structures.
.PARAMETER SystemInfo
    The base system information hashtable
.PARAMETER TerminalContext
    Terminal-specific context data to integrate
.PARAMETER Format
    Output format (CSV, JSON) for compatibility
.PARAMETER UseFastPath
    Whether to use minimal terminal data integration
.EXAMPLE
    Add-TerminalContextToSystemInfo -SystemInfo $sysInfo -TerminalContext $termContext -Format "JSON"
#>

function Add-TerminalContextToSystemInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SystemInfo,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$TerminalContext,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("CSV", "JSON")]
        [string]$Format = "JSON",
        
        [Parameter(Mandatory = $false)]
        [switch]$UseFastPath
    )
    
    # GuardRails Part 4.1: FastPath escape hatch
    if ($UseFastPath) {
        # Minimal terminal integration for FastPath
        if ($TerminalContext -and $TerminalContext.ContainsKey("Available")) {
            $SystemInfo["TerminalAvailable"] = $TerminalContext.Available
            if ($TerminalContext.ContainsKey("Platform")) {
                $SystemInfo["TerminalPlatform"] = $TerminalContext.Platform
            }
        }
        return $SystemInfo
    }
    
    # Full terminal integration
    if (-not $TerminalContext) {
        # Add placeholder terminal context for consistency
        $terminalData = @{
            Available = $false
            Platform = "None"
            Reason = "No terminal context provided"
            Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        }
    } else {
        $terminalData = $TerminalContext.Clone()
        $terminalData["IntegrationTimestamp"] = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    }
    
    # Format-specific integration
    switch ($Format) {
        "CSV" {
            # Flatten terminal data for CSV compatibility
            $flattenedTerminal = @{}
            foreach ($key in $terminalData.Keys) {
                $value = $terminalData[$key]
                if ($value -is [hashtable] -or $value -is [array]) {
                    # Convert complex objects to strings for CSV
                    $flattenedTerminal["Terminal_$key"] = ($value | ConvertTo-Json -Compress)
                } else {
                    $flattenedTerminal["Terminal_$key"] = $value
                }
            }
            
            # Merge flattened data into SystemInfo
            foreach ($key in $flattenedTerminal.Keys) {
                $SystemInfo[$key] = $flattenedTerminal[$key]
            }
        }
        
        "JSON" {
            # Preserve full terminal data structure in JSON
            $SystemInfo["TerminalContext"] = $terminalData
            
            # Add summary fields for easier access
            $SystemInfo["TerminalAvailable"] = $terminalData.Available
            if ($terminalData.ContainsKey("Platform")) {
                $SystemInfo["TerminalPlatform"] = $terminalData.Platform
            }
            if ($terminalData.ContainsKey("Sessions")) {
                $SystemInfo["TerminalSessionCount"] = $terminalData.Sessions.Count
            }
        }
    }
    
    # Add integration metadata
    $SystemInfo["TerminalIntegration"] = @{
        Version = "1.0"
        Format = $Format
        UsedFastPath = $UseFastPath.IsPresent
        IntegratedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        DataSource = if ($TerminalContext) { "Provided" } else { "Generated" }
    }
    
    return $SystemInfo
}

<#
.SYNOPSIS
    Helper function to collect current terminal output for integration
.DESCRIPTION
    Collects terminal output using appropriate capture method based on context.
.PARAMETER Commands
    Array of commands to execute in terminal
.PARAMETER Session
    TmuxSessionReference for execution context
.PARAMETER UseFastPath
    Whether to use FastPath capture
.EXAMPLE
    $output = Get-TerminalOutputForIntegration -Commands @("uname -a", "whoami") -Session $session
#>
function Get-TerminalOutputForIntegration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$Commands = @(),
        
        [Parameter(Mandatory = $false)]
        [object]$Session,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseFastPath
    )
    
    if (-not $Session -or $Commands.Count -eq 0) {
        return @{
            Available = $false
            Reason = "No session or commands provided"
            Commands = $Commands
        }
    }
    
    $results = @()
    $correlationId = [System.Guid]::NewGuid().ToString()
    
    foreach ($command in $Commands) {
        try {
            $output = Get-TerminalOutput.WSL -Command $command -Session $Session -UseFastPath:$UseFastPath -CorrelationId $correlationId
            $results += @{
                Command = $command
                Success = $output.Success
                Output = if ($output.Success) { $output.Output } else { $output.Error }
                Path = $output.Path
                Timestamp = $output.Timestamp
            }
        }
        catch {
            $results += @{
                Command = $command
                Success = $false
                Output = $_.Exception.Message
                Path = "Error"
                Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            }
        }
    }
    
    return @{
        Available = $true
        Results = $results
        CorrelationId = $correlationId
        ExecutionPath = if ($UseFastPath) { "FastPath" } else { "FullTelemetry" }
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    }
}

# Functions ready for dot-sourcing or module import
