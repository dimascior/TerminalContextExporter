Of course. This is the definitive, fully elaborated **Unified Architecture Module**. It retains all previous information and integrates the new, highly detailed frameworks for adaptive AI collaboration and environment discovery. This document now represents a complete, end-to-end design specification, bridging high-level architecture with the granular, real-world complexities of cross-environment execution and pragmatic, AI-driven development.

---

### **Unified Architecture Module: MyExporter — Dynamic & Adaptive Specification**

**MyExporter** is conceived as a **living architecture**: a self-describing codebase whose manifest, directory topology, and idiomatic patterns form a continuously accurate reference manual. This specification now includes a dynamic framework to ensure that architectural compliance accelerates, rather than impedes, development by both human and AI agents.

**Core Goal:** To create a robust, maintainable, and cross-compatible PowerShell module where the architecture itself serves as a "tool selection and code optimization" guide. The codebase is designed to have **self-documenting intent**, where structure reveals purpose, while providing **pragmatic escape hatches and adaptive strategies** to avoid over-engineering.

---

### **Part 1: The Constitutional Layer — The Immutable Contract**

The module manifest (`MyExporter.psd1`) is the single source of truth for semantic versioning, platform gates, dependency injection, and compliance metadata. It is the **non-negotiable contract** for the entire project.

*(This section remains unchanged, as the constitutional layer is intended to be rigid and non-negotiable.)*

| Manifest Element | Expanded AI Reasoning Rule | Engineering Consequence |
| :--- | :--- | :--- |
| **`GUID` & `ModuleVersion`** | “This is the module's unique identity and official version. I will use the `GUID` for unambiguous identification and the `ModuleVersion` for all semantic versioning logic, dependency resolution, and release management tasks.” | Enables CI/CD & Dependency Management: Provides a stable, machine-readable identity for packaging, publishing, and resolving version-specific dependencies. |
| **`RootModule = 'MyExporter.psm1'`** | “All public functions must be reachable by importing this root file only; I will never instruct a user to dot-source internal paths.” | Disallows brittle `Import-Module "$PSScriptRoot\Public\*.ps1"` calls from consumer scripts, enabling atomic versioning and PowerShellGet publishing. |
| **`PowerShellVersion = '7.2'`** | “This is a hard floor for compatibility. I will not suggest syntax or cmdlets deprecated before this version. My code generation will target features of PowerShell 7.2+, selecting modern, performant tools like `ForEach-Object -Parallel`.” | Maximizes Performance & Readability: Prevents the use of outdated code and guides the AI to generate idiomatic, modern PowerShell. |
| **`CompatiblePSEditions = 'Core', 'Desktop'`** | “Any code I generate or modify MUST be compatible with both Windows PowerShell and modern PowerShell. I will avoid platform-exclusive APIs unless they are wrapped in conditional logic explicitly demonstrated in the module's private functions.” | Guarantees Maximum Portability: Prevents platform-specific runtime failures by forcing the selection of cross-platform cmdlets (`Get-CimInstance`) by default. |
| **`FunctionsToExport`** | “This is the complete and exclusive public API. I will not generate code that calls any other functions from this module directly. They are internal implementation details. My primary interface for user tasks is `'Export-SystemInfo'`.” | Enforces Strong Encapsulation: Creates a stable public interface, allowing internal refactoring without breaking consumer scripts. Makes the AI a **project-aware assistant**. |
| **`RequiredModules`** | “These external modules are guaranteed to be present. I can safely assume their cmdlets are available without needing to add `Install-Module` commands for them in my generated scripts.” | Standardizes the Execution Environment: Reduces boilerplate setup code and prevents "command not found" errors by declaratively defining the module's ecosystem. |
| **`FileList`** | “The manifest enumerates every shipping *.ps1*, *.psm1*, and *.psd1* file. I will treat any unlisted file as *draft* until the list is updated.” | Guarantees repeatable builds and tamper-evident releases; essential for signed modules and reproducible Docker images. |
| **`PrivateData.PSData.PrereleaseTag`** | “If a `PrereleaseTag` exists (e.g., *alpha.3*), I will inject preview caveats into my auto-generated README snippets and set an `-AllowPrerelease` flag in `Install-Module` samples.” | Communicates stability expectations downstream, preventing CI pipelines from pinning to unstable versions by accident. |
| **`PowerShellHostName`, `PowerShellHostVersion`** | “The module may require a graphical host (Windows Terminal) or specific host features; I will assert these requirements before running any interactive code.” | Stops headless Docker jobs or tmux sessions from invoking commands that assume VT-enhanced progress bars. |
| **`RequiredAssemblies`** | “If native DLLs are listed, I will emit guard clauses that throw a descriptive error on non-Windows systems or prompt the user to install compatible libraries.” | Prevents cryptic `Add-Type` failures when a WPF-only assembly is missing inside a Linux container. |
| **`PrerequisiteModules`** | “Modules placed here are soft dependencies. I will test for them at runtime and activate reduced-capability paths if they’re absent.” | Enables graceful degradation—critical when running under constrained Alpine images where optional features (LDAP querying, PDF generation) are removed to shrink attack surface. |

