Of course. This response incorporates all previous details and integrates the new, highly refined implementation plan. It builds upon the established structure, replacing and enhancing sections with the provided granulated details to create a complete, actionable engineering roadmap.

---

## Integrational Roadmap Analysis: `MyExporter` Terminal Context Bridge (Refined)

**Generated:** 2025-07-06 14:24:17
**Framework:** `GuardRails.md` Dynamic & Adaptive Architecture
**Objective:** Integrate a persistent `tmux`-backed WSL terminal session for observable, stateful command execution, while maintaining 100% compliance with existing architectural constraints.

### 1. Executive Summary

This refined roadmap details the engineering plan to bridge the stateless, version-locked `MyExporter` module with a stateful, persistent WSL/`tmux` terminal session. The core challenge is managing this new, mutable state across multiple OS and process boundaries without violating the `GuardRails.md` "constitution."

The solution achieves this by treating the `tmux` session not as shared state, but as an **immutable resource reference** managed by the module's existing state mechanisms. This refined plan introduces a versioned state schema, a policy-driven security layer, and a capability-based platform dispatcher. All communication adheres strictly to `GuardRails` principles of encapsulation, parameter forwarding, and robust cross-boundary data serialization. The result is a powerful "execute, observe, adjust" capability for AI agents that is architecturally sound, secure, and fully integrated with the existing framework.

### 2. Architectural Layers: Applying `GuardRails.md` to the Terminal Bridge

This section granulates every constraint and applies them to the refined implementation plan.

#### **Phase 1: The Constitutional Layer - Encapsulation and Public Surface Integrity**

**Constraint:** *"never exposes that pane directly to public code; all interaction flows through the existing...entry points, so module consumers still see a single, version-locked public cmdlet surface"*

**Refined Implementation:**
The `tmux` functionality is exposed via new, optional parameters on `Export-SystemInfo`. The public API contract in `MyExporter.psd1`'s `FunctionsToExport` remains unchanged, preserving the "single cmdlet surface." The `@Forward` pattern ensures parameters are passed internally without polluting function signatures.

*   **File:** `MyExporter/Public/Export-SystemInfo.ps1` (Enhanced)
*   **Granulated Code Example:**

```powershell
# No new functions are exported. We extend the existing public API.
function Export-SystemInfo {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        # --- Existing Parameters ---
        [Parameter(Mandatory, ValueFromPipeline)] [string[]]$ComputerName,
        [Parameter(Mandatory)] [string]$OutputPath,
        [switch]$UseSSH,
        [switch]$AsJson,

        # --- New, Non-Breaking Parameters for Terminal Integration ---
        [Parameter()]
        [switch]$IncludeTerminalContext,
        [Parameter()]
        [int]$TerminalContextLines = 50
    )

    begin {
        # ... existing begin block ...
        # Add terminal context to the @Forward hashtable if requested.
        if ($IncludeTerminalContext) {
            # This call is to a private helper, respecting encapsulation.
            $currentSession = Get-CurrentSession # (from Phase 1.2 of the refined plan)
            if ($currentSession) {
                $Forward.TerminalContext = @{
                    SessionId = $currentSession.SessionId
                    MaxLines = $TerminalContextLines
                }
            }
        }
    }

    process {
        # ... the process block delegates to private functions using @Forward,
        # which now may contain the TerminalContext key. Private functions
        # decide how to act on this, keeping the logic out of the public API.
    }
}
```

#### **Phase 2: The State and Data Layer - Schema Migration & Session Registry**

**Constraint:** Manage the state of the persistent `tmux` session without using mutable global state.

**Refined Implementation:**
A versioned **StateFile Schema** is introduced, and `tmux` sessions are managed as a collection of immutable `TmuxSessionReference` objects within the module's existing `state.json`. This provides persistence, lifecycle management (stale session cleanup), and rollback capabilities.

*   **Files:** `Private/Update-StateFileSchema.ps1` (New), `Classes/TmuxSessionReference.ps1` (New), `Private/Get-CurrentSession.ps1` (New)
*   **Granulated Code Example (TmuxSessionReference Class):**

```powershell
# Classes/TmuxSessionReference.ps1
class TmuxSessionReference {
    [string]$SessionId
    [string]$WSLDistro
    [datetime]$CreatedAt
    [datetime]$LastAccessedAt
    [string]$CorrelationId
    [bool]$IsActive

    # Constructor creates an immutable reference, per GuardRails.
    TmuxSessionReference([string]$distro) {
        $this.SessionId = "myexporter-$(New-Guid)"
        # ... other properties initialized ...
    }

    [bool] IsStale() {
        return (Get-Date) - $this.LastAccessedAt -gt [timespan]::FromHours(24)
    }
}
```

#### **Phase 3: The Cross-Boundary Communication Layer - Triple-Hop Marshalling**

**Constraint:** *"every argument bound for the Linux shell is packed into a hashtable that is splatted...No mutable reference objects cross a run-space boundary...any data crossing a process boundary be stringified and re-hydrated."*

