<#
.SYNOPSIS
Invoke-FreshSession: Isolated PowerShell execution environment

.DESCRIPTION
Spawns a fresh PowerShell process to avoid state pollution.
Essential for: module loading tests, class instantiation, telemetry isolation.

.PARAMETER ScriptBlock
PowerShell code to execute in fresh session

.PARAMETER ArgumentList
Arguments to pass to script block

.PARAMETER Wait
If true, block until completion. If false, return job object

.PARAMETER SessionTag
Tag for logging (e.g., "test-phase-3-leg-1")

.EXAMPLE
$Result = Invoke-FreshSession {
    Import-Module MyExporter
    Export-SystemInfo -ComputerName localhost
} -SessionTag "phase3-leg1" -Wait $true
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [scriptblock]$ScriptBlock,
    
    [string[]]$ArgumentList = @(),
    
    [bool]$Wait = $true,
    
    [string]$SessionTag = "fresh-session"
)

$PSVersion = $PSVersionTable.PSVersion.Major
$Edition = $PSVersionTable.PSEdition

Write-Host "[FRESH-SESSION] Spawning isolated PowerShell ($Edition PS$PSVersion)" -ForegroundColor Cyan
Write-Host "[SESSION-TAG] $SessionTag"

# Build argument list for job
$JobArgs = @($SessionTag, $ScriptBlock) + $ArgumentList

# Spawn fresh session
$Job = Start-Job -ScriptBlock {
    param($Tag, [scriptblock]$Script, $Args)
    
    $StartTime = Get-Date
    Write-Host "[JOB-START] $Tag at $StartTime"
    
    try {
        # Execute in isolated context
        $Result = & $Script @Args
        
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        
        Write-Host "[JOB-SUCCESS] $Tag completed in $Duration seconds" -ForegroundColor Green
        
        @{
            Tag = $Tag
            Status = "PASS"
            Result = $Result
            StartTime = $StartTime
            EndTime = $EndTime
            DurationSeconds = $Duration
        }
    }
    catch {
        Write-Host "[JOB-ERROR] $Tag failed with: $_" -ForegroundColor Red
        
        @{
            Tag = $Tag
            Status = "FAIL"
            Error = $_.Exception.Message
            StackTrace = $_.ScriptStackTrace
            StartTime = Get-Date
        }
    }
} -ArgumentList $JobArgs -Name $SessionTag

if ($Wait) {
    # Wait for completion
    $JobResult = Wait-Job -Job $Job | Receive-Job
    Remove-Job -Job $Job
    
    Write-Host "[SESSION-COMPLETE] $SessionTag"
    return $JobResult
}
else {
    Write-Host "[SESSION-STARTED] Job ID: $($Job.Id) (non-blocking)"
    return $Job
}
