# Terminal Context Exporter

A PowerShell module for exporting system information and context data in various formats (CSV, JSON) for terminal-based workflows and automation.

## Overview

The Terminal Context Exporter (`MyExporter`) is a comprehensive PowerShell module designed to capture and export system information, execution context, and environment data. This tool is particularly useful for:

- System diagnostics and monitoring
- Environment documentation
- Automation workflow context capture
- Cross-platform system information gathering

## Features

- **Multi-format Export**: Supports CSV and JSON output formats
- **Cross-platform Compatibility**: Works on both Windows and Linux systems
- **Comprehensive System Info**: Captures detailed system information including:
  - Operating system details
  - Hardware specifications
  - Network configuration
  - Process information
  - Environment variables
- **Execution Context Tracking**: Records execution context and telemetry data
- **Modular Architecture**: Clean separation of public and private functions
- **Test Coverage**: Comprehensive test suite included

## Module Structure

```
MyExporter/
├── Classes/           # PowerShell classes
├── Private/           # Internal helper functions
├── Public/            # Exported public functions
├── MyExporter.psd1    # Module manifest
└── MyExporter.psm1    # Main module file
```

## Installation

1. Clone this repository
2. Import the module in PowerShell:
   ```powershell
   Import-Module .\MyExporter\MyExporter.psd1
   ```

## Usage

### Basic Usage

```powershell
# Export system information to CSV
Export-SystemInfo -OutputPath "system-info.csv" -Format CSV

# Export system information to JSON
Export-SystemInfo -OutputPath "system-info.json" -Format JSON
```

### Advanced Usage

The module provides several internal functions for specific use cases:

- `Get-SystemInfo.Windows.ps1` - Windows-specific system information
- `Get-SystemInfo.Linux.ps1` - Linux-specific system information
- `Get-ExecutionContext.ps1` - Execution context and environment data
- `Invoke-WithTelemetry.ps1` - Telemetry and performance tracking

## Testing

The module includes comprehensive tests:

- `Test-MyExporter.ps1` - Main functionality tests
- `Test-ModuleLoading.ps1` - Module loading and import tests
- `Test-JobFunctionality.ps1` - Background job functionality tests
- `Test-PowerShell51Compatibility.ps1` - PowerShell 5.1 compatibility tests

Run tests with:
```powershell
.\MyExporter\Test-MyExporter.ps1
```

## Documentation

Detailed documentation is available in the `docs/` directory:

- Implementation status and progress tracking
- Technical specifications and architecture
- Workflow analysis and context information
- Agent integration guidelines

## Platform Support

- **Windows**: Full support with Windows-specific optimizations
- **Linux**: Full support with Linux-specific system calls
- **PowerShell Core**: Compatible with PowerShell 6+ and PowerShell 5.1

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run the test suite
5. Submit a pull request

## License

This project is open source. Please see the license file for details.
