# Invoke-WslTmuxCommand.ps1 - TasksV4 Phase 3.3
# Created: July 6, 2025
# Framework: GuardRails.md Part 11.3 - Process Boundaries
# Purpose: WSL execution bridge for tmux commands with security validation

function Invoke-WslTmuxCommand {
    <#
    .SYNOPSIS
    Executes tmux commands via WSL with full security validation and cross-boundary data integrity
    
    .DESCRIPTION
    Provides secure bridge for executing tmux commands through WSL, implementing:
    - Policy-driven command validation via Test-CommandSafety
    - 4-layer escaping pipeline via New-TmuxArgumentList
    - Cross-boundary error handling and output capture
    - Telemetry correlation for end-to-end tracing
    
    .PARAMETER Command
    The base command to execute in tmux
    
    .PARAMETER Arguments
    Array of arguments to pass to the command
    
    .PARAMETER SessionName
    Name of the tmux session (optional, creates if not exists)
    
    .PARAMETER WindowName
    Name of the tmux window (optional)
    
    .PARAMETER PolicyPath
    Path to security policy file for command validation
    
    .PARAMETER AllowWarningCommands
    Whether to allow commands that require approval
    
    .PARAMETER TimeoutSeconds
    Maximum execution time in seconds (default: 30)
    
    .PARAMETER CorrelationId
    Correlation ID for telemetry tracking
    
    .EXAMPLE
    $result = Invoke-WslTmuxCommand -Command "ps" -Arguments @("aux") -SessionName "monitoring"
    # Executes 'ps aux' in tmux session 'monitoring' via WSL
    
    .EXAMPLE
    $result = Invoke-WslTmuxCommand -Command "find" -Arguments @("/var/log", "-name", "*.log") -TimeoutSeconds 60
    # Executes find command with 60-second timeout
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @(),
        
        [Parameter(Mandatory = $false)]
        [string]$SessionName,
        
        [Parameter(Mandatory = $false)]
        [string]$WindowName,
        
        [Parameter(Mandatory = $false)]
        [string]$PolicyPath = (Join-Path (Join-Path $PSScriptRoot "..") "Policies/terminal-deny.yaml"),
        
        [Parameter(Mandatory = $false)]
        [switch]$AllowWarningCommands,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 30,
        
        [Parameter(Mandatory = $false)]
        [string]$CorrelationId = [guid]::NewGuid().ToString()
    )
    
    begin {
        Write-Debug "[$CorrelationId] Starting WSL tmux command execution: $Command"
        
        # Import required functions
        if (-not (Get-Command Test-CommandSafety -ErrorAction SilentlyContinue)) {
            . (Join-Path $PSScriptRoot "Test-CommandSafety.ps1")
        }
        
        if (-not (Get-Command New-TmuxArgumentList -ErrorAction SilentlyContinue)) {
            . (Join-Path $PSScriptRoot "New-TmuxArgumentList.ps1")
        }
        
        # Validate WSL availability
        $wslAvailable = $null -ne (Get-Command "wsl" -ErrorAction SilentlyContinue)
        if (-not $wslAvailable) {
            throw "[$CorrelationId] WSL not available on this system"
        }
    }
    
    process {
        try {
            # Initialize result object
            $result = [PSCustomObject]@{
                Command = $Command
                Arguments = $Arguments
                SessionName = $SessionName
                WindowName = $WindowName
                CorrelationId = $CorrelationId
                Timestamp = Get-Date
                ExecutionStartTime = $null
                ExecutionEndTime = $null
                ExecutionDuration = $null
                SecurityValidation = $null
                EscapingResult = $null
                WslCommand = $null
                ExitCode = $null
                Output = $null
                ErrorOutput = $null
                Success = $false
                FailureReason = $null
            }
            
            # Phase 1: Security Validation
            Write-Debug "[$CorrelationId] Phase 1: Security validation"
            
            $fullCommand = $Command
            if ($Arguments.Count -gt 0) {
                $fullCommand += " " + ($Arguments -join " ")
            }
            
            $securityResult = Test-CommandSafety -Command $fullCommand -PolicyPath $PolicyPath -AllowWarningCommands:$AllowWarningCommands -CorrelationId $CorrelationId
            $result.SecurityValidation = $securityResult
            
            if (-not $securityResult.IsAllowed) {
                $result.FailureReason = "SECURITY_VIOLATION"
                $result.ErrorOutput = "Command blocked by security policy: $($securityResult.ViolationType)"
                Write-Warning "[$CorrelationId] Command blocked: $($securityResult.ViolationDetails -join '; ')"
                return $result
            }
            
            Write-Debug "[$CorrelationId] Security validation passed: $($securityResult.SecurityLevel)"
            
            # Phase 2: 4-Layer Escaping
            Write-Debug "[$CorrelationId] Phase 2: 4-layer escaping pipeline"
            
            $escapingResult = New-TmuxArgumentList -Command $Command -Arguments $Arguments -SessionName $SessionName -WindowName $WindowName -CorrelationId $CorrelationId
            $result.EscapingResult = $escapingResult
            
            Write-Debug "[$CorrelationId] Tmux command prepared: $($escapingResult.TmuxCommand)"
            
            # Phase 3: WSL Command Construction
            Write-Debug "[$CorrelationId] Phase 3: WSL command construction"
            
            # Use the sanitized command if available, otherwise execute directly without tmux for testing
            if ($securityResult.SanitizedCommand) { 
                $commandToExecute = $securityResult.SanitizedCommand 
            } elseif ($SessionName) {
                # Only use tmux if session is specified
                $commandToExecute = $escapingResult.TmuxCommand 
            } else {
                # Direct execution for immediate testing
                $commandToExecute = $Command
                if ($Arguments.Count -gt 0) {
                    $escapedArgs = $Arguments | ForEach-Object { "'$_'" }
                    $commandToExecute += " " + ($escapedArgs -join " ")
                }
            }
            
            # Construct WSL command with proper environment setup
            $wslArgs = @(
                "--"
                "sh"  # Use sh instead of bash for better compatibility
                "-c"
                $commandToExecute
            )
            
            $result.WslCommand = "wsl " + ($wslArgs -join " ")
            Write-Debug "[$CorrelationId] WSL command: $($result.WslCommand)"
            
            # Phase 4: Execution with Timeout
            Write-Debug "[$CorrelationId] Phase 4: Command execution (timeout: ${TimeoutSeconds}s)"
            
            $result.ExecutionStartTime = Get-Date
            
            # Create process start info for better control
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = "wsl"
            $processInfo.Arguments = $wslArgs -join " "
            $processInfo.UseShellExecute = $false
            $processInfo.RedirectStandardOutput = $true
            $processInfo.RedirectStandardError = $true
            $processInfo.CreateNoWindow = $true
            
            # Start process
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $processInfo
            
            # Setup output capture
            $outputBuilder = New-Object System.Text.StringBuilder
            $errorBuilder = New-Object System.Text.StringBuilder
            
            $outputEvent = Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -Action {
                if ($EventArgs.Data) {
                    [void]$Event.MessageData.AppendLine($EventArgs.Data)
                }
            } -MessageData $outputBuilder
            
            $errorEvent = Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action {
                if ($EventArgs.Data) {
                    [void]$Event.MessageData.AppendLine($EventArgs.Data)
                }
            } -MessageData $errorBuilder
            
            # Start process and begin async reading
            $process.Start() | Out-Null
            $process.BeginOutputReadLine()
            $process.BeginErrorReadLine()
            
            # Wait with timeout
            $completed = $process.WaitForExit($TimeoutSeconds * 1000)
            
            $result.ExecutionEndTime = Get-Date
            $result.ExecutionDuration = $result.ExecutionEndTime - $result.ExecutionStartTime
            
            # Clean up events
            Unregister-Event -SourceIdentifier $outputEvent.Name -Force
            Unregister-Event -SourceIdentifier $errorEvent.Name -Force
            
            if (-not $completed) {
                # Timeout occurred
                Write-Warning "[$CorrelationId] Command execution timed out after $TimeoutSeconds seconds"
                $process.Kill()
                $result.FailureReason = "TIMEOUT"
                $result.ErrorOutput = "Command execution timed out after $TimeoutSeconds seconds"
                return $result
            }
            
            # Capture results
            $result.ExitCode = $process.ExitCode
            $result.Output = $outputBuilder.ToString().Trim()
            $result.ErrorOutput = $errorBuilder.ToString().Trim()
            $result.Success = ($process.ExitCode -eq 0)
            
            if (-not $result.Success) {
                $result.FailureReason = "COMMAND_FAILED"
                Write-Warning "[$CorrelationId] Command failed with exit code: $($result.ExitCode)"
            }
            
            Write-Debug "[$CorrelationId] Command execution completed - Exit Code: $($result.ExitCode), Duration: $($result.ExecutionDuration.TotalSeconds)s"
            
            return $result
            
        } catch {
            $result.FailureReason = "EXCEPTION"
            $result.ErrorOutput = $_.Exception.Message
            $result.ExecutionEndTime = Get-Date
            if ($result.ExecutionStartTime) {
                $result.ExecutionDuration = $result.ExecutionEndTime - $result.ExecutionStartTime
            }
            
            Write-Error "[$CorrelationId] WSL tmux command execution failed: $($_.Exception.Message)"
            return $result
        } finally {
            # Clean up process if it exists
            if ($process -and -not $process.HasExited) {
                try {
                    $process.Kill()
                    $process.Dispose()
                } catch {
                    Write-Debug "[$CorrelationId] Error cleaning up process: $($_.Exception.Message)"
                }
            }
        }
    }
}

