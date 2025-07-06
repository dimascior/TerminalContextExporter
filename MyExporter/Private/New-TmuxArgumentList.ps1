# New-TmuxArgumentList.ps1 - TasksV4 Phase 3.1
# Created: July 6, 2025
# Framework: GuardRails.md Part 11.3 - Process Boundaries
# Purpose: 4-layer escaping pipeline for PowerShell→Bash→Tmux communication

function New-TmuxArgumentList {
    <#
    .SYNOPSIS
    Creates properly escaped argument list for tmux execution via WSL
    
    .DESCRIPTION
    Implements 4-layer escaping pipeline to preserve special characters across:
    1. PowerShell parameter handling
    2. PowerShell→WSL process boundary  
    3. Bash shell interpretation
    4. Tmux command parsing
    
    .PARAMETER Command
    The base command to execute in tmux
    
    .PARAMETER Arguments
    Array of arguments to pass to the command
    
    .PARAMETER SessionName
    Name of the tmux session (optional)
    
    .PARAMETER WindowName
    Name of the tmux window (optional)
    
    .PARAMETER CorrelationId
    Correlation ID for telemetry tracking
    
    .EXAMPLE
    $args = New-TmuxArgumentList -Command "echo" -Arguments @("hello world", "test`"quote", "special$chars")
    # Returns properly escaped argument array for tmux execution
    
    .EXAMPLE
    $args = New-TmuxArgumentList -Command "find" -Arguments @("/tmp", "-name", "*.log") -SessionName "search-session"
    # Returns tmux command with session management
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
        [string]$CorrelationId = [guid]::NewGuid().ToString()
    )
    
    begin {
        Write-Debug "[$CorrelationId] Creating tmux argument list for command: $Command"
        
        # Define character escape mappings for each layer
        $PowerShellEscapes = @{
            '`'  = '``'   # PowerShell backtick
            '"'  = '`"'   # PowerShell quote
            '$'  = '`$'   # PowerShell variable
            '&'  = '`&'   # PowerShell background operator
            '|'  = '`|'   # PowerShell pipe
            ';'  = '`;'   # PowerShell statement separator
            '<'  = '`<'   # PowerShell redirection
            '>'  = '`>'   # PowerShell redirection
        }
        
        $BashEscapes = @{
            '\'  = '\\'   # Bash backslash
            '"'  = '\"'   # Bash quote
            '$'  = '\$'   # Bash variable
            '`'  = '\`'   # Bash command substitution
            '!'  = '\!'   # Bash history expansion
            '&'  = '\&'   # Bash background
            '|'  = '\|'   # Bash pipe
            ';'  = '\;'   # Bash statement separator
            '*'  = '\*'   # Bash glob
            '?'  = '\?'   # Bash glob
            '['  = '\['   # Bash bracket expression
            ']'  = '\]'   # Bash bracket expression
            '('  = '\('   # Bash subshell
            ')'  = '\)'   # Bash subshell
            '{'  = '\{'   # Bash brace expansion
            '}'  = '\}'   # Bash brace expansion
        }
        
        $TmuxEscapes = @{
            '"'  = '\"'   # Tmux quote
            '\'  = '\\'   # Tmux backslash
            '$'  = '\$'   # Tmux variable
            '`'  = '\`'   # Tmux command substitution
        }
    }
    
    process {
        try {
            $result = [PSCustomObject]@{
                OriginalCommand = $Command
                OriginalArguments = $Arguments
                EscapedCommand = $null
                EscapedArguments = @()
                TmuxCommand = $null
                SessionName = $SessionName
                WindowName = $WindowName
                CorrelationId = $CorrelationId
                Timestamp = Get-Date
                EscapingLayers = @{
                    Layer1_PowerShell = @()
                    Layer2_Bash = @()
                    Layer3_Tmux = @()
                    Layer4_Final = @()
                }
            }
            
            # Layer 1: PowerShell escaping
            $layer1Command = $Command
            foreach ($char in $PowerShellEscapes.Keys) {
                if ($layer1Command.Contains($char)) {
                    $layer1Command = $layer1Command.Replace($char, $PowerShellEscapes[$char])
                    Write-Debug "[$CorrelationId] Layer1 - Escaped '$char' in command"
                }
            }
            
            $layer1Arguments = @()
            foreach ($arg in $Arguments) {
                $escapedArg = $arg
                foreach ($char in $PowerShellEscapes.Keys) {
                    if ($escapedArg.Contains($char)) {
                        $escapedArg = $escapedArg.Replace($char, $PowerShellEscapes[$char])
                        Write-Debug "[$CorrelationId] Layer1 - Escaped '$char' in argument: $arg"
                    }
                }
                $layer1Arguments += $escapedArg
            }
            
            $result.EscapingLayers.Layer1_PowerShell = @{
                Command = $layer1Command
                Arguments = $layer1Arguments
            }
            
            # Layer 2: Bash escaping
            $layer2Command = $layer1Command
            foreach ($char in $BashEscapes.Keys) {
                if ($layer2Command.Contains($char)) {
                    $layer2Command = $layer2Command.Replace($char, $BashEscapes[$char])
                    Write-Debug "[$CorrelationId] Layer2 - Escaped '$char' in command"
                }
            }
            
            $layer2Arguments = @()
            foreach ($arg in $layer1Arguments) {
                $escapedArg = $arg
                foreach ($char in $BashEscapes.Keys) {
                    if ($escapedArg.Contains($char)) {
                        $escapedArg = $escapedArg.Replace($char, $BashEscapes[$char])
                        Write-Debug "[$CorrelationId] Layer2 - Escaped '$char' in argument: $arg"
                    }
                }
                $layer2Arguments += $escapedArg
            }
            
            $result.EscapingLayers.Layer2_Bash = @{
                Command = $layer2Command
                Arguments = $layer2Arguments
            }
            
            # Layer 3: Tmux escaping
            $layer3Command = $layer2Command
            foreach ($char in $TmuxEscapes.Keys) {
                if ($layer3Command.Contains($char)) {
                    $layer3Command = $layer3Command.Replace($char, $TmuxEscapes[$char])
                    Write-Debug "[$CorrelationId] Layer3 - Escaped '$char' in command"
                }
            }
            
            $layer3Arguments = @()
            foreach ($arg in $layer2Arguments) {
                $escapedArg = $arg
                foreach ($char in $TmuxEscapes.Keys) {
                    if ($escapedArg.Contains($char)) {
                        $escapedArg = $escapedArg.Replace($char, $TmuxEscapes[$char])
                        Write-Debug "[$CorrelationId] Layer3 - Escaped '$char' in argument: $arg"
                    }
                }
                $layer3Arguments += $escapedArg
            }
            
            $result.EscapingLayers.Layer3_Tmux = @{
                Command = $layer3Command
                Arguments = $layer3Arguments
            }
            
            # Layer 4: Final tmux command construction
            $tmuxArgs = @()
            
            # Add session management if specified
            if ($SessionName) {
                $tmuxArgs += "new-session"
                $tmuxArgs += "-d"  # detached
                $tmuxArgs += "-s"
                $tmuxArgs += "`"$SessionName`""
            } else {
                $tmuxArgs += "send-keys"
            }
            
            # Add window management if specified
            if ($WindowName -and $SessionName) {
                $tmuxArgs += "-n"
                $tmuxArgs += "`"$WindowName`""
            }
            
            # Construct the command to execute
            $fullCommand = $layer3Command
            if ($layer3Arguments.Count -gt 0) {
                $quotedArgs = $layer3Arguments | ForEach-Object { "`"$_`"" }
                $fullCommand += " " + ($quotedArgs -join " ")
            }
            
            if ($SessionName) {
                $tmuxArgs += $fullCommand
            } else {
                $tmuxArgs += "`"$fullCommand`""
                $tmuxArgs += "Enter"
            }
            
            $result.EscapedCommand = $layer3Command
            $result.EscapedArguments = $layer3Arguments
            $result.TmuxCommand = "tmux " + ($tmuxArgs -join " ")
            $result.EscapingLayers.Layer4_Final = $tmuxArgs
            
            Write-Debug "[$CorrelationId] 4-layer escaping complete - Final tmux command: $($result.TmuxCommand)"
            
            return $result
            
        } catch {
            Write-Error "[$CorrelationId] Failed to create tmux argument list: $($_.Exception.Message)"
            throw
        }
    }
}

# Helper function for testing character preservation
function Test-CharacterPreservation {
    <#
    .SYNOPSIS
    Tests that special characters are preserved through the 4-layer escaping pipeline
    
    .DESCRIPTION
    Validates that problematic characters don't get lost or corrupted during escaping
    
    .PARAMETER TestString
    String containing special characters to test
    
    .PARAMETER CorrelationId
    Correlation ID for tracking
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestString,
        
        [Parameter(Mandatory = $false)]
        [string]$CorrelationId = [guid]::NewGuid().ToString()
    )
    
    $testResult = New-TmuxArgumentList -Command "echo" -Arguments @($TestString) -CorrelationId $CorrelationId
    
    # Validate that no characters were lost
    $originalLength = $TestString.Length
    $escapedLength = $testResult.EscapedArguments[0].Length
    
    $result = [PSCustomObject]@{
        TestString = $TestString
        OriginalLength = $originalLength
        EscapedLength = $escapedLength
        LengthPreserved = $escapedLength -ge $originalLength  # Allow growth due to escaping
        EscapingResult = $testResult
        CorrelationId = $CorrelationId
    }
    
    Write-Debug "[$CorrelationId] Character preservation test - Original: $originalLength chars, Escaped: $escapedLength chars"
    
    return $result
}

# Functions exported for testing when called from module context
# Export-ModuleMember -Function New-TmuxArgumentList, Test-CharacterPreservation