---

### **Part 2: The Architectural Layer — Scaffolding, Patterns, and Dialect**

*(This section remains unchanged, as it defines the stable structure of the project.)*

| Structural Unit | Granular Rule for Tool Selection | Optimisation & Maintainability Impact |
| :--- | :--- | :--- |
| **/Public** | Public scripts must confine themselves to orchestration. *No* `try/catch` except for parameter validation; error bubbling is handled centrally by a private telemetry wrapper. | Keeps entry points minimal, facilitating automated doc generation (`platyPS`) and reducing merge conflicts. |
| **/Private** | Implementation scripts must be named verb-noun-platform.ps1 (e.g., `Get-SystemInfo.Linux.ps1`). Dispatchers live one level up (`Get-SystemInfo.ps1`) and load the correct variant via `$IsWindows`, `$IsMacOS`, `$IsLinux`. | Enables drop-in platform modules without touching existing code; Docker builds targeting Alpine simply skip Windows variants. |
| **/Classes** | Every class must have a companion Pester test file under `/Tests/Classes` verifying `[ValidateScript]` blocks, custom methods, and JSON round-trip serialization. | Assures schema stability; TypeScript or Python consumers can rely on predictable field sets when deserialising CLI output. |
| **/Tasks** | YAML task definitions consumed by `Invoke-Build`. AI suggestions must reference these tasks for complex chains (lint → test → build-docker). | Provides deterministic local and CI workflows; reduces cognitive load switching between PowerShell, npm, and make. |
| **/Templates** | Houses stub files (new platform provider, new cmdlet template). When AI generates code, it clones these templates rather than emitting ad-hoc scaffolding. | Standardises style, headers, and comment-based help; speeds onboarding. |
| **/Docs** | Auto-generated markdown produced by `New-MarkdownHelp`. AI must not hand-craft help text; it updates parameters and examples in source, then triggers doc regeneration. | Eliminates stale documentation; ensures help reflects code at merge time. |
| **Pipeline Definition (.github/workflows/ci.yml)** | Contains matrix builds for Windows Latest, Ubuntu Latest, and macOS. AI adjustments to module dependencies must update this matrix accordingly. | Guarantees cross-OS green pipelines; catches platform regressions before release. |

---

### **Part 3: The Implementation Layer — Patterns, Contracts, and Mentorship**

*(This section remains unchanged, as it defines the ideal implementation patterns.)*

#### **3.1 Data Contracts and Strong Typing**
*   **`class SystemInfo`** now implements `IFormattable` and overrides `.ToString()` for human-friendly log output. AI referencing `$obj` in logging must call `$obj.ToString('table')` to honour custom formatting.
*   **`[OutputType([SystemInfo])]`** in every public cmdlet powers VS Code IntelliSense through the PowerShell extension, improving developer ergonomics and reducing tab-completion ambiguity. This is the **Data Contract Enforcer**.

#### **3.2 Telemetry and Exception Model**
*   All private executor functions call **`Invoke-WithTelemetry`**, a wrapper adding:
    *   Correlation IDs (`[guid]::NewGuid()`) for each operation.
    *   `Stopwatch` timing for performance monitoring.
    *   Structured error objects (`[pscustomobject]@{Stage='Collect';Error=$_}`) that bubble to outer scopes.
*   The top-level cmdlet converts native exceptions to a unified **`[MyExporter.ErrorRecord]`** class that surfaces fields **Code**, **Message**, and **SuggestedFix**—mirroring JSON error contracts exposed to Node.js and Python wrappers.

#### **3.3 Idempotence and State Management**
*   Persistent state lives under `$env:APPDATA\MyExporter\state.json` on Windows or `$XDG_STATE_HOME` on Linux/macOS.
*   A **`StateFile`** class abstracts read/write operations with file locks (`[System.IO.FileShare]::None`), guaranteeing concurrency safety when multiple instances run in parallel (e.g., in tmux splits).

#### **3.4 Concurrency Strategy**
*   `ForEach-Object -Parallel` is gated behind an `$env:PS7_PARALLEL_LIMIT` environment variable; AI must respect this throttling so CI machines with few cores don’t overload.
*   Linux/macOS variants fall back to `Start-Job` if PowerShell 7 parallelism is unavailable, providing graceful degradation.

#### **3.5 Logging and Verbosity**
*   A central **`Write-Log`** function writes to the console with `Write-Host` *only* when `$PSStyle.OutputRendering -eq 'Ansi'`; otherwise, it logs to a rotating file via `System.Diagnostics.TraceSource` for headless environments.
*   Log levels map directly to PowerShell streams: Verbose → 4, Debug → 5, Information → 6. AI must route noisy diagnostics to `Write-Debug`, not `Write-Verbose`, to respect user-controlled verbosity toggles.

