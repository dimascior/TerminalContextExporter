#requires -Module Pester

Describe "Class Loading Regression Test" {
    
    Context "SystemInfo Class" {
        
        It "Should load SystemInfo class when module is imported" {
            # Remove any existing module
            Remove-Module MyExporter -Force -ErrorAction SilentlyContinue
            
            # Import fresh
            $ModulePath = Join-Path $PSScriptRoot ".." "MyExporter.psd1"
            Import-Module $ModulePath -Force
            
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
