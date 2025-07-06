# Test-CommandSafety.ps1 - TasksV4 Phase 2.2
# Created: July 6, 2025
# Framework: GuardRails.md Security Validation
# Purpose: Policy-driven command sanitizer with YAML policy support

function Test-CommandSafety {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        
        [string]$PolicyPath = (Join-Path $PSScriptRoot ".." "Policies" "terminal-deny.yaml"),
        
        [switch]$AllowWarningCommands,
        
        [string]$CorrelationId = [guid]::NewGuid().ToString()
    )
    
    begin {
        Write-Debug "[$CorrelationId] Testing command safety: $Command"
        
        # Load policy (with caching for performance)
        if (-not $script:SecurityPolicy -or -not $script:PolicyLastLoaded -or 
            (Get-Date) - $script:PolicyLastLoaded -gt [TimeSpan]::FromMinutes(5)) {
            $script:SecurityPolicy = Import-SecurityPolicy -PolicyPath $PolicyPath
            $script:PolicyLastLoaded = Get-Date
            Write-Debug "[$CorrelationId] Security policy loaded from: $PolicyPath"
        }
    }
    
    process {
        try {
            # Create result object
            $result = [PSCustomObject]@{
                Command = $Command
                IsAllowed = $false
                SecurityLevel = "UNKNOWN"
                ViolationType = $null
                ViolationDetails = @()
                SanitizedCommand = $null
                RequiresApproval = $false
                PolicyVersion = $script:SecurityPolicy.version
                CorrelationId = $CorrelationId
                Timestamp = Get-Date
            }
            
            # Pre-validation checks
            if ([string]::IsNullOrWhiteSpace($Command)) {
                $result.ViolationType = "EMPTY_COMMAND"
                $result.ViolationDetails += "Command cannot be empty or whitespace"
                return $result
            }
            
            if ($Command.Length -gt $script:SecurityPolicy.validation.max_command_length) {
                $result.ViolationType = "COMMAND_TOO_LONG"
                $result.ViolationDetails += "Command exceeds maximum length: $($script:SecurityPolicy.validation.max_command_length)"
                return $result
            }
            
            # Normalize command for analysis
            $normalizedCommand = $Command.Trim().ToLower()
            $commandParts = $Command -split '\s+', 0, 'RegexMatch'
            $baseCommand = $commandParts[0].ToLower()
            
            # Check argument count
            if ($commandParts.Count - 1 -gt $script:SecurityPolicy.validation.max_arguments) {
                $result.ViolationType = "TOO_MANY_ARGUMENTS"
                $result.ViolationDetails += "Command has too many arguments: $($commandParts.Count - 1)"
                return $result
            }
            
            # BLOCK level checks - Immediate rejection
            $blockResult = Test-BlockedCommands -Command $normalizedCommand -BaseCommand $baseCommand -Policy $script:SecurityPolicy -CorrelationId $CorrelationId
            if (-not $blockResult.IsAllowed) {
                $result.SecurityLevel = "BLOCK"
                $result.ViolationType = $blockResult.ViolationType
                $result.ViolationDetails = $blockResult.ViolationDetails
                return $result
            }
            
            # WARN level checks - Requires approval
            $warnResult = Test-WarningCommands -BaseCommand $baseCommand -Policy $script:SecurityPolicy -CorrelationId $CorrelationId
            if ($warnResult.RequiresApproval) {
                $result.SecurityLevel = "WARN"
                $result.RequiresApproval = $true
                $result.ViolationDetails = $warnResult.ViolationDetails
                
                # Check if warnings are allowed
                if ($AllowWarningCommands) {
                    Write-Warning "[$CorrelationId] Warning command approved by -AllowWarningCommands flag: $baseCommand"
                    $result.IsAllowed = $true
                    $result.SanitizedCommand = $Command
                } else {
                    $result.ViolationType = "REQUIRES_APPROVAL"
                    return $result
                }
            }
            
            # SANITIZE level checks - Clean and allow
            $sanitizeResult = Test-SanitizeCommands -Command $Command -BaseCommand $baseCommand -Policy $script:SecurityPolicy -CorrelationId $CorrelationId
            if ($sanitizeResult.RequiresSanitization) {
                $result.SecurityLevel = "SANITIZE"
                $result.SanitizedCommand = $sanitizeResult.SanitizedCommand
                $result.ViolationDetails = $sanitizeResult.ViolationDetails
                $result.IsAllowed = $true
                return $result
            }
            
            # ALLOW level - Command is explicitly allowed
            $allowResult = Test-AllowedCommands -BaseCommand $baseCommand -Policy $script:SecurityPolicy -CorrelationId $CorrelationId
            if ($allowResult.IsExplicitlyAllowed) {
                $result.SecurityLevel = "ALLOW"
                $result.IsAllowed = $true
                $result.SanitizedCommand = $Command
                return $result
            }
            
            # Default DENY - Command not in any policy list
            $result.SecurityLevel = "BLOCK"
            $result.ViolationType = "NOT_IN_POLICY"
            $result.ViolationDetails += "Command '$baseCommand' not found in security policy"
            
            return $result
            
        } catch {
            Write-Error "[$CorrelationId] Security validation failed: $($_.Exception.Message)"
            throw
        }
    }
}

# Load security policy from YAML file
function Import-SecurityPolicy {
    [CmdletBinding()]
    param([string]$PolicyPath)
    
    if (-not (Test-Path $PolicyPath)) {
        throw "Security policy file not found: $PolicyPath"
    }
    
    try {
        # Simple YAML parser for our specific format
        $policyContent = Get-Content $PolicyPath -Raw
        $policy = ConvertFrom-Yaml -YamlContent $policyContent
        
        Write-Debug "Loaded security policy: $($policy.policy_name) v$($policy.version)"
        return $policy
        
    } catch {
        throw "Failed to parse security policy: $($_.Exception.Message)"
    }
}

