Describe "TmuxSessionReference Class Autoloading" {
    BeforeAll {
        $ModulePath = "$PSScriptRoot\..\MyExporter.psd1"
    }
    
    BeforeEach {
        # Clean module scope before each test
        Remove-Module MyExporter -Force -ErrorAction SilentlyContinue
    }
    
    It "Should have TmuxSessionReference class available after module import" -Pending {
        # Clean import with forced reload
        Import-Module $ModulePath -Force
        
        # Try to create an instance of TmuxSessionReference
        $SessionRef = [TmuxSessionReference]::new(@{SessionId='test-session'})
        $SessionRef | Should -Not -BeNullOrEmpty
        $SessionRef.GetType().Name | Should -Be "TmuxSessionReference"
        $SessionRef.SessionId | Should -Be "test-session"
    }
    
    It "Should load TmuxSessionReference via direct dot-sourcing in module" {
        $ModuleContent = Get-Content $ModulePath.Replace('.psd1', '.psm1') -Raw
        $ModuleContent | Should -Match '\. "\$PSScriptRoot/Classes/TmuxSessionReference\.ps1"'
    }
    
    It "Should have SessionId property available" -Pending {
        Import-Module $ModulePath -Force
        $SessionRef = [TmuxSessionReference]::new(@{SessionId='test-props'})
        $SessionRef.PSObject.Properties.Name | Should -Contain "SessionId"
        $SessionRef.PSObject.Properties.Name | Should -Contain "SessionName" 
        $SessionRef.PSObject.Properties.Name | Should -Contain "CorrelationId"
    }
}