**Refined Implementation:**
A comprehensive escaping pipeline in `New-TmuxArgumentList.ps1` handles the `PowerShell -> Bash -> Tmux` triple-hop. It applies multiple layers of escaping and wraps the final payload using the existing `New-StrictArgumentList` pattern. A full Pester test suite validates preservation of problematic characters.

*   **File:** `Private/New-TmuxArgumentList.ps1` (New)
*   **Granulated Code Example (Escaping Pipeline):**

```powershell
function New-TmuxArgumentList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Command,
        [Parameter(Mandatory)] [string]$CorrelationId,
        [hashtable]$Context = @{}
    )

    # Layer 1: PowerShell escaping (for internal use)
    $psEscaped = [System.Management.Automation.Language.CodeGeneration]::EscapeBlockComment($Command)
    # Layer 2: Bash escaping (for the WSL shell)
    $bashEscaped = $psEscaped -replace '(["$`\\])', '\$1'
    # Layer 3: Tmux payload with correlation markers
    $tmuxPayload = @"
echo '### CORRELATION: $CorrelationId ###'; $bashEscaped; echo '### EXIT: `$? ###'
"@
    # Layer 4: Strict Argument wrapper for final transport
    return New-StrictArgumentList -Arguments @($tmuxPayload)
}
```

#### **Phase 4: The Security & Sandboxing Layer**

**Constraint:** Implicitly required by a robust system; this new layer formalizes security.

**Refined Implementation:**
A policy-driven command sanitizer is introduced, loading rules from an external `terminal-deny.yaml` file. This prevents injection of destructive commands. Furthermore, all `tmux` sessions are run under a dedicated, restricted, non-root WSL user created on-demand.

*   **Files:** `Policies/terminal-deny.yaml` (New), `Private/Test-CommandSafety.ps1` (New), `Private/Initialize-WSLUser.sh` (New)
*   **Granulated Code Example (Policy-Driven Sanitizer):**

```powershell
# Private/Test-CommandSafety.ps1
function Test-CommandSafety {
    param([string]$Command, [switch]$AllowElevated)

    # Load deny list policy from external YAML file.
    $policy = ConvertFrom-Yaml (Get-Content "Policies/terminal-deny.yaml" -Raw)

    foreach ($rule in $policy.rules) {
        if ($Command -match $rule.pattern) {
            # Check for severity and required flags (e.g., -AllowElevated)
            if ($rule.requiresFlag -and (Get-Variable -Name $rule.requiresFlag -ValueOnly)) { continue }
            if ($rule.severity -eq 'critical') {
                throw [System.Security.SecurityException]::new("Command blocked: $($rule.reason)")
            }
        }
    }
    return $true
}
```

#### **Phase 5: The Implementation & Platform Layer - Capability-Based Routing**

**Constraint:** *"Every new helper...is added under `/Private`...preserving the platform-strategy pattern."*

**Refined Implementation:**
The platform dispatcher is enhanced to use **Capability-Based Routing**. Instead of just checking the OS, it actively probes for the availability of `wsl.exe` and `tmux` to determine if the terminal integration feature can be activated.

*   **File:** `Private/Get-TerminalContextPlatformSpecific.ps1` (Enhanced)
*   **Granulated Code Example (Dispatcher Logic):**

```powershell
function Get-TerminalContextPlatformSpecific {
    # Probes for required executables and features.
    $capabilities = @{
        WSL = Test-Command -Name 'wsl.exe' -ErrorAction SilentlyContinue
        Tmux = Test-Command -Name 'tmux' -InWSL # A conceptual helper
    }

    # Routes based on available capabilities, not just OS name.
    if ($capabilities.WSL -and $capabilities.Tmux) {
        return Get-TerminalContext.WSL @Forward # Calls the WSL-specific implementation
    }
    # ... other conditions for native Linux, etc.
}
```

#### **Phase 6: The Adaptive Collaboration Layer - Selective Capture & Telemetry**

**Constraint:** *"Telemetry remains optional through the existing FastPath because the wrapper checks `$env:MYEXPORTER_FAST_PATH`."*

**Refined Implementation:**
The `Get-TerminalOutput.WSL.ps1` function has two distinct code paths. If `$env:MYEXPORTER_FAST_PATH` is true, it performs a raw, low-overhead `tmux capture-pane`. Otherwise, it uses the full `Invoke-WithTelemetry` wrapper and parses correlation markers from the output. A new `TerminalTelemetryBatcher` class prevents "telemetry pollution" by batching metrics before writing them.

*   **File:** `Private/Get-TerminalOutput.WSL.ps1` (New), `Private/TerminalTelemetryBatcher.ps1` (New)
*   **Granulated Code Example (FastPath vs. Full Telemetry):**
```powershell
function Get-TerminalOutput {
    # ... params ...
    if ($env:MYEXPORTER_FAST_PATH) {
        # Raw, minimal overhead capture. Returns a simple object.
        $output = & wsl.exe -e tmux capture-pane -p -S -$Last
        return [PSCustomObject]@{ Content = $output; TelemetryWrapped = $false }
    }

    # Full telemetry capture.
    return Invoke-WithTelemetry -OperationName "TerminalCapture" -ScriptBlock {
        $output = & wsl.exe -e tmux capture-pane -p -S -$Last
        # ... parse output, handle truncation, etc. ...
        return [PSCustomObject]@{ Content = $parsed.Content; TelemetryWrapped = $true }
    }
}
```

### 3. End-to-End Workflow Execution Example (Refined)

This example incorporates the new, refined components.

**Scenario:** An AI agent, guided by a prompt, runs a `git status` command inside the persistent terminal.

1.  **User/AI Input (WSL Terminal):**
    *   `Export-SystemInfo -IncludeTerminalContext -CommandToRun "git status"`
    *   (Assuming `-CommandToRun` is a new conceptual parameter for this workflow)

2.  **Public API (`Export-SystemInfo.ps1`):**
    *   The `begin` block calls `Get-CurrentSession`, retrieving the active `tmux` session ID from the `state.json` file.
    *   It adds this session ID and the command to the `@Forward` hashtable.

3.  **Private Dispatcher (`Get-TerminalContextPlatformSpecific.ps1`):**
    *   Probes for `wsl.exe` and `tmux`. Both are found.
    *   It routes the call to `Get-TerminalContext.WSL`, passing the `@Forward` bundle.

4.  **WSL Implementation (`Get-TerminalContext.WSL.ps1`):**
    *   It calls `Test-CommandSafety` to validate `"git status"`. The check passes.
    *   It calls `New-TmuxArgumentList`, which applies the 4-layer escaping to the command.
    *   It calls `Invoke-WslTmuxCommand` with the escaped payload.

5.  **Cross-Boundary Bridge & WSL Execution:**
    *   `Invoke-WslTmuxCommand` executes `wsl.exe`, passing the escaped payload.
    *   `claude-tmux-exporter.sh` decodes the payload and runs `tmux send-keys...`.
    *   The command executes within the sandboxed `myexporter-agent` user's `tmux` session.
    *   The script captures the output, packages it into a JSON response, and sends it back to PowerShell.

6.  **Telemetry and Final Output:**
    *   `Get-TerminalOutput.WSL.ps1` receives the JSON, parses it, and passes it to the `TerminalTelemetryBatcher`.
    *   The final, structured terminal output is attached as a `TerminalContext` property to the `SystemInfo` object.
    *   The final CSV/JSON report includes both the machine's system info and the `git status` output, linked by the same correlation ID.

### 4. Granulated Implementation Task List (Refined)

| Phase | Task ID | Description | `GuardRails` Principle(s) | Status |
| :--- | :--- | :--- | :--- | :--- |
| **1: State** | 1.1 | Implement `Update-StateFileSchema` for v2.0 schema. | State Management, Rollback | To Do |
| | 1.2 | Create immutable `TmuxSessionReference` class. | Immutability, Data Contracts | To Do |
| | 1.3 | Implement session lifecycle management (`Get-CurrentSession`, `Test-TmuxSession`). | State Management | To Do |
| **2: Marshalling**| 2.1 | Implement `New-TmuxArgumentList` with 4-layer escaping. | Stringify/Re-hydrate, `@Forward`| To Do |
| | 2.2 | Create Pester test suite for character preservation in `New-TmuxArgumentList`. | Testing & Validation | To Do |
| **3: Capture** | 3.1 | Implement `Get-TerminalOutput.WSL` with dual FastPath/Telemetry logic. | FastPath, Selective Telemetry | To Do |
| | 3.2 | Implement `TerminalTelemetryBatcher` to prevent telemetry pollution. | Telemetry Batching | To Do |
| **4: Security** | 4.1 | Create `Policies/terminal-deny.yaml` and `Test-CommandSafety` function. | Policy-Driven Security | To Do |
| | 4.2 | Implement `Initialize-WSLUser.sh` for sandboxed user creation. | User Isolation | To Do |
| **5: Dispatch** | 5.1 | Enhance `Get-TerminalContextPlatformSpecific` with capability-based routing. | Platform Dispatch | To Do |
| **6: Integration**| 6.1 | Add `-IncludeTerminalContext` and other parameters to `Export-SystemInfo`. | Public API Surface | To Do |
| | 6.2 | Implement `Add-TerminalContextToSystemInfo` private helper. | Encapsulation | To Do |
| **7: CI/CD** | 7.1 | Update GitHub Actions `ci.yml` with the new, complex test matrix. | CI/CD Validation | To Do |
| | 7.2 | Create `Test-TerminalCompliance.ps1` integration test suite. | Compliance Testing | To Do |
| **8: Bridge** | 8.1 | Enhance `claude-wsl-launcher.sh` to use `WSLENV` for context propagation. | Environment Hand-off | To Do |