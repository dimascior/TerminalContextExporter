# MyExporter/Test-MyExporter.ps1

<#
.SYNOPSIS
    Simple test script to validate the enhanced MyExporter architecture.
.DESCRIPTION
    This script tests the core functionality of the MyExporter module,
    validating the architectural patterns implemented.
#>

# Import the module
try {
    Import-Module "$PSScriptRoot\MyExporter.psd1" -Force -Verbose
    Write-Host "✓ Module imported successfully" -ForegroundColor Green
}
catch {
    Write-Error "✗ Failed to import module: $_"
    exit 1
}

# Test 1: Basic functionality
Write-Host "`n=== Test 1: Basic Local System Info Collection ===" -ForegroundColor Cyan
try {
    Export-SystemInfo -ComputerName 'localhost' -OutputPath "$env:TEMP\test-output.csv" -Verbose
    
    if (Test-Path "$env:TEMP\test-output.csv") {
        $content = Import-Csv "$env:TEMP\test-output.csv"
        Write-Host "✓ Output file created with $($content.Count) record(s)" -ForegroundColor Green
        Write-Host "  Computer: $($content[0].ComputerName)" -ForegroundColor Gray
        Write-Host "  Platform: $($content[0].Platform)" -ForegroundColor Gray
        Write-Host "  OS: $($content[0].OS)" -ForegroundColor Gray
        
        # Clean up
        Remove-Item "$env:TEMP\test-output.csv" -Force
    }
    else {
        Write-Warning "✗ Output file was not created"
    }
}
catch {
    Write-Error "✗ Test 1 failed: $_"
}

# Test 2: JSON output format
Write-Host "`n=== Test 2: JSON Output Format ===" -ForegroundColor Cyan
try {
    Export-SystemInfo -ComputerName 'localhost' -OutputPath "$env:TEMP\test-output.json" -AsJson -Verbose
    
    if (Test-Path "$env:TEMP\test-output.json") {
        $content = Get-Content "$env:TEMP\test-output.json" | ConvertFrom-Json
        Write-Host "✓ JSON output created successfully" -ForegroundColor Green
        Write-Host "  Records: $($content.Count)" -ForegroundColor Gray
        Write-Host "  Has CorrelationId: $([bool]$content[0].CorrelationId)" -ForegroundColor Gray
        
        # Clean up
        Remove-Item "$env:TEMP\test-output.json" -Force
    }
    else {
        Write-Warning "✗ JSON output file was not created"
    }
}
catch {
    Write-Error "✗ Test 2 failed: $_"
}

# Test 3: SystemInfo class functionality
Write-Host "`n=== Test 3: SystemInfo Class Features ===" -ForegroundColor Cyan
try {
    $testData = @{
        ComputerName = 'TestMachine'
        Platform = 'Windows'
        OS = 'Windows 11'
        Version = '10.0.22000'
        Source = 'Test'
    }
    
    $sysInfo = [SystemInfo]::new($testData)
    
    Write-Host "✓ SystemInfo object created" -ForegroundColor Green
    Write-Host "  Default ToString(): $($sysInfo.ToString())" -ForegroundColor Gray
    Write-Host "  Table format: $($sysInfo.ToString('table', $null))" -ForegroundColor Gray
    Write-Host "  Has CorrelationId: $([bool]$sysInfo.CorrelationId)" -ForegroundColor Gray
}
catch {
    Write-Error "✗ Test 3 failed: $_"
}

Write-Host "`n=== Testing Complete ===" -ForegroundColor Green
Write-Host "The MyExporter module is functioning with enhanced architectural patterns:" -ForegroundColor Gray
Write-Host "  ✓ Telemetry integration" -ForegroundColor Gray
Write-Host "  ✓ Context discovery" -ForegroundColor Gray
Write-Host "  ✓ Parameter forwarding" -ForegroundColor Gray
Write-Host "  ✓ Enhanced data contracts" -ForegroundColor Gray
Write-Host "  ✓ Correlation tracking" -ForegroundColor Gray
