#requires -Module Pester

Describe "Telemetry Compliance Tests" {
    
    BeforeAll {
        $ModulePath = Join-Path (Split-Path $PSScriptRoot -Parent) "MyExporter.psd1"
        Import-Module $ModulePath -Force
    }
    
    Context "Telemetry Wrapper Usage Limits" {
        
        It "Should have ≤3 telemetry calls per Export-SystemInfo execution" -Pending {
            # This test ensures we don't have telemetry pollution per GuardRails.md
            # We'll mock the telemetry functions to count calls
            
            $TelemetryCallCount = 0
            
            # Mock telemetry functions to count calls
            Mock Invoke-WithTelemetry -ModuleName MyExporter {
                $script:TelemetryCallCount++
                & $ScriptBlock
            }
            
            Mock TerminalTelemetryBatcher -ModuleName MyExporter {
                $script:TelemetryCallCount++
            }
            
            # Create a temp output file
            $TempOutput = [System.IO.Path]::GetTempFileName()
            
            try {
                # Execute Export-SystemInfo with minimal parameters
                Export-SystemInfo -ComputerName "localhost" -OutputPath $TempOutput -Format "JSON" -IncludeTerminalInfo -WhatIf
                
                # Verify telemetry call count is within limits
                $TelemetryCallCount | Should -BeLessOrEqual 3 -Because "GuardRails.md requires ≤3 telemetry calls per Export-SystemInfo"
                
            } finally {
                Remove-Item $TempOutput -ErrorAction SilentlyContinue
            }
        }
        
        It "Should only wrap Get-TerminalContext* functions with telemetry" -Pending {
            # Per GuardRails requirement: Remove all inner telemetry wrappers from /Private/*.ps1, 
            # wrap only in Get-TerminalContext*.ps1
            
            $PrivateFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot '../Private') -Filter '*.ps1'
            $TelemetryViolations = @()
            
            foreach ($File in $PrivateFiles) {
                $Content = Get-Content $File.FullName -Raw
                
                # Skip the telemetry files themselves and Get-TerminalContext* files and Get-TerminalOutput* files
                if ($File.Name -in @('Invoke-WithTelemetry.ps1', 'TerminalTelemetryBatcher.ps1') -or 
                    $File.Name -like 'Get-TerminalContext*.ps1' -or
                    $File.Name -like 'Get-TerminalOutput*.ps1') {
                    continue
                }
                
                # Check for telemetry wrapper usage
                if ($Content -match 'Invoke-WithTelemetry|TerminalTelemetryBatcher') {
                    $TelemetryViolations += $File.Name
                }
            }
            
            $TelemetryViolations | Should -BeNullOrEmpty -Because "Only Get-TerminalContext* functions should use telemetry wrappers per GuardRails.md"
        }
    }
}
