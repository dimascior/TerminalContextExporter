
## 📂 **Complete Project Structure & GuardRails.md Framework Integration**

### **🏗️ Root Directory Architecture**

```
WorkflowDynamics/                    # Master Framework Implementation
├── .claude/                         # AI Collaboration Configuration
│   └── settings.local.json          # Claude IDE permissions and settings
├── .gitignore                       # Git exclusions (test outputs, temp files)
├── README.md                        # Framework documentation and usage guide
├── docs/                            # Framework Knowledge Base & Analysis
│   ├── GuardRails.md                # 🎯 PRIMARY FRAMEWORK SPECIFICATION
│   ├── tasksV3.md                   # TasksV3 completion validation & methodology
│   ├── CLAUDE.md                    # Prompt engineering templates for AI collaboration
│   ├── Implementation-Status.md     # Detailed progress tracking and root cause analysis
│   ├── operation-context.xml        # Operation manifest for complex tasks
│   ├── CCSummary.md                 # Cross-platform context summary
│   ├── MCD.md                       # Anti-pattern guidance (avoiding over-engineering)
│   ├── claudeAgent.md               # AI agent interaction patterns
│   ├── ChatgptDeepRe*.md           # Deep analysis iterations (V1/V2/V3)
│   ├── WorkspaceAnalysis.md         # Workspace structure analysis
│   ├── tasks*.md                    # Task evolution (tasks → tasksV2 → tasksV3)
│   └── status.md                    # Development status tracking
└── MyExporter/                      # 🎯 REFERENCE IMPLEMENTATION MODULE
    ├── MyExporter.psd1              # Constitutional Layer - Immutable contracts
    ├── MyExporter.psm1              # Architectural Layer - Module orchestration
    ├── Classes/                     # Data Contract Layer
    │   └── SystemInfo.ps1           # PowerShell class with strict mode compatibility
    ├── Private/                     # Implementation Layer - Internal functions
    │   ├── _Initialize.ps1          # Context establishment ($script scope)
    │   ├── Assert-ContextPath.ps1   # Path validation (GuardRails compliance)
    │   ├── Assert-ContextualPath.ps1 # Legacy function (superseded)
    │   ├── Get-ExecutionContext.ps1 # Environmental context discovery
    │   ├── Get-SystemInfo.Windows.ps1 # Windows-specific implementation
    │   ├── Get-SystemInfo.Linux.ps1   # Linux-specific implementation
    │   ├── Get-SystemInfoPlatformSpecific.ps1 # Platform dispatcher
    │   └── Invoke-WithTelemetry.ps1 # Telemetry wrapper with correlation IDs
    ├── Public/                      # Public API Layer
    │   └── Export-SystemInfo.ps1    # Main cmdlet with job-safe execution
    ├── Test-*.ps1                   # Testing & Validation Suite
    │   ├── Test-MyExporter.ps1      # Core functionality tests
    │   ├── Test-ModuleLoading.ps1   # Module loading validation
    │   ├── Test-JobFunctionality.ps1 # Background job testing
    │   ├── Test-PowerShell51Compatibility.ps1 # Cross-edition validation
    │   └── test_claude_analysis.ps1 # AI collaboration testing
    ├── claude-*.sh/bat              # 🎯 EXECUTION BRIDGE INFRASTRUCTURE
    │   ├── claude-powershell-bridge.bat # WSL→Windows PowerShell execution
    │   ├── claude-wsl-launcher.sh   # Cross-platform orchestration
    │   └── claude-direct-test.sh    # Direct command execution
    └── final-test-*.csv/json        # TasksV3 completion evidence files
        ├── final-test-fastpath.csv  # FastPath CSV validation (226 bytes)
        ├── final-test-fastpath.json # FastPath JSON validation (288 bytes)
        ├── final-test-normal.csv    # Normal mode CSV validation (306 bytes)
        └── final-test-normal.json   # Normal mode JSON validation (390 bytes)
```

---

## 🎯 **Framework Layer Analysis (GuardRails.md Integration)**

### **1. Constitutional Layer (GuardRails.md Part 1)**
**Files:** `MyExporter.psd1`, `.gitignore`, `settings.local.json`

| File | GuardRails Function | Framework Purpose |
|------|-------------------|------------------|
| **MyExporter.psd1** | **Immutable Contract** | Single source of truth for versioning, dependencies, and API surface. Implements manifest-driven architecture. |
| **.gitignore** | **Artifact Control** | Prevents test output pollution in version control. Maintains clean constitutional state. |
| **settings.local.json** | **AI Collaboration Contract** | Defines Claude IDE permissions. Establishes constitutional boundaries for AI interaction. |

