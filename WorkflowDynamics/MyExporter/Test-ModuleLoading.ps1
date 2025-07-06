# Test-ModuleLoading.ps1
# Comprehensive test for PowerShell 5.1 module loading

Write-Host "=== PowerShell 5.1 Module Loading Test ===" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host "Edition: $($PSVersionTable.PSEdition)" -ForegroundColor Gray

# Clean any existing module
Remove-Module MyExporter -Force -ErrorAction SilentlyContinue

Write-Host "`n--- Step 1: Test Individual Components ---" -ForegroundColor Yellow

# Test SystemInfo class
try {
    . .\Classes\SystemInfo.ps1
    $testData = @{ComputerName='Test'; Platform='Windows'; OS='Windows 10'; Version='10.0'; Source='Test'}
    $obj = [SystemInfo]::new($testData)
    Write-Host "✓ SystemInfo class: $($obj.ToString())" -ForegroundColor Green
}
catch {
    Write-Host "✗ SystemInfo class failed: $_" -ForegroundColor Red
}

# Test execution context
try {
    . .\Private\_Initialize.ps1
    . .\Private\Get-ExecutionContext.ps1
    $context = Get-ExecutionContext
    Write-Host "✓ ExecutionContext: IsWindows=$($context.Platform.IsWindows)" -ForegroundColor Green
}
catch {
    Write-Host "✗ ExecutionContext failed: $_" -ForegroundColor Red
}

# Test telemetry
try {
    . .\Private\Invoke-WithTelemetry.ps1
    $result = Invoke-WithTelemetry -OperationName "Test" -ScriptBlock { "Success" }
    Write-Host "✓ Telemetry: $result" -ForegroundColor Green
}
catch {
    Write-Host "✗ Telemetry failed: $_" -ForegroundColor Red
}

Write-Host "`n--- Step 2: Test Module Import ---" -ForegroundColor Yellow

try {
    Import-Module .\MyExporter.psd1 -Force -Verbose
    Write-Host "✓ Module imported successfully" -ForegroundColor Green
    
    $module = Get-Module MyExporter
    Write-Host "  Module loaded: $($module.Name) v$($module.Version)" -ForegroundColor Gray
    
    $exportedFunctions = $module.ExportedFunctions
    if ($exportedFunctions.Count -gt 0) {
        Write-Host "  Exported functions: $($exportedFunctions.Keys -join ', ')" -ForegroundColor Gray
    } else {
        Write-Host "  No functions exported - checking module scope..." -ForegroundColor Yellow
        
        # Check if function exists in module scope
        $moduleCommands = Get-Command -Module MyExporter -ErrorAction SilentlyContinue
        if ($moduleCommands) {
            Write-Host "  Commands in module scope: $($moduleCommands.Name -join ', ')" -ForegroundColor Gray
        } else {
            Write-Host "  No commands found in module scope" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "✗ Module import failed: $_" -ForegroundColor Red
}

Write-Host "`n--- Step 3: Test Direct Function Call ---" -ForegroundColor Yellow

try {
    # Load all dependencies manually
    . .\Classes\SystemInfo.ps1
    . .\Private\_Initialize.ps1
    . .\Private\Get-ExecutionContext.ps1
    . .\Private\Invoke-WithTelemetry.ps1
    . .\Private\Get-SystemInfo.Windows.ps1
    . .\Private\Get-SystemInfo.Linux.ps1
    . .\Private\Get-SystemInfoPlatformSpecific.ps1
    . .\Private\Assert-ContextPath.ps1
    . .\Public\Export-SystemInfo.ps1
    
    Write-Host "✓ All functions loaded directly" -ForegroundColor Green
    
    # Test if Export-SystemInfo is available
    $cmd = Get-Command Export-SystemInfo -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "✓ Export-SystemInfo command available: $($cmd.CommandType)" -ForegroundColor Green
    } else {
        Write-Host "✗ Export-SystemInfo not available" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Direct loading failed: $_" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
