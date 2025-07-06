# Update-StateFileSchema.ps1 - TasksV4 Phase 1.2
# Created: July 6, 2025
# Framework: GuardRails.md Part 3.3 - State Management
# Purpose: Implement v2.0 state schema migration with backward compatibility

function Update-StateFileSchema {
    [CmdletBinding()]
    param(
        [string]$StateFilePath = (Join-Path $env:TEMP "myexporter-state.json"),
        [switch]$Force
    )
    
    begin {
        Write-Debug "[$(Get-Date)] Starting state schema migration to v2.0"
        
        # State schema versions (constitutional layer)
        $SchemaVersions = @{
            V1 = "1.0"
            V2 = "2.0" 
        }
        
        # Current target schema
        $TargetVersion = $SchemaVersions.V2
    }
    
    process {
        try {
            # Check if state file exists
            if (-not (Test-Path $StateFilePath)) {
                Write-Verbose "No existing state file found. Creating new v2.0 schema."
                $newState = New-StateFileV2 -StateFilePath $StateFilePath
                return $newState
            }
            
            # Read existing state with error handling
            $existingContent = Get-Content $StateFilePath -Raw -ErrorAction Stop
            $existingState = $existingContent | ConvertFrom-Json -ErrorAction Stop
            
            # Determine current schema version (defensive property access)
            $currentVersion = if ($existingState.PSObject.Properties['SchemaVersion']) { 
                $existingState.SchemaVersion 
            } else { 
                $SchemaVersions.V1  # Default to v1.0 for legacy files
            }
            
            Write-Verbose "Current state schema version: $currentVersion"
            Write-Verbose "Target schema version: $TargetVersion"
            
            # Check if migration needed
            if ($currentVersion -eq $TargetVersion) {
                Write-Verbose "State file already at target schema version $TargetVersion"
                return (ConvertTo-StateFileV2Object -StateData $existingState)
            }
            
            # Perform migration based on source version
            switch ($currentVersion) {
                $SchemaVersions.V1 {
                    Write-Verbose "Migrating from v1.0 to v2.0..."
                    $migratedState = Convert-StateV1ToV2 -V1State $existingState -StateFilePath $StateFilePath
                    Write-Verbose "Migration completed successfully"
                    return $migratedState
                }
                default {
                    throw "Unsupported state schema version: $currentVersion"
                }
            }
        }
        catch {
            Write-Error "Failed to update state file schema: $($_.Exception.Message)"
            
            if ($Force) {
                Write-Warning "Force parameter specified. Creating new v2.0 state file."
                $newState = New-StateFileV2 -StateFilePath $StateFilePath
                return $newState
            }
            
            throw
        }
    }
}

# Create new v2.0 state file
function New-StateFileV2 {
    [CmdletBinding()]
    param([string]$StateFilePath)
    
    $newStateV2 = @{
        SchemaVersion = "2.0"
        CreatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        LastUpdated = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        Sessions = @()
        Configuration = @{
            DefaultSessionName = "myexporter"
            DefaultWindowName = "main"
            DefaultCommand = "bash"
            MaxSessions = 10
            SessionTimeout = 3600  # 1 hour in seconds
        }
        Metadata = @{
            Platform = $null
            WorkingDirectory = $PWD.Path
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            CorrelationId = [guid]::NewGuid().ToString()
        }
    }
    
    # Save new state file
    $newStateV2 | ConvertTo-Json -Depth 4 | Out-File $StateFilePath -Encoding UTF8
    Write-Debug "Created new v2.0 state file: $StateFilePath"
    
    return (ConvertTo-StateFileV2Object -StateData $newStateV2)
}

# Convert v1.0 state to v2.0 (backward compatibility)
function Convert-StateV1ToV2 {
    [CmdletBinding()]
    param(
        [object]$V1State,
        [string]$StateFilePath
    )
    
    Write-Debug "Converting v1.0 state structure to v2.0..."
    
    # Create v2.0 structure from v1.0 data
    $v2State = @{
        SchemaVersion = "2.0"
        CreatedAt = if ($V1State.PSObject.Properties['CreatedAt']) { 
            $V1State.CreatedAt 
        } else { 
            (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ') 
        }
        LastUpdated = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        Sessions = @()
        Configuration = @{
            DefaultSessionName = "myexporter"
            DefaultWindowName = "main" 
            DefaultCommand = "bash"
            MaxSessions = 10
            SessionTimeout = 3600
        }
        Metadata = @{
            Platform = $null
            WorkingDirectory = $PWD.Path
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            CorrelationId = [guid]::NewGuid().ToString()
            MigratedFrom = "1.0"
        }
    }
    
    # Migrate existing sessions if they exist in v1.0 format
    if ($V1State.PSObject.Properties['Sessions'] -and $V1State.Sessions) {
        foreach ($v1Session in $V1State.Sessions) {
            $v2Session = @{
                SessionId = if ($v1Session.PSObject.Properties['SessionId']) { 
                    $v1Session.SessionId 
                } else { 
                    [guid]::NewGuid().ToString() 
                }
                SessionName = if ($v1Session.PSObject.Properties['SessionName']) { 
                    $v1Session.SessionName 
                } else { 
                    "migrated-session" 
                }
                WindowId = "0"
                WindowName = "main"
                PaneId = "0"
                CreatedAt = if ($v1Session.PSObject.Properties['CreatedAt']) { 
                    $v1Session.CreatedAt 
                } else { 
                    (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ') 
                }
                LastActivity = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                WorkingDirectory = if ($v1Session.PSObject.Properties['WorkingDirectory']) { 
                    $v1Session.WorkingDirectory 
                } else { 
                    $PWD.Path 
                }
                Command = "bash"
                Environment = @{}
                Status = "migrated"
                CorrelationId = [guid]::NewGuid().ToString()
            }
            
            $v2State.Sessions += $v2Session
        }
    }
    
    # Save migrated state
    $v2State | ConvertTo-Json -Depth 4 | Out-File $StateFilePath -Encoding UTF8
    Write-Debug "Saved migrated v2.0 state file"
    
    return (ConvertTo-StateFileV2Object -StateData $v2State)
}

# Convert state data to structured object
function ConvertTo-StateFileV2Object {
    [CmdletBinding()]
    param([object]$StateData)
    
    return [PSCustomObject]@{
        SchemaVersion = $StateData.SchemaVersion
        CreatedAt = [datetime]::Parse($StateData.CreatedAt)
        LastUpdated = [datetime]::Parse($StateData.LastUpdated)
        Sessions = $StateData.Sessions
        Configuration = $StateData.Configuration
        Metadata = $StateData.Metadata
    }
}
