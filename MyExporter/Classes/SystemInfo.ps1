# MyExporter/Classes/SystemInfo.ps1

<#
.SYNOPSIS
    Data contract class for system information.
.DESCRIPTION
    Defines the SystemInfo class for consistent data representation across the module.
    Compatible with Windows PowerShell 5.1+.
#>
class SystemInfo {
    [string]$ComputerName
    [string]$Platform
    [string]$OS
    [string]$Version
    [string]$Source
    [datetime]$Timestamp
    [string]$CorrelationId
    
    # Constructor with validation (PowerShell 5.1 compatible)
    SystemInfo([hashtable]$data) {
        if (-not $data.ComputerName) {
            throw [System.ArgumentException]::new("ComputerName is required", "data")
        }
        
        $this.ComputerName = $data.ComputerName
        $this.Platform = if ($data.ContainsKey('Platform') -and $data.Platform) { $data.Platform } else { 'Unknown' }
        $this.OS = if ($data.ContainsKey('OS') -and $data.OS) { $data.OS } else { 'Unknown' }
        $this.Version = if ($data.ContainsKey('Version') -and $data.Version) { $data.Version } else { 'Unknown' }
        $this.Source = if ($data.ContainsKey('Source') -and $data.Source) { $data.Source } else { 'Direct' }
        
        # Safe property access for optional values
        if ($data.ContainsKey('Timestamp') -and $data['Timestamp']) {
            $this.Timestamp = $data['Timestamp']
        } else {
            $this.Timestamp = Get-Date
        }
        
        if ($data.ContainsKey('CorrelationId') -and $data['CorrelationId']) {
            $this.CorrelationId = $data['CorrelationId']
        } else {
            $this.CorrelationId = ([guid]::NewGuid()).ToString()
        }
    }
    
    # Static factory method for CIM objects (PowerShell 5.1 compatible)
    static [SystemInfo] FromCim([object]$cimObject, [string]$correlationId) {
        $data = @{
            ComputerName = if ($cimObject.CSName) { $cimObject.CSName } else { $env:COMPUTERNAME }
            Platform = 'Windows'  # PowerShell 5.1 assumes Windows
            OS = if ($cimObject.Caption) { $cimObject.Caption } else { $cimObject.Description }
            Version = $cimObject.Version
            Source = 'CIM'
            CorrelationId = $correlationId
        }
        
        return [SystemInfo]::new($data)
    }
    
    # Custom ToString methods for PowerShell 5.1 compatibility
    [string] ToString() {
        return "$($this.ComputerName) ($($this.Platform))"
    }
    
    [string] ToTableString() {
        return "$($this.ComputerName) | $($this.Platform) | $($this.OS) | $($this.Version)"
    }
    
    [string] ToJsonString() {
        return $this | ConvertTo-Json -Compress
    }
}