# Simple YAML to object converter (focused on our policy format)
function ConvertFrom-Yaml {
    [CmdletBinding()]
    param([string]$YamlContent)
    
    $policy = @{}
    $stack = New-Object System.Collections.ArrayList  # Use ArrayList for dynamic sizing
    $currentContext = $policy
    
    foreach ($rawLine in $YamlContent -split "`n") {
        $line = $rawLine.TrimEnd()
        
        # Skip comments and empty lines
        if ($line -match '^\s*#' -or [string]::IsNullOrEmpty($line)) {
            continue
        }
        
        # Calculate indentation level
        $indent = ($rawLine.Length - $rawLine.TrimStart().Length)
        
        # Pop from stack if indentation decreased
        while ($stack.Count -gt 0 -and $stack[$stack.Count - 1].Indent -ge $indent) {
            $stack.RemoveAt($stack.Count - 1)
        }
        
        # Set current context based on stack
        $currentContext = $policy
        foreach ($level in $stack) {
            $currentContext = $level.Context
        }
        
        # Handle key-value pairs
        if ($line -match '^\s*([^:]+):\s*(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            
            # Remove inline comments
            if ($value -match '^([^#]+)#.*$') {
                $value = $matches[1].Trim()
            }
            
            # Handle quoted values
            if ($value -match '^["\''](.*)["\'']$') {
                $value = $matches[1]
            }
            
            # Handle boolean values
            if ($value -eq 'true') { $value = $true }
            elseif ($value -eq 'false') { $value = $false }
            
            # Handle numeric values
            if ($value -match '^\d+$') { $value = [int]$value }
            
            # Determine if this starts a new section
            if ([string]::IsNullOrEmpty($value)) {
                # This is either an object or array that will have children
                $newObject = @{}
                $currentContext[$key] = $newObject
                
                # Push new context onto stack
                $null = $stack.Add(@{
                    Key = $key
                    Context = $newObject
                    Indent = $indent
                    IsArray = $false
                })
            } else {
                # Simple key-value pair
                $currentContext[$key] = $value
            }
        }
        # Handle array items
        elseif ($line -match '^\s*-\s*(.+)$') {
            $item = $matches[1].Trim()
            
            # Remove quotes
            if ($item -match '^["\''](.*)["\'']$') {
                $item = $matches[1]
            }
            
            # Convert current context to array if it's not already
            if ($stack.Count -gt 0) {
                $parentLevel = $stack[$stack.Count - 1]
                if (-not $parentLevel.IsArray) {
                    # Convert the object to an array
                    $parentContext = $policy
                    for ($i = 0; $i -lt $stack.Count - 1; $i++) {
                        $parentContext = $stack[$i].Context
                    }
                    $parentContext[$parentLevel.Key] = @()
                    $parentLevel.IsArray = $true
                }
                
                # Add item to array
                $parentContext = $policy
                for ($i = 0; $i -lt $stack.Count - 1; $i++) {
                    $parentContext = $stack[$i].Context
                }
                $parentContext[$parentLevel.Key] += $item
            }
        }
    }
    
    return $policy
}

# Test for blocked commands and patterns
function Test-BlockedCommands {
    [CmdletBinding()]
    param($Command, $BaseCommand, $Policy, $CorrelationId)
    
    $result = @{ IsAllowed = $true; ViolationType = $null; ViolationDetails = @() }
    
    # Check blocked commands
    if ($Policy.blocked_commands -contains $BaseCommand) {
        $result.IsAllowed = $false
        $result.ViolationType = "BLOCKED_COMMAND"
        $result.ViolationDetails += "Command '$BaseCommand' is in blocked commands list"
        return $result
    }
    
    # Check blocked patterns
    foreach ($pattern in $Policy.blocked_patterns) {
        if ($Command -match $pattern) {
            $result.IsAllowed = $false
            $result.ViolationType = "BLOCKED_PATTERN"
            $result.ViolationDetails += "Command matches blocked pattern: $pattern"
            return $result
        }
    }
    
    return $result
}

# Test for warning commands
function Test-WarningCommands {
    [CmdletBinding()]
    param($BaseCommand, $Policy, $CorrelationId)
    
    $result = @{ RequiresApproval = $false; ViolationDetails = @() }
    
    if ($Policy.warning_commands -contains $BaseCommand) {
        $result.RequiresApproval = $true
        $result.ViolationDetails += "Command '$BaseCommand' requires explicit approval"
    }
    
    return $result
}

# Test and sanitize commands
function Test-SanitizeCommands {
    [CmdletBinding()]
    param($Command, $BaseCommand, $Policy, $CorrelationId)
    
    $result = @{ RequiresSanitization = $false; SanitizedCommand = $Command; ViolationDetails = @() }
    
    if ($Policy.sanitize_commands -contains $BaseCommand) {
        $result.RequiresSanitization = $true
        $result.ViolationDetails += "Command '$BaseCommand' requires sanitization"
        
        # Apply basic sanitization
        $sanitized = $Command
        
        # Escape dangerous characters
        foreach ($char in $Policy.dangerous_characters) {
            if ($sanitized.Contains($char)) {
                $sanitized = $sanitized.Replace($char, "\$char")
                $result.ViolationDetails += "Escaped dangerous character: $char"
            }
        }
        
        $result.SanitizedCommand = $sanitized
    }
    
    return $result
}

# Test for explicitly allowed commands
function Test-AllowedCommands {
    [CmdletBinding()]
    param($BaseCommand, $Policy, $CorrelationId)
    
    return @{ IsExplicitlyAllowed = ($Policy.allowed_commands -contains $BaseCommand) }
}
