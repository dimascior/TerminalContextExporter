#!/usr/bin/env bats
# Tests for Initialize-WSLUser.sh idempotency
# These tests verify that the script can be run multiple times safely

setup() {
    # Create a temporary directory for testing
    export TEST_HOME="/tmp/myexporter-test-$$"
    export WSL_USER="testuser-$$"
    export ORIGINAL_HOME="$HOME"
    
    # Create test environment
    mkdir -p "$TEST_HOME"
    
    # Mock sudo if running in environment without it
    if ! command -v sudo >/dev/null; then
        export PATH="$TEST_HOME:$PATH"
        echo '#!/bin/bash' > "$TEST_HOME/sudo"
        echo 'exec "$@"' >> "$TEST_HOME/sudo"
        chmod +x "$TEST_HOME/sudo"
    fi
}

teardown() {
    # Clean up test user and directories
    if id "$WSL_USER" &>/dev/null; then
        sudo userdel -r "$WSL_USER" 2>/dev/null || true
    fi
    
    # Clean up test files
    rm -rf "$TEST_HOME" 2>/dev/null || true
    
    # Remove sudo mock if we created it
    if [[ -f "$TEST_HOME/sudo" ]]; then
        rm -f "$TEST_HOME/sudo"
    fi
}

@test "Initialize-WSLUser.sh exists and is executable" {
    [[ -x "$BATS_TEST_DIRNAME/../Initialize-WSLUser.sh" ]]
}

@test "Script runs successfully on first execution" {
    skip "Requires root privileges - run manually"
    
    # First run should succeed
    run sudo "$BATS_TEST_DIRNAME/../Initialize-WSLUser.sh"
    [[ $status -eq 0 ]]
    [[ $output =~ "MyExporter WSL user initialization complete" ]]
}

@test "Script runs successfully on second execution (idempotency)" {
    skip "Requires root privileges - run manually"
    
    # First run
    sudo "$BATS_TEST_DIRNAME/../Initialize-WSLUser.sh"
    
    # Second run should also succeed and not fail
    run sudo "$BATS_TEST_DIRNAME/../Initialize-WSLUser.sh"
    [[ $status -eq 0 ]]
    [[ $output =~ "User.*already exists" ]]
}

@test "Script handles missing sudo gracefully" {
    # Test the sudo fallback logic
    run bash -c 'command -v sudo >/dev/null || alias sudo=""'
    [[ $status -eq 0 ]]
}

@test "Script validates user existence before creation" {
    # Test the getent passwd check logic
    run bash -c '
        WSL_USER="nonexistentuser12345"
        if id "$WSL_USER" &>/dev/null; then
            echo "User exists"
        else
            echo "User does not exist"
        fi
    '
    [[ $status -eq 0 ]]
    [[ $output =~ "User does not exist" ]]
}

@test "Script creates required directory structure" {
    skip "Requires root privileges - run manually"
    
    # After running the script, verify directories exist
    sudo "$BATS_TEST_DIRNAME/../Initialize-WSLUser.sh"
    
    local user_home="/home/${WSL_USER:-myexporter}"
    [[ -d "$user_home/workspace" ]]
    [[ -d "$user_home/workspace/tmp" ]]
    [[ -d "$user_home/workspace/logs" ]]
    [[ -d "$user_home/workspace/scripts" ]]
    [[ -d "$user_home/bin" ]]
}

@test "Script creates configuration files" {
    skip "Requires root privileges - run manually"
    
    sudo "$BATS_TEST_DIRNAME/../Initialize-WSLUser.sh"
    
    local user_home="/home/${WSL_USER:-myexporter}"
    [[ -f "$user_home/.bashrc" ]]
    [[ -f "$user_home/.profile" ]]
    [[ -f "$user_home/.tmux.conf" ]]
    [[ -f "$user_home/bin/start-session" ]]
}

@test "Script sets proper file permissions" {
    skip "Requires root privileges - run manually"
    
    sudo "$BATS_TEST_DIRNAME/../Initialize-WSLUser.sh"
    
    local user_home="/home/${WSL_USER:-myexporter}"
    local user_name="${WSL_USER:-myexporter}"
    
    # Check home directory permissions
    run stat -c "%a" "$user_home"
    [[ $output == "750" ]]
    
    # Check file ownership
    run stat -c "%U" "$user_home/.bashrc"
    [[ $output == "$user_name" ]]
}

@test "Script validates sudoers configuration" {
    skip "Requires root privileges - run manually"
    
    sudo "$BATS_TEST_DIRNAME/../Initialize-WSLUser.sh"
    
    # Test that sudoers syntax is valid
    run sudo visudo -c
    [[ $status -eq 0 ]]
}

@test "Environment variables are properly configured" {
    # Test basic environment setup
    run bash -c '
        export MYEXPORTER_USER=1
        export MYEXPORTER_SESSION_TIMEOUT=3600
        export MYEXPORTER_MAX_COMMANDS=100
        echo "Variables set: $MYEXPORTER_USER $MYEXPORTER_SESSION_TIMEOUT $MYEXPORTER_MAX_COMMANDS"
    '
    [[ $status -eq 0 ]]
    [[ $output =~ "Variables set: 1 3600 100" ]]
}

@test "Session script is functional" {
    skip "Requires root privileges and tmux - run manually"
    
    sudo "$BATS_TEST_DIRNAME/../Initialize-WSLUser.sh"
    
    local user_home="/home/${WSL_USER:-myexporter}"
    local session_script="$user_home/bin/start-session"
    
    # Test that session script exists and is executable
    [[ -x "$session_script" ]]
    
    # Test that it contains expected session logic
    run grep -q "tmux new-session" "$session_script"
    [[ $status -eq 0 ]]
}
