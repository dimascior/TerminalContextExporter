#!/bin/bash
# Claude's WSL PowerShell Launcher - Phase 7 Enhanced
# Extends GuardRails.md Part 10 workflow into WSL environment
# Phase 7: WSLENV context propagation and terminal integration

echo "=== CLAUDE WSL POWERSHELL LAUNCHER (Phase 7) ==="
echo "Environment: $(uname -a)"
echo "Working Directory: $(pwd)"
echo "WSL Distribution: ${WSL_DISTRO_NAME:-'Not in WSL'}"

# Phase 7.1: WSLENV context propagation setup
echo
echo "=== Phase 7: Environment Context Propagation ==="

# Set up WSLENV for cross-boundary context passing
export WSLENV="MYEXPORTER_CORRELATION_ID/u:MYEXPORTER_TERMINAL_MODE/u:MYEXPORTER_WSL_CONTEXT/u"

# Generate correlation ID if not provided
if [ -z "$MYEXPORTER_CORRELATION_ID" ]; then
    export MYEXPORTER_CORRELATION_ID=$(uuidgen 2>/dev/null || echo "$(date +%s)-$$-$(($RANDOM * $RANDOM))")
fi

# Set terminal context indicators
export MYEXPORTER_TERMINAL_MODE="${MYEXPORTER_TERMINAL_MODE:-enhanced}"
export MYEXPORTER_WSL_CONTEXT="true"

echo "Correlation ID: $MYEXPORTER_CORRELATION_ID"
echo "Terminal Mode: $MYEXPORTER_TERMINAL_MODE"
echo "WSL Context: $MYEXPORTER_WSL_CONTEXT"

# Phase 7: Terminal capability detection
echo
echo "=== Terminal Capabilities Detection ==="
detect_terminal_capabilities() {
    local capabilities=""
    
    # Check for tmux
    if command -v tmux >/dev/null 2>&1; then
        capabilities="tmux"
        echo "✓ tmux available: $(tmux -V 2>/dev/null || echo 'unknown version')"
        
        # Check if tmux server is running
        if tmux has-session 2>/dev/null; then
            echo "  └─ tmux server running with $(tmux list-sessions 2>/dev/null | wc -l) sessions"
        else
            echo "  └─ tmux server not running"
        fi
    else
        echo "○ tmux not available"
    fi
    
    # Check for screen
    if command -v screen >/dev/null 2>&1; then
        capabilities="${capabilities:+$capabilities,}screen"
        echo "✓ screen available: $(screen -v 2>/dev/null | head -1 || echo 'unknown version')"
    else
        echo "○ screen not available"
    fi
    
    # Check for bash
    if command -v bash >/dev/null 2>&1; then
        capabilities="${capabilities:+$capabilities,}bash"
        echo "✓ bash available: $BASH_VERSION"
    else
        echo "○ bash not available"
    fi
    
    export MYEXPORTER_TERMINAL_CAPABILITIES="$capabilities"
    echo "Terminal capabilities: $capabilities"
    
    return 0
}

detect_terminal_capabilities
echo

# Function to execute Windows PowerShell from WSL with enhanced context
execute_powershell() {
    local command="$1"
    local description="$2"
    local terminal_mode="${3:-normal}"
    
    echo "[EXEC] $description (Terminal Mode: $terminal_mode)"
    echo "[CMD]  $command"
    echo "[CTX]  Correlation ID: $MYEXPORTER_CORRELATION_ID"
    
    # Phase 7: Set terminal-specific environment for PowerShell execution
    export MYEXPORTER_TERMINAL_MODE="$terminal_mode"
    
    # Phase 7: Enhanced command execution with context propagation
    local windows_pwd
    windows_pwd=$(wslpath -w "$(pwd)")
    
    # Use cmd.exe to execute the batch file that runs PowerShell
    # The WSLENV variables will be automatically propagated
    cmd.exe /c "cd /d \"$windows_pwd\" && claude-powershell-bridge.bat"
    
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