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

    # FileList - Complete enumeration of all shipping files
    FileList = @(
        'MyExporter.psm1',
        'Classes/SystemInfo.ps1',
        'Classes/TmuxSessionReference.ps1',
        'Private/_Initialize.ps1',
        'Private/Assert-ContextPath.ps1',
        'Private/Get-ExecutionContext.ps1',
        'Private/Get-SystemInfo.Windows.ps1',
        'Private/Get-SystemInfo.Linux.ps1', 
        'Private/Get-SystemInfoPlatformSpecific.ps1',
        'Private/Invoke-WithTelemetry.ps1',
        'Public/Export-SystemInfo.ps1'
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
            Prerelease = 'alpha.4'
        }
    }
}
