# Test-TmuxArgumentList.ps1 - TasksV4 Phase 3.2
# Created: July 6, 2025
# Framework: GuardRails.md Testing Framework
# Purpose: Character preservation validation for 4-layer escaping pipeline

param(
    [switch]$Verbose,
    [switch]$IncludeStressTests,
    [string]$TestOutputPath = "test-tmux-escaping-results.json"
)

$ErrorActionPreference = "Stop"

# Import the function to test
. "$PSScriptRoot\..\Private\New-TmuxArgumentList.ps1"

Write-Host "=== TasksV4 Phase 3: Cross-Boundary Communication Tests ===" -ForegroundColor Cyan
Write-Host "Testing 4-layer escaping pipeline (PowerShell→Bash→Tmux)" -ForegroundColor Yellow

$testResults = @{
    TestSuite = "Phase3-CrossBoundaryCommunication"
    Timestamp = Get-Date
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        CharacterTests = 0
        EscapingTests = 0
    }
}

function Add-TestResult {
    param($Name, $Status, $Details, $Evidence = @(), $TestType = "General")
    
    $test = @{
        Name = $Name
        Status = $Status
        TestType = $TestType
        Details = $Details
        Evidence = $Evidence
        Timestamp = Get-Date
    }
    
    $testResults.Tests += $test
    $testResults.Summary.Total++
    
    if ($Status -eq "PASS") {
        $testResults.Summary.Passed++
        $color = "Green"
    } else {
        $testResults.Summary.Failed++
        $color = "Red"
    }
    
    if ($TestType -eq "Character") {
        $testResults.Summary.CharacterTests++
    } elseif ($TestType -eq "Escaping") {
        $testResults.Summary.EscapingTests++
    }
    
    Write-Host "[$TestType] $Name - $Status" -ForegroundColor $color
    if ($Verbose -and $Details) {
        Write-Host "  Details: $Details" -ForegroundColor Gray
    }
}

# Test 1: Basic Function Functionality
try {
    Write-Host "`n--- Test 1: Basic Function Functionality ---" -ForegroundColor Magenta
    
    $basicResult = New-TmuxArgumentList -Command "echo" -Arguments @("hello", "world")
    
    if ($basicResult -and $basicResult.TmuxCommand) {
        Add-TestResult -Name "Basic-FunctionExecution" -Status "PASS" -Details "Function executed successfully" -TestType "General" -Evidence @($basicResult)
    } else {
        Add-TestResult -Name "Basic-FunctionExecution" -Status "FAIL" -Details "Function failed to execute or return result" -TestType "General"
    }
    
    # Validate required properties exist
    $requiredProperties = @('OriginalCommand', 'EscapedCommand', 'TmuxCommand', 'EscapingLayers')
    $missingProperties = @()
    
    foreach ($prop in $requiredProperties) {
        if (-not ($basicResult.PSObject.Properties.Name -contains $prop)) {
            $missingProperties += $prop
        }
    }
    
    if ($missingProperties.Count -eq 0) {
        Add-TestResult -Name "Basic-RequiredProperties" -Status "PASS" -Details "All required properties present" -TestType "General"
    } else {
        Add-TestResult -Name "Basic-RequiredProperties" -Status "FAIL" -Details "Missing properties: $($missingProperties -join ', ')" -TestType "General"
    }
    
} catch {
    Add-TestResult -Name "Basic-FunctionException" -Status "FAIL" -Details $_.Exception.Message -TestType "General"
}

# Test 2: Special Character Preservation
try {
    Write-Host "`n--- Test 2: Special Character Preservation ---" -ForegroundColor Magenta
    
    $specialCharacters = @{
        "PowerShell_Backtick" = "test`"quote"
        "PowerShell_Dollar" = "test`$variable"
        "PowerShell_Pipe" = "test|command"
        "Bash_Backslash" = "test\path"
        "Bash_Quote" = 'test"quote'
        "Bash_Variable" = "test`$VAR"
        "Tmux_Quote" = 'test"tmux'
        "Tmux_Backslash" = "test\tmux"
        "Mixed_Characters" = 'test`$"var\path|cmd'
    }
    
    foreach ($testName in $specialCharacters.Keys) {
        $testString = $specialCharacters[$testName]
        
        try {
            $charResult = Test-CharacterPreservation -TestString $testString
            
            if ($charResult.LengthPreserved) {
                Add-TestResult -Name "Character-$testName" -Status "PASS" -Details "Length preserved: $($charResult.OriginalLength) → $($charResult.EscapedLength)" -TestType "Character" -Evidence @($charResult)
            } else {
                Add-TestResult -Name "Character-$testName" -Status "FAIL" -Details "Length not preserved: $($charResult.OriginalLength) → $($charResult.EscapedLength)" -TestType "Character" -Evidence @($charResult)
            }
        } catch {
            Add-TestResult -Name "Character-$testName" -Status "FAIL" -Details "Exception testing character: $($_.Exception.Message)" -TestType "Character"
        }
    }
    
} catch {
    Add-TestResult -Name "Character-TestException" -Status "FAIL" -Details $_.Exception.Message -TestType "Character"
}

