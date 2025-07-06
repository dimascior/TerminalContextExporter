@echo off
REM Claude's PowerShell Execution Bridge for WSL Environment
REM Implements GuardRails.md Part 10 operational flow from Linux

setlocal enabledelayedexpansion

echo === CLAUDE POWERSHELL BRIDGE v1.0 ===
echo Environment: WSL2 calling Windows PowerShell
echo Working Directory: %~dp0
echo.

REM Check if we're being called from WSL (detect Linux environment)
if defined WSL_DISTRO_NAME (
    echo [CONTEXT] WSL Distribution: %WSL_DISTRO_NAME%
    echo [CONTEXT] Implementing WSL-to-Windows PowerShell bridge
) else (
    echo [CONTEXT] Native Windows environment detected
)

REM Set PowerShell execution policy for this session
echo [INIT] Setting PowerShell execution policy...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force"

REM Import MyExporter module with enhanced error handling
echo [IMPORT] Loading MyExporter module...
powershell -Command "try { Import-Module '%~dp0MyExporter.psd1' -Force -Verbose; Write-Host '[SUCCESS] Module imported successfully' -ForegroundColor Green } catch { Write-Host '[ERROR] Module import failed:' $_.Exception.Message -ForegroundColor Red; exit 1 }"

if %ERRORLEVEL% NEQ 0 (
    echo [FATAL] Module import failed. Exiting.
    exit /b 1
)

REM Execute the operational flow from GuardRails.md Part 10
echo.
echo [WORKFLOW] Executing GuardRails.md Part 10 operational flow...
echo [WORKFLOW] Scenario: WSL developer testing MyExporter functionality

REM Test 1: FastPath Mode (Anti-tail-chasing pattern)
echo.
echo === TEST 1: FASTPATH MODE (GuardRails Part 4.2) ===
set MYEXPORTER_FAST_PATH=true
powershell -Command "$env:MYEXPORTER_FAST_PATH='true'; Export-SystemInfo -ComputerName 'localhost' -OutputPath '%TEMP%\claude-fastpath-test.csv' -Verbose; if (Test-Path '%TEMP%\claude-fastpath-test.csv') { Write-Host '[SUCCESS] FastPath CSV generated' -ForegroundColor Green; Get-Content '%TEMP%\claude-fastpath-test.csv' | Select-Object -First 2 } else { Write-Host '[ERROR] FastPath test failed' -ForegroundColor Red }"

REM Test 2: Normal Mode with Job-Based Execution
echo.
echo === TEST 2: NORMAL MODE (Job-Based Architecture) ===
set MYEXPORTER_FAST_PATH=
powershell -Command "$env:MYEXPORTER_FAST_PATH=$null; Export-SystemInfo -ComputerName 'localhost' -OutputPath '%TEMP%\claude-normal-test.csv' -Verbose; if (Test-Path '%TEMP%\claude-normal-test.csv') { Write-Host '[SUCCESS] Normal mode CSV generated' -ForegroundColor Green; Get-Content '%TEMP%\claude-normal-test.csv' | Select-Object -First 2 } else { Write-Host '[ERROR] Normal mode test failed' -ForegroundColor Red }"

REM Test 3: JSON Output Format
echo.
echo === TEST 3: JSON OUTPUT FORMAT ===
powershell -Command "$env:MYEXPORTER_FAST_PATH='true'; Export-SystemInfo -ComputerName 'localhost' -OutputPath '%TEMP%\claude-json-test.json' -AsJson -Verbose; if (Test-Path '%TEMP%\claude-json-test.json') { Write-Host '[SUCCESS] JSON output generated' -ForegroundColor Green; $json = Get-Content '%TEMP%\claude-json-test.json' | ConvertFrom-Json; Write-Host 'Platform:' $json.Platform 'OS:' $json.OS } else { Write-Host '[ERROR] JSON test failed' -ForegroundColor Red }"

REM Test 4: Correlation ID Telemetry Analysis
echo.
echo === TEST 4: TELEMETRY CORRELATION ANALYSIS ===
powershell -Command "Write-Host '[TELEMETRY] Analyzing correlation ID propagation...'; $csv = Import-Csv '%TEMP%\claude-fastpath-test.csv' -ErrorAction SilentlyContinue; if ($csv) { Write-Host 'CorrelationId:' $csv.CorrelationId -ForegroundColor Cyan; Write-Host 'Source:' $csv.Source -ForegroundColor Cyan; Write-Host 'Timestamp:' $csv.Timestamp -ForegroundColor Cyan } else { Write-Host '[WARNING] No CSV data for telemetry analysis' -ForegroundColor Yellow }"

REM Test 5: Cross-Platform Detection Validation
echo.
echo === TEST 5: CROSS-PLATFORM DETECTION ===
powershell -Command "$context = Get-ExecutionContext; Write-Host '[PLATFORM]' $context.Platform.IsWindows 'Windows,' $context.Platform.IsLinux 'Linux,' $context.Platform.IsWSL 'WSL' -ForegroundColor Magenta; Write-Host '[POWERSHELL]' $context.PowerShell.Edition $context.PowerShell.Version -ForegroundColor Magenta"

echo.
echo === CLAUDE BRIDGE ANALYSIS COMPLETE ===
echo [RESULT] All tests executed. Check output files in %TEMP%
echo [FILES] claude-fastpath-test.csv, claude-normal-test.csv, claude-json-test.json
echo.

endlocal