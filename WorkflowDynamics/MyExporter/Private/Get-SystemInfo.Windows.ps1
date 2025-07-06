# MyExporter/Private/Get-SystemInfo.Windows.ps1

<#
.SYNOPSIS
    Windows-specific system information collection implementation.
.DESCRIPTION
    Collects system information from Windows targets using CIM/WMI.
    Supports both local and remote execution via WinRM.
#>
function Get-SystemInfoWindows {
    [CmdletBinding()]
    [OutputType([SystemInfo])]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,
        
        [string]$CorrelationId = [guid]::NewGuid().ToString()
    )
    
    begin {
        Write-Debug "[$CorrelationId] Windows system info collection for: $ComputerName"
    }
    
    process {
        $scriptBlock = {
            param($CorrelationId)
            
            $os = Get-CimInstance -ClassName Win32_OperatingSystem
            # Return a hashtable. The caller will cast this to the [SystemInfo] class.
            # This avoids needing the class definition on the remote machine.
            return @{
                ComputerName = $os.CSName
                Platform     = 'Windows'
                OS           = $os.Caption
                Version      = $os.Version
                Source       = 'CIM/WinRM'
                CorrelationId = $CorrelationId
            }
        }
        
        # Determine if this is local or remote execution
        $isLocal = ($ComputerName -eq 'localhost') -or 
                  ($ComputerName -eq $env:COMPUTERNAME) -or 
                  ($ComputerName -eq '127.0.0.1')
        
        if ($isLocal) {
            # Local execution
            $data = & $scriptBlock $CorrelationId
        }
        else {
            # Remote execution via WinRM
            $data = Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -ArgumentList $CorrelationId
        }
        
        return [SystemInfo]::new($data)
    }
}