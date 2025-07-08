<!-- GUARDRAIL: Always begin by reading docs/integration loop/GuardRails.md Part 5 (State Tracking) -->
<!-- MASTER CONTEXT VERSION: v1.2 (docs/MASTER-CONTEXT-FRAMEWORK.md) -->

# TasksV4: Terminal Integration Implementation Plan

**🚨 CONSTITUTIONAL GUARDRAIL BANNER 🚨**  
**Authority:** All task definitions below derive from `docs/integration loop/GuardRails.md` constitutional framework  
**Master Context:** Always validate against `docs/MASTER-CONTEXT-FRAMEWORK.md` before proceeding  
**Mandatory Reading:** GuardRails.md Parts 1-3 → CLAUDE.md → Isolate-Trace-Verify-Loop.md

**Generated:** July 6, 2025  
**Framework:** GuardRails.md Dynamic & Adaptive Architecture  
**Objective:** Implement persistent tmux-backed WSL terminal integration while maintaining 100% GuardRails compliance  
**Base:** TasksV3 100% completion success patterns  

## 🎯 **Executive Summary**

This task list implements the **IntegrationalRoadMapAnalysis.md** roadmap using proven **TasksV3 methodologies**. The approach applies **Progressive Context Anchoring** with **Isolate-Trace-Verify** discipline to systematically integrate terminal capabilities without compromising the existing architecture.

**Strategic Goals:**
- ✅ Maintain 100% GuardRails.md compliance from TasksV3 success
- ✅ Add terminal integration as non-breaking enhancement to Export-SystemInfo
- ✅ Preserve FastPath escape hatch and job-safe execution patterns
- ✅ Implement security-first approach with policy-driven command validation

## 📊 **Development Framework & Limitations**

### **🔒 Core Limitations (Constitutional Constraints)**
1. **Public API Immutability**: No new exported functions. All terminal features via existing Export-SystemInfo parameters
2. **GuardRails Compliance**: Every component must follow established patterns (parameter splatting, job-safe loading, etc.)
3. **Cross-Platform Compatibility**: Must work across WSL2/Windows/PowerShell 5.1+7.x environments
4. **Security Boundaries**: All terminal commands subject to policy-driven validation
5. **Performance Impact**: Terminal integration <5% overhead on normal operations
6. **Testing Requirements**: All four test scenarios (FastPath/Normal × CSV/JSON) must continue passing

### **🎯 Strategic Goals**
1. **Non-Breaking Enhancement**: Terminal features integrate seamlessly with existing architecture
2. **Security-First Implementation**: Policy-driven command validation prevents injection attacks
3. **Stateful Session Management**: Persistent tmux sessions via immutable reference objects
4. **Cross-Boundary Data Integrity**: 4-layer escaping for PowerShell→Bash→Tmux communication
5. **Telemetry Integration**: Terminal output includes correlation IDs for end-to-end tracing
6. **Capability-Based Routing**: Dynamic detection of WSL/tmux availability with graceful degradation

## 🗂️ **Implementation Phases (Progressive Context Anchoring)**

### **Phase 1: Level 1 (Essential) - State Management Foundation**
**Context:** Simple, isolated state management without cross-boundary complexity  
**Duration:** 2-3 hours  
**Bailout Trigger:** If state schema requires more than 2 file modifications

| Task | File | GuardRails Section | Description |
|------|------|-------------------|-------------|
| **1.1** | `Classes/TmuxSessionReference.ps1` | Part 3.1 - Data Contracts | Create immutable session reference class |
| **1.2** | `Private/Update-StateFileSchema.ps1` | Part 3.3 - State Management | Implement v2.0 state schema migration |
| **1.3** | `Private/Get-CurrentSession.ps1` | Part 3.3 - State Management | Session lifecycle management |

**Testing:** Use `claude-direct-test.sh` for simple validation  
**Success Criteria:** State file loads correctly, sessions tracked without errors

### **Phase 2: Level 1 (Essential) - Security Foundation**
**Context:** Policy-driven command validation as isolated component  
**Duration:** 2-3 hours  
**Bailout Trigger:** If security rules become more complex than core business logic

| Task | File | GuardRails Section | Description |
|------|------|-------------------|-------------|
| **2.1** | `Policies/terminal-deny.yaml` | New - Policy Layer | Command safety rules and patterns |
| **2.2** | `Private/Test-CommandSafety.ps1` | New - Security Validation | Policy-driven command sanitizer |
| **2.3** | `Private/Initialize-WSLUser.sh` | Part 11.5 - Virtual Environment | Sandboxed user creation |

