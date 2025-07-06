# MyExporter/MyExporter.psm1

# PRINCIPLE: Acknowledge the JIT compiler. Enforce strictness for the entire module scope.
Set-StrictMode -Version Latest

# STEP 1: Load all class files FIRST, immediately after Set-StrictMode
. "$PSScriptRoot/Classes/SystemInfo.ps1"
. "$PSScriptRoot/Classes/TmuxSessionReference.ps1"

# PRINCIPLE: Use $PSScriptRoot for robust pathing, immune to `Set-Location` side effects.
$privatePath = Join-Path -Path $PSScriptRoot -ChildPath 'Private'
$publicPath = Join-Path -Path $PSScriptRoot -ChildPath 'Public'
$classesPath = Join-Path -Path $PSScriptRoot -ChildPath 'Classes'

# STEP 2: Load the context initializer after classes are available
. "$privatePath/_Initialize.ps1"

# STEP 3: Load all private helpers and public functions. They can now safely use the
# established context and class definitions.
$allPrivateFiles = @(Get-ChildItem -Path $privatePath -Filter '*.ps1')
$privateFiles = @($allPrivateFiles | Where-Object { $_.Name -ne '_Initialize.ps1' })
$publicFiles = @(Get-ChildItem -Path $publicPath -Filter '*.ps1')
$allFiles = $privateFiles + $publicFiles | Sort-Object Name

foreach ($file in $allFiles) {
    try {
        Write-Debug "Loading: $($file.Name)"
        . $file.FullName
        Write-Debug "Successfully loaded: $($file.Name)"
    } catch { 
        Write-Error "FATAL: Failed to load script file '$($file.FullName)': $_" 
        Write-Error "Stack trace: $($_.ScriptStackTrace)"
    }
}

# Explicitly export only the members defined in the manifest's contract.
# PowerShell 5.1 compatible approach
$functionsToExport = @('Export-SystemInfo')
Export-ModuleMember -Function $functionsToExport