# MyExporter/Private/Get-SystemInfoPlatformSpecific.ps1

<#
.SYNOPSIS
    Platform dispatcher that routes to appropriate implementation based on target and local context.
.DESCRIPTION
    This function implements the platform-specific routing pattern described in the architecture.
    It determines the target platform and delegates to the appropriate implementation.
#>
function Get-SystemInfoPlatformSpecific {
    [CmdletBinding()]
    [OutputType([SystemInfo])]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,
        
        [switch]$UseSSH,
        
        [hashtable]$Context = @{}
    )
    
    # Job-safe execution context access (avoid PowerShell built-in collision)
    $correlationId = if ($Context.CorrelationId) { $Context.CorrelationId } else { [guid]::NewGuid().ToString() }
    Write-Debug "[$correlationId] Platform dispatch for '$ComputerName'"
    
    # Determine target platform for remote systems
    $isLocalhost = @('localhost', '127.0.0.1', 'localhost.localdomain', $env:COMPUTERNAME, $env:HOSTNAME) -contains $ComputerName
    
    if ($isLocalhost) {
        # Local system - dispatch based on current platform
        if ($IsWindows) {
            Write-Debug "[$correlationId] Dispatching to Windows implementation"
            return Get-SystemInfoWindows -ComputerName $ComputerName -CorrelationId $correlationId
        }
        elseif ($IsLinux) {
            Write-Debug "[$correlationId] Dispatching to Linux implementation"
            return Get-SystemInfoLinux -ComputerName $ComputerName -UseSSH:$false -CorrelationId $correlationId
        }
        elseif ($IsMacOS) {
            Write-Debug "[$correlationId] macOS implementation not yet available"
            # Fallback to basic implementation for macOS
            $systemData = @{
                ComputerName = $ComputerName
                Platform = "macOS"
                OSVersion = if ($PSVersionTable.OS) { $PSVersionTable.OS } else { "Unknown macOS" }
                CPUCount = try { 
                    [int](sysctl -n hw.logicalcpu 2>/dev/null) 
                } catch { 
                    1 
                };
                TotalMemoryGB = try { 
                    [Math]::Round([double](sysctl -n hw.memsize) / 1GB, 2) 
                } catch { 
                    0.0 
                }
            }
            return [SystemInfo]::new($systemData)
        }
        else {
            Write-Warning "[$correlationId] Unknown local platform, using fallback"
            $systemData = @{
                ComputerName = $ComputerName
                Platform = "Unknown"
                OSVersion = if ($PSVersionTable.OS) { $PSVersionTable.OS } else { "Unknown" }
                CPUCount = 1
                TotalMemoryGB = 0.0
            }
            return [SystemInfo]::new($systemData)
        }
    }
    else {
        # Remote system - assume Windows for now, could be enhanced with platform detection
        Write-Debug "[$correlationId] Remote system assumed to be Windows"
        if ($UseSSH) {
            # Assume Linux/Unix if SSH is explicitly requested
            Write-Debug "[$correlationId] SSH requested, dispatching to Linux implementation"
            return Get-SystemInfoLinux -ComputerName $ComputerName -UseSSH:$true -CorrelationId $correlationId
        }
        else {
            # Default to Windows for WinRM
            Write-Debug "[$correlationId] Using WinRM, dispatching to Windows implementation"
            return Get-SystemInfoWindows -ComputerName $ComputerName -CorrelationId $correlationId
        }
    }
}