**Testing:** Validate security rules prevent dangerous commands  
**Success Criteria:** Policy engine blocks configured command patterns

### **Phase 3: Level 2 (Architectural) - Cross-Boundary Communication**
**Context:** Multi-layer data marshalling across process boundaries  
**Duration:** 4-6 hours  
**Bailout Trigger:** If escaping complexity exceeds 40% of implementation time

| Task | File | GuardRails Section | Description |
|------|------|-------------------|-------------|
| **3.1** | `Private/New-TmuxArgumentList.ps1` | Part 11.3 - Process Boundaries | 4-layer escaping pipeline |
| **3.2** | `Tests/Test-TmuxArgumentList.ps1` | Testing Framework | Character preservation validation |
| **3.3** | `Private/Invoke-WslTmuxCommand.ps1` | Part 11.3 - Process Boundaries | WSL execution bridge |

**Testing:** Use `claude-powershell-bridge.bat` for cross-boundary validation  
**Success Criteria:** Special characters preserved across PowerShell→Bash→Tmux

### **Phase 4: Level 2 (Architectural) - Platform Integration**
**Context:** Platform dispatcher enhancement with capability detection  
**Duration:** 3-4 hours  
**Bailout Trigger:** If capability detection becomes more complex than platform-specific implementations

| Task | File | GuardRails Section | Description |
|------|------|-------------------|-------------|
| **4.1** | `Private/Get-TerminalContextPlatformSpecific.ps1` | Part 2 - Platform Strategy | Capability-based routing |
| **4.2** | `Private/Get-TerminalContext.WSL.ps1` | Part 2 - Platform Strategy | WSL-specific implementation |
| **4.3** | `Private/Test-TerminalCapabilities.ps1` | Dynamic Discovery | WSL/tmux availability detection |

**Testing:** Validate capability detection across different environments  
**Success Criteria:** Graceful degradation when tmux/WSL unavailable

### **Phase 5: Level 2 (Architectural) - Terminal Output Capture**
**Context:** Dual-path output capture (FastPath vs Full Telemetry)  
**Duration:** 3-4 hours  
**Bailout Trigger:** If telemetry integration violates FastPath simplicity

| Task | File | GuardRails Section | Description |
|------|------|-------------------|-------------|
| **5.1** | `Private/Get-TerminalOutput.WSL.ps1` | Part 4.1 - FastPath Pattern | Dual-path output capture |
| **5.2** | `Private/TerminalTelemetryBatcher.ps1` | Part 3.2 - Selective Telemetry | Batch telemetry to prevent pollution |
| **5.3** | `Private/Add-TerminalContextToSystemInfo.ps1` | Part 11.1 - Parameter Flow | Integrate terminal data |

**Testing:** Validate both FastPath and telemetry paths work correctly  
**Success Criteria:** Terminal output includes correlation IDs, FastPath remains fast

### **Phase 6: Level 3 (Environmental) - Public API Integration**
**Context:** Non-breaking enhancement to Export-SystemInfo with cross-platform support  
**Duration:** 4-5 hours  
**Bailout Trigger:** If public API changes break existing test scenarios

| Task | File | GuardRails Section | Description |
|------|------|-------------------|-------------|
| **6.1** | `Public/Export-SystemInfo.ps1` | Part 11.1 - Parameter Flow | Add terminal parameters |
| **6.2** | `Private/Get-ExecutionContext.ps1` | Part 12.1 - Environment Detection | Enhance context discovery |
| **6.3** | Update existing test files | Testing Framework | Ensure backward compatibility |

**Testing:** All four existing test scenarios must continue passing  
**Success Criteria:** Terminal features work without breaking existing functionality

### **Phase 7: Level 3 (Environmental) - Execution Bridge Enhancement**
**Context:** Cross-platform testing infrastructure for terminal features  
**Duration:** 2-3 hours  
**Bailout Trigger:** If execution bridge complexity exceeds terminal feature complexity

| Task | File | GuardRails Section | Description |
|------|------|-------------------|-------------|
| **7.1** | `claude-wsl-launcher.sh` | Part 12.2 - Dynamic Path Resolution | WSLENV context propagation |
| **7.2** | `claude-terminal-test.sh` | New - Testing Infrastructure | Terminal-specific test script |
| **7.3** | `.github/workflows/ci.yml` | CI/CD Pipeline | Terminal integration tests |

