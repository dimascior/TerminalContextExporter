# Changelog

All notable changes to the MyExporter module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0-alpha.8] - 2025-07-06

### Added
- TasksV5 GuardRails Recovery & Evidence Closure implementation
- Four-leg CI matrix (Windows PS 5.1/7.4, Ubuntu WSL/no-tmux)
- WSLUser.Idempotency.bats test for Initialize-WSLUser.sh validation
- Test-TmuxAvailability.ps1 for real tmux integration verification
- Telemetry batch stub with ≤3 events per session validation

### Changed
- Re-ordered class dot-sources in MyExporter.psm1 for PowerShell 5.1 compatibility
- Replaced ScriptsToProcess with pure dot-source loading order
- Synchronized FileList from git ls-files (excluding DevScripts)
- Enhanced TelemetryCompliance.Tests.ps1 with real in-memory counter
- Excluded DevScripts from Verify-Phase PSA and FileList scans

### Fixed
- Class loading issues causing "type not found" errors in PowerShell 5.1
- Module import warnings and duplicate load issues
- FileList drift causing Verify-Phase manifest failures
- Mock/sentinel code patterns in telemetry compliance tests
- DevScripts triggering false positives in compliance checks

### Security
- Validated WSL user script idempotency in container environments
- Enhanced terminal integration with proper session isolation

## [1.0.0-alpha.7] - 2025-07-06

### Added
- Enhanced test bridge (enhanced-test-bridge.ps1) for real testing validation
- Comprehensive TasksV4 implementation audit and TasksV5 recovery plan
- Real tmux integration testing infrastructure
- Evidence generation with Git commit context and timestamps
- Class loading verification for SystemInfo and TmuxSessionReference types

### Changed
- Relocated enhanced-test-bridge.ps1 to MyExporter directory with corrected paths
- Enhanced test infrastructure to address project manager questions about test reality
- Improved error handling and evidence capture in testing framework
- Updated implementation-changes.md with comprehensive TasksV4 audit findings

### Fixed
- Path resolution issues in enhanced test bridge for module-relative execution
- String interpolation and encoding issues in PowerShell test scripts
- Git context handling for evidence generation from module subdirectory

## [1.0.0-alpha.6] - 2025-07-06

### Added
- GuardRails compliance enforcement in CI pipeline
- TelemetryCompliance.Tests.ps1 for telemetry pollution prevention
- WSL user script idempotency testing with bats
- Enhanced Verify-Phase.ps1 with CHANGELOG and [Pending] test checks

### Changed
- Removed ScriptsToProcess from manifest; classes now only dot-sourced in module
- Enhanced FileList in manifest to include all runtime assets
- Hardened Initialize-WSLUser.sh for idempotency and sudo-less environments
- CI matrix now enforces GuardRails verification as a required gate

### Fixed
- Class loading issues in PowerShell 5.1 strict mode
- Function name consistency (Assert-ContextPath vs Assert-ContextualPath)
- Telemetry wrapper usage limited to ≤3 calls per Export-SystemInfo execution

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
