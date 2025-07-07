#requires -Module Pester

Describe "Class Loading Regression Test" {
    
    BeforeAll {
        # Ensure clean import for all tests in this file
        Remove-Module MyExporter -Force -ErrorAction SilentlyContinue
        $ModulePath = Split-Path $PSCommandPath -Parent | Split-Path -Parent | Join-Path -ChildPath "MyExporter.psd1"
        Import-Module $ModulePath -Force
    }
    
    Context "SystemInfo Class" {
        
        It "Should load SystemInfo class when module is imported" {
            # Test that the class is available
            { [SystemInfo] } | Should -Not -Throw
        }
        
        It "Should be able to instantiate SystemInfo class" {
            $testData = @{
                ComputerName = 'test'
                Platform = 'test'
                OS = 'test' 
                Version = 'test'
                Source = 'test'
                Timestamp = Get-Date
                CorrelationId = 'test'
            }
            
            { [SystemInfo]::new($testData) } | Should -Not -Throw
        }
    }
    
    Context "TmuxSessionReference Class" {
        
        It "Should load TmuxSessionReference class when module is imported" {
            { [TmuxSessionReference] } | Should -Not -Throw
        }
    }
}
