# MyExporter/Public/Export-SystemInfo.ps1

<# .SYNOPSIS, .DESCRIPTION, etc. as you defined #>
function Export-SystemInfo {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([SystemInfo])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)] [string[]]$ComputerName,
        [Parameter(Mandatory)] [string]$OutputPath,
        [switch]$UseSSH,
        [switch]$AsJson
    )

    begin {
        # FASTPATH ESCAPE HATCH: Environment-controlled architectural bypass
        # This demonstrates the framework's pragmatic approach to avoiding tail-chasing
        if ($env:MYEXPORTER_FAST_PATH) {
            Write-Warning "FastPath mode enabled - bypassing full architectural compliance"
            $script:useFastPath = $true
            # Create simple output path for FastPath mode
            $script:safeOutputPath = $OutputPath
        } else {
            $script:useFastPath = $false
            
            # ARCHITECTURAL PATTERN: Establish execution context first
            $myExporterContext = Get-ExecutionContext
            Write-Debug "Execution context established: $($myExporterContext.CorrelationId)"
            
            # CONTEXTUAL HANDSHAKE: Before any work is done, validate the user-provided path
            # against the detected execution context. This prevents all path-related errors.
            $script:safeOutputPath = Assert-ContextPath -Path $OutputPath -ParameterName 'OutputPath'

            if ((Test-Path -LiteralPath $script:safeOutputPath) -and $PSCmdlet.ShouldProcess($script:safeOutputPath, "Overwrite existing file")) {
                Write-Warning "Output file '$script:safeOutputPath' will be overwritten."
            }
            
            # ARCHITECTURAL PATTERN: Create forward hashtable for parameter passing
            $forward = @{
                UseSSH = $UseSSH
                ExecutionContext = $myExporterContext
            }
        }
        
        # ARCHITECTURAL PATTERN: Use ArrayList for PowerShell 5.1 compatibility
        $results = New-Object System.Collections.ArrayList
    }

    process {
        # FASTPATH IMPLEMENTATION: Direct execution without jobs or complex architecture
        if ($script:useFastPath) {
            # Even in FastPath, we need basic context for correlation IDs
            $simpleContext = @{
                CorrelationId = [guid]::NewGuid().ToString()
                Platform = @{
                    IsWindows = $IsWindows
                    IsLinux = $IsLinux
                    IsMacOS = $IsMacOS
                }
            }
            
            foreach ($target in $ComputerName) {
                if (-not $PSCmdlet.ShouldProcess($target, "Export System Info (FastPath)")) { continue }
                
                try {
                    Write-Debug "FastPath: Attempting to call Get-SystemInfoPlatformSpecific for $target"
                    
                    # Direct call to platform-specific function with simple context
                    $systemInfo = Get-SystemInfoPlatformSpecific -ComputerName $target -UseSSH:$UseSSH -Context $simpleContext
                    Write-Debug "FastPath: Function returned: $($systemInfo -ne $null)"
                    if ($systemInfo) {
                        [void]$results.Add($systemInfo)
                        Write-Verbose "FastPath: Collected data from $target"
                    } else {
                        Write-Warning "FastPath: No data returned from $target"
                    }
                }
                catch {
                    Write-Error "FastPath failed on '$target': $($_.Exception.Message)"
                    Write-Debug "FastPath error details: $($_.ScriptStackTrace)"
                }
            }
            # Continue to end block for FastPath mode (don't return early)
        } else {
            # PowerShell 5.1 compatible parallel processing using jobs
            $jobs = @()
            
            # Prepare function definitions for job injection (GuardRails.md 11.3 pattern)
            $functionDefs = @()
            $functionDefs += (Get-Content "$((Split-Path $PSScriptRoot -Parent))\Classes\SystemInfo.ps1" -Raw)
            $functionDefs += (Get-Content "$((Split-Path $PSScriptRoot -Parent))\Private\Get-SystemInfo.Windows.ps1" -Raw)
            $functionDefs += (Get-Content "$((Split-Path $PSScriptRoot -Parent))\Private\Get-SystemInfo.Linux.ps1" -Raw)
            $functionDefs += (Get-Content "$((Split-Path $PSScriptRoot -Parent))\Private\Get-SystemInfoPlatformSpecific.ps1" -Raw)
            $functionDefsString = $functionDefs -join "`n"
            
            foreach ($target in $ComputerName) {
                if (-not $PSCmdlet.ShouldProcess($target, "Export System Info")) { continue }
                
                # Create a job for each target
                $job = Start-Job -ScriptBlock {
                    param($target, $useSSH, $functionDefs, $correlationId)
                    
                    # Re-hydrate function definitions in job context (GuardRails.md 11.3)
                    Invoke-Expression $functionDefs
                    
                    try {
                        # Create job-safe execution context (avoid $ExecutionContext collision)
                        $jobContext = @{
                            CorrelationId = $correlationId
                            Platform = @{
                                IsWindows = $IsWindows
                                IsLinux = $IsLinux
                                IsMacOS = $IsMacOS
                            }
                        }
                        
                        # Function call with job-safe context parameter
                        $info = Get-SystemInfoPlatformSpecific -ComputerName $target -UseSSH:$useSSH -Context $jobContext
                        return $info
                    }
                    catch {
                        Write-Error "Failed on '$target': $($_.Exception.Message)"
                        return $null
                    }
                } -ArgumentList $target, $UseSSH, $functionDefsString, $myExporterContext.CorrelationId
                
                $jobs += $job
            }
            
            # Wait for all jobs to complete and collect results
            if ($jobs.Count -gt 0) {
                Write-Verbose "Waiting for $($jobs.Count) background jobs to complete..."
                $jobResults = $jobs | Wait-Job | Receive-Job
                $jobs | Remove-Job
                
                # Add non-null results to our collection
                foreach ($result in $jobResults) {
                    if ($result) {
                        [void]$results.Add($result)
                    }
                }
            }
        }
    }

    end {
        if ($results.Count -eq 0) {
            Write-Warning "No data collected. Output file not created."
            return
        }

        Write-Verbose "Collected $($results.Count) records. Writing to '$script:safeOutputPath'."

        # Convert ArrayList to array for output
        $outputData = $results.ToArray()
        if ($AsJson) {
            $outputData | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $script:safeOutputPath -Encoding UTF8
        } else {
            $outputData | Export-Csv -LiteralPath $script:safeOutputPath -NoTypeInformation -Encoding UTF8
        }
        Write-Host "Export complete. Exported $($outputData.Count) records to: $script:safeOutputPath" -ForegroundColor Green
    }
}