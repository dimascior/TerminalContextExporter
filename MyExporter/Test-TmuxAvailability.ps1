# Test-TmuxAvailability.ps1
# Real tmux capability verification for MyExporter terminal integration
# Addresses Project Manager question: "Does tmux integration actually work?"
# Created: July 6, 2025

function Test-TmuxAvailability {
    [CmdletBinding()]
    param(
        [switch]$Detailed,
        [switch]$CreateTestSession
    )
    
    $results = @{
        TmuxInstalled = $false
        SessionCreation = $false
        CommandExecution = $false
        SessionCleanup = $false
        EnvironmentSupported = $false
        Version = ""
        TestOutput = ""
        Error = ""
    }
    
    Write-Host "[TEST] Testing tmux Availability and Functionality" -ForegroundColor Cyan
    
    # Determine environment
    $environment = if ($IsWindows -and ((Get-Content /proc/version -ErrorAction SilentlyContinue) -match 'microsoft|wsl')) {
        "WSL2"
    } elseif ($IsLinux) {
        "Linux"
    } elseif ($IsMacOS) {
        "macOS"
    } else {
        "Unsupported"
    }
    
    Write-Host "Environment: $environment"
    
    if ($environment -eq "Unsupported") {
        Write-Host "[WARN] tmux testing not supported on this platform" -ForegroundColor Yellow
        $results.Error = "Platform not supported for tmux testing"
        return $results
    }
    
    $results.EnvironmentSupported = $true
    
    try {
        # Test 1: tmux command availability
        Write-Host "Step 1: Checking tmux installation..." -ForegroundColor Yellow
        
        $tmuxCommand = if ($environment -eq "WSL2") { "wsl tmux" } else { "tmux" }
        
        # Use & and command array to avoid Invoke-Expression
        if ($environment -eq "WSL2") {
            $versionOutput = & wsl tmux -V 2>$null
        } else {
            $versionOutput = & tmux -V 2>$null
        }
        
        if ($versionOutput -match "tmux (\d+\.\d+)") {
            $results.TmuxInstalled = $true
            $results.Version = $matches[1]
            Write-Host "[PASS] tmux installed: $versionOutput" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] tmux not available or not responding" -ForegroundColor Red
            $results.Error = "tmux command not found or not responding"
            return $results
        }
        
        if (-not $CreateTestSession) {
            Write-Host "[PASS] Basic tmux availability confirmed" -ForegroundColor Green
            return $results
        }
        
        # Test 2: Session creation
        Write-Host "Step 2: Testing session creation..." -ForegroundColor Yellow
        $sessionName = "tmux-test-$(Get-Date -Format 'HHmmss')"
        
        Write-Host "Creating session: $sessionName" -ForegroundColor Gray
        
        # Use direct command call instead of Invoke-Expression
        if ($environment -eq "WSL2") {
            & wsl tmux new-session -d -s $sessionName
        } else {
            & tmux new-session -d -s $sessionName
        }
        Start-Sleep -Seconds 1
        
        # Verify session exists
        if ($environment -eq "WSL2") {
            $sessions = & wsl tmux list-sessions 2>$null
        } else {
            $sessions = & tmux list-sessions 2>$null
        }
        
        if ($sessions -match $sessionName) {
            $results.SessionCreation = $true
            Write-Host "[PASS] Session created successfully: $sessionName" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] Session creation failed" -ForegroundColor Red
            $results.Error = "Failed to create tmux session"
            return $results
        }
        
        # Test 3: Command execution
        Write-Host "Step 3: Testing command execution..." -ForegroundColor Yellow
        $testCommand = 'echo "MyExporter tmux test - $(date)"'
        
        Write-Host "Sending command to session: $sessionName" -ForegroundColor Gray
        if ($environment -eq "WSL2") {
            & wsl tmux send-keys -t $sessionName $testCommand Enter
        } else {
            & tmux send-keys -t $sessionName $testCommand Enter
        }
        Start-Sleep -Seconds 2
        
        # Capture output using direct command
        if ($environment -eq "WSL2") {
            $output = & wsl tmux capture-pane -t $sessionName -p
        } else {
            $output = & tmux capture-pane -t $sessionName -p
        }
        
        Write-Host "Captured output:" -ForegroundColor Gray
        Write-Host $output -ForegroundColor White
        
        if ($output -match "MyExporter tmux test") {
            $results.CommandExecution = $true
            $results.TestOutput = $output
            Write-Host "[PASS] Command execution successful" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] Command execution failed or output not captured" -ForegroundColor Red
            $results.Error = "Command execution verification failed"
        }
        
        # Test 4: Session cleanup
        Write-Host "Step 4: Testing session cleanup..." -ForegroundColor Yellow
        
        Write-Host "Killing session: $sessionName" -ForegroundColor Gray
        if ($environment -eq "WSL2") {
            & wsl tmux kill-session -t $sessionName
        } else {
            & tmux kill-session -t $sessionName
        }
        Start-Sleep -Seconds 1
        
        # Verify session is gone
        if ($environment -eq "WSL2") {
            $sessionsAfter = & wsl tmux list-sessions 2>$null
        } else {
            $sessionsAfter = & tmux list-sessions 2>$null
        }
        
        if ($sessionsAfter -notmatch $sessionName) {
            $results.SessionCleanup = $true
            Write-Host "[PASS] Session cleanup successful" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Session may still exist" -ForegroundColor Yellow
            $results.SessionCleanup = $false
        }
        
    } catch {
        $results.Error = $_.Exception.Message
        Write-Host "[FAIL] tmux testing failed: $($_.Exception.Message)" -ForegroundColor Red
        
        # Attempt cleanup if session was created
        if ($results.SessionCreation -and $sessionName) {
            try {
                Write-Host "[INFO] Attempting cleanup of test session..." -ForegroundColor Yellow
                if ($environment -eq "WSL2") {
                    & wsl tmux kill-session -t $sessionName 2>$null
                } else {
                    & tmux kill-session -t $sessionName 2>$null
                }
            } catch {
                Write-Host "[WARN] Cleanup attempt failed, session may persist" -ForegroundColor Red
            }
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host "[SUMMARY] tmux Capability Summary:" -ForegroundColor Cyan
    Write-Host "  Environment Supported: $($results.EnvironmentSupported)" -ForegroundColor $(if ($results.EnvironmentSupported) { "Green" } else { "Red" })
    Write-Host "  tmux Installed: $($results.TmuxInstalled)" -ForegroundColor $(if ($results.TmuxInstalled) { "Green" } else { "Red" })
    Write-Host "  Session Creation: $($results.SessionCreation)" -ForegroundColor $(if ($results.SessionCreation) { "Green" } else { "Red" })
    Write-Host "  Command Execution: $($results.CommandExecution)" -ForegroundColor $(if ($results.CommandExecution) { "Green" } else { "Red" })
    Write-Host "  Session Cleanup: $($results.SessionCleanup)" -ForegroundColor $(if ($results.SessionCleanup) { "Green" } else { "Red" })
    
    if ($results.Error) {
        Write-Host "  Error: $($results.Error)" -ForegroundColor Red
    }
    
    $overallSuccess = $results.TmuxInstalled -and $results.SessionCreation -and $results.CommandExecution -and $results.SessionCleanup
    Write-Host "  Overall: $(if ($overallSuccess) { "[PASS] READY FOR INTEGRATION" } else { "[FAIL] NOT READY" })" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Red" })
    
    return $results
}

# Export function for module use
Export-ModuleMember -Function Test-TmuxAvailability

# If run directly, execute test
if ($MyInvocation.InvocationName -ne '.') {
    Test-TmuxAvailability -CreateTestSession -Detailed
}
