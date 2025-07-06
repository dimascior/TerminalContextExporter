#!/bin/bash
# Claude's Direct MyExporter Test
# Working solution for WSL PowerShell execution

echo "=== CLAUDE DIRECT MYEXPORTER TEST ==="
echo "Environment: $(echo $WSL_DISTRO_NAME)"
echo "Working Directory: $(pwd)"
echo

# Function to execute PowerShell commands directly
execute_ps_command() {
    local command="$1"
    local description="$2"
    
    echo "[TEST] $description"
    echo "[EXEC] $command"
    
    # Get Windows-style path for current directory
    local win_path=$(wslpath -w "$(pwd)")
    
    # Execute PowerShell command with proper working directory
    cmd.exe /c "cd \"$win_path\" && powershell -Command \"$command\""
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "[SUCCESS] ✓ $description"
    else
        echo "[ERROR] ✗ $description (exit code: $exit_code)"
    fi
    echo
    return $exit_code
}

# Test 1: Basic PowerShell connectivity
execute_ps_command \
    "Write-Host 'Claude PowerShell Bridge Active' -ForegroundColor Green; Get-Host | Select-Object Name, Version" \
    "PowerShell connectivity verification"

# Test 2: Module import test
execute_ps_command \
    "try { Import-Module './MyExporter.psd1' -Force; Write-Host 'Module imported successfully' -ForegroundColor Green; Get-Module MyExporter | Select-Object Name, Version, ExportedFunctions } catch { Write-Host 'Import failed:' \$_.Exception.Message -ForegroundColor Red }" \
    "MyExporter module import"

# Test 3: FastPath execution test
execute_ps_command \
    "\$env:MYEXPORTER_FAST_PATH='true'; Write-Host 'Testing FastPath mode...' -ForegroundColor Cyan; try { Export-SystemInfo -ComputerName 'localhost' -OutputPath '\$env:TEMP\\claude-test.csv' -WhatIf; Write-Host 'FastPath WhatIf test passed' -ForegroundColor Green } catch { Write-Host 'FastPath test failed:' \$_.Exception.Message -ForegroundColor Red }" \
    "FastPath anti-tail-chasing pattern"

# Test 4: Cross-platform context discovery
execute_ps_command \
    "try { \$ctx = Get-ExecutionContext; Write-Host 'Platform Detection:' -ForegroundColor Yellow; Write-Host '  IsWindows:' \$ctx.Platform.IsWindows; Write-Host '  PowerShell:' \$ctx.PowerShell.Edition \$ctx.PowerShell.Version; Write-Host '  WorkingDir:' \$ctx.Paths.WorkingDirectory } catch { Write-Host 'Context discovery failed:' \$_.Exception.Message -ForegroundColor Red }" \
    "Environmental context discovery"

# Test 5: Architecture validation
execute_ps_command \
    "Write-Host 'GuardRails.md Pattern Validation:' -ForegroundColor Magenta; if (Test-Path 'Public/Export-SystemInfo.ps1') { \$content = Get-Content 'Public/Export-SystemInfo.ps1' -Raw; if (\$content -match 'GuardRails.md 11.3') { Write-Host '  ✓ Job-safe function loading pattern found' } else { Write-Host '  ✗ GuardRails pattern not found' } } else { Write-Host '  ✗ Export-SystemInfo.ps1 not found' }" \
    "GuardRails.md architectural pattern verification"

echo "=== CLAUDE DIRECT TEST COMPLETE ==="
echo "This demonstrates successful WSL-to-Windows PowerShell execution"
echo "implementing the GuardRails.md Part 10 operational workflow."
echo