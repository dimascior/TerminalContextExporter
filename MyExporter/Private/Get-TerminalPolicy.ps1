function Get-TerminalPolicy {
    <#
    .SYNOPSIS
        Loads terminal security policy from YAML configuration file.
    
    .DESCRIPTION
        This function loads the terminal command security policy from the 
        Policies/terminal.deny.yml file and returns a structured policy object
        that can be used by Test-CommandSafety.ps1 for command validation.
        
        Implements GuardRails.md policy-driven security architecture.
    
    .PARAMETER PolicyPath
        Path to the policy YAML file. Defaults to module's Policies directory.
    
    .OUTPUTS
        [PSCustomObject] Policy object with security rules and configurations.
    
    .EXAMPLE
        $policy = Get-TerminalPolicy
        $isAllowed = Test-CommandSafety -Command "ps aux" -Policy $policy
    
    .NOTES
        Author: MyExporter Module
        GuardRails: Part 3.2 - Security Foundation
        Dependencies: PowerShell-Yaml module (optional, falls back to manual parsing)
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [string]$PolicyPath
    )
    
    begin {
        Write-Verbose "Starting terminal policy load operation"
        
        # Default policy path relative to module root
        if (-not $PolicyPath) {
            $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
            $PolicyPath = Join-Path $moduleRoot "Policies\terminal.deny.yml"
        }
        
        # Fallback policy in case file is missing or corrupted
        $fallbackPolicy = @{
            version = "1.0"
            description = "Fallback security policy"
            denied_commands = @("rm -rf", "del /s", "format", "sudo", "curl", "wget")
            injection_patterns = @(";", "&&", "||", "|", "`$(", "``", "eval", "exec")
            allowed_commands = @("ps", "ls", "echo", "tmux")
            max_command_length = 500
            audit_logging = $true
            tmux = @{
                max_sessions = 5
                session_name_pattern = "^[a-zA-Z0-9-_]+`$"
                max_session_lifetime = 30
                allowed_in_tmux = @("ps aux", "echo", "exit")
            }
        }
    }
    
    process {
        try {
            # Verify policy file exists
            if (-not (Test-Path $PolicyPath)) {
                Write-Warning "Policy file not found at '$PolicyPath', using fallback policy"
                return [PSCustomObject]$fallbackPolicy
            }
            
            # Read the YAML content
            $yamlContent = Get-Content -Path $PolicyPath -Raw -ErrorAction Stop
            
            # Try to use PowerShell-Yaml module if available
            $policy = $null
            if (Get-Module -Name powershell-yaml -ListAvailable) {
                try {
                    Import-Module powershell-yaml -ErrorAction Stop
                    $policy = ConvertFrom-Yaml $yamlContent -ErrorAction Stop
                    Write-Verbose "Successfully parsed policy using PowerShell-Yaml module"
                }
                catch {
                    Write-Verbose "PowerShell-Yaml parsing failed: $($_.Exception.Message)"
                }
            }
            
            # Fallback to manual YAML parsing if PowerShell-Yaml not available
            if (-not $policy) {
                Write-Verbose "Using manual YAML parsing"
                $policy = ConvertFrom-ManualYaml -YamlContent $yamlContent
            }
            
            # Validate required policy fields
            $requiredFields = @('denied_commands', 'injection_patterns', 'allowed_commands', 'max_command_length')
            foreach ($field in $requiredFields) {
                if (-not $policy.$field) {
                    Write-Warning "Missing required policy field '$field', using fallback value"
                    $policy.$field = $fallbackPolicy.$field
                }
            }
            
            # Ensure numeric fields are properly typed
            if ($policy.max_command_length -is [string]) {
                $policy.max_command_length = [int]$policy.max_command_length
            }
            
            # Validate tmux section
            if (-not $policy.tmux) {
                $policy.tmux = $fallbackPolicy.tmux
            }
            else {
                # Ensure tmux numeric fields are properly typed
                if ($policy.tmux.max_sessions -is [string]) {
                    $policy.tmux.max_sessions = [int]$policy.tmux.max_sessions
                }
                if ($policy.tmux.max_session_lifetime -is [string]) {
                    $policy.tmux.max_session_lifetime = [int]$policy.tmux.max_session_lifetime
                }
            }
            
            Write-Verbose "Successfully loaded policy with $($policy.denied_commands.Count) denied commands"
            return [PSCustomObject]$policy
        }
        catch {
            Write-Error "Failed to load terminal policy from '$PolicyPath': $($_.Exception.Message)"
            Write-Warning "Using fallback security policy"
            return [PSCustomObject]$fallbackPolicy
        }
    }
}

