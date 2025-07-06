# Test-JobFunctionality.ps1
# Quick test to validate job path resolution fixes

param()

Write-Host "=== Testing Job Functionality Fixes ===" -ForegroundColor Magenta

# Test 1: Module Loading
Write-Host "`n1. Testing module loading..." -ForegroundColor Yellow
try {
    Remove-Module MyExporter -ErrorAction SilentlyContinue
    Import-Module .\MyExporter.psd1 -Force
    Write-Host "✓ Module loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Module loading failed: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Function Availability
Write-Host "`n2. Testing function availability..." -ForegroundColor Yellow
try {
    $exportCmd = Get-Command Export-SystemInfo -ErrorAction SilentlyContinue
    if ($exportCmd) {
        Write-Host "✓ Export-SystemInfo is available" -ForegroundColor Green
    } else {
        Write-Host "✗ Export-SystemInfo not found" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Function availability test failed: $_" -ForegroundColor Red
    exit 1
}

# Test 3: Dependencies Loading
Write-Host "`n3. Testing critical dependencies..." -ForegroundColor Yellow
try {
    # Load dependencies manually to test them
    . .\Private\_Initialize.ps1
    . .\Classes\SystemInfo.ps1
    . .\Private\Get-ExecutionContext.ps1
    . .\Private\Assert-ContextPath.ps1
    . .\Private\Invoke-WithTelemetry.ps1
    
    Write-Host "✓ All dependencies loaded" -ForegroundColor Green
} catch {
    Write-Host "✗ Dependency loading failed: $_" -ForegroundColor Red
    exit 1
}

# Test 4: Context Creation
Write-Host "`n4. Testing execution context..." -ForegroundColor Yellow
try {
    $context = Get-ExecutionContext
    if ($context -and $context.Platform) {
        Write-Host "✓ Execution context created successfully" -ForegroundColor Green
        Write-Host "   Platform: $($context.Platform.IsWindows)" -ForegroundColor Gray
    } else {
        Write-Host "✗ Invalid execution context" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Context creation failed: $_" -ForegroundColor Red
}

# Test 5: SystemInfo Class
Write-Host "`n5. Testing SystemInfo class..." -ForegroundColor Yellow
try {
    $testData = @{ComputerName = $env:COMPUTERNAME; Platform = 'Windows'}
    $sysInfo = [SystemInfo]::new($testData)
    Write-Host "✓ SystemInfo class works: $($sysInfo.ComputerName)" -ForegroundColor Green
} catch {
    Write-Host "✗ SystemInfo class failed: $_" -ForegroundColor Red
}

# Test 6: Job Path Resolution (Simulation)
Write-Host "`n6. Testing job path resolution..." -ForegroundColor Yellow
try {
    $moduleRoot = Split-Path $PSScriptRoot -Parent
    $testPaths = @(
        (Join-Path $moduleRoot "Classes" "SystemInfo.ps1"),
        (Join-Path $moduleRoot "Private" "Invoke-WithTelemetry.ps1"),
        (Join-Path $moduleRoot "Private" "Get-ExecutionContext.ps1")
    )
    
    $allExist = $true
    foreach ($path in $testPaths) {
        if (-not (Test-Path $path)) {
            Write-Host "✗ Missing: $path" -ForegroundColor Red
            $allExist = $false
        }
    }
    
    if ($allExist) {
        Write-Host "✓ All job dependency paths resolve correctly" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Path resolution test failed: $_" -ForegroundColor Red
}

Write-Host "`n=== Job Functionality Test Complete ===" -ForegroundColor Magenta
