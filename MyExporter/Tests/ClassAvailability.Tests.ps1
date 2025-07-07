InModuleScope MyExporter {
    Describe 'Class availability' {
        BeforeEach {
            Remove-Module MyExporter -Force -ErrorAction SilentlyContinue
            Import-Module "$PSScriptRoot\..\MyExporter.psd1" -Force
        }
        
        It 'SystemInfo should be loadable' {
            $sysInfo = [SystemInfo]::new(@{ComputerName='test'})
            $sysInfo | Should -Not -BeNullOrEmpty
            $sysInfo.GetType().Name | Should -Be 'SystemInfo'
        }
        
        It 'TmuxSessionReference should be loadable' {
            $sessionRef = [TmuxSessionReference]::new(@{SessionId='test'})
            $sessionRef | Should -Not -BeNullOrEmpty
            $sessionRef.GetType().Name | Should -Be 'TmuxSessionReference'
        }
        
        It 'Export-SystemInfo param block survives' {
            (Get-Command Export-SystemInfo).Parameters.Keys |
              Should -Contain 'ComputerName'
        }
        
        It 'Export-SystemInfo should have OutputType attribute' {
            $cmd = Get-Command Export-SystemInfo
            $cmd.OutputType | Should -Not -BeNullOrEmpty
        }
    }
}
