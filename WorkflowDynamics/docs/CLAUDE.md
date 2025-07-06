🎯 Prompt Templates for MyExporter Project Suite

  Level 1: Essential Context (Simple Tasks)

  CONTEXT: MyExporter Dynamic & Adaptive Architecture project
  TASK: [specific objective]
  FASTPATH: Use $env:MYEXPORTER_FAST_PATH=true for quick testing
  EXECUTE: Use claude-powershell-bridge.bat for validation

  Example:
  CONTEXT: MyExporter project with GuardRails.md framework
  TASK: Add CPU temperature monitoring to SystemInfo class
  FASTPATH: Implement Windows-only first, leave TODO for Linux/macOS
  EXECUTE: Test with claude-powershell-bridge.bat

  Level 2: Architectural Context (Complex Tasks)

  CONTEXT: MyExporter GuardRails.md Level 2 (Architectural)
  TASK: [complex objective involving multiple components]
  PATTERNS: Apply GuardRails.md [specific section] methodology
  ISOLATE-TRACE-VERIFY: Use systematic component analysis
  BAILOUT_IF: More than 3 files need modification
  EXECUTE: Full testing via claude-wsl-launcher.sh

  Example:
  CONTEXT: MyExporter GuardRails.md Level 2 - Job integration patterns
  TASK: Implement remote SSH connectivity for Linux systems
  PATTERNS: Apply GuardRails.md 11.3 job-safe function loading
  ISOLATE-TRACE-VERIFY: Target Private/Get-SystemInfo.Linux.ps1 and related components
  BAILOUT_IF: SSH implementation becomes more complex than core system info collection
  EXECUTE: Validate with both FastPath and normal modes

  Level 3: Cross-Platform/Environmental Context

  CONTEXT: MyExporter cross-platform execution (WSL2/Windows/PowerShell 5.1+7.x)
  TASK: [platform-specific objective]
  WSL_PATHS: Handle path translation between Linux and Windows
  EXECUTION_BRIDGE: Use claude-powershell-bridge.bat for cross-interpreter testing
  TELEMETRY: Ensure correlation IDs propagate through scope boundaries
  VALIDATE: Test across all target environments

  🔧 Specialized Prompt Patterns

  For Framework Analysis

  Analyze the MyExporter project using GuardRails.md Part [X] methodology.
  Focus on [specific pattern/concern].
  Use Isolate-Trace-Verify discipline.
  Execute tests via claude-powershell-bridge.bat to validate findings.

  For Extension Development

  Extend MyExporter with [new feature] following the Dynamic & Adaptive Architecture.
  Apply Progressive Context Anchoring at Level [1/2/3].
  Reference GuardRails.md patterns for [specific technical challenge].
  Implement with FastPath escape hatch for immediate testing.

  For Cross-Platform Testing

  Test MyExporter [specific functionality] across WSL2, Windows PowerShell 5.1, and PowerShell Core.
  Use the claude-wsl-launcher.sh execution bridge.
  Validate GuardRails.md Part 10 operational flow.
  Report correlation ID propagation and telemetry data.

  For Troubleshooting

  Debug MyExporter [specific issue] using the established execution bridges.
  Apply the troubleshooting methodology from tasksV3.md root cause analysis.
  Use claude-direct-test.sh for simple validation.
  Focus on [specific component/pattern] isolation.

  🎪 Advanced Integration Prompts

  For New Feature Development

  CONTEXT: MyExporter Dynamic & Adaptive Architecture
  TASK: Add [feature] following established patterns
  ARCHITECTURE_RULES: 
  - Splat $Forward for parameter passing
  - Use job-safe function loading (GuardRails.md 11.3)
  - Implement FastPath escape hatch
  - Maintain PowerShell 5.1 compatibility
  TESTING: Validate with all four test scenarios (FastPath/Normal × CSV/JSON)
  CORRELATION: Ensure telemetry propagation through execution chain

  For Performance Analysis

  Analyze MyExporter performance using Invoke-WithTelemetry correlation data.
  Focus on [specific operation/bottleneck].
  Use claude-powershell-bridge.bat to collect timing metrics.
  Apply GuardRails.md optimization patterns.
  Report findings with structured telemetry data.

  For Architecture Validation

  Validate MyExporter architectural compliance against GuardRails.md framework.
  Use the established execution bridges for comprehensive testing.
  Apply the success patterns from tasksV3.md analysis.
  Focus on [specific architectural layer/concern].
  Generate compliance report with evidence from test outputs.

  🚀 Quick Access Patterns

  For immediate testing:
  Quick test: Run MyExporter [function] using claude-powershell-bridge.bat

  For framework exploration:
  Explore MyExporter [pattern/component] using GuardRails.md [section] methodology

  For extension work:
  Extend MyExporter with [feature] following the established Dynamic & Adaptive Architecture patterns        

  🎯 Key Success Factors

  1. Always reference the execution bridges (claude-powershell-bridge.bat, claude-wsl-launcher.sh)
  2. Specify GuardRails.md section for complex architectural work
  3. Use Progressive Context Anchoring levels (1/2/3) to match task complexity
  4. Include FastPath consideration for immediate productivity
  5. Reference established patterns from tasksV3.md success methodology

  This approach leverages the complete framework ecosystem we've established, ensuring you get
  sophisticated architectural compliance while maintaining the pragmatic productivity that the Dynamic &     
   Adaptive Architecture was designed to provide.