---

### **Part 4: The Adaptive Collaboration Framework**

This section directly addresses the criticisms of over-specification and cognitive overhead. It provides a pragmatic, tiered approach to AI interaction, ensuring that architectural compliance is a tool, not a burden.

#### **4.1 Progressive Context Anchoring with Isolate-Trace-Verify Methodology**
This enhanced framework provides a systematic discipline for navigating complex codebases, addressing the limitations of the original three-level context system.

*   **Level 1: Essential Context + Tactical Isolation**
    *   **Purpose:** For simple, localized tasks where dependencies are minimal.
    *   **CONTEXT:** WSL2 PowerShell 7.4+ environment. Working directory contains MyExporter module.
    *   **CONSTRAINTS:** Use cross-platform cmdlets. Avoid Windows-specific APIs unless wrapped.
    *   **ESCAPE:** Use `-FastPath` mode for simple tasks.
    *   **DISCIPLINE (Isolate-Trace-Verify):**
        *   **Isolate:** Start with minimal file patterns (`Classes/SystemInfo.ps1`). Expand scope only if necessary.
        *   **Trace:** Verify that `Import-Module` succeeds and the target class/function is available.
        *   **Verify:** Prove the isolated component works (e.g., class instantiation) before integrating it.
    *   **Application:** This was successfully used to fix the `SystemInfo` class for PowerShell 5.1 strict mode, requiring only one file change and a simple instantiation test.

*   **Level 2: Architectural Context + Import Chain Tracing**
    *   **Purpose:** For tasks involving multiple module components and their interactions.
    *   **ARCHITECTURE:** Follow manifest-driven design. Public cmdlets orchestrate, private functions implement.
    *   **TELEMETRY & SPLATTING:** Apply these patterns only where justified by debugging needs or parameter evolution.
    *   **DISCIPLINE (Isolate-Trace-Verify):**
        *   **Isolate:** Use precise globs to capture the set of interacting components (`Public/*.ps1`, `Private/Get-*.ps1`).
        *   **Trace:** Follow the exact import order from the `.psm1` root module to understand the dependency chain.
        *   **Verify:** Use "registries as truth sources." Compare the manifest's `FunctionsToExport` with the `Get-Module` cmdlet's `ExportedFunctions` to ensure consistency.
    *   **Application:** This was used to design the job integration architecture, ensuring the `Start-Job` script block correctly loaded its dependencies in the right order.

*   **Level 3: Environment-Specific Context + End-to-End Pipeline Verification**
    *   **Purpose:** For tasks involving cross-platform logic, external processes, or environmental dependencies.
    *   **WSL_PATHS, PARALLEL_LIMIT, DOCKER_SOCKET:** Apply these environment-specific rules.
    *   **DISCIPLINE (Isolate-Trace-Verify):**
        *   **Isolate:** Target environment-specific patterns (`*WSL*`, `*Linux*`, `*Windows*`).
        *   **Trace:** Map the execution path through environment abstractions (`Get-ExecutionContext` → platform dispatch → specific implementation).
        *   **Verify:** Execute the smallest possible end-to-end pipeline (`Export-SystemInfo -ComputerName localhost`) in each target environment to confirm the mental model. Use automated dependency analysis (`Get-Command`) to validate runtime availability.
    *   **Application:** This was used to validate the cross-platform path resolution, confirming that `Join-Path` and `wslpath` produced correct paths in WSL, Windows, and GitBash.

#### **4.2 Anti-Tail-Chasing Prompt Patterns**
To prevent the AI from getting stuck in compliance loops, prompts will be structured to prioritize the objective.

*   **Task-First Prompt Structure:**
    *   **TASK:** [Clear, specific objective]
    *   **CONTEXT:** [Minimal necessary context from §4.1]
    *   **CONSTRAINTS:** [Hard limits only, e.g., "must not break existing tests"]
    *   **ESCAPE_HATCH:** [When to bypass architecture, e.g., "implement for one platform first"]

    **Example:**
    ```
    TASK: Add CPU temperature monitoring to the SystemInfo class.
    CONTEXT: Level 1 (Essential).
    CONSTRAINTS: Cross-platform compatibility is required.
    ESCAPE_HATCH: If Linux/macOS temp monitoring is complex, implement the Windows-only version first and leave a 'TODO:' comment in the platform dispatcher.
    ```

*   **Incremental Complexity Prompts:** For large features, break down the request.
    1.  **PHASE 1:** "Get the basic functionality working for the current platform. Ignore architectural patterns like telemetry and advanced error handling for now."
    2.  **PHASE 2:** "Now, take the working code from Phase 1 and add robust error handling and logging."
    3.  **PHASE 3:** "Finally, integrate the code from Phase 2 with the existing architecture (splatting, telemetry wrappers, etc.)."
    4.  **VALIDATE:** "Run the Pester tests for each phase before proceeding."

