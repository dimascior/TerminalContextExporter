# MyExporter/Private/Get-SystemInfo.Linux.ps1

<#
.SYNOPSIS
    Linux-specific system information collection implementation.
.DESCRIPTION
    Collects system information from Linux targets using native commands.
    Supports both local and remote execution via SSH.
#>
function Get-SystemInfoLinux {
    [CmdletBinding()]
    [OutputType([SystemInfo])]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,
        
        [switch]$UseSSH,
        
        [string]$CorrelationId = [guid]::NewGuid().ToString()
    )
    
    begin {
        Write-Debug "[$CorrelationId] Linux system info collection for: $ComputerName"
    }
    
    process {
        $scriptBlock = {
            param($CorrelationId)
            
            # Try to read OS release information
            $osInfo = 'Unknown Linux'
            $version = 'Unknown'
            
            if (Test-Path '/etc/os-release') {
                try {
                    $osRelease = Get-Content /etc/os-release | ConvertFrom-StringData
                    $osInfo = if ($osRelease.PRETTY_NAME) { $osRelease.PRETTY_NAME } else { $osRelease.NAME }
                }
                catch {
                    Write-Warning "Could not parse /etc/os-release: $_"
                }
            }
            
            try {
                $version = uname -r
            }
            catch {
                Write-Warning "Could not get kernel version: $_"
            }
            
            return @{
                ComputerName = try { 
                    hostname 
                } catch { 
                    if ($env:HOSTNAME) { $env:HOSTNAME } else { 'Unknown' } 
                };
                Platform     = 'Linux';
                OS           = $osInfo;
                Version      = $version;
                Source       = if ($args[1]) { 'SSH/Native' } else { 'Local/Native' };
                CorrelationId = $CorrelationId
            }
        }
        
        # Determine if this is local or remote execution
        $isLocal = ($ComputerName -eq 'localhost') -or 
                  ($ComputerName -eq '127.0.0.1') -or
                  (-not $UseSSH -and $IsLinux)
        
        if ($isLocal) {
            # Local execution
            $data = & $scriptBlock $CorrelationId $false
        }
        else {
            # Remote execution via SSH
            $data = Invoke-Command -HostName $ComputerName -ScriptBlock $scriptBlock -ArgumentList $CorrelationId, $true
        }
        
        return [SystemInfo]::new($data)
    }
}