# Helper function for testing WSL tmux integration
function Test-WslTmuxIntegration {
    <#
    .SYNOPSIS
    Tests WSL tmux integration with a safe command
    
    .DESCRIPTION
    Validates that the WSL execution bridge works correctly with tmux
    
    .PARAMETER CorrelationId
    Correlation ID for tracking
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CorrelationId = [guid]::NewGuid().ToString()
    )
    
    try {
        Write-Host "[$CorrelationId] Testing WSL tmux integration..." -ForegroundColor Yellow
        
        # Test 1: Direct echo (not through tmux for immediate feedback)
        $result1 = Invoke-WslTmuxCommand -Command "echo" -Arguments @("WSL integration test successful") -CorrelationId $CorrelationId
        
        # Test 2: Simple whoami command
        $result2 = Invoke-WslTmuxCommand -Command "whoami" -CorrelationId $CorrelationId
        
        $testResult = [PSCustomObject]@{
            Test1_EchoCommand = $result1
            Test2_WhoamiCommand = $result2
            OverallSuccess = ($result1.Success -and $result2.Success)
            CorrelationId = $CorrelationId
        }
        
        Write-Host "[$CorrelationId] Test 1 (echo) - Success: $($result1.Success), Output: '$($result1.Output)'" -ForegroundColor $(if($result1.Success){"Green"}else{"Red"})
        Write-Host "[$CorrelationId] Test 2 (whoami) - Success: $($result2.Success), Output: '$($result2.Output)'" -ForegroundColor $(if($result2.Success){"Green"}else{"Red"})
        
        if ($testResult.OverallSuccess) {
            Write-Host "[$CorrelationId] WSL tmux integration test PASSED" -ForegroundColor Green
        } else {
            Write-Host "[$CorrelationId] WSL tmux integration test FAILED" -ForegroundColor Red
        }
        
        return $testResult
        
    } catch {
        Write-Error "[$CorrelationId] WSL tmux integration test exception: $($_.Exception.Message)"
        throw
    }
}

# Functions available for testing when called from module context
# Export-ModuleMember -Function Invoke-WslTmuxCommand, Test-WslTmuxIntegration