#### **4.3 Context-Aware Bailout Triggers**
The AI is instructed to stop and ask for clarification if a task becomes unexpectedly complex, preventing it from over-engineering a solution.
*   **BAILOUT_IF:**
    *   More than 3 files need modification for a seemingly simple change.
    *   A circular dependency is detected (e.g., between the JSON schema and the class).
    *   The environment detection logic becomes more complex than the core business logic.
    *   The `Invoke-WithTelemetry` wrapper code becomes larger than the actual work being done.

---

### **Part 5: State Tracking and Context Preservation**

To prevent information loss during complex, multi-step operations, the AI will use physical artifacts to track its state, moving context from fragile conversational memory to durable files.

#### **5.1 Artifact-Based Context (`operation-context.xml`)**
Instead of relying on chat history, the AI will create an operation manifest at the start of a complex task.
```powershell
# AI generates this file before starting work
$OpManifest = @{
    Goal = "Add CPU temperature monitoring"
    FilesInvolved = @("Classes/SystemInfo.ps1", "Private/Get-SystemInfo.Windows.ps1")
    ArchitectureRules = @("Schema-first", "Splat parameters", "Wrap in telemetry")
    CurrentStep = 1
    TotalSteps = 4
    Shortcuts = @{
        FastPath = $false
        SkipTelemetry = $false
        SkipTests = $false
    }
}
$OpManifest | Export-Clixml "operation-context.xml"
```
In subsequent prompts, the human or a wrapper script will include: "Reference `operation-context.xml` for the current state."

#### **5.2 Checkpoint Pattern for Long Operations**
For long-running tasks, the AI will use checkpoints to validate progress and enable resumption.
```powershell
# A helper function available in the development environment
function Checkpoint-Operation {
    param($Phase, $State, [hashtable]$Validation)
    Write-Host "=== CHECKPOINT: $Phase ===" -ForegroundColor Green
    if (-not $Validation.IsValid) {
        Write-Host "BAILOUT: $($Validation.Reason)" -ForegroundColor Red
        throw "Operation failed at checkpoint $Phase"
    }
}
```
**Usage in Prompts:** "After implementing the Windows version, call `Checkpoint-Operation` with the current state and the result of the Pester test run."

---

### **Part 6: Meta-Prompts and Self-Correction**

This section provides templates for common tasks and a final "self-check" to ensure the AI remains aligned with the project's pragmatic goals.

#### **6.1 Prompt Templates for Common Scenarios**
*   **Schema-Class Synchronization:**
    ```
    TASK: Sync schema and class for [ClassName].
    APPROACH: 1. Read current class definition. 2. Generate schema from class (inference allowed). 3. Validate schema completeness. 4. Update class if schema reveals gaps. 5. Regenerate TypeScript definitions.
    BAILOUT_IF: More than 2 sync cycles are needed.
    ```
*   **Cross-Platform Implementation:**
    ```
    TASK: Implement [Feature] across Windows/Linux/macOS.
    APPROACH: 1. Start with the current platform's implementation. 2. Identify platform-specific dependencies. 3. Create an abstraction layer only if necessary. 4. Implement other platforms or mark as TODO.
    BAILOUT_IF: The abstraction layer becomes larger than the implementations themselves.
    ```

#### **6.2 The Meta-Prompt for Self-Correction**
The AI is instructed to run this internal monologue before finalizing any significant contribution.
*   **SELF_CHECK:**
    1.  Am I solving the *actual problem* or just following architecture for its own sake?
    2.  Is the complexity of my solution justified by the requirements?
    3.  Can I explain this solution to a junior developer in 2 minutes?
    4.  Does this change make the system *more* or *less* maintainable?
    5.  If I were debugging this in 6 months, would I understand it?
*   **PROCEED_IF:** All answers are positive.
*   **SIMPLIFY_IF:** Any answer is negative.
*   **ESCALATE_IF:** Simplification breaks a core architectural requirement (ask for human guidance).

---

### **Part 7: Synergistic Human–AI Lifecycle — Expanded**

*(This section remains unchanged, as it describes the ideal collaborative workflow.)*

