# MyExporter/Private/Assert-ContextPath.ps1

function Assert-ContextPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$ParameterName
    )

    # In WSLInterop, the user's CWD might be a Linux path. Resolve-Path can fail.
    # We must resolve relative to the *caller's* location, not the module's.
    $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

    # If running in the high-risk WSL Interop context...
    if ($script:MyExporterContext -eq 'WSLInterop') {
        if ($resolvedPath.StartsWith('/') -or $resolvedPath.StartsWith('\mnt\')) {
            $errorMessage = @(
                "CONTEXT MISMATCH for parameter '-$ParameterName': Path '$Path' appears to be a Linux/WSL path."
                "This script is running in Windows PowerShell and requires a Windows-style path (e.g., 'C:\Users\User')."
                "HINT: This commonly occurs when running a script from a WSL terminal in VS Code."
                "Please provide a path that is accessible to the Windows host."
            ) -join [System.Environment]::NewLine
            throw $errorMessage
        }
    }

    # General validation for all contexts.
    $parentDir = Split-Path -Path $resolvedPath -Parent
    if (-not (Test-Path -Path $parentDir -PathType Container)) {
        throw "The directory for the specified path does not exist: '$parentDir' (for parameter '-$ParameterName')."
    }

    return $resolvedPath
}