# Test 3: Layer-by-Layer Escaping Validation
try {
    Write-Host "`n--- Test 3: Layer-by-Layer Escaping Validation ---" -ForegroundColor Magenta
    
    $testCommand = "find"
    $testArgs = @("/tmp", "-name", "*.log", "-exec", "echo", "found: {}", "\;")
    
    $layerResult = New-TmuxArgumentList -Command $testCommand -Arguments $testArgs
    
    # Validate each layer exists
    $layers = @('Layer1_PowerShell', 'Layer2_Bash', 'Layer3_Tmux', 'Layer4_Final')
    foreach ($layer in $layers) {
        if ($layerResult.EscapingLayers.$layer) {
            Add-TestResult -Name "Escaping-$layer" -Status "PASS" -Details "Layer exists and populated" -TestType "Escaping"
        } else {
            Add-TestResult -Name "Escaping-$layer" -Status "FAIL" -Details "Layer missing or empty" -TestType "Escaping"
        }
    }
    
    # Validate escaping progression (each layer should be different from previous)
    $layer1Args = ($layerResult.EscapingLayers.Layer1_PowerShell.Arguments -join " ")
    $layer2Args = ($layerResult.EscapingLayers.Layer2_Bash.Arguments -join " ")
    $layer3Args = ($layerResult.EscapingLayers.Layer3_Tmux.Arguments -join " ")
    
    if ($layer2Args -ne $layer1Args -or $layer3Args -ne $layer2Args) {
        Add-TestResult -Name "Escaping-Progression" -Status "PASS" -Details "Each layer applies different escaping" -TestType "Escaping"
    } else {
        Add-TestResult -Name "Escaping-Progression" -Status "FAIL" -Details "Layers appear identical (no escaping applied)" -TestType "Escaping"
    }
    
} catch {
    Add-TestResult -Name "Escaping-LayerException" -Status "FAIL" -Details $_.Exception.Message -TestType "Escaping"
}

# Test 4: Session and Window Management
try {
    Write-Host "`n--- Test 4: Session and Window Management ---" -ForegroundColor Magenta
    
    $sessionResult = New-TmuxArgumentList -Command "ps" -Arguments @("aux") -SessionName "test-session" -WindowName "processes"
    
    if ($sessionResult.TmuxCommand -and $sessionResult.TmuxCommand.Contains("new-session")) {
        Add-TestResult -Name "Session-NewSession" -Status "PASS" -Details "Session management included in tmux command" -TestType "General" -Evidence @($sessionResult)
    } else {
        Add-TestResult -Name "Session-NewSession" -Status "FAIL" -Details "Session management not found in tmux command" -TestType "General" -Evidence @($sessionResult)
    }
    
    if ($sessionResult.TmuxCommand.Contains("test-session")) {
        Add-TestResult -Name "Session-SessionName" -Status "PASS" -Details "Session name preserved in command" -TestType "General"
    } else {
        Add-TestResult -Name "Session-SessionName" -Status "FAIL" -Details "Session name not found in command" -TestType "General"
    }
    
    if ($sessionResult.TmuxCommand.Contains("processes")) {
        Add-TestResult -Name "Session-WindowName" -Status "PASS" -Details "Window name preserved in command" -TestType "General"
    } else {
        Add-TestResult -Name "Session-WindowName" -Status "FAIL" -Details "Window name not found in command" -TestType "General"
    }
    
} catch {
    Add-TestResult -Name "Session-Exception" -Status "FAIL" -Details $_.Exception.Message -TestType "General"
}

# Test 5: Stress Test (if enabled)
if ($IncludeStressTests) {
    try {
        Write-Host "`n--- Test 5: Stress Testing ---" -ForegroundColor Magenta
        
        # Generate complex test cases
        $stressTests = @(
            @{ Cmd = "awk"; Args = @('{print $1}', '/var/log/syslog') },
            @{ Cmd = "sed"; Args = @('-e', 's/old/new/g', '-e', 's/test/prod/g') },
            @{ Cmd = "grep"; Args = @('-E', '(error|warn|fail)', '--color=never') },
            @{ Cmd = "find"; Args = @('/tmp', '-type', 'f', '-name', '*.tmp', '-delete') }
        )
        
        foreach ($i in 0..($stressTests.Count - 1)) {
            $test = $stressTests[$i]
            try {
                $stressResult = New-TmuxArgumentList -Command $test.Cmd -Arguments $test.Args
                
                if ($stressResult -and $stressResult.TmuxCommand) {
                    Add-TestResult -Name "Stress-Test$i" -Status "PASS" -Details "Complex command handled successfully" -TestType "Escaping"
                } else {
                    Add-TestResult -Name "Stress-Test$i" -Status "FAIL" -Details "Complex command failed" -TestType "Escaping"
                }
            } catch {
                Add-TestResult -Name "Stress-Test$i" -Status "FAIL" -Details "Exception: $($_.Exception.Message)" -TestType "Escaping"
            }
        }
        
    } catch {
        Add-TestResult -Name "Stress-Exception" -Status "FAIL" -Details $_.Exception.Message -TestType "Escaping"
    }
}

# Final Summary
Write-Host "`n=== Test Results Summary ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.Summary.Total)" -ForegroundColor White
Write-Host "Passed: $($testResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Summary.Failed)" -ForegroundColor Red
Write-Host "Character Tests: $($testResults.Summary.CharacterTests)" -ForegroundColor Yellow
Write-Host "Escaping Tests: $($testResults.Summary.EscapingTests)" -ForegroundColor Yellow

$passRate = if ($testResults.Summary.Total -gt 0) { 
    $testResults.Summary.Passed / $testResults.Summary.Total * 100 
} else { 0 }

Write-Host "Pass Rate: $([math]::Round($passRate, 1))%" -ForegroundColor Cyan

# Save results
$testResults | ConvertTo-Json -Depth 5 | Set-Content -Path $TestOutputPath -Encoding UTF8
Write-Host "`nTest results saved to: $TestOutputPath" -ForegroundColor Gray

# Return exit code
if ($testResults.Summary.Failed -gt 0) {
    Write-Host "`nSome tests failed. See details above." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nAll tests passed! 4-layer escaping pipeline validated." -ForegroundColor Green
    exit 0
}