1.  **Guardrail Synthesis & Requirement Encoding:** Human architects encode new non-functional requirements (e.g., security policies, observability hooks) directly into the manifest (`PrivateData`) and CI task definitions (`/Tasks`). **Example:** To enforce a data residency policy, a `validRegions` array is added to `PrivateData`. The AI is now constitutionally obligated to generate logic that validates target computer locations against this array before execution, citing the manifest as the source of this constraint.
2.  **Linter-Enforced Pull Requests & Pre-Commit Hooks:** `PSScriptAnalyzer` rules are tuned to the architecture (e.g., "disallow `Write-Host`", "require `[OutputType]`"). These rules are integrated into a Git pre-commit hook. When the AI proposes code, it first validates its own output against this linter, presenting not just code but a "linter-compliant" solution. This drastically reduces the human review burden from "is this correct?" to "does this meet the strategic goal?".
3.  **Round-Trip Validation for Cross-Language Fidelity:** For every new data class (e.g., `[NetworkInfo]`), the AI's workflow is to:
    *   Add a corresponding JSON schema to `/Schemas/NetworkInfo.schema.json`.
    *   Add a test to `/Tests/test_schemas.py` using `pytest` and `jsonschema` that:
        1.  Runs `Export-SystemInfo ... -AsJson` to get sample output.
        2.  Validates the generated JSON against the schema.
    *   This closes the loop, guaranteeing that any changes to the PowerShell class that break the JSON contract will fail the CI pipeline, protecting downstream Python or Node.js consumers.
4.  **Evolutionary Metrics & Justified Refactoring:** The `Invoke-WithTelemetry` wrapper logs execution times and success/failure rates to a structured log file. A scheduled CI job parses these logs and updates a dashboard (e.g., a README badge or a simple metrics file). The AI can then be tasked with: "Analyze the last 100 runs and identify the most error-prone or slowest operation." It can use this data to justify a refactoring proposal, e.g., "The `Get-DiskInfo` function fails 15% of the time on Windows targets. I propose replacing the CIM query with a more resilient .NET API call, which my analysis suggests will improve reliability."

---

### **Part 8: Cross-Platform Parallels — Broader Ecosystem Mapping**