**Testing:** Cross-platform validation via enhanced execution bridges  
**Success Criteria:** Terminal features work across WSL2/Windows/PowerShell editions

### **Phase 8: Level 3 (Environmental) - Integration Testing & Validation**
**Context:** End-to-end validation across all environments and scenarios  
**Duration:** 3-4 hours  
**Bailout Trigger:** If integration testing reveals fundamental architecture issues

| Task | File | GuardRails Section | Description |
|------|------|-------------------|-------------|
| **8.1** | `Test-TerminalCompliance.ps1` | Compliance Testing | Terminal-specific integration tests |
| **8.2** | `terminal-validation-matrix.csv` | Evidence Generation | Test results across all environments |
| **8.3** | Documentation updates | Knowledge Transfer | Update README and framework docs |

**Testing:** Complete end-to-end validation matrix  
**Success Criteria:** All terminal features validated across all supported environments

## 🔄 **CLAUDE.md Prompt Integration Patterns**

### **Phase 1-2 Pattern (Level 1 Essential):**
```
CONTEXT: MyExporter Dynamic & Adaptive Architecture project
TASK: Implement [specific component] following GuardRails.md patterns
FASTPATH: Focus on core functionality first, add telemetry later
EXECUTE: Use claude-direct-test.sh for validation
ISOLATE: Target single component (state management OR security)
VERIFY: Component works in isolation before integration
```

### **Phase 3-5 Pattern (Level 2 Architectural):**
```
CONTEXT: MyExporter GuardRails.md Level 2 (Architectural)
TASK: Implement [cross-boundary communication] with job-safe patterns
PATTERNS: Apply GuardRails.md 11.3 job-safe function loading
ISOLATE-TRACE-VERIFY: Target specific component set (marshalling/platform/capture)
BAILOUT_IF: Cross-boundary complexity exceeds core business logic
EXECUTE: Full testing via claude-powershell-bridge.bat
```

### **Phase 6-8 Pattern (Level 3 Environmental):**
```
CONTEXT: MyExporter cross-platform execution (WSL2/Windows/PowerShell 5.1+7.x)
TASK: Integrate terminal features with existing Export-SystemInfo API
WSL_PATHS: Handle terminal output path translation
EXECUTION_BRIDGE: Use claude-wsl-launcher.sh for comprehensive testing
TELEMETRY: Ensure correlation IDs propagate through terminal execution
VALIDATE: Test across all target environments with existing test matrix
```

## 📊 **Success Metrics & Validation Framework**

### **Phase Completion Criteria:**
- ✅ **Phase 1-2**: Foundation components work in isolation
- ✅ **Phase 3-5**: Cross-boundary communication preserves data integrity
- ✅ **Phase 6-8**: Terminal integration works without breaking existing functionality

### **Overall Success Validation:**
1. **All existing TasksV3 test scenarios continue passing**
2. **Terminal features work across WSL2/Windows/PowerShell 5.1+7.x**
3. **Security policies prevent command injection attacks**
4. **Performance impact <5% on normal operations**
5. **Correlation IDs propagate through terminal execution paths**
6. **FastPath escape hatch remains operational**

### **Evidence Generation:**
- **terminal-test-fastpath.csv/json**: Terminal features with FastPath
- **terminal-test-normal.csv/json**: Terminal features with full telemetry
- **security-test-results.csv**: Command safety validation results
- **performance-benchmark.csv**: Performance impact measurements

## 🎯 **Risk Mitigation & Bailout Strategies**

### **Common Failure Modes:**
1. **State Management Complexity**: Bailout to file-based session tracking
2. **Cross-Boundary Data Loss**: Bailout to base64 encoding for problematic characters
3. **Security Policy Overhead**: Bailout to whitelist-only approach
4. **Performance Degradation**: Bailout to terminal features as separate cmdlet
5. **Platform Compatibility Issues**: Bailout to Windows-only terminal integration

### **Progressive Validation Strategy:**
1. **Each phase validates in isolation before proceeding**
2. **Existing test matrix must pass after each phase**
3. **Performance benchmarks checked after phases 5 and 8**
4. **Security validation required before any terminal execution**
5. **Cross-platform testing mandatory before final integration**

---

**TasksV4 Status: 📋 READY FOR IMPLEMENTATION**  
**Framework Compliance: 🎯 GUARDRAILS.MD PATTERNS APPLIED**  
**Success Foundation: ✅ BUILT ON TASKSV3 METHODOLOGY**
