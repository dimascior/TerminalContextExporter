# TmuxSessionReference.ps1 - TasksV4 Phase 1.1
# Created: July 6, 2025
# Framework: GuardRails.md Part 3.1 - Data Contracts
# Purpose: Immutable session reference class for terminal integration

class TmuxSessionReference {
    [string]$SessionId
    [string]$SessionName  
    [string]$WindowId
    [string]$WindowName
    [string]$PaneId
    [datetime]$CreatedAt
    [datetime]$LastActivity
    [string]$WorkingDirectory
    [string]$Command
    [hashtable]$Environment
    [string]$Status
    [string]$CorrelationId

    # PowerShell 5.1 compatible constructor with defensive property access
    TmuxSessionReference([hashtable]$data) {
        # Required properties with validation
        $this.SessionId = if ($data.ContainsKey('SessionId') -and $data.SessionId) { 
            $data.SessionId 
        } else { 
            throw "SessionId is required for TmuxSessionReference" 
        }
        
        $this.SessionName = if ($data.ContainsKey('SessionName') -and $data.SessionName) { 
            $data.SessionName 
        } else { 
            "session-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        }
        
        # Window identification (defensive access pattern from SystemInfo success)
        $this.WindowId = if ($data.ContainsKey('WindowId') -and $data.WindowId) { 
            $data.WindowId 
        } else { 
            '0' 
        }
        
        $this.WindowName = if ($data.ContainsKey('WindowName') -and $data.WindowName) { 
            $data.WindowName 
        } else { 
            'myexporter' 
        }
        
        $this.PaneId = if ($data.ContainsKey('PaneId') -and $data.PaneId) { 
            $data.PaneId 
        } else { 
            '0' 
        }
        
        # Timestamps with defensive defaults
        $this.CreatedAt = if ($data.ContainsKey('CreatedAt') -and $data.CreatedAt) { 
            [datetime]$data.CreatedAt 
        } else { 
            Get-Date 
        }
        
        $this.LastActivity = if ($data.ContainsKey('LastActivity') -and $data.LastActivity) { 
            [datetime]$data.LastActivity 
        } else { 
            Get-Date 
        }
        
        # Path and execution context
        $this.WorkingDirectory = if ($data.ContainsKey('WorkingDirectory') -and $data.WorkingDirectory) { 
            $data.WorkingDirectory 
        } else { 
            $PWD.Path 
        }
        
        $this.Command = if ($data.ContainsKey('Command') -and $data.Command) { 
            $data.Command 
        } else { 
            'bash' 
        }
        
        # Environment variables (hashtable with safe defaults)
        $this.Environment = if ($data.ContainsKey('Environment') -and $data.Environment -is [hashtable]) { 
            $data.Environment 
        } else { 
            @{} 
        }
        
        $this.Status = if ($data.ContainsKey('Status') -and $data.Status) { 
            $data.Status 
        } else { 
            'active' 
        }
        
        # Correlation ID for telemetry (GuardRails.md Part 3.2)
        $this.CorrelationId = if ($data.ContainsKey('CorrelationId') -and $data.CorrelationId) { 
            $data.CorrelationId 
        } else { 
            [guid]::NewGuid().ToString() 
        }
    }
    
    # Convert to hashtable for JSON serialization (cross-platform compatibility)
    [hashtable] ToHashtable() {
        return @{
            SessionId = $this.SessionId
            SessionName = $this.SessionName
            WindowId = $this.WindowId
            WindowName = $this.WindowName
            PaneId = $this.PaneId
            CreatedAt = $this.CreatedAt.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            LastActivity = $this.LastActivity.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            WorkingDirectory = $this.WorkingDirectory
            Command = $this.Command
            Environment = $this.Environment
            Status = $this.Status
            CorrelationId = $this.CorrelationId
        }
    }
    
    # Generate tmux target string for command execution
    [string] GetTarget() {
        return "$($this.SessionName):$($this.WindowId).$($this.PaneId)"
    }
    
    # Check if session is still active (for state validation)
    [bool] IsActive() {
        return $this.Status -eq 'active'
    }
    
    # Update last activity timestamp (immutable pattern - returns new instance)
    [TmuxSessionReference] WithUpdatedActivity() {
        $data = $this.ToHashtable()
        $data.LastActivity = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        return [TmuxSessionReference]::new($data)
    }
    
    # Override ToString for logging (GuardRails.md Part 3.1 - IFormattable pattern)
    [string] ToString() {
        return "TmuxSession($($this.SessionName):$($this.WindowId).$($this.PaneId)) [$($this.Status)]"
    }
}
