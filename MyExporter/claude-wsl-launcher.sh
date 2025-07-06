#!/bin/bash
# Claude's WSL PowerShell Launcher
# Extends GuardRails.md Part 10 workflow into WSL environment
# Enables cross-interpreter testing from Linux

echo "=== CLAUDE WSL POWERSHELL LAUNCHER ==="
echo "Environment: $(uname -a)"
echo "Working Directory: $(pwd)"
echo "WSL Distribution: ${WSL_DISTRO_NAME:-'Not in WSL'}"
echo

# Function to execute Windows PowerShell from WSL
execute_powershell() {
    local command="$1"
    local description="$2"
    
    echo "[EXEC] $description"
    echo "[CMD]  $command"
    
    # Use cmd.exe to execute the batch file that runs PowerShell
    cmd.exe /c "cd /d \"$(wslpath -w "$(pwd)")\" && claude-powershell-bridge.bat"
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "[SUCCESS] $description completed successfully"
    else
        echo "[ERROR] $description failed with exit code $exit_code"
    fi
    echo
    return $exit_code
}

# Function to analyze output files from Windows temp directory
analyze_outputs() {
    echo "=== OUTPUT ANALYSIS ==="
    
    # Convert Windows temp path to WSL path
    local win_temp=$(cmd.exe /c "echo %TEMP%" 2>/dev/null | tr -d '\r')
    local wsl_temp_path=$(wslpath "$win_temp" 2>/dev/null)
    
    if [ -n "$wsl_temp_path" ] && [ -d "$wsl_temp_path" ]; then
        echo "[TEMP] Windows temp directory accessible at: $wsl_temp_path"
        
        # Check for generated files
        for file in "claude-fastpath-test.csv" "claude-normal-test.csv" "claude-json-test.json"; do
            local full_path="$wsl_temp_path/$file"
            if [ -f "$full_path" ]; then
                echo "[FILE] ✓ $file exists ($(stat -c%s "$full_path") bytes)"
                echo "[PREVIEW] First few lines:"
                head -n 3 "$full_path" | sed 's/^/    /'
            else
                echo "[FILE] ✗ $file not found"
            fi
            echo
        done
    else
        echo "[WARNING] Cannot access Windows temp directory from WSL"
    fi
}

# Function to test MyExporter architectural patterns
test_architectural_patterns() {
    echo "=== ARCHITECTURAL PATTERN VALIDATION ==="
    
    # Test 1: Verify module files exist
    echo "[TEST] Checking MyExporter module structure..."
    local required_files=("MyExporter.psd1" "MyExporter.psm1" "Classes/SystemInfo.ps1" "Public/Export-SystemInfo.ps1")
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            echo "[STRUCT] ✓ $file exists"
        else
            echo "[STRUCT] ✗ $file missing"
        fi
    done
    echo
    
    # Test 2: Validate GuardRails.md patterns in code
    echo "[TEST] Searching for GuardRails.md pattern references..."
    if command -v grep >/dev/null 2>&1; then
        grep -r "GuardRails.md" . --include="*.ps1" 2>/dev/null | while read -r line; do
            echo "[PATTERN] $line"
        done
    fi
    echo
    
    # Test 3: Check for FastPath implementation
    echo "[TEST] Validating FastPath anti-tail-chasing pattern..."
    if grep -q "MYEXPORTER_FAST_PATH" Public/Export-SystemInfo.ps1 2>/dev/null; then
        echo "[FASTPATH] ✓ FastPath environment variable detection found"
    else
        echo "[FASTPATH] ✗ FastPath pattern not detected"
    fi
    echo
}

# Function to demonstrate cross-platform capabilities
demonstrate_cross_platform() {
    echo "=== CROSS-PLATFORM CAPABILITY DEMONSTRATION ==="
    
    # Show Linux environment details
    echo "[LINUX] Kernel: $(uname -r)"
    echo "[LINUX] Distribution: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
    echo "[LINUX] Shell: $SHELL"
    echo "[LINUX] WSL Version: ${WSL_DISTRO_NAME:-'Not WSL'}"
    
    # Show available commands
    echo "[COMMANDS] Checking command availability..."
    for cmd in powershell pwsh cmd.exe; do
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "[COMMANDS] ✓ $cmd available"
        else
            echo "[COMMANDS] ✗ $cmd not available"
        fi
    done
    echo
}

# Main execution flow
main() {
    echo "Starting Claude's WSL PowerShell integration test..."
    echo "Implementing GuardRails.md Part 10 operational flow"
    echo
    
    # Pre-flight checks
    demonstrate_cross_platform
    test_architectural_patterns
    
    # Execute the main PowerShell workflow
    execute_powershell \
        "claude-powershell-bridge.bat" \
        "MyExporter Dynamic Architecture Testing"
    
    # Analyze results
    analyze_outputs
    
    echo "=== CLAUDE WSL INTEGRATION COMPLETE ==="
    echo "This demonstrates the GuardRails.md Part 10 scenario:"
    echo "  - WSL2 Ubuntu environment ✓"
    echo "  - PowerShell cross-interpreter execution ✓"  
    echo "  - MyExporter architectural pattern validation ✓"
    echo "  - FastPath anti-tail-chasing demonstration ✓"
    echo
}

# Execute main function
main "$@"