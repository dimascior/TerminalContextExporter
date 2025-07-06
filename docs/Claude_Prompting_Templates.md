prompt templates designed specifically for the **MyExporter** project. These templates codify the "Why, How, and What" of our **Dynamic & Adaptive Architecture**, ensuring any AI interaction is productive, context-aware, and compliant with the `GuardRails.md` framework.

---

### **Claude Prompt Templates for the MyExporter Project**

These templates are designed to manage complexity, prevent "tail-chasing," and leverage the project's built-in architectural patterns and tools.

### **Template 1: The Bootstrapping Meta-Prompt (For a New Session)**

**Purpose:** To force a new AI instance to become self-aware of its own execution context using the project's tools. This should be the *first* prompt in any new development session.

```text
CONTEXT: You are an AI assistant for the 'MyExporter' PowerShell module. Your primary challenge is operating across multiple execution boundaries (WSL/Linux -> Windows, bash -> PowerShell). Your work must adhere to the 'Dynamic & Adaptive Architecture' defined in the project's `GuardRails.md`.

TASK: Before beginning any development task, you must first perform a self-analysis to establish your own execution context and report on the cross-boundary risks you face. You are required to use the project's own discovery tools to do this.

METHODOLOGY:
1.  **EXECUTE DISCOVERY:** Run the `./MyExporter/claude-direct-test.sh` script, which uses the `Get-ExecutionContext` function. This is your non-negotiable source of truth.
2.  **ANALYZE FINDINGS:** Capture the output from the discovery script.
3.  **REPORT RISKS & MITIGATIONS:** Based on your findings, produce a short report in the following format, identifying the risks you face and the corresponding architectural pattern or tool that mitigates it:

    *   **Execution Environment:** [e.g., WSL2 on Windows, PowerShell Core 7.4 via Desktop 5.1 bridge]
    *   **Identified Risks & Corresponding Mitigations:**
        *   **Risk: Path Ambiguity** (Receiving Linux paths like '/mnt/c/').
            *   **Mitigation:** The `Assert-ContextPath.ps1` helper function.
        *   **Risk: Interpreter Mismatch** (Executing `powershell.exe` from `bash`).
            *   **Mitigation:** The `claude-powershell-bridge.bat` Environmental Bridge.
        *   **Risk: Job Scope Isolation** (Functions unavailable in background jobs).
            *   **Mitigation:** The 'Job-Safe Function Loading' pattern from `GuardRails.md Section 11.3`.
        *   **Risk: Dependency Blindness** (Required commands like 'git' or 'docker' may be missing).
            *   **Mitigation:** The dynamic command probing feature within `Get-ExecutionContext`.
```

---

### **Template 2: Simple Feature or Bug Fix (Level 1)**

**Purpose:** For localized, low-complexity tasks where the full weight of the architecture is unnecessary. This template explicitly encourages using the `FastPath` escape hatch.

```text
CONTEXT: You are working on the 'MyExporter' module, following the 'GuardRails.md' Level 1 (Essential) context.

TASK: [Clearly and concisely describe the small feature or bug fix. e.g., "Add a 'SystemUptime' property to the SystemInfo class and populate it in the Windows-specific collector."]

ESCAPE_HATCH: Prioritize speed and simplicity. You are encouraged to implement this change within the **FastPath** execution loop first. Do not add job-related logic or complex telemetry wrappers unless absolutely necessary.

VERIFICATION:
1.  Modify the necessary files (e.g., `Classes/SystemInfo.ps1`, `Private/Get-SystemInfo.Windows.ps1`).
2.  Run the `./MyExporter/claude-powershell-bridge.bat` script to test.
3.  Confirm that the new property appears in the `final-test-fastpath.csv` and `final-test-fastpath.json` output files.
```

---

### **Template 3: Complex Architectural Change (Level 2)**

**Purpose:** For tasks that involve multiple components, modify core patterns, or have cross-platform implications. This template enforces the full `Isolate-Trace-Verify` discipline.

```text
CONTEXT: You are performing a significant architectural change to the 'MyExporter' module, following the 'GuardRails.md' Level 2 (Architectural) context.

TASK: [Describe the complex objective. e.g., "Refactor the job creation logic in 'Export-SystemInfo.ps1' to use a reusable helper function and add a timeout parameter."]

REFERENCE: This task directly relates to `GuardRails.md Section 11.3 (Job-Safe Function Loading)`. All changes must be compliant with this pattern.

METHODOLOGY (ISOLATE-TRACE-VERIFY):
1.  **ISOLATE:** First, create a new test script (e.g., `Test-NewJobLogic.ps1`) to develop and test the new helper function in complete isolation from the `Export-SystemInfo` cmdlet.
2.  **TRACE:** In your isolated test, trace the parameter flow and ensure the function definitions are correctly passed into the job's script block.
3.  **VERIFY:** Once the isolated test passes, integrate the new helper function back into `Export-SystemInfo.ps1`.

BAILOUT_IF: The complexity of the new helper function exceeds the original code block by more than 50%. If this happens, stop and suggest a simpler approach.

VERIFICATION:
1.  Run the full `./MyExporter/claude-wsl-launcher.sh` script.
2.  Confirm that BOTH FastPath and Normal mode tests pass and produce valid output files. The timeout feature should be functional in Normal mode.
```

---

### **Template 4: Cross-Platform Implementation or Debugging (Level 3)**

**Purpose:** To address issues or features that behave differently across Windows and Linux/WSL environments.

```text
CONTEXT: You are addressing a cross-platform issue in the 'MyExporter' module, requiring 'GuardRails.md' Level 3 (Environmental) context awareness.

TASK: [Describe the cross-platform issue. e.g., "The 'Get-SystemInfo.Linux.ps1' script fails to parse the OS version from '/etc/os-release' on Arch Linux derivatives. Implement a fallback to 'lsb_release -d'."]

KEY_COMPONENT: The primary file to modify is `Private/Get-SystemInfo.Linux.ps1`. The dispatcher logic in `Get-SystemInfoPlatformSpecific.ps1` should not need to change.

APPROACH:
1.  Inside `Get-SystemInfo.Linux.ps1`, wrap the existing `/etc/os-release` logic in a `try/catch` block.
2.  In the `catch` block, implement the fallback logic using the `lsb_release` command.
3.  Ensure the output hashtable always has the same structure, regardless of which method succeeds.

VERIFICATION:
1.  Since we cannot change your underlying OS, you will simulate the fix. Provide the updated `Get-SystemInfo.Linux.ps1` file content.
2.  Then, provide a sample `bash` command that would test this new logic, like: `pwsh -Command ". ./path/to/updated/script.ps1; Get-SystemInfoLinux -ComputerName localhost"`
```