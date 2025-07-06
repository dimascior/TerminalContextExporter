#requires -version 5.1

<#
.SYNOPSIS
    Dual-path terminal output capture for WSL environments
.DESCRIPTION
    Implements FastPath vs Full Telemetry capture patterns based on system context.
    Follows GuardRails.md Part 4.1 FastPath Pattern requirements.
.PARAMETER Command
    The command to execute in the terminal
.PARAMETER Session
    TmuxSessionReference object for session context
.PARAMETER UseFastPath
    Whether to use FastPath (minimal telemetry) or Full capture
.PARAMETER CorrelationId
    Correlation ID for telemetry tracking
.EXAMPLE
    Get-TerminalOutput.WSL -Command "uname -a" -Session $session -UseFastPath
#>

function Get-TerminalOutput.WSL {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        
        [Parameter(Mandatory = $true)]
        [object]$Session,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseFastPath,
        
        [Parameter(Mandatory = $false)]
        [string]$CorrelationId = [System.Guid]::NewGuid().ToString()
    )
    
    # GuardRails Part 4.1: FastPath escape hatch
    if ($UseFastPath) {
        try {
            # Minimal overhead path - direct execution
            $result = Invoke-WslTmuxCommand -Command $Command -Session $Session -SkipTelemetry
            return @{
                Success = $true
                Output = $result.Output
                CorrelationId = $CorrelationId
                Path = "FastPath"
                Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            }
        }
        catch {
            # Even FastPath includes basic error context
            return @{
                Success = $false
                Error = $_.Exception.Message
                CorrelationId = $CorrelationId
                Path = "FastPath-Error"
                Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            }
        }
    }
    
    # Full telemetry path
    $startTime = Get-Date
    $telemetryData = @{
        CorrelationId = $CorrelationId
        Command = $Command
        SessionId = $Session.SessionId
        StartTime = $startTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        Platform = "WSL"
    }
    
    try {
        # Enhanced execution with full telemetry
        $result = Invoke-WslTmuxCommand -Command $Command -Session $Session
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        $fullResult = @{
            Success = $true
            Output = $result.Output
            CorrelationId = $CorrelationId
            Path = "FullTelemetry"
            Timestamp = $endTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            Duration = $duration
            Telemetry = $telemetryData
            ExitCode = $result.ExitCode
            SessionState = $Session.GetCurrentState()
        }
        
        # Queue telemetry for batching (non-blocking)
        TerminalTelemetryBatcher -Data $telemetryData -Result $fullResult
        
        return $fullResult
    }
    catch {
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        $errorResult = @{
            Success = $false
            Error = $_.Exception.Message
            CorrelationId = $CorrelationId
            Path = "FullTelemetry-Error"
            Timestamp = $endTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            Duration = $duration
            Telemetry = $telemetryData
        }
        
        # Queue error telemetry as well
        TerminalTelemetryBatcher -Data $telemetryData -Result $errorResult
        
        return $errorResult
    }
}

# Function ready for dot-sourcing or module import
