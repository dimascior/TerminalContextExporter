# MyExporter/Private/_Initialize.ps1

# This script establishes the module's understanding of its own environment.
# Compatible with Windows PowerShell 5.1+

# STEP 1: Detect OS Platform (PowerShell 5.1 compatible)
$script:IsWindows = $env:OS -eq 'Windows_NT' -or $PSVersionTable.PSEdition -eq 'Desktop'
$script:IsLinux = $false
$script:IsMacOS = $false

# In PowerShell 5.1, we're always on Windows, but let's be future-compatible
if ($PSVersionTable.PSEdition -eq 'Core') {
    # Modern PowerShell - use automatic variables if available
    if (Get-Variable -Name 'IsWindows' -ErrorAction SilentlyContinue) {
        $script:IsWindows = $IsWindows
    }
    if (Get-Variable -Name 'IsLinux' -ErrorAction SilentlyContinue) {
        $script:IsLinux = $IsLinux
    }
    if (Get-Variable -Name 'IsMacOS' -ErrorAction SilentlyContinue) {
        $script:IsMacOS = $IsMacOS
    }
}

# STEP 2: Detect Execution Context (The "Where")
$script:MyExporterContext = 'Unknown'
if ($script:IsWindows) { $script:MyExporterContext = 'Windows' }
if ($script:IsLinux) { $script:MyExporterContext = 'Linux' }
if ($script:IsMacOS) { $script:MyExporterContext = 'MacOS' }

# The CRITICAL check for context collision. If we are a Windows process but see
# WSL environment variables, we are in the high-risk "WSL Interop" context.
if ($script:IsWindows -and -not [string]::IsNullOrEmpty($env:WSL_DISTRO_NAME)) {
    $script:MyExporterContext = 'WSLInterop'
    Write-Warning "CONTEXT-AWARENESS: Module is running in Windows but was invoked from a WSL shell ('$($env:WSL_DISTRO_NAME)'). Path validation is now in high-security mode."
}