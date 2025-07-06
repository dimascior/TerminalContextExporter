# Claude's Dynamic Architecture Analysis Test
# Applying GuardRails.md Isolate-Trace-Verify methodology

Write-Host "=== CLAUDE'S DYNAMIC ARCHITECTURE ANALYSIS ===" -ForegroundColor Yellow

# ISOLATE: Check constitutional layer compliance (Part 1)
Write-Host "`n1. CONSTITUTIONAL LAYER VALIDATION" -ForegroundColor Cyan
$manifest = Import-PowerShellDataFile "MyExporter.psd1"
Write-Host "   GUID: $($manifest.GUID)"
Write-Host "   PowerShell Version: $($manifest.PowerShellVersion)" 
Write-Host "   Compatible Editions: $($manifest.CompatiblePSEditions -join ', ')"
Write-Host "   Functions to Export: $($manifest.FunctionsToExport -join ', ')"

# TRACE: Module loading sequence (Part 2)
Write-Host "`n2. ARCHITECTURAL LAYER TRACING" -ForegroundColor Cyan
Write-Host "   Testing module import with debug output..."
try {
    $DebugPreference = 'Continue'
    Import-Module "./MyExporter.psd1" -Force
    $DebugPreference = 'SilentlyContinue'
    
    $exportedFunctions = (Get-Module MyExporter).ExportedFunctions.Keys
    Write-Host "   ✓ Exported functions: $($exportedFunctions -join ', ')" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Module import failed: $($_.Exception.Message)" -ForegroundColor Red
}

# VERIFY: Cross-platform patterns (GuardRails Part 11.3)
Write-Host "`n3. CROSS-PLATFORM PATTERN VERIFICATION" -ForegroundColor Cyan
$platformFiles = Get-ChildItem -Path "Private" -Filter "*SystemInfo*.ps1"
Write-Host "   Platform-specific files found: $($platformFiles.Count)"
foreach ($file in $platformFiles) {
    Write-Host "     - $($file.Name)" -ForegroundColor Gray
}

# Test FastPath Pattern (Anti-tail-chasing from GuardRails Part 4.2)
Write-Host "`n4. FASTPATH ESCAPE HATCH TEST" -ForegroundColor Cyan
$env:MYEXPORTER_FAST_PATH = "true"
Write-Host "   FastPath environment variable set: $env:MYEXPORTER_FAST_PATH"

Write-Host "`n=== ANALYSIS COMPLETE ===" -ForegroundColor Yellow
EOF < /dev/null
EOF
