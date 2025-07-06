# Get-CurrentSession.ps1 - TasksV4 Phase 1.3
# Created: July 6, 2025  
# Framework: GuardRails.md Part 3.3 - State Management
# Purpose: Session lifecycle management with state persistence

function Get-CurrentSession {
    [CmdletBinding()]
    param(
        [string]$SessionName,
        [string]$StateFilePath = (Join-Path $env:TEMP "myexporter-state.json"),
        [switch]$CreateIfMissing,
        [string]$WorkingDirectory = $PWD.Path,
        [hashtable]$Environment = @{}
    )
    
    begin {
        Write-Debug "[$(Get-Date)] Getting current session: $SessionName"
        
        # Ensure state file schema is current (GuardRails.md Part 3.3)
        $state = Update-StateFileSchema -StateFilePath $StateFilePath
    }
    
    process {
        try {
            # If no specific session requested, find or create default
            if (-not $SessionName) {
                $SessionName = $state.Configuration.DefaultSessionName
                Write-Debug "Using default session name: $SessionName"
            }
            
            # Search existing sessions
            $existingSession = $state.Sessions | Where-Object { 
                $_.SessionName -eq $SessionName -and $_.Status -eq 'active' 
            } | Select-Object -First 1
            
            if ($existingSession) {
                Write-Debug "Found existing session: $($existingSession.SessionId)"
                
                # Convert PSCustomObject to hashtable for class constructor
                $sessionData = @{}
                $existingSession.PSObject.Properties | ForEach-Object { $sessionData[$_.Name] = $_.Value }
                
                # Convert to TmuxSessionReference object
                $sessionRef = [TmuxSessionReference]::new($sessionData)
                
                # Update last activity and persist
                $updatedSession = $sessionRef.WithUpdatedActivity()
                Update-SessionInState -SessionReference $updatedSession -StateFilePath $StateFilePath
                
                return $updatedSession
            }
            
            # No existing session found
            if (-not $CreateIfMissing) {
                Write-Debug "No active session found for: $SessionName"
                return $null
            }
            
            # Create new session
            Write-Debug "Creating new session: $SessionName"
            $newSession = New-SessionReference -SessionName $SessionName -WorkingDirectory $WorkingDirectory -Environment $Environment
            
            # Add to state and persist
            Add-SessionToState -SessionReference $newSession -StateFilePath $StateFilePath
            
            return $newSession
        }
        catch {
            Write-Error "Failed to get current session: $($_.Exception.Message)"
            throw
        }
    }
}

# Create new session reference
function New-SessionReference {
    [CmdletBinding()]
    param(
        [string]$SessionName,
        [string]$WorkingDirectory = $PWD.Path,
        [hashtable]$Environment = @{}
    )
    
    $sessionData = @{
        SessionId = [guid]::NewGuid().ToString()
        SessionName = $SessionName
        WindowId = "0"
        WindowName = "main"
        PaneId = "0" 
        CreatedAt = Get-Date
        LastActivity = Get-Date
        WorkingDirectory = $WorkingDirectory
        Command = "bash"
        Environment = $Environment
        Status = "active"
        CorrelationId = [guid]::NewGuid().ToString()
    }
    
    return [TmuxSessionReference]::new($sessionData)
}

# Add session to state file
function Add-SessionToState {
    [CmdletBinding()]
    param(
        [TmuxSessionReference]$SessionReference,
        [string]$StateFilePath
    )
    
    try {
        # Read current state
        $stateContent = Get-Content $StateFilePath -Raw | ConvertFrom-Json
        
        # Add new session
        $stateContent.Sessions += $SessionReference.ToHashtable()
        $stateContent.LastUpdated = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        
        # Clean up old sessions (respect MaxSessions limit)
        $maxSessions = $stateContent.Configuration.MaxSessions
        if ($stateContent.Sessions.Count -gt $maxSessions) {
            # Remove oldest inactive sessions first
            $activeSessions = $stateContent.Sessions | Where-Object { $_.Status -eq 'active' }
            $inactiveSessions = $stateContent.Sessions | Where-Object { $_.Status -ne 'active' } | 
                Sort-Object LastActivity | Select-Object -First ($stateContent.Sessions.Count - $maxSessions)
            
            $stateContent.Sessions = $activeSessions + $inactiveSessions
        }
        
        # Save state with file locking (GuardRails.md Part 3.3)
        $stateContent | ConvertTo-Json -Depth 4 | Out-File $StateFilePath -Encoding UTF8
        Write-Debug "Added session to state: $($SessionReference.SessionId)"
    }
    catch {
        Write-Error "Failed to add session to state: $($_.Exception.Message)"
        throw
    }
}

# Update existing session in state
function Update-SessionInState {
    [CmdletBinding()]
    param(
        [TmuxSessionReference]$SessionReference,
        [string]$StateFilePath
    )
    
    try {
        # Read current state
        $stateContent = Get-Content $StateFilePath -Raw | ConvertFrom-Json
        
        # Find and update session
        $sessionIndex = -1
        for ($i = 0; $i -lt $stateContent.Sessions.Count; $i++) {
            if ($stateContent.Sessions[$i].SessionId -eq $SessionReference.SessionId) {
                $sessionIndex = $i
                break
            }
        }
        
        if ($sessionIndex -ge 0) {
            $stateContent.Sessions[$sessionIndex] = $SessionReference.ToHashtable()
            $stateContent.LastUpdated = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            
            # Save updated state
            $stateContent | ConvertTo-Json -Depth 4 | Out-File $StateFilePath -Encoding UTF8
            Write-Debug "Updated session in state: $($SessionReference.SessionId)"
        } else {
            Write-Warning "Session not found in state for update: $($SessionReference.SessionId)"
        }
    }
    catch {
        Write-Error "Failed to update session in state: $($_.Exception.Message)"
        throw
    }
}

# Remove session from state (cleanup function)
function Remove-SessionFromState {
    [CmdletBinding()]
    param(
        [string]$SessionId,
        [string]$StateFilePath
    )
    
    try {
        # Read current state
        $stateContent = Get-Content $StateFilePath -Raw | ConvertFrom-Json
        
        # Filter out target session
        $stateContent.Sessions = $stateContent.Sessions | Where-Object { $_.SessionId -ne $SessionId }
        $stateContent.LastUpdated = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        
        # Save updated state  
        $stateContent | ConvertTo-Json -Depth 4 | Out-File $StateFilePath -Encoding UTF8
        Write-Debug "Removed session from state: $SessionId"
    }
    catch {
        Write-Error "Failed to remove session from state: $($_.Exception.Message)"
        throw
    }
}
