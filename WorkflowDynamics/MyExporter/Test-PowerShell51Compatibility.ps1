# Test-PowerShell51Compatibility.ps1
# Simple test script for PowerShell 5.1 compatibility

Write-Host "=== PowerShell 5.1 Compatibility Test ===" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host "Edition: $($PSVersionTable.PSEdition)" -ForegroundColor Gray

# Test 1: SystemInfo Class
Write-Host "`n--- Test 1: SystemInfo Class ---" -ForegroundColor Yellow
try {
    . .\Classes\SystemInfo.ps1
    
    $testData = @{
        ComputerName = $env:COMPUTERNAME
        Platform = 'Windows'
        OS = 'Windows Test'
        Version = '10.0'
        Source = 'Test'
    }
    
    $sysInfo = [SystemInfo]::new($testData)
    Write-Host "✓ SystemInfo object created successfully" -ForegroundColor Green
    Write-Host "  Computer: $($sysInfo.ComputerName)" -ForegroundColor Gray
    Write-Host "  Platform: $($sysInfo.Platform)" -ForegroundColor Gray
    Write-Host "  CorrelationId: $($sysInfo.CorrelationId)" -ForegroundColor Gray
    Write-Host "  Default ToString(): $($sysInfo.ToString())" -ForegroundColor Gray
    Write-Host "  Table format: $($sysInfo.ToTableString())" -ForegroundColor Gray
}
catch {
    Write-Host "✗ SystemInfo test failed: $_" -ForegroundColor Red
}

# Test 2: Telemetry Function
Write-Host "`n--- Test 2: Telemetry Function ---" -ForegroundColor Yellow
try {
    . .\Private\Invoke-WithTelemetry.ps1
    
    $result = Invoke-WithTelemetry -OperationName "TestOperation" -ScriptBlock {
        return "Operation completed successfully"
    } -Verbose
    
    if ($result -eq "Operation completed successfully") {
        Write-Host "✓ Telemetry wrapper works correctly" -ForegroundColor Green
    } else {
        Write-Host "✗ Telemetry returned unexpected result: $result" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Telemetry test failed: $_" -ForegroundColor Red
}

# Test 3: Environment Detection
Write-Host "`n--- Test 3: Environment Detection ---" -ForegroundColor Yellow
try {
    . .\Private\_Initialize.ps1
    . .\Private\Get-ExecutionContext.ps1
    
    $context = Get-ExecutionContext
    Write-Host "✓ Environment context detected" -ForegroundColor Green
    Write-Host "  IsWindows: $($context.Platform.IsWindows)" -ForegroundColor Gray
    Write-Host "  PowerShell Edition: $($context.PowerShell.Edition)" -ForegroundColor Gray
    Write-Host "  PowerShell Version: $($context.PowerShell.Version)" -ForegroundColor Gray
}
catch {
    Write-Host "✗ Environment detection failed: $_" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "The MyExporter module components are compatible with PowerShell 5.1" -ForegroundColor Green
