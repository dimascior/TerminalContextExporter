#requires -version 5.1

<#
.SYNOPSIS
    Batch telemetry collector for terminal operations
.DESCRIPTION
    Implements GuardRails.md Part 3.2 Selective Telemetry patterns.
    Prevents telemetry pollution by batching and controlled flushing.
.PARAMETER Data
    Telemetry data to add to batch
.PARAMETER Result
    Result data to include with telemetry
.PARAMETER Flush
    Force flush current batch to storage
.PARAMETER GetStats
    Return current batch statistics
.EXAMPLE
    TerminalTelemetryBatcher -Data $telemetryData -Result $result
.EXAMPLE
    TerminalTelemetryBatcher -Flush
#>

function TerminalTelemetryBatcher {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Data,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Result,
        
        [Parameter(Mandatory = $false)]
        [switch]$Flush,
        
        [Parameter(Mandatory = $false)]
        [switch]$GetStats
    )
    
    # Static batch storage (module-scoped)
    if (-not $script:TelemetryBatch) {
        $script:TelemetryBatch = @{
            Items = @()
            LastFlush = Get-Date
            FlushThreshold = 50  # Configurable batch size
            MaxAge = [TimeSpan]::FromMinutes(5)  # Auto-flush after 5 minutes
        }
    }
    
    # Return statistics if requested
    if ($GetStats) {
        return @{
            ItemCount = $script:TelemetryBatch.Items.Count
            LastFlush = $script:TelemetryBatch.LastFlush
            NextAutoFlush = $script:TelemetryBatch.LastFlush.Add($script:TelemetryBatch.MaxAge)
            ThresholdReached = ($script:TelemetryBatch.Items.Count -ge $script:TelemetryBatch.FlushThreshold)
            AgeThresholdReached = ((Get-Date) - $script:TelemetryBatch.LastFlush) -gt $script:TelemetryBatch.MaxAge
        }
    }
    
    # Add telemetry item to batch
    if ($Data -and $Result) {
        $telemetryItem = @{
            Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            Data = $Data
            Result = $Result
            BatchSequence = $script:TelemetryBatch.Items.Count + 1
        }
        
        $script:TelemetryBatch.Items += $telemetryItem
        
        # Auto-flush if threshold reached
        $shouldFlush = ($script:TelemetryBatch.Items.Count -ge $script:TelemetryBatch.FlushThreshold) -or
                      (((Get-Date) - $script:TelemetryBatch.LastFlush) -gt $script:TelemetryBatch.MaxAge)
        
        if ($shouldFlush) {
            Write-Verbose "Auto-flushing telemetry batch (threshold: $($script:TelemetryBatch.FlushThreshold), age: $($script:TelemetryBatch.MaxAge))"
            TerminalTelemetryBatcher -Flush
        }
        
        return @{
            Added = $true
            BatchSize = $script:TelemetryBatch.Items.Count
            CorrelationId = $Data.CorrelationId
        }
    }
    
    # Flush current batch
    if ($Flush -or $script:TelemetryBatch.Items.Count -gt 0) {
        if ($script:TelemetryBatch.Items.Count -eq 0) {
            Write-Verbose "No telemetry items to flush"
            return @{ Flushed = 0; Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ" }
        }
        
        try {
            # Get execution context for telemetry storage
            $context = Get-ExecutionContext
            $telemetryPath = Join-Path $context.StateDirectory "terminal-telemetry"
            
            if (-not (Test-Path $telemetryPath)) {
                New-Item -Path $telemetryPath -ItemType Directory -Force | Out-Null
            }
            
            # Create batch file with timestamp
            $batchTimestamp = Get-Date -Format "yyyyMMdd-HHmmss-fff"
            $batchFile = Join-Path $telemetryPath "batch-$batchTimestamp.json"
            
            $batchData = @{
                BatchId = [System.Guid]::NewGuid().ToString()
                FlushTimestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
                ItemCount = $script:TelemetryBatch.Items.Count
                Items = $script:TelemetryBatch.Items
                Metadata = @{
                    ModuleVersion = (Get-Module MyExporter).Version.ToString()
                    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
                    Platform = $context.Platform
                    WorkingDirectory = $context.WorkingDirectory
                }
            }
            
            # Write batch to file (non-blocking)
            $batchData | ConvertTo-Json -Depth 10 | Out-File -FilePath $batchFile -Encoding UTF8
            
            $flushedCount = $script:TelemetryBatch.Items.Count
            
            # Reset batch
            $script:TelemetryBatch.Items = @()
            $script:TelemetryBatch.LastFlush = Get-Date
            
            Write-Verbose "Flushed $flushedCount telemetry items to: $batchFile"
            
            return @{
                Flushed = $flushedCount
                BatchFile = $batchFile
                Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            }
        }
        catch {
            Write-Warning "Failed to flush telemetry batch: $($_.Exception.Message)"
            return @{
                Flushed = 0
                Error = $_.Exception.Message
                Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            }
        }
    }
    
    # Default return if no action taken
    return @{
        Action = "None"
        BatchSize = $script:TelemetryBatch.Items.Count
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    }
}

# Function ready for dot-sourcing or module import
