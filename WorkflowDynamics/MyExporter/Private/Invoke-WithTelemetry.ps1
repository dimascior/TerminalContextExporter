# MyExporter/Private/Invoke-WithTelemetry.ps1

<#
.SYNOPSIS
    Wraps operations with telemetry, correlation IDs, and structured error handling.
.DESCRIPTION
    This function implements the telemetry framework described in the unified architecture.
    It provides correlation tracking, timing metrics, and structured error objects.
    Compatible with Windows PowerShell 5.1+.
#>
function Invoke-WithTelemetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory)]
        [string]$OperationName,
        
        [hashtable]$Parameters = @{},
        
        [string]$CorrelationId = ([guid]::NewGuid()).ToString()
    )
    
    begin {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $startTime = Get-Date
        
        Write-Debug "[$CorrelationId] Starting operation: $OperationName"
        
        # Initialize telemetry context
        $telemetryContext = @{
            CorrelationId = $CorrelationId
            OperationName = $OperationName
            StartTime = $startTime
            Parameters = $Parameters
        }
    }
    
    process {
        try {
            # Execute the wrapped operation
            $result = & $ScriptBlock
            
            $telemetryContext.Success = $true
            $telemetryContext.Result = $result
            
            return $result
        }
        catch {
            $stopwatch.Stop()
            
            # Create structured error object as described in architecture
            $structuredError = [pscustomobject]@{
                CorrelationId = $CorrelationId
                Stage = $OperationName
                Error = $_
                Timestamp = Get-Date
                Duration = $stopwatch.Elapsed
            }
            
            $telemetryContext.Success = $false
            $telemetryContext.Error = $structuredError
            
            Write-Error "Operation '$OperationName' failed: $($_.Exception.Message)" -ErrorId "TELEMETRY_$($OperationName.ToUpper())"
            throw $structuredError
        }
        finally {
            $stopwatch.Stop()
            $telemetryContext.Duration = $stopwatch.Elapsed
            $telemetryContext.EndTime = Get-Date
            
            # Log telemetry data
            Write-Verbose "[$CorrelationId] Operation '$OperationName' completed in $($stopwatch.ElapsedMilliseconds)ms"
            
            # In a full implementation, this would write to structured logs
            # For now, we'll use Debug stream
            Write-Debug "TELEMETRY: $($telemetryContext | ConvertTo-Json -Compress)"
        }
    }
}
