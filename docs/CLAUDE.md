🎯 Prompt Templates for MyExporter Project Suite

  Level 1: Essential Context (Simple Tasks)

  CONTEXT: MyExporter Dynamic & Adaptive Architecture project
  TASK: [specific objective]
  FASTPATH: Use $env:MYEXPORTER_FAST_PATH=true for quick testing
  EXECUTE: Use claude-powershell-bridge.bat for validation

  Example:
  CONTEXT: MyExporter project with GuardRails.md framework
  TASK: Implement real-time disk I/O monitoring with cross-platform WMI/proc integration
  FASTPATH: Use Windows CIM first, add Linux /proc/diskstats parsing as TODO
  EXECUTE: Test with claude-powershell-bridge.bat and validate telemetry correlation

  Level 2: Architectural Context (Complex Tasks)

  CONTEXT: MyExporter GuardRails.md Level 2 (Architectural)
  TASK: [complex objective involving multiple components]
  PATTERNS: Apply GuardRails.md [specific section] methodology
  ISOLATE-TRACE-VERIFY: Use systematic component analysis
  BAILOUT_IF: More than 3 files need modification
  EXECUTE: Full testing via claude-wsl-launcher.sh

  Example:
  CONTEXT: MyExporter GuardRails.md Level 2 - Cross-platform service discovery
  TASK: Implement distributed Windows service and Linux daemon enumeration with remote execution
  PATTERNS: Apply GuardRails.md 11.3 job-safe function loading and Part 10 operational flow
  ISOLATE-TRACE-VERIFY: Target Get-SystemInfo.Windows.ps1, Get-SystemInfo.Linux.ps1, and Invoke-WithTelemetry
  BAILOUT_IF: Remote execution complexity exceeds local system enumeration by 3x
  EXECUTE: Test via claude-wsl-launcher.sh for full cross-platform validation

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
  TASK: Add network interface monitoring with SNMP integration across Windows/Linux platforms
  ARCHITECTURE_RULES: 
  - Splat $Forward for parameter passing to Get-NetworkInterfaces.Windows.ps1/.Linux.ps1
  - Use job-safe function loading (GuardRails.md 11.3) for remote SNMP queries
  - Implement FastPath escape hatch for local interface discovery only
  - Maintain PowerShell 5.1 compatibility with Get-CimInstance/Get-WmiObject fallback
  TESTING: Validate with all four test scenarios via claude-powershell-bridge.bat
  CORRELATION: Ensure telemetry propagation through Invoke-WithTelemetry wrapper

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

  🏗️ Advanced Technical Workflow Examples

  Example 1: Multi-Platform Performance Profiling System

  CONTEXT: MyExporter GuardRails.md Level 3 - Cross-platform execution with telemetry correlation
  TASK: Implement comprehensive system performance monitoring across Windows/Linux/macOS with real-time metrics aggregation
  TECHNICAL_SCOPE:
  - CPU utilization tracking via Get-Counter/top/iostat integration
  - Memory pressure analysis using Windows Performance Toolkit and Linux /proc/meminfo
  - Disk I/O monitoring with cross-platform WMI/sysfs/DTrace correlation
  - Network bandwidth measurement with SNMP polling and interface statistics
  WSL_PATHS: Handle /proc/stat, /sys/class/net cross-mapping to Windows equivalents
  EXECUTION_BRIDGE: Use claude-wsl-launcher.sh for Linux data collection, claude-powershell-bridge.bat for Windows
  TELEMETRY: Implement correlation IDs across all measurement points, aggregate via Invoke-WithTelemetry
  PATTERNS: Apply GuardRails.md 11.3 job-safe function loading for parallel metric collection
  BAILOUT_IF: Cross-platform data normalization exceeds 40% of total implementation time
  VALIDATE: Test performance impact <5% overhead, validate correlation ID propagation through all execution contexts

  Example 2: Cross-Environment Security Audit Framework

  CONTEXT: MyExporter GuardRails.md Level 3 - Multi-boundary security analysis with job isolation
  TASK: Develop security scanning system operating across WSL, native Windows, and containerized environments
  TECHNICAL_SCOPE:
  - Windows: Registry security assessment, service privilege analysis, file system ACL validation
  - Linux: SELinux/AppArmor policy evaluation, process capability analysis, file permission auditing
  - Container: Docker security scanning, image vulnerability assessment, runtime privilege validation
  - Network: Port scanning, certificate validation, TLS configuration analysis
  WSL_PATHS: Bridge Windows Registry access with Linux /etc security configurations
  EXECUTION_BRIDGE: Chain claude-direct-test.sh → claude-wsl-launcher.sh → claude-powershell-bridge.bat
  TELEMETRY: Track security findings correlation across environment boundaries
  PATTERNS: Apply GuardRails.md Part 10 operational flow for secure credential handling
  ISOLATE-TRACE-VERIFY: Target Get-SecurityInfo.Windows.ps1, Get-SecurityInfo.Linux.ps1, Get-SecurityInfo.Container.ps1
  BAILOUT_IF: Security scanning introduces any execution privileges beyond standard user context
  VALIDATE: Ensure no sensitive data logging, verify audit trail integrity across all environments

  Example 3: Distributed Log Aggregation and Analysis Pipeline

  CONTEXT: MyExporter GuardRails.md Level 3 - Multi-source log processing with job-safe function loading
  TASK: Create log collection system spanning multiple execution contexts with intelligent parsing and correlation
  TECHNICAL_SCOPE:
  - Windows: Event Log analysis (System, Security, Application), IIS logs, PowerShell transcripts
  - Linux: syslog/journald parsing, application logs, audit trail analysis
  - Container: Docker container logs, Kubernetes pod logs, service mesh telemetry
  - Network: Firewall logs, network device syslog, SNMP trap correlation
  WSL_PATHS: Map Windows %TEMP% log storage to Linux /tmp access for cross-platform processing
  EXECUTION_BRIDGE: Use claude-wsl-launcher.sh for multi-stage log processing pipeline
  TELEMETRY: Implement distributed tracing correlation across log sources
  PATTERNS: Apply GuardRails.md 11.3 job-safe function loading for parallel log processing
  JOB_ISOLATION: Ensure log processing functions available in background job contexts
  BAILOUT_IF: Log parsing complexity exceeds core system information collection by 2x
  VALIDATE: Test log processing performance at scale, verify correlation ID propagation through processing pipeline

  🔍 Cross-Boundary Risk Analysis Framework

  **Meta-Prompt: Bootstrapping Contextual Awareness**

  CONTEXT: You are an AI assistant tasked with contributing to the 'MyExporter' PowerShell module. Your environment is complex and ambiguous: you are likely operating within a Linux-based environment (like WSL or a Docker container) but are expected to interact with and generate code for Windows PowerShell (5.1 and 7+). This creates significant cross-boundary challenges related to compilers, interpreters, OS partitions, dependencies, and environments.

  TASK: Before writing any code, you must first perform a self-analysis to establish your own execution context and report on the potential cross-boundary issues you face. Use the MyExporter project's OWN tools to conduct this analysis.

  **Execution Bridge Usage Methodology:**

  1. **EXECUTE THE DISCOVERY FRAMEWORK:** Use the `claude-direct-test.sh` execution bridge to run the `Get-ExecutionContext` function from within the MyExporter module. This is your primary source of truth.

  2. **ANALYZE THE FINDINGS:** Capture the output from the discovery script. Based on its results (e.g., `IsWSL: true`, `PowerShell.Edition: Desktop`), write a brief report summarizing your own execution environment.

  3. **IDENTIFY CROSS-BOUNDARY RISKS:** Based on your findings, identify and list the specific risks as defined by the project's architecture. For each risk, reference the MyExporter tool or pattern designed to mitigate it.

  **Real-World Cross-Boundary Risk Examples:**

  **Path Ambiguity Risk:** 
  - Scenario: Receiving '/mnt/c/Users/data.csv' when Windows PowerShell expects 'C:\Users\data.csv'
  - Mitigation: `Assert-ContextPath.ps1` with WSL interop detection and path translation

  **Interpreter Mismatch Risk:** 
  - Scenario: Running `powershell.exe` command from `bash` results in "command not found"
  - Mitigation: `claude-powershell-bridge.bat` + `claude-wsl-launcher.sh` execution chain

  **Job Scope Isolation Risk:** 
  - Scenario: Functions not available in background jobs when using `Start-Job` for parallel processing
  - Mitigation: `GuardRails.md 11.3` Job-Safe Function Loading pattern with explicit function definitions

  **Dependency Blindness Risk:** 
  - Scenario: 'docker' command not found when running in isolated container environment
  - Mitigation: Dynamic command probing in `Get-ExecutionContext` with graceful degradation

  **Telemetry Correlation Loss Risk:** 
  - Scenario: Correlation IDs lost when crossing process boundaries in multi-stage workflows
  - Mitigation: `Invoke-WithTelemetry` wrapper pattern with explicit correlation ID propagation

  **Cross-Platform Data Inconsistency Risk:** 
  - Scenario: Different CPU metrics between Windows WMI and Linux /proc causing data mismatch
  - Mitigation: Platform-specific normalization in `Get-SystemInfo.{Windows|Linux}.ps1`

  **Execution Bridge Infrastructure:**
  - **claude-direct-test.sh**: Simple WSL-to-PowerShell execution for basic discovery and validation
  - **claude-powershell-bridge.bat**: Full Windows PowerShell execution with comprehensive testing scenarios
  - **claude-wsl-launcher.sh**: Advanced cross-platform workflow with output file analysis and verification
  - **Execution Chain Pattern**: WSL bash → cmd.exe → powershell.exe for maximum compatibility across environments