*(This section remains unchanged, as it maps the architecture's principles to other languages and platforms.)*

*   **Go / Rust:** `go.mod` or `Cargo.toml` mirror the manifest’s dependency lock. The strategy pattern (`Get-SystemInfoPlatformSpecific`) equates to Rust’s `#[cfg(target_os = "windows")]` or Go’s `*_linux.go` build constraints. When the AI is asked to "port the disk info collector to a Rust sidecar for performance," it will correctly identify the relevant private function in PowerShell and propose a Rust implementation with matching platform-specific compilation flags.
*   **Python:** `pyproject.toml` (the contract) + `typing` hints and `abc.ABC` (the enforcer) + `if sys.platform == 'win32'` blocks (the coach).
*   **Node.js/TypeScript:** `package.json` (the contract) + `.d.ts` interfaces (the enforcer) + environment-specific loaders (the coach).
*   **Terraform:** Module definitions with `required_providers` (contract) + provider-specific resources (coach) + `output` blocks (enforcer).
*   **Ansible:** Roles have `meta/main.yml` (contract), `tasks/`/`handlers/` (architecture), and `library/` (implementation). MyExporter borrows this tiered philosophy, aiding ops engineers familiar with playbooks.
*   **Kubernetes Operators:** Custom Resource Definitions (CRDs) define the contract, controllers embody architecture, and reconcilers implement logic. When containerising MyExporter, the manifest (`MyExporter.psd1`) acts like a CRD for the PowerShell runtime, ensuring declarative state.

---

### **Part 9: Extended Feature Roadmap / Backlog (Illustrative)**

*(This section remains unchanged, as it outlines future development goals.)*

1.  **Pluggable Output Formats:** Abstract an `IExporter` interface in a `/Classes/Interfaces.ps1` file. Create concrete classes like `CsvExporter`, `JsonExporter`, and `ParquetExporter`. The `Export-SystemInfo` cmdlet will use a factory pattern based on a `-Format` parameter to instantiate the correct exporter class.
2.  **Policy-Driven Compliance:** Define YAML rules in a `/Policies` directory (e.g., "no data older than 90 days"). The public cmdlet will have a `-Policy` parameter. A private `Test-PolicyCompliance` function will parse the YAML and evaluate it against the collected data *before* the `end` block, failing the pipeline if breached.
3.  **Self-Updating Mechanism:** Implement `Update-MyExporter` that uses `Find-Module` and `Install-Module` against the PowerShell Gallery. It will parse the manifest of the installed and latest versions to provide a changelog summary to the user before they confirm the update.
4.  **Native Python Wheel:** Leverage `pythonnet`. The build task in `/Tasks/Build.ps1` will include a step that generates a `setup.py` file, wraps the PowerShell module, and builds a Python wheel (`.whl`) for distribution via PyPI, enabling `pip install myexporter` and direct use in Jupyter.
5.  **Docker Healthcheck Hook:** Create a private script `Test-ModuleHealth.ps1` that performs a quick, non-network-intensive check (e.g., can it load classes?). The `Dockerfile` will use `HEALTHCHECK CMD ["pwsh", "-File", "/app/Private/Test-ModuleHealth.ps1"]` for liveness and readiness probes.

---

### **Part 10: Operational Flow — An End-to-End Walkthrough**

*(This section remains unchanged, as it provides a concrete example of the module in action.)*

**Scenario:** A developer is in **VS Code** on a Windows machine. The integrated terminal is a **WSL 2 (Ubuntu)** session running `pwsh` 7.4. The project directory `/mnt/c/dev/MyExporter` is open.

**The Command:**
```powershell
# In the WSL terminal:
cd /mnt/c/dev/MyExporter
Import-Module ./MyExporter.psd1 -Force
Export-SystemInfo -ComputerName 'localhost', 'WIN-DC01' -OutputPath '~/report.csv' -Verbose
```

**Flow of Operations:**

1.  **Invocation Environment (WSL Host - `pwsh` 7.4):**
    *   **Interpreter Profile:** The `pwsh` interpreter loads its profile (`$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1`). This can define aliases or environment variables that exist *before* our module is even aware.
    *   **Module Import:** `Import-Module` triggers the **Constitutional Layer**. The `pwsh` engine parses `MyExporter.psd1`, validating `PowerShellVersion` and `CompatiblePSEditions`. All checks pass.
    *   **Orchestration:** The engine runs the `RootModule` (`MyExporter.psm1`). `Set-StrictMode` is activated for the module's scope. Using `$PSScriptRoot`, it dot-sources all `.ps1` files from `/Classes`, `/Private`, and `/Public` into the **module's private scope**. `Export-ModuleMember` makes only `Export-SystemInfo` visible in the **user's session scope**.

2.  **Parameter Binding (User Scope → Module Scope):**
    *   The user's command is parsed. The PowerShell engine binds the arguments:
        *   `$ComputerName` (in `Export-SystemInfo`) becomes `[string[]]@('localhost', 'WIN-DC01')`.
        *   `$OutputPath` becomes the string `'~/report.csv'`.
        *   The `-Verbose` switch sets the automatic variable `$VerbosePreference` to `'Continue'`.
    *   The `begin` block of `Export-SystemInfo` executes. `Write-Verbose "Initialization..."` now prints to the console. It resolves `$OutputPath`: `'~/report.csv'` becomes `/home/user/report.csv` (the WSL user's home directory).

3.  **Execution & The First Scope Hop (WSL → Local Linux):**
    *   The `process` block starts `ForEach-Object -Parallel`.
    *   **Thread 1 (`localhost`):** The `Get-SystemInfoPlatformSpecific` dispatcher runs. It checks `$IsLinux` (which is `$true`) and calls the private function `Get-SystemInfo.Linux`. This function executes *natively within the WSL environment*, running commands like `hostname` and `uname`. It constructs a `[SystemInfo]` object. This object lives and dies within this thread, its result passed back to the `end` block's results collection. No remoting occurs.

4.  **The Second Scope Hop & Interpreter Change (WSL `pwsh` → Windows `powershell.exe`):**
    *   **Thread 2 (`WIN-DC01`):** `Get-SystemInfoPlatformSpecific` runs again. It determines the target is Windows and prepares for remoting.
    *   **Argument Marshalling:** It constructs an `Invoke-Command` call. The script block `{...}` is prepared. Any local variables needed inside that block must be passed with the `$using:` scope modifier (e.g., `$using:someLocalVar`). This is the explicit bridge for passing arguments across the remoting boundary.
    *   **Remoting & Interpreter Switch:** `Invoke-Command` connects to `WIN-DC01` via **WinRM**. On the remote machine, a `powershell.exe` (Windows PowerShell 5.1) process might be launched. **This is a different interpreter with a different CLR and profile.** The serialized script block is received, JIT-compiled by the *target's* engine, and executed.
    *   **Remote Execution:** Inside this temporary session on `WIN-DC01`, `Get-SystemInfo.Windows` runs. It calls `Get-CimInstance Win32_OperatingSystem`. It has no access to the WSL caller's variables (`$OutputPath` is unknown here). It creates a `[SystemInfo]` object.

5.  **The Return Journey & Deserialization:**
    *   The `[SystemInfo]` object from `WIN-DC01` is serialized into CLIXML (a text-based XML format).
    *   This CLIXML text travels back over WinRM to the calling WSL `pwsh` process.
    *   The WSL `pwsh` engine deserializes the XML. Because the `[SystemInfo]` class definition exists in its memory (from the initial module import), it "rehydrates" the object into a `[PSCustomObject]` with the original type name `SystemInfo` attached. It now behaves like the local object, though its methods are lost (a core tenet of remoting).

6.  **Aggregation & Final Output (Back in WSL):**
    *   The `end` block of `Export-SystemInfo` runs after all parallel threads complete.
    *   It now has a collection of two objects: one created natively on Linux, one created remotely on Windows and deserialized.
    *   It pipes this collection to `Export-Csv -Path /home/user/report.csv`. The final file is written inside the WSL filesystem, fully accessible to the developer in their VS Code terminal.

---

### **Part 11: Detailed Engineering — Variable and State Flow Across Boundaries**

*(This section remains unchanged, as it defines the technical rules for data transfer.)*

#### **11.1 In-Module Argument Flow (File-to-File within PowerShell)**
*   **The Rule:** Public cmdlets **must** pass parameters to private functions using hashtable splatting (`@Forward`).
*   **Claude's Workflow:** To add a new `-Timeout` parameter, Claude must:
    1.  Add `[int]$Timeout` to `Public/Export-SystemInfo.ps1`.
    2.  Add a new key-value pair to the `$Forward` hashtable: `$Forward.Timeout = $Timeout`.
    3.  Add the `[int]$Timeout` parameter to the `param()` block of the private dispatcher and all platform-specific implementations.
*   **Why (Dependencies):** Mandatory splatting decouples the public API from the private implementation. It prevents breaking changes where adding an optional parameter to the public function would cause a positional binding error in a private helper. The `$Forward` hashtable becomes a stable, versioned contract between internal components.

#### **11.2 Run-space Boundaries (Parallel Threads & Jobs)**
*   **The Rule:** Do not pass mutable reference types (like `[PSCredential]`) into concurrent operations using `$using:`.
*   **Claude's Workflow:** If asked to pass a `[PSCredential]` object, Claude will refuse, citing the `PSCustom.UseOfMutableUsing` linter rule. It will instead suggest a safe alternative: passing the username and a secure string password as separate, immutable `$using:` variables and re-constructing the `[PSCredential]` object *inside* the `ForEach-Object -Parallel` script block.
*   **Why (Environments):** This prevents Heisenbugs arising from race conditions and shared-state corruption. By forcing the use of immutable primitives, each parallel thread operates on its own deterministic copy of the data, eliminating side effects and making the parallel logic pure and reliable.

#### **11.3 Process Boundaries (Invoke-Command & Start-Process)**
*   **The Rule:** All arguments passed via `-ArgumentList` **must** be wrapped with the `New-StrictArgumentList` helper. Complex objects **must** be stringified before sending and re-hydrated on the receiving end.
*   **Claude's Workflow:** To pass a `[System.Version]` object remotely, Claude generates a two-step pattern:
    1.  **Sending side:** `$stringifiedVersion = $MyVersion.ToString()`
    2.  **Receiving side (in remote scriptblock):** `$versionObj = [System.Version]::Parse($using:stringifiedVersion)`
*   **Why (Compilers):** This defends against two layers of corruption. `New-StrictArgumentList` prevents the PowerShell parser from misinterpreting arguments with spaces. The stringification/re-hydration pattern defeats the CLIXML serialization engine, which can mangle complex .NET objects during remote transport into useless `Deserialized.*` property bags, ensuring type fidelity.

#### **11.4 Process-to-Language Bridges (PowerShell → Python/Node)**
*   **The Rule:** The JSON schema, not the PowerShell class, is the **source of truth** for the data contract.
*   **Claude's Workflow:** To add a 'BIOS Serial Number' to the output, Claude's process is:
    1.  Modify `/Schemas/SystemInfo.schema.json` to add the new `biosSerialNumber` property.
    2.  Modify `/Classes/SystemInfo.ps1` to match the schema.
    3.  Run the CI command (`npm run build-types`) to regenerate the TypeScript definitions from the schema.
    4.  Only then will it add the logic to retrieve the BIOS serial number. It knows CI will fail if the schema and class are out of sync.
*   **Why (Interpreters):** This decouples the PowerShell module from its downstream consumers. The Python and Node.js teams can develop against a static, standard schema file without needing to run or understand PowerShell, creating a robust, polyglot contract.

#### **11.5 Virtual-environment Hand-off (WSL Bootstrap)**
*   **The Rule:** The producer (PowerShell) is responsible for path normalization.
*   **Claude's Workflow:** When generating a JSON payload, any property intended to be a file path **must** be pre-processed inside PowerShell using `[System.IO.Path]::GetFullPath($myPath).Replace('\','/')`. This ensures the path is absolute and uses POSIX-style separators *before* it is serialized to JSON.
*   **Why (Paths):** This simplifies the consumer (Python/Node) code, which can assume any path it receives in the JSON is already in a usable POSIX format. It avoids peppering consumer code with `wslpath` calls or other environment-specific logic.

---

### **Part 12: Environment Context Discovery Framework for AI Collaboration**

*(This section remains unchanged, as it defines the technical implementation for environment discovery.)*

#### **12.1 Automatic Environment Detection (Bootstrap Script)**
*   **Purpose:** To provide Claude with an initial, comprehensive snapshot of the environment's state.
*   **Mechanism:** A bootstrap script (`bootstrap-env.ps1`) runs at the start of any session. It gathers shell type, OS platform (including a specific `WSL` check), active virtual environments (`VIRTUAL_ENV`, `CONDA_DEFAULT_ENV`), and probes for common commands (`python`, `node`, `git`).
*   **Claude's Workflow:**
    1.  Claude executes `bootstrap-env.ps1`.
    2.  The script populates a `$Context` hashtable with discovered details.
    3.  This context is serialized to a temporary file (`$env:TEMP/claude-context.xml`).
    4.  All subsequent operations load this XML file to make informed decisions.
*   **Why (Environments, Paths):** This initial "constitutional" analysis prevents entire classes of errors. By learning about `WSLInterop` upfront, Claude is primed to handle the primary source of frustration in mixed environments: **path context collision**.

#### **12.2 Dynamic Path Resolution**
*   **Purpose:** To locate commands and resources without hardcoding paths.
*   **Mechanism:** A helper function, `Resolve-ExecutionPath`, uses the discovered context to find executables.
*   **Claude's Workflow:**
    1.  Instead of assuming `C:\Python39\python.exe`, Claude calls `Resolve-ExecutionPath -Command 'python'`.
    2.  The function first checks the context file for a known path.
    3.  If not found, it uses platform-specific logic: on WSL, it tries `wslpath`; on Windows, it checks common install locations.
*   **Why (Paths):** This aligns with best practices to avoid hard-coded paths. The script adapts to where tools are actually installed, dramatically improving portability.

#### **12.3 Dependency Validation (Pre-flight Check)**
*   **Purpose:** To verify that all required tools and modules are present before executing complex tasks.
*   **Mechanism:** A `Test-Dependencies` function checks a list of required commands and modules against the discovered context.
*   **Claude's Workflow:**
    1.  Before running a task, Claude calls `Test-Dependencies -RequiredCommands 'docker' -RequiredModules 'Pester'`.
    2.  If dependencies are missing, the function returns a structured report with platform-specific installation suggestions (e.g., `sudo apt install docker.io` on WSL vs. `winget install Docker.DockerDesktop` on Windows).
    3.  Claude presents these suggestions to the user and halts execution, preventing failures due to missing prerequisites.
*   **Why (Dependencies):** This "pre-flight check" improves reliability by handling missing dependencies upfront, providing a better user experience than cryptic runtime errors.

#### **12.4 Smart Environment Setup**
*   **Purpose:** To automatically initialize and configure the working environment for a specific project.
*   **Mechanism:** An `Initialize-WorkingEnvironment` function auto-detects the project type (Python, Node, PowerShell) based on marker files (`requirements.txt`, `package.json`, `*.psd1`).
*   **Claude's Workflow:**
    1.  After dependency validation, Claude runs `Initialize-WorkingEnvironment`.
    2.  If a `requirements.txt` is found, the function looks for and activates a `.venv` virtual environment.
    3.  If a `.nvmrc` is found, it runs `nvm use`.
    4.  After setup, it refreshes the context file to capture the changes (e.g., the new `PATH` from an activated venv).
*   **Why (Interpreters, Profiles):** This automates best practices. Claude can adapt to the project on-the-fly, using the correct, isolated environment without manual user intervention, reducing setup overhead and errors.

#### **12.5 Natural Knowledge Integration & Persistence**
*   **Purpose:** To enable Claude to remember and learn from the environment over time, making its assistance smarter and more natural.
*   **Mechanism:**
    1.  **Context Persistence:** At the end of a session, the context file is saved to a persistent location (e.g., `$env:USERPROFILE/.claude/session-context.json`). The next session loads this file to "remember" the last known state.
    2.  **Knowledge Base:** Claude maintains an internal, updatable knowledge base of environment patterns (e.g., knowing that Python venv activation scripts differ on Windows vs. Linux).
*   **Claude's Workflow:** When `Get-InstallSuggestions` is called, it first consults the knowledge base for the current platform (`WSL + Python`) to provide the most accurate command (`sudo apt install...`). This knowledge base can be updated as Claude successfully installs tools in new ways.
*   **Why (Environments):** This transforms Claude from a stateless tool into an experienced assistant that learns the quirks of a user's system, making its suggestions progressively more tailored and accurate.

---

### **Final Checklist: The AI's Architectural "Ten Commandments"**

Claude uses this checklist to validate any and all contributions, ensuring the living architecture's integrity.

1.  **Splat `$Forward`:** All public cmdlets must pass state via `@Forward`.
2.  **Match Private Params:** All private helpers must accept `@Forward` via splatting.
3.  **No Mutable `$using:`:** No mutable objects into parallel blocks.
4.  **Wrap Argument Lists:** All `-ArgumentList`s must use `New-StrictArgumentList`.
5.  **Stringify for Remoting:** Dehydrate/re-hydrate complex objects across processes.
6.  **Pre-normalize Paths:** PowerShell must deliver POSIX paths in JSON.
7.  **Schema First:** JSON Schema changes must precede class changes.
8.  **Lock State-Files:** All shared file writes must use `Invoke-WithTelemetry` (which handles locking).
9.  **Verify Host Context:** Abort if required host variables (e.g., `$MYEXPORTER_HOST`) are missing.
10. **Respect the Manifest:** All code must adhere to the version, edition, and dependency contracts in the `.psd1` file.