**Core Principle:** These files establish the **non-negotiable foundation** that all other layers must respect.

### **2. Architectural Layer (GuardRails.md Part 2)**  
**Files:** `MyExporter.psm1`, `/Classes/`, `/Private/`, `/Public/` directory structure

| Component | GuardRails Pattern | Architecture Purpose |
|-----------|-------------------|---------------------|
| **MyExporter.psm1** | **Module Orchestration** | Root module loader implementing deterministic loading sequence. Controls scope boundaries. |
| **/Classes/** | **Data Contract Enforcer** | Strong typing with PowerShell 5.1 compatibility. Self-validating data structures. |
| **/Private/** | **Implementation Isolation** | Verb-noun-platform naming. Platform-specific logic separation. Job-safe function definitions. |
| **/Public/** | **API Gateway** | Single entry point (`Export-SystemInfo`). Parameter validation and orchestration only. |

**Core Principle:** Directory topology **reveals architectural intent**. Structure is self-documenting.

### **3. Implementation Layer (GuardRails.md Part 3)**
**Files:** All `.ps1` files in `/Private/` and `/Public/`

#### **Critical Implementation Files:**

| File | GuardRails Section | Implementation Purpose |
|------|-------------------|----------------------|
| **Export-SystemInfo.ps1** | **11.3 Job-Safe Loading** | Public API with FastPath escape hatch. Implements job-safe function injection. |
| **Get-SystemInfoPlatformSpecific.ps1** | **Platform Dispatcher** | Routes to platform-specific implementations. Avoids `$ExecutionContext` collision. |
| **Get-SystemInfo.Windows.ps1** | **Platform Implementation** | Windows-specific system information collection via CIM/WinRM. |
| **Get-SystemInfo.Linux.ps1** | **Platform Implementation** | Linux-specific collection via native commands and SSH support. |
| **Invoke-WithTelemetry.ps1** | **Selective Telemetry** | Correlation ID propagation. Avoids telemetry-everywhere anti-pattern. |
| **Get-ExecutionContext.ps1** | **Environmental Discovery** | Cross-platform context detection (WSL/Windows/PowerShell editions). |
| **Assert-ContextPath.ps1** | **Path Validation** | Cross-platform path normalization. POSIX compliance for JSON output. |

### **4. Adaptive Collaboration Layer (GuardRails.md Part 4)**
**Files:** `/docs/CLAUDE.md`, execution bridges, test files

#### **AI Collaboration Infrastructure:**

| Component | GuardRails Section | Collaboration Purpose |
|-----------|-------------------|---------------------|
| **CLAUDE.md** | **4.1 Progressive Context Anchoring** | Prompt templates for Level 1/2/3 complexity management. |
| **claude-powershell-bridge.bat** | **12.2 Dynamic Path Resolution** | WSL→Windows PowerShell execution bridge. Implements Part 10 operational flow. |
| **claude-wsl-launcher.sh** | **Cross-Platform Orchestration** | Linux script orchestrating Windows PowerShell execution. |
| **claude-direct-test.sh** | **Simplified Testing** | Direct command execution for rapid validation. |
| **operation-context.xml** | **5.1 Artifact-Based Context** | Operation manifest preventing context loss during complex tasks. |

---

## 🔄 **Core Workflow Patterns (Claude + GuardRails.md Integration)**

### **Pattern 1: Level 1 (Essential) Development Workflow**

```powershell
# CLAUDE PROMPT TEMPLATE:
CONTEXT: MyExporter Dynamic & Adaptive Architecture project
TASK: [specific objective]
FASTPATH: Use $env:MYEXPORTER_FAST_PATH=true for quick testing
EXECUTE: Use claude-powershell-bridge.bat for validation

# IMPLEMENTATION FLOW:
1. Edit MyExporter files (following GuardRails.md patterns)
2. Execute: ./claude-powershell-bridge.bat
3. Validate: FastPath mode testing with correlation IDs
4. Verify: Output files contain expected data structure
```

### **Pattern 2: Level 2 (Architectural) Development Workflow**

```powershell
# CLAUDE PROMPT TEMPLATE:
CONTEXT: MyExporter GuardRails.md Level 2 (Architectural)
TASK: [complex objective involving multiple components]
PATTERNS: Apply GuardRails.md [specific section] methodology
ISOLATE-TRACE-VERIFY: Use systematic component analysis
BAILOUT_IF: More than 3 files need modification
EXECUTE: Full testing via claude-wsl-launcher.sh

# IMPLEMENTATION FLOW:
1. ISOLATE: Target specific component set (e.g., job execution)
2. TRACE: Follow dependency chain through module boundaries
3. VERIFY: Registry validation (Get-Module vs manifest)
4. INTEGRATE: Apply changes with telemetry correlation
5. VALIDATE: All four test scenarios (FastPath/Normal × CSV/JSON)
```

### **Pattern 3: Level 3 (Environmental) Development Workflow**

```powershell
# CLAUDE PROMPT TEMPLATE:
CONTEXT: MyExporter cross-platform execution (WSL2/Windows/PowerShell 5.1+7.x)
TASK: [platform-specific objective]
WSL_PATHS: Handle path translation between Linux and Windows
EXECUTION_BRIDGE: Use claude-powershell-bridge.bat for cross-interpreter testing
TELEMETRY: Ensure correlation IDs propagate through scope boundaries
VALIDATE: Test across all target environments

# IMPLEMENTATION FLOW:
1. Environmental Context Discovery (Get-ExecutionContext)
2. Cross-Platform Path Normalization (Assert-ContextPath)
3. Platform-Specific Implementation (Get-SystemInfo.*.ps1)
4. Job-Safe Function Loading (GuardRails.md 11.3)
5. End-to-End Validation across WSL/Windows/PowerShell editions
```

---

## 🎪 **Framework Classes & Core Components**

### **SystemInfo Class (Constitutional Data Contract)**
```powershell
# Location: /Classes/SystemInfo.ps1
# GuardRails Section: Part 3.1 - Data Contracts and Strong Typing

class SystemInfo {
    [string]$ComputerName    # Mandatory field with validation
    [string]$Platform        # Windows/Linux/macOS detection
    [string]$OS             # Operating system details
    [string]$Version        # OS version information
    [string]$Source         # Collection method (CIM/WinRM/SSH/Direct)
    [datetime]$Timestamp    # Collection timestamp
    [string]$CorrelationId  # End-to-end telemetry tracking
    
    # PowerShell 5.1 compatible constructor with defensive property access
    SystemInfo([hashtable]$data) {
        # Implements GuardRails.md constitutional validation patterns
    }
}
```

### **Export-SystemInfo Cmdlet (Public API Gateway)**
```powershell
# Location: /Public/Export-SystemInfo.ps1
# GuardRails Section: Part 11.3 - Job-Safe Function Loading

function Export-SystemInfo {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)] [string[]]$ComputerName,
        [Parameter(Mandatory)] [string]$OutputPath,
        [switch]$UseSSH,
        [switch]$AsJson
    )
    
    # FASTPATH ESCAPE HATCH (GuardRails.md 4.2)
    if ($env:MYEXPORTER_FAST_PATH) {
        # Direct execution bypassing job architecture
    }
    
    # ARCHITECTURAL PATTERN (GuardRails.md 11.1)
    $forward = @{
        UseSSH = $UseSSH
        Context = Get-ExecutionContext  # Renamed to avoid $ExecutionContext collision
    }
    
    # JOB-SAFE FUNCTION LOADING (GuardRails.md 11.3)
    Start-Job -ScriptBlock {
        param($functionDefs)
        Invoke-Expression $functionDefs  # Re-hydrate functions in job context
    }
}
```

### **Execution Bridge Infrastructure (Cross-Platform Orchestration)**
```batch
REM Location: claude-powershell-bridge.bat
REM GuardRails Section: Part 10 - Operational Flow

@echo off
REM Implements GuardRails.md Part 10 operational flow from WSL environment
REM Tests all four scenarios: FastPath/Normal × CSV/JSON
REM Validates correlation ID propagation and telemetry integration
REM Provides evidence files for TasksV3 completion validation
```

---

## 🎯 **Framework Success Evidence & Validation**

### **TasksV3 Completion Artifacts**
All validation files demonstrate successful GuardRails.md implementation:

| File | Size | Purpose | GuardRails Validation |
|------|------|---------|---------------------|
| **final-test-fastpath.csv** | 226 bytes | FastPath CSV output | Anti-tail-chasing pattern working |
| **final-test-fastpath.json** | 288 bytes | FastPath JSON output | Escape hatch operational |
| **final-test-normal.csv** | 306 bytes | Normal mode CSV | Job-safe function loading working |
| **final-test-normal.json** | 390 bytes | Normal mode JSON | Correlation ID telemetry successful |

### **Framework Methodology Validation**
- ✅ **Constitutional Layer**: Manifest-driven contracts respected
- ✅ **Architectural Layer**: Self-documenting structure maintained  
- ✅ **Implementation Layer**: Job-safe execution with telemetry
- ✅ **Adaptive Collaboration**: Progressive context anchoring applied
- ✅ **AI Integration**: CLAUDE.md templates institutionalize success patterns

**Project demonstrates complete GuardRails.md Dynamic & Adaptive Architecture implementation with 100% TasksV3 validation success.**
