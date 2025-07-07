# Changelog

All notable changes to the MyExporter module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0-alpha.5] - 2024-12-19

### Added
- Initial release of MyExporter module
- Cross-platform system information export functionality
- Support for JSON, CSV, and XML output formats
- SSH remote execution capability
- Terminal context detection and tmux session management
- WSL integration with user initialization script
- Comprehensive test suite with Pester
- CI/CD pipeline with matrix testing across Windows and Ubuntu
- Guard rails implementation with architectural compliance checking

### Changed
- Enhanced parameter validation for Export-SystemInfo
- Improved class loading mechanism for PowerShell 5.1 compatibility
- Refactored telemetry system for controlled usage patterns

### Security
- Added terminal access policy controls
- Implemented secure context path validation

### Fixed
- PowerShell 5.1 compatibility issues with class definitions
- Module manifest FileList accuracy
- Cross-platform path handling

## [Unreleased]

### Planned
- Performance optimizations for large-scale deployments
- Enhanced error reporting and diagnostics
- Extended platform support
