#requires -Module Pester

Describe "Export-SystemInfo Parameter Block Regression Test" {
    
    BeforeAll {
        # Import the module fresh for testing
        $ModulePath = Join-Path (Split-Path $PSScriptRoot -Parent) "MyExporter.psd1"
        Import-Module $ModulePath -Force
    }
    
    Context "Parameter Block Integrity" {
        
        It "Should have a valid parameter block with all expected parameters" {
            $Command = Get-Command Export-SystemInfo
            
            # Test that the command exists and has parameters
            $Command | Should -Not -BeNullOrEmpty
            $Command.Parameters.Count | Should -BeGreaterThan 0
            
            # Test original parameters exist
            $Command.Parameters.ContainsKey('ComputerName') | Should -Be $true
            $Command.Parameters.ContainsKey('OutputPath') | Should -Be $true
            $Command.Parameters.ContainsKey('UseSSH') | Should -Be $true
            $Command.Parameters.ContainsKey('AsJson') | Should -Be $true
        }
        
        It "Should have correct parameter types" {
            $Command = Get-Command Export-SystemInfo
            
            $Command.Parameters['ComputerName'].ParameterType | Should -Be ([string[]])
            $Command.Parameters['OutputPath'].ParameterType | Should -Be ([string])
            $Command.Parameters['UseSSH'].ParameterType | Should -Be ([switch])
            $Command.Parameters['AsJson'].ParameterType | Should -Be ([switch])
        }
        
        It "Should have mandatory parameters correctly configured" {
            $Command = Get-Command Export-SystemInfo
            
            # ComputerName should be mandatory
            $ComputerNameParam = $Command.Parameters['ComputerName']
            $ComputerNameParam.Attributes | Where-Object { $_ -is [Parameter] } | 
                ForEach-Object { $_.Mandatory } | Should -Contain $true
            
            # OutputPath should be mandatory  
            $OutputPathParam = $Command.Parameters['OutputPath']
            $OutputPathParam.Attributes | Where-Object { $_ -is [Parameter] } |
                ForEach-Object { $_.Mandatory } | Should -Contain $true
        }
        
        It "Should support ShouldProcess" {
            $Command = Get-Command Export-SystemInfo
            
            # Check for SupportsShouldProcess in the function definition
            $FunctionDefinition = $Command.Definition
            $FunctionDefinition | Should -Match "SupportsShouldProcess.*true"
        }
        
        It "Should have correct OutputType" {
            $Command = Get-Command Export-SystemInfo
            # Check that OutputType is defined (may be empty array if no class is loaded)
            $Command.OutputType | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Function Invocation" {
        
        It "Should accept WhatIf parameter without error" {
            $TestPath = Join-Path $env:TEMP "pester-test-output.json"
            
            # This should not throw an exception
            { Export-SystemInfo -ComputerName "localhost" -OutputPath $TestPath -Format "JSON" -AsJson -WhatIf } | 
                Should -Not -Throw
        }
    }
}