function ConvertFrom-ManualYaml {
    <#
    .SYNOPSIS
        Manual YAML parsing for simple policy structures.
    
    .DESCRIPTION
        Provides basic YAML parsing capability when PowerShell-Yaml module
        is not available. Handles the specific structure of terminal.deny.yml.
    
    .PARAMETER YamlContent
        Raw YAML content as string.
    
    .OUTPUTS
        [PSCustomObject] Parsed policy object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$YamlContent
    )
    
    $policy = @{
        denied_commands = @()
        injection_patterns = @()
        allowed_commands = @()
        tmux = @{}
    }
    
    $lines = $YamlContent -split "`n" | ForEach-Object { $_.Trim() }
    $currentSection = $null
    $currentArray = $null
    
    foreach ($line in $lines) {
        # Skip comments and empty lines
        if ($line -match '^\s*#' -or $line -eq '') {
            continue
        }
        
        # Handle simple key-value pairs
        if ($line -match '^(\w+):\s*(.+)$') {
            $key = $matches[1]
            $value = $matches[2].Trim('"').Trim("'")
            
            switch ($key) {
                'version' { $policy.version = $value }
                'description' { $policy.description = $value }
                'max_command_length' { $policy.max_command_length = [int]$value }
                'audit_logging' { $policy.audit_logging = $value -eq 'true' }
            }
            continue
        }
        
        # Handle array sections
        if ($line -match '^(\w+):$') {
            $currentSection = $matches[1]
            $currentArray = @()
            continue
        }
        
        # Handle array items
        if ($line -match '^\s*-\s*"?([^"]+)"?$') {
            $item = $matches[1].Trim('"').Trim("'")
            $currentArray += $item
            continue
        }
        
        # Handle nested objects (tmux section)
        if ($line -match '^(\w+):$' -and $currentSection -eq 'tmux') {
            if ($currentArray) {
                $policy.$currentSection = $currentArray
            }
            $currentSection = 'tmux'
            continue
        }
        
        # Handle tmux subsections
        if ($currentSection -eq 'tmux' -and $line -match '^\s+(\w+):\s*(.+)$') {
            $key = $matches[1]
            $value = $matches[2].Trim('"').Trim("'")
            
            switch ($key) {
                'max_sessions' { $policy.tmux.max_sessions = [int]$value }
                'session_name_pattern' { $policy.tmux.session_name_pattern = $value }
                'max_session_lifetime' { $policy.tmux.max_session_lifetime = [int]$value }
            }
            continue
        }
        
        # Handle tmux arrays
        if ($currentSection -eq 'tmux' -and $line -match '^\s+(\w+):$') {
            $tmuxSection = $matches[1]
            if ($currentArray) {
                $policy.$currentSection = $currentArray
                $currentArray = @()
            }
            $currentArray = @()
            continue
        }
        
        if ($currentSection -eq 'tmux' -and $line -match '^\s+-\s*"?([^"]+)"?$') {
            $item = $matches[1].Trim('"').Trim("'")
            $currentArray += $item
            continue
        }
    }
    
    # Assign final array to appropriate section
    if ($currentSection -and $currentArray) {
        if ($currentSection -eq 'tmux') {
            $policy.tmux.allowed_in_tmux = $currentArray
        }
        else {
            $policy.$currentSection = $currentArray
        }
    }
    
    return $policy
}
