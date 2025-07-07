@{
    # A unique identifier for the module. Generate a new one with [guid]::NewGuid()
    GUID = '1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d'

    # --- Declarative Constraints: Rules for the AI Agent & PowerShell Engine ---

    # RULE: Compatible with Windows PowerShell 5.1 and modern PowerShell 7.x
    PowerShellVersion = '5.1'

    # RULE: All code must function in both Windows PowerShell (Desktop) and modern pwsh (Core).
    # This forces consideration of API differences (e.g., .NET Framework vs. .NET Core).
    CompatiblePSEditions = 'Desktop', 'Core'

    # RULE: This is the definitive list of public commands. Do not suggest calling any
    # internal functions directly. This enforces encapsulation.
    FunctionsToExport = @(
        'Export-SystemInfo'
    )
    
    # RULE: These are the only external modules this project depends on.
    RequiredModules = @()

    # ScriptsToProcess - Classes must be loaded via this mechanism to be available in caller scope (PS 5.1 requirement)
    ScriptsToProcess = @(
        'Classes/SystemInfo.ps1',
        'Classes/TmuxSessionReference.ps1'
    )

    # FileList - Complete enumeration of all shipping files
    FileList = @(
        'Classes/SystemInfo.ps1',
        'Classes/TmuxSessionReference.ps1',
        'Initialize-WSLUser.sh',
        'MyExporter.psd1',
        'MyExporter.psm1',
        'Policies/terminal.deny.yml',
        'Policies/terminal-deny.yaml',
        'Private/_Initialize.ps1',
        'Private/Add-TerminalContextToSystemInfo.ps1',
        'Private/Assert-ContextPath.ps1',
        'Private/Assert-ContextualPath.ps1',
        'Private/Get-CurrentSession.ps1',
        'Private/Get-ExecutionContext.ps1',
        'Private/Get-SystemInfo.Linux.ps1',
        'Private/Get-SystemInfo.Windows.ps1',
        'Private/Get-SystemInfoPlatformSpecific.ps1',
        'Private/Get-TerminalContext.WSL.ps1',
        'Private/Get-TerminalContextPlatformSpecific.ps1',
        'Private/Get-TerminalOutput.WSL.ps1',
        'Private/Invoke-WithTelemetry.ps1',
        'Private/Invoke-WslTmuxCommand.ps1',
        'Private/New-TmuxArgumentList.ps1',
        'Private/TerminalTelemetryBatcher.ps1',
        'Private/Test-CommandSafety.ps1',
        'Private/Test-TerminalCapabilities.ps1',
        'Private/Update-StateFileSchema.ps1',
        'Public/Export-SystemInfo.ps1',
        'Tests/ClassAvailability.Tests.ps1',
        'Tests/ClassLoading.Tests.ps1',
        'Tests/Export-SystemInfo.Tests.ps1',
        'Tests/Initialize-WSLUser.bats',
        'Tests/TelemetryCompliance.Tests.ps1',
        'Tests/Test-TmuxArgumentList.ps1',
        'Tests/TmuxSessionReference.Tests.ps1',
        'Test-TmuxAvailability.ps1',
        'Verify-Phase.ps1',
        'enhanced-test-bridge.ps1'
    )

    # --- Module Metadata ---
    ModuleVersion = '1.0.0'
    Author = 'AI-Assisted Engineering'
    CompanyName = 'Context-Aware Systems'
    RootModule = 'MyExporter.psm1'
    Description = 'A robust, context-aware module for exporting system information from diverse environments.'

    PrivateData = @{
        PSData = @{
            Tags = @('Exporter', 'SystemInfo', 'CrossPlatform', 'ContextAware', 'AI')
            Prerelease = 'alpha.8'
        }
    }
}
