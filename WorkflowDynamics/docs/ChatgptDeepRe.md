Great. I’ll begin preparing a comprehensive Model-Centric Document (MCD) based on your Unified Architecture specification for `MyExporter`. This will start with Section 1 (Overview & Goals) and Section 2 (Technical Architecture), focusing on variable passing, argument flow, and formalizing the design structure across layers.

I’ll return with a detailed breakdown of each component and its requirements shortly.


# MyExporter Module – Comprehensive Design Document (MCD)

**MyExporter** is a PowerShell module designed as a dynamic, self-documenting architecture for exporting system information in a robust, cross-platform manner. This document serves as a Multi-Context Design (MCD) blueprint, detailing the project’s goals, architecture, and the guiding principles that ensure both humans and AI agents can collaborate efficiently in its development.

## 1. Overview and Goals

**Project Vision:** MyExporter’s mission is to provide a **robust, maintainable, and cross-compatible system information exporter** for modern infrastructure. It goes beyond simple scripts by embedding its architecture and patterns into the codebase itself – effectively making the code a reference manual for future development. The result is a tool where **structure reveals purpose** and compliance with best practices accelerates development rather than hindering it.

**Why a Structured Module?** Traditional ad-hoc PowerShell scripts can become unmanageable across different environments and contributors. MyExporter’s strict architecture offers:

* **Consistency:** A single source of truth (the module manifest) defines how the module functions, versioning, and dependencies are managed.
* **Clarity:** A clear separation between public interfaces and internal logic, making it easier for new contributors (or AI assistants) to understand and extend the module.
* **Adaptability:** Built-in patterns for telemetry, error handling, and cross-platform support allow the module to evolve without breaking compatibility or over-complicating the code.

**Target Users:**

* **Human Operators:** DevOps engineers, system administrators, and SREs use MyExporter to gather comprehensive system information (CPU, memory, environment, configurations) in a unified format. They benefit from intuitive cmdlets (e.g., `Export-SystemInfo`) and reliable outputs that can feed into documentation, monitoring systems, or audits.
* **Automated Systems:** CI/CD pipelines and monitoring agents leverage MyExporter in headless environments. For example, a GitHub Actions workflow might import MyExporter to collect system metrics or configuration states as part of deployment validation. The structured JSON outputs and correlation IDs facilitate automation: other tools can parse these outputs and make decisions or store records without ambiguity.

**Core Features:**

1. **Unified System Information Export:** Gathers system details (OS version, hardware stats, configs) into a strongly-typed **`[SystemInfo]`** object and outputs to standard formats (JSON, CSV, etc.). The output format is driven by user choice (with an extensible exporter system for new formats).
2. **Cross-Platform Compatibility:** Works on Windows PowerShell 5.1 (Desktop) and PowerShell Core 7.x (Core) without code changes. Platform-specific differences are handled internally, ensuring the same public cmdlet works anywhere.
3. **Self-Documenting Architecture:** The project structure (folders, naming conventions) and the manifest act as living documentation. New functions are added in predefined patterns (public interface vs. private implementation), so the code itself teaches contributors how to extend it.
4. **Built-in Telemetry and Logging:** Every operation can be traced via a **Correlation ID** and performance timing. This is seamlessly integrated using a telemetry wrapper (`Invoke-WithTelemetry`) that logs steps and errors in a consistent format, aiding both debugging and automated log analysis.
5. **Strong Data Contracts:** The module enforces that all data passed around conforms to defined contracts – e.g., the `SystemInfo` class with a JSON schema. This ensures any JSON output can be validated against a schema (for use by external systems or TypeScript clients) and that cmdlet outputs are predictable for PowerShell IntelliSense.
6. **Adaptive AI Collaboration Tools:** Uniquely, MyExporter is designed to be friendly for AI co-development. The specification includes guidelines for AI assistants on how to contribute (e.g., progressively add features, when to apply patterns, when to ask for help). This means the project not only solves its domain problem but also serves as a testbed for human-AI collaboration in coding.

**Success Criteria:**

* *Correctness:* 100% of `Export-SystemInfo` outputs must validate against the defined JSON schema for SystemInfo. All Pester tests for each class and function must pass on Windows, Linux, and macOS environments.
* *Performance:* A standard system information export (with default settings) should complete in under **5 seconds** on a typical 2-core VM. Telemetry logs the duration of each operation to ensure no step significantly degrades performance across versions.
* *Reliability:* The module must handle absence of optional dependencies gracefully (no crashes if a soft dependency like a PDF generator isn’t installed – it should log a warning or degrade functionality). In headless or constrained environments (e.g., minimal Docker containers), the module should still perform core tasks without requiring GUI components or unavailable services.
* *Maintainability:* Following the architecture is not optional. Success means a new contributor (or AI agent) can add a feature (e.g., support a new OS or a new export format) by following the existing patterns **without introducing regressions**. This is measured by code review checklists: e.g., “Did the contributor avoid using any unsupported cmdlets? Did they update the manifest and tests accordingly?”
* *Traceability:* 99% of all log entries and output files should include a **CorrelationId** (a GUID) that can be used to trace an operation across logs and outputs. This ensures that any error or performance issue can be traced back to its source context, which is crucial in automated pipelines.

---

## 2. Technical Architecture

MyExporter’s architecture is carefully layered, with each layer responsible for a specific aspect of the system. The primary language and runtime is **PowerShell 7.2+** (PowerShell Core), which provides cross-platform support. However, the module is also compatible with Windows PowerShell (Desktop edition) as needed, thanks to conditional logic and compatibility settings in the manifest.

**High-Level Components:**

* **Module Manifest (`MyExporter.psd1`):** The single source of truth for module configuration. It declares module identity (GUID, version), dependency modules, supported PowerShell editions, files included in the package, and more. This is treated as an **immutable contract** – it defines what the module is and supports, and the rest of the code must follow these declarations.
* **Root Module Script (`MyExporter.psm1`):** The primary script module that is loaded when someone runs `Import-Module MyExporter`. It typically acts as a loader: dot-sourcing all public functions and perhaps some initialization. Crucially, all public commands are accessible through this root module (no one should have to import internal files separately). The manifest’s `RootModule` field ensures this is the entry point.
* **Public Cmdlets (Folder: `/Public/*.ps1`):** These are the user-facing functions (as listed in the manifest’s `FunctionsToExport`). They contain minimal logic – mostly orchestrating calls to private functions and handling user input/output. For instance, `Export-SystemInfo.ps1` in Public might parse parameters (like `-Format Csv or Json`), maybe perform simple validation, then delegate to internal functions for the heavy lifting.
* **Private Functions (Folder: `/Private/*.ps1`):** These implement the core functionality. They are not exported, meaning they can only be called from within the module. They are often broken down by platform or specific tasks. For example, `Get-SystemInfo.Windows.ps1`, `Get-SystemInfo.Linux.ps1`, etc., each gather data for their respective OS. A higher-level private dispatcher (e.g., `Get-SystemInfo.ps1` without a suffix) detects the OS and invokes the appropriate platform-specific script. This layer ensures the module can easily be extended to new platforms by adding new files, without modifying the rest of the system.
* **Classes (Folder: `/Classes/*.ps1`):** PowerShell classes that define structured data and related methods. A key class here is likely `SystemInfo` which encapsulates the data collected. Classes might also include things like an `Exporter` base class or specific exporter classes (CsvExporter, JsonExporter) to handle formatting the output. Each class can include methods for validation, formatting (implementing interfaces like `IFormattable`), and serialization. Classes improve the robustness of the module by providing a blueprint for the data (with properties of specific types).
* **Tests (Folder: `/Tests`):** Though not explicitly detailed in the overview, the mention of Pester tests implies a tests directory. There would be tests corresponding to each component (especially classes and public functions) to ensure everything works as intended and to lock in the contract (prevent regressions).
* **Build & CI Scripts (Folder: `/Tasks` and workflows):** A set of build tasks, likely defined in YAML for the `Invoke-Build` module or in GitHub Actions workflows (like `.github/workflows/ci.yml`). These automate tasks like code linting, running tests on multiple OSes, packaging the module, and perhaps generating documentation (via `platyPS`) or publishing to a gallery. This ensures the project’s quality gates are automated.

**Key Technologies & Justifications:**

* **PowerShell 7.2**: Chosen for its cross-platform capabilities and modern features (like `ForEach-Object -Parallel`, new operators, etc.), ensuring MyExporter can run on Windows, Linux, and macOS. By setting `PowerShellVersion = '7.2'` in the manifest, we avoid using deprecated syntax and ensure we can use up-to-date cmdlets and parallelism out-of-the-box for performance.
* **Module Manifest as Configuration**: The manifest `.psd1` is preferred over ad-hoc configuration files because PowerShell natively understands it. It’s parsed automatically when the module loads, making its contents readily available (e.g., PowerShell can automatically apply `RequiredModules` or check `PowerShellVersion`). Unlike a custom JSON or XML config, the manifest is a standard that integrates with PowerShell’s module system. This ensures consistency and that the module can be published/installed via PowerShell Gallery with all metadata in place.
* **Separation of Public and Private**: By strictly dividing public and private functions, we ensure **encapsulation**. Public functions are the only entry points for users – they act as a façade. They typically **pass parameters** and data to private functions by splatting or calling them with explicit arguments, never through global variables. This way, any state is passed along the call chain (for example, the `CorrelationId` is generated in a public function and then passed to private routines, rather than stored in a global variable). This design prevents unintended side-effects and makes each function’s dependencies clear.
* **No Direct Dot-Sourcing in Consumer Code**: The manifest’s `FunctionsToExport` list guarantees that when a user imports the module, they get all necessary functions. The architecture forbids telling a user to `.` (dot source) internal scripts. This prevents versioning issues and hidden dependencies – a user script will always call the official public API, which remains stable even if internal implementations change.
* **Parameter Splatting and Forwarding**: Within the module, when a public function calls a private one, it often collects parameters into a hashtable and uses splatting (e.g., `Invoke-WithTelemetry @params`). This pattern, as recommended in the architecture, makes it easier to forward new parameters through the stack without modifying every function signature along the way. For example, if a new optional parameter is added to `Export-SystemInfo`, the public function can accept it and simply pass it down via `@Forward` to the private functions or classes that need it. This reduces tight coupling.
* **Cross-Platform Guardrails**: The manifest declares `CompatiblePSEditions = 'Core','Desktop'`, which means the module supports both PowerShell Core (cross-platform) and Windows PowerShell. To honor this:

  * Code must use cross-platform .NET APIs and cmdlets wherever possible. For instance, use `Get-CimInstance` (which works on all platforms) instead of the older `Get-WmiObject` (Windows-only).
  * If a feature truly requires a platform-specific approach (like accessing the Windows Registry or a Linux-specific file), the code must check the platform at runtime (using `$IsWindows`, `$IsLinux`, etc.) and only execute the applicable portion. The project’s structure of separate `.Windows.ps1` and `.Linux.ps1` files embodies this rule.
  * If certain capabilities are only available on Windows (say, reading from Event Viewer), those must be optional or have a safe fallback on other OSes. The manifest’s `RequiredAssemblies` or `RequiredModules` might list Windows-specific libraries, and the code uses conditional logic to handle their presence or absence.

**Data Flow (How components interact):**

When a user runs a MyExporter command, the flow is orchestrated and cleanly separated into layers:

1. **User Invocation:** The user calls a public cmdlet, e.g. `Export-SystemInfo -Format JSON -Path "./out.json"`. PowerShell loads `MyExporter.psm1` (root module) which in turn has dot-sourced all files in `/Public`, so `Export-SystemInfo` is available.
2. **Public Cmdlet Execution:** `Export-SystemInfo.ps1` (in Public) begins execution. Its responsibilities include:

   * Validating user inputs (ensuring `-Format` is one of the allowed values, etc., possibly using `[ValidateSet()]` attributes or manual checks).
   * Initiating context for the operation: for example, generating a **Correlation ID** (`$CorrelationId = [Guid]::NewGuid()`) to tag this run.
   * Logging the start of the operation via a common logging function (like `Write-Log`) and maybe writing a verbose message that it’s gathering system info.
   * Preparing parameters for deeper layers. It may assemble a parameter hashtable like `$invokeParams = @{ CorrelationId = $CorrelationId; Format = $Format; Path = $Path; }` to pass along.
   * Calling the private function that actually collects the data. For instance, `Invoke-WithTelemetry` might wrap the call to `Get-SystemInfo`:

     ```powershell
     Invoke-WithTelemetry -Operation "CollectSystemInfo" -CorrelationId $CorrelationId -ScriptBlock {
         $sysInfo = Get-SystemInfo @invokeParams
         return $sysInfo
     }
     ```

     Here `Invoke-WithTelemetry` could be a public (or internal) function that handles timing and error capture. It takes a script block to execute (the actual collection) and logs telemetry around it.
3. **Private Logic Execution:** Within the script block (or directly if not using a telemetry wrapper for that call), the dispatcher `Private/Get-SystemInfo.ps1` runs. This script determines which platform-specific collector to use:

   * It might check `$IsWindows`, `$IsLinux`, `$IsMacOS` and import or call the corresponding file (e.g., `Get-SystemInfo.Windows.ps1`).
   * The platform-specific script (say `Get-SystemInfo.Windows.ps1`) defines a function that gathers data using Windows-specific tools (WMI/CIM, registry, etc.). Similarly, `Get-SystemInfo.Linux.ps1` might read `/proc` files or use commands like `uname` or `lscpu`. Each returns data in a common format (likely a hashtable or a partially constructed `SystemInfo` object).
   * **Passing Data via Arguments:** These private functions do not rely on global state; they receive needed variables via parameters. For example, if a correlation ID or user-specified options (like level of detail) are needed, those are passed as parameters to the private function. This makes the flow explicit and testable – we can call `Get-SystemInfo.Windows -CorrelationId $guid` in a test with a dummy GUID and known environment to verify it returns the expected structure.
4. **Data Modeling:** The raw information from the system is used to instantiate a structured object. For example, `Get-SystemInfo.Windows.ps1` might gather various pieces of info and then do:

   ```powershell
   [SystemInfo]::FromHashtable($collectedData, $CorrelationId)
   ```

   Here `SystemInfo` is a class defined in `/Classes/SystemInfo.ps1`. It could have a static method (like `FromHashtable` or multiple constructors) to create a new object from raw data plus some context. The class ensures that only known properties are set and possibly transforms or validates the data (ensuring types are correct, e.g., converting strings to integers for CPU count).

   * The `SystemInfo` class likely has properties like `OS`, `CPU`, `Memory`, etc., and might implement custom formatting (e.g., a `.ToString()` override for pretty printing). It also may implement `[OutputType([SystemInfo])]` in the public function, which helps tools like VSCode understand what type of object is output for intellisense.
5. **Returning to Public Layer:** The `SystemInfo` object is returned back up to the public function (through the telemetry wrapper if used). Now the public `Export-SystemInfo` function has the complete system info object.

   * It next handles **exporting** to the requested format. The architecture might have separate classes or functions for exporting (e.g., a `ExportTo-Json` vs `ExportTo-Csv`). Given the specification, perhaps a class like `ExporterFactory` decides which exporter to use based on format. For instance:

     ```powershell
     $exporter = [ExporterFactory]::CreateExporter($Format, $Path, $CorrelationId)
     $exporter.Export($sysInfo)
     ```

     Under the hood, `CreateExporter` might return a `JsonExporter` or `CsvExporter` object (polymorphic classes in `/Classes`) that know how to take a `SystemInfo` and write it out. They could also attach the correlation ID or other metadata in the output file if needed.
   * The public cmdlet might also handle output: if `-PassThru` is a parameter (common in such patterns), it may output the \$sysInfo object to the pipeline (allowing the user to capture it or pipe it further). Otherwise, it might just indicate success or output the path of the created file.
6. **Telemetry and Logging:** Throughout this flow, the **Invoke-WithTelemetry** wrapper (and possibly internal try/catch blocks) ensure that any error is caught and converted to a standardized `MyExporter.ErrorRecord`. Instead of spewing a raw exception, the top-level cmdlet will catch exceptions and rethrow or write a structured error containing:

   * `Code` (a short error code or category),
   * `Message` (friendly message describing what went wrong),
   * `SuggestedFix` (if available, e.g., "Ensure you have admin rights" for an access denied scenario).
     These are surfaced either in the PowerShell error stream or in the JSON output if running in an automated context, so that programmatic clients can understand the failure.
   * Additionally, every major step might log to verbose or debug streams. For instance, data gathering functions use `Write-Verbose` for non-critical info (visible if the user sets `-Verbose`), and `Write-Debug` for very detailed info (visible with `-Debug`). The custom `Write-Log` function decides where to send output: if it detects an interactive console with ANSI support, it might print nicely formatted messages; if not (e.g., running in a service), it writes to a log file via a .NET `TraceSource`. This dual approach ensures that in interactive use the user sees progress, but in automated use logs are captured persistently without cluttering the console.

**Design Structures & File Relationships:**

* *Manifest to Files:* The manifest’s `FileList` explicitly enumerates all the files that constitute the module (public, private, classes, etc.). This means any new file (function or class) should be added to that list to be included. It ensures a build is repeatable and no rogue files slip into a release. If a file isn’t listed, it’s effectively considered “draft” or not part of the module yet – a safeguard so that shipping code is deliberate.
* *Public to Private:* Public functions **import** or dot-source private ones as needed. Often, the module’s loading process (in the .psm1 or in each public function) will dot-source all private scripts. A common pattern is in the root `MyExporter.psm1`:

  ```powershell
  # In MyExporter.psm1
  $privatePath = Join-Path $PSScriptRoot "Private"
  Get-ChildItem "$privatePath\*.ps1" | ForEach-Object { . $_.FullName }
  ```

  This loads all private functions into memory (but they are not exported). Alternatively, each public function might dot-source only what it needs. The key is that the end user is oblivious to this; they just call the public function and everything required has already been loaded internally.
* *Modular Growth:* Because of the structure:

  * Adding a new public cmdlet means creating a script in /Public, possibly corresponding private scripts, adding tests, and updating the manifest’s `FunctionsToExport` and `FileList`.
  * Extending support for a new OS means adding a new private implementation (e.g., `Get-SystemInfo.FreeBSD.ps1` if one day needed) and updating the dispatcher logic in `Get-SystemInfo.ps1`. The rest of the system (public interface, classes) can remain unchanged.
  * Adding a new output format (say YAML exporter) might mean creating a new class in /Classes (e.g., `YAMLExporter`) and updating a factory or if-else in the public function or ExporterFactory. The design with classes means adding formats is open/closed (likely it could even discover exporters by naming convention or interface).

---

## 3. Architectural Patterns and Project Structure

MyExporter’s design is underpinned by specific patterns that enforce clarity and maintainability. This section details **how variables and data flow through the system (via arguments, not globals)** and the **project structures (directories and naming conventions)** that implement these patterns.

**3.1 Immutable Manifest – The “Constitutional” Layer:**

As described, the manifest (`MyExporter.psd1`) is treated as an **immutable contract** for the module. It not only provides metadata but also imposes constraints on development:

* *Version and Identity:* The manifest’s `ModuleVersion` and `GUID` uniquely identify the module version. All code and documentation refer to this version for consistency. For example, CI pipelines use `ModuleVersion` from the manifest to tag release artifacts, ensuring what's built is exactly what’s declared.
* *Public API Definition:* `FunctionsToExport` in the manifest lists exactly which functions are public. This acts as a **gate** – if it’s not in that list, it’s not part of the official API. Developers (and AI assistants) know that anything not exported can be changed freely without impacting users. It also tells tools like PowerShell exactly which functions to auto-load on import.
* *Dependencies:* `RequiredModules` (and `PrerequisiteModules`) declare other modules that MyExporter depends on. By listing them, we know those are available in the environment when MyExporter runs. **Design decision:** Instead of writing code to manually check or import dependencies, relying on the manifest means PowerShell’s module system will auto-import them and even fail to install MyExporter if dependencies are missing. This keeps dependency handling declarative.

  * If a feature requires an external module (say MyExporter can optionally use a module `PSJSON` for advanced JSON processing), adding it to `RequiredModules` means any user who installs MyExporter will also fetch PSJSON. If it’s optional, it might go into `PrerequisiteModules` and the code will check at runtime and adapt (like disable JSON enhancements if not present).
* *Platform Constraints:* The `PowerShellVersion` and `CompatiblePSEditions` fields mean that if someone tries to import the module on an unsupported platform, PowerShell will warn or error out early. This saves the user from mysterious failures and guides development: code inside the module should not use anything outside those bounds (e.g., don’t use a cmdlet only introduced in PS 7.3 if manifest says 7.2).
* *Security & Release Integrity:* The manifest’s `FileList` being complete means we can sign the module (if needed) and ensure no tampering. If a file is not listed, even if present on disk, it’s not considered part of the module. This prevents scenarios where a malicious or unvetted script sneaks into the release package. For developers, it means when preparing a release or build, one must update `FileList` – a cue to review what new files are included.

**3.2 Public/Private Function Pattern – Encapsulation and Argument Passing:**

The **/Public** and **/Private** folder division is a core pattern:

* **Public Cmdlets:** Act as **orchestrators** and face the user. They handle input parsing, minimal validation, and then **pass data via parameters** to private functions. They avoid heavy logic themselves for clarity and testability. They also do not usually contain `Try/Catch` around their main work (unless to catch usage errors) – error handling and logging is delegated.

  * *No Global Variables:* Public functions do not rely on any global module state except what is set in the manifest/environment. For instance, if there’s a need to know if verbose logging is on, they might check the preference variable or use `Write-Verbose`, but they wouldn’t use custom global flags. If they need to share a piece of data (like a user-specified setting) with a private function, they include it in that function’s parameter call.
  * *Example:* `Export-SystemInfo` generates a `CorrelationId` and then calls `Invoke-WithTelemetry` or `Get-SystemInfo` **passing that ID as an argument**. The private functions then all accept a `-CorrelationId` parameter. This means any part of the code that needs to log or associate with the operation has access to that ID via its own parameters, rather than referencing some global \$CurrentCorrelationId.
* **Private Functions:** Are the **implementers**. Each is focused on a specific task or platform. They assume that any required context or data is passed in by the caller. They might have parameters like `-CorrelationId`, `-OutputPath`, or a bundle of settings. This makes them reusable and easy to test in isolation. For example, we can directly call a private function with test inputs in Pester and verify it returns expected results, since it doesn’t require setting up global state.

  * *Platform-specific Naming:* A distinctive naming scheme is used (e.g., Verb-Noun.OS.ps1). This is an architectural decision to handle multi-OS differences cleanly. The dispatcher (`Get-SystemInfo.ps1`) will contain logic like:

    ```powershell
    if ($IsWindows) {
        $result = Get-SystemInfoWindows @parameters
    } elseif ($IsLinux) {
        $result = Get-SystemInfoLinux @parameters
    } elseif ($IsMacOS) {
        $result = Get-SystemInfoMacOS @parameters
    } else {
        throw "Unsupported OS"
    }
    ```

    Under the hood, `Get-SystemInfoWindows` would be a function defined in `Get-SystemInfo.Windows.ps1`. Because all such functions are dot-sourced at module import, the dispatcher can call them directly. This pattern avoids big monolithic functions with a bunch of `if/else` inside for each OS – instead, each OS’s logic is in its own file, which is easier to maintain and evolve.
  * *Error Bubbling:* Private functions generally don’t catch errors unless they can handle them meaningfully. Instead, errors thrown (or non-terminating errors) bubble up to the public function or the telemetry wrapper. This ensures a single, consistent error handling strategy at the top level. For instance, if `Get-SystemInfoWindows` fails at some step, it might throw an exception which is caught by `Invoke-WithTelemetry` that then wraps it in our standardized error object.

**3.3 Classes and Strong Typing – Data Contracts:**

Using PowerShell classes (in the **/Classes** directory) is a deliberate design to enforce data contracts and provide a clear interface for data:

* **SystemInfo Class:** Represents the schema of the exported data. Instead of using loose PSCustomObjects, having a `[SystemInfo]` class means:

  * We define exactly what properties (and types) a system info object has (e.g., `public string OSName`, `public int CPUCount`, `public double TotalMemoryGB`, etc.).
  * We can include methods, like a custom `ToString()` that might format the system info in a human-friendly table or summary. Implementing .NET interfaces such as `IFormattable` allows the object to respond to format strings. For example, `$sysInfo.ToString('table')` could produce a neat column-aligned output, whereas `'json'` could produce a JSON string. This is extremely useful for logging or interactive use.
  * We can mark up the class for output type attributes in cmdlets (`[OutputType([SystemInfo])]` on Export-SystemInfo) so that IDEs and help docs know what’s coming out. This makes it easier for users to consume the module because they can discover properties via tab-completion and get documentation on them.
* **Exporter Classes:** If the architecture uses classes for exporters (e.g., `CsvExporter`, `JsonExporter`), they likely inherit from a common interface or base class. They encapsulate the logic of taking a `SystemInfo` object and writing it to a file (or returning a string). By having separate classes or at least separate functions for each format, adding new formats doesn’t disturb existing ones (Open/Closed principle). The Exporter might also embed metadata: for instance, a JSON exporter might include a schema reference or a timestamp in the output, whereas a CSV exporter might have to flatten nested data.
* **Testing Classes:** Each class in /Classes has a corresponding Pester test (mentioned under the Architectural layer rules). For example, if `SystemInfo` has validation in its constructor (maybe ensuring no property is null), tests will attempt to create invalid instances to verify it throws meaningful errors. If `SystemInfo` supports JSON round-trip serialization, a test will serialize it to JSON and back and ensure the object remains equal. This enforces that changes to the class (like adding a new property) are done in a way that doesn’t break the contract (tests would fail if, say, the JSON schema wasn’t updated accordingly).

**3.4 Project Directory and File Layout Recap:**

* **Root**: Contains `MyExporter.psd1` (manifest) and `MyExporter.psm1` (entry point script). Possibly a module logo or README as well.
* **Public**: All `.ps1` files here are named after the cmdlets they implement (Export-SystemInfo.ps1, maybe other cmdlets if any). They are all short and primarily call into Private or Classes.
* **Private**: Helper scripts not meant for public use. Naming may mirror the public function or the subsystem they belong to. Key patterns:

  * If a public cmdlet is just a facade, the heavy work might be done in a private script of the same base name. E.g., `Export-SystemInfo.ps1` (public) calls `Invoke-ExportSystemInfo.ps1` (private) which contains the complex logic. However, in our case, it appears the main heavy lifting is directly in `Get-SystemInfo` and exporters, so the naming might differ.
  * Platform-specific scripts use dot in filename (`Name.Windows.ps1`). This convention is not standard in PowerShell by default, but the project explicitly adopts it for clarity.
* **Classes**: `.ps1` files that use the `class` keyword to define classes. Typically named after the class (SystemInfo.ps1, ErrorRecord.ps1, maybe Exporter.ps1).
* **Tests**: Usually mirroring the folders above under a `/Tests` directory. For instance, `Tests/Public/Export-SystemInfo.Tests.ps1`, `Tests/Classes/SystemInfo.Tests.ps1`, etc. This separation ensures tests are organized by the part of the system they cover.
* **Docs**: The mention of `/Docs` suggests that the module’s help is auto-generated. Likely, running `New-MarkdownHelp` or a similar tool will generate markdown documentation for each public cmdlet and place it here. These would be kept in sync by not editing them manually – instead, editing the comment-based help in the source `.ps1` and regenerating ensures docs are up to date.
* **Build scripts (/Tasks)**: Possibly contains build/test scripts in PowerShell or YAML format. The mention of YAML task definitions for `Invoke-Build` suggests that there’s a build script (like a psake or Invoke-Build script) that orchestrates tasks such as cleaning, testing, packaging. The AI or developer referencing these tasks ensures they use the established build pipeline (for example, if asked to run tests, the instruction might be "invoke `Invoke-Build Test` as defined in Tasks/Build.yaml").

**3.5 How Variables Pass Through the System (No Implicit Globals):**

A fundamental design choice is that **state is passed through parameters and return values**, rather than using global variables or module-wide variables:

* Configuration settings or context (like the correlation ID, or an environment-specific flag) are fed into functions explicitly. For instance, if some functions need to know the path to the state file directory, they might be given `$StatePath` as a parameter or the class that manages state knows how to derive it (using environment variables like `$env:APPDATA` or `$XDG_STATE_HOME`).
* There may be a **module-level variable** for very core settings (for example, a constant like `$StateDir = "$env:APPDATA\MyExporter"` set at import time), but anything dynamic flows through arguments.
* Splatting is used heavily to forward parameters. This allows intermediate functions to remain unchanged when new parameters are introduced. For example, if in the future we add `-IncludeHardwareDetails` as an option, the public function can accept it and just add it to the `@invokeParams` hashtable, and all downstream private functions that care about it will receive it (ones that don’t have it in their param list will simply ignore it via PowerShell’s binding).
* **No Dot Sourcing between Public Functions:** Each public cmdlet is independent. If they share code, that code goes into a private function or a class method that both call, rather than one public function dot-sourcing another. This avoids hidden couplings where using one cmdlet implicitly runs another’s code. The architecture encourages a single-responsibility principle even at the script level.

**3.6 List of Key Architectural Requirements (Summary):**

* *Manifest-Defined API:* Only functions listed in `FunctionsToExport` are public. All others are internal. **Consequence:** internal functions can change freely; external ones require backward compatibility.
* *Single Import Entry:* Users only ever run `Import-Module MyExporter` (optionally with `-RequiredVersion`). That action should load everything needed. **No additional dot-sourcing by users.**
* *Cross-Platform Code:* All core functionality must run on PowerShell Core. Use `$PSVersionTable.PSEdition` or built-in variables to guard OS-specific code. If a required assembly is Windows-only, check for OS and throw a clear error or use an alternate approach on other OSes.
* *Public Functions as Thin Wrappers:* They should contain logic only for orchestration: parameter parsing, calling internal logic, formatting results. No heavy computations or data manipulations are done in the public scope.
* *Internal Logic Modularized:* Break down tasks into private functions and/or methods. E.g., collecting data, transforming data to objects, exporting formats, writing logs are separate concerns handled in separate units of code.
* *No Unnecessary Repetition:* Use common utilities (like `Write-Log`, `Invoke-WithTelemetry`) rather than duplicating that code in multiple places. This ensures consistent behavior (all telemetry logs look the same, all errors are handled uniformly).
* *Testing and Validation:* Every new function or class comes with corresponding tests. Also, any new user-facing output (like adding a new property in `SystemInfo`) should be reflected in the JSON schema and type definitions, ensuring external consistency.
* *Documentation Automation:* Do not manually write long help files. Instead, write concise comment-based help in the functions and leverage tools to generate or update markdown docs. This reduces the risk of outdated documentation.
* *Performance Consideration:* Use parallel processing (`ForEach-Object -Parallel`) when collecting data if it provides significant speedup (e.g., querying multiple WMI classes in parallel). However, respect an environment variable (like `$env:PS7_PARALLEL_LIMIT`) or use PowerShell thread throttling to avoid overwhelming systems. On systems where -Parallel is not available or not permitted, fall back to sequential or background jobs.
* *Graceful Degradation:* If an optional module or feature isn’t present (as signaled by `PrerequisiteModules` or simply by runtime detection), the module should detect that and either inform the user or operate in a reduced functionality mode rather than crash. E.g., if a fancy logging feature is unavailable on Linux, just skip it with a warning.

---

## 4. Adaptive Collaboration Framework (Human + AI Development)

One of the innovative aspects of MyExporter’s specification is how it accounts for collaboration not just among human developers, but also with AI assistants (like pair-programming with ChatGPT or similar tools). This section addresses how the architecture and processes are structured to guide such collaborations, preventing the AI from introducing anti-patterns or getting “stuck” on complex rules.

**4.1 Progressive Context Anchoring:**

When using an AI to assist with coding tasks, providing it the right amount of context is crucial. Too little context and it might produce irrelevant or incorrect suggestions; too much and it might become overwhelmed or overly rigid following patterns. MyExporter defines **tiers of context** to supply to the AI depending on the complexity of the task:

* **Level 1 – Essential Context (Always Include):** This is the minimum the AI should know for any task on the project.

  * *Environment:* Assume a development environment like Windows Subsystem for Linux (WSL2) with PowerShell 7.4+, which means a mostly POSIX-compliant environment with PowerShell available. This is important so the AI doesn’t write Windows-only paths or assume a Windows GUI is present if not needed.
  * *Cross-platform constraint:* The AI is reminded that any code must be cross-platform unless told otherwise. This stops it from using, say, `Get-ADUser` (which only works on Windows with RSAT) unless it’s explicitly in scope.
  * *Modern PowerShell:* Use features and modules that are available in PS7.4 environment. For example, prefer `Get-Process` (available everywhere) to `gps` (alias) or older approaches.
  * *Escape hatch indicator:* A concept of `-FastPath` mode is introduced. This means if the task is simple and doesn’t impact core architecture, the AI can be allowed to output a quick solution without threading through all layers of the architecture. **Example:** If asked to give a one-liner for how many processes are running, the AI might normally try to wrap it in all the module structure (which is overkill). With a fast-path flag (conceptually), it could just answer with a basic snippet. This level of context implies that for trivial or isolated tasks, the AI need not enforce every architectural rule.

* **Level 2 – Architectural Context (For Complex Tasks):** Include this when a task touches multiple parts of the module or could affect architectural integrity.

  * *Architecture guidelines:* Remind the AI of the manifest-driven design (e.g., “remember, if you add a new public function, update the manifest `FunctionsToExport` and add a skeleton in /Public and an entry in /Docs”).
  * *Telemetry and wrappers:* Ensure the AI knows that significant operations should use `Invoke-WithTelemetry` for consistency. However, minor utility functions might not need telemetry overhead.
  * *Parameter forwarding (splatting):* If modifying or creating functions that call others, instruct the AI to use parameter splatting for forward-compatibility. For instance, “Instead of calling `Get-SystemInfo -Detail Full -CorrelationId $ID`, gather those into a hashtable and splat, to allow adding more parameters later easily.”
  * Essentially, Level 2 context is the distilled version of this design document’s Part 1-3 content – the rules that keep the code aligned with the grand plan.

* **Level 3 – Platform/Environment Specific (For environment-dependent tasks):** Use when the task involves interacting with the OS or external systems.

  * *WSL Paths:* If the AI needs to write code that interacts with Windows from Linux (or vice versa), remind it to use utilities like `wslpath` to convert paths. E.g., if saving a file to a Windows path from inside WSL, convert it accordingly.
  * *Resource Limits:* If running tasks that could be heavy (like parallel processing), check for environment limits. `$env:PS7_PARALLEL_LIMIT` was mentioned as an env var to throttle parallelism – if not set, default to a safe value (e.g., 2 threads) to avoid saturating the CPU in CI environments.
  * *External dependencies:* If a task needs Docker (like building a container) or other external service, the AI should verify their presence (e.g., check if `/var/run/docker.sock` exists before trying to use Docker, to avoid confusing errors if Docker isn’t running).
  * This level ensures that suggestions don’t assume things that might not hold in all dev environments or CI.

By structuring AI prompts with these context levels, the collaboration remains efficient. The AI is less likely to provide a Windows-only solution for a cross-platform task or to ignore an important piece of context. It also means a developer can explicitly tell the AI “stick to level 1 context for now” if they want a quick and dirty draft, or “include level 2 context” if they want the AI to enforce the full architecture.

**4.2 Anti-Tail-Chasing Prompt Patterns:**

Sometimes AI can get stuck in a loop of refining or over-complicating (tail-chasing) especially when trying to comply with many rules. MyExporter’s approach is to structure prompts clearly and in stages to keep the AI focused:

* **Task-First Prompt Structure:** Always start the prompt to the AI with a clear statement of the objective, then provide context and constraints. For example:

  ```
  TASK: Add CPU temperature monitoring to the SystemInfo class.
  CONTEXT: Level 1 (Essential) + knowledge that CPU temp can be read via OS-specific commands.
  CONSTRAINTS: Must work on Windows and Linux. Do not add new dependencies.
  ESCAPE_HATCH: If Linux part is complex, implement Windows fully and put a TODO for Linux.
  ```

  In this structure:

  * The **TASK** is plainly stated so the AI focuses on the goal.
  * The relevant **CONTEXT** is given (maybe summarizing that SystemInfo currently has CPU info but not temperature, etc.).
  * Only critical **CONSTRAINTS** are listed (like cross-platform requirement, or "don't use modules outside RequiredModules").
  * An **ESCAPE\_HATCH** is explicitly given: permission for the AI to partially implement if needed (with a clear marker for follow-up). This prevents the AI from either giving up or producing a half-baked cross-platform solution. It knows it can do one part well and mark the rest as TODO without failing the task.

* **Incremental Complexity Approach:** For larger features, break the work into phases for the AI:

  1. **Phase 1 – Prototype the Core Functionality:** "Ignore telemetry, ignore advanced patterns, just get a basic implementation working for one scenario." This allows quick validation and keeps the AI from trying to do everything at once.
  2. **Phase 2 – Error Handling & Logging:** "Now take that working core and add proper error traps, input validation, and logging according to our patterns." This stage ensures robustness.
  3. **Phase 3 – Integrate with Architecture:** "Finally, embed this into our module structure: e.g., move the code into the appropriate private function, ensure it’s called from the public cmdlet, add any missing telemetry wrappers or parameter splatting as needed."
  4. **Validate at Each Phase:** After each phase, run tests or at least do basic validation. The instruction to the AI would be, for instance, "Run Pester tests now, they should pass for the added feature (or if tests don't exist yet for it, run a quick manual test of the function)."

  This staged approach mirrors good development practice and also aligns well with how an AI can iteratively refine its output. It ensures early feedback (so if Phase 1 output is wrong, it can be corrected before adding complexity). It also means that if something goes awry, you know at which phase it happened and can roll back or adjust without losing all progress.

* **Bailout Triggers:** The specification wisely includes conditions for the AI to stop and seek human input:

  * If a task that seemed simple is ballooning (e.g., "more than 3 files need modification for a simple change"), the AI should recognize this and not continue blindly. It would then respond with something like, "This change is touching a lot of areas. Are we sure we want to proceed, or should we rethink the approach?"
  * If it detects any circular dependency or design contradiction (for example, the AI finds that to implement feature X it needs data from Y, but implementing Y depends on X), it should not try to hack around it; instead, stop and flag the issue.
  * If environment or context assumptions break (maybe it realized that a library isn't available or the API it planned to use doesn’t exist in PS7), it should stop and report the problem rather than output nonsense.

  These guidelines effectively tell the AI: it’s better to ask for help or clarification than to produce a wrong or overly complex solution. This ensures the human developers remain in control of critical design decisions and that the AI doesn’t create unmaintainable code in an attempt to follow rules.

**4.3 How Architecture Benefits Collaboration:**

The way MyExporter is structured (with manifest rules, clear modular boundaries, etc.) might seem strict, but it serves as a teaching tool for new contributors and AI alike:

* The manifest and file structure act like a checklist for adding new features. An AI (or human) can be told, "If you add a new cmdlet, search for `FunctionsToExport` in the manifest and update it; look at `/Templates` folder for a skeleton to use; add a test in `/Tests/Public`." The architecture thus **orchestrates the development tasks** because each rule implies a to-do (update manifest, create file in X location, run tests in Y).
* Because everything is explicit (no “magic” global behavior), an AI agent can more easily infer how to do something by analogy. For example, "We want a new function Export-ProcessInfo, how did we do Export-SystemInfo? Let's imitate that structure." The consistency reduces the cognitive load on the AI to invent solutions from scratch; it can mostly follow patterns.
* The collaboration framework ensures that the AI is used where it’s strong (generating boilerplate, following patterns, doing tedious multi-OS coding) and that it defers to humans for validation and judgment when needed (complex design trade-offs, confirming requirements). This synergy can speed up development while maintaining quality.

---

## 5. State Tracking and Context Preservation

When building complex features or executing multi-step operations (especially with AI involvement), there is a risk of losing track of the context or intermediate results. MyExporter introduces a concept of using **physical artifacts (files) to track operation state**, which is beneficial for long-running tasks and for synchronizing between human and AI contributions.

**5.1 Artifact-Based Context (`operation-context.xml`):**

Instead of relying purely on the transient conversation or memory, an approach is to serialize the current state of an operation to disk so it can be reloaded or inspected at any time. For example, when an AI is asked to perform a multi-step refactor:

* At the very start, the AI (or a script guiding it) creates an **operation manifest** (in this case, using PowerShell’s `Export-Clixml` to produce an XML file).

* This `operation-context.xml` might contain:

  * **Goal**: A brief description of what is being accomplished (e.g., "Add CPU temperature monitoring").
  * **FilesInvolved**: A list of file paths that are expected to be created or modified (so all changes are tracked).
  * **ArchitectureRules**: Perhaps a reiteration of key rules to follow for this task ("use telemetry wrapper", "update JSON schema if adding property", etc.).
  * **CurrentStep** and **TotalSteps**: If broken into phases, track which step we are on.
  * **Shortcuts/Flags**: The example shows flags like `FastPath = $false`, `SkipTelemetry = $false`, `SkipTests = $false`. These could be toggles that indicate if certain compliance steps are being skipped for now (maybe turned on in early phases and off by the final phase).

  This file acts as a **single source of truth** for the operation’s context. Anyone (or any tool) can open it to see what’s going on. If an AI session times out or loses state, it can be restarted with this file to know where it left off.

* In practice, a developer might load this context for the AI by saying: "Given the context in operation-context.xml, proceed to the next step." This way, the AI doesn't need to be fed the entire design document and chat history each time – it has a distilled context to refer to.

* The choice of Clixml (PowerShell’s serialized XML format) is convenient because PowerShell can easily export and import it back into an object. So the AI could even be instructed to run `Import-Clixml "operation-context.xml"` at the start of a prompt to get an object with all the info, rather than parsing text.

**5.2 Checkpoints and Long-Running Task Resumption:**

Large changes might involve multiple code edits, test runs, etc., which could be done over hours or days. The concept of **checkpoints** is introduced to manage this:

* A function like `Checkpoint-Operation` can be called at significant milestones (end of Phase 1, Phase 2, etc.). It might log the current phase, do some validations, and halt if something is off.
* For instance, after implementing the Windows part of CPU temperature monitoring, one would call:

  ```powershell
  Checkpoint-Operation -Phase "WindowsTempDone" -State $OpState -Validation $testResults
  ```

  Where `$OpState` might contain info like "Windows implementation complete, Linux pending" and `$testResults` might be an object with a property `IsValid` (true if all tests passed on Windows scenario) and maybe a `Reason` if not.
* If tests or validations fail at a checkpoint, the function might throw or clearly log a **BAILOUT** message. This signals that the process should stop here until the issue is resolved (either by human intervention or adjusting the plan).
* Each checkpoint essentially verifies that the project is still in a good state (nothing broken) before proceeding. If a failure is detected, by halting, it prevents compounding errors in subsequent steps.

For AI collaboration, this is important because:

* It provides a natural pause where the AI can be told to stop if certain conditions aren’t met (instead of plowing ahead and making things worse).
* It enables **resumption:** If you come back later or start a new session, you know exactly the last successful checkpoint and what needs to happen next. The operation context file would be updated with `CurrentStep` so you can continue.

**5.3 Persistent Module State File:**

Aside from AI operation contexts, MyExporter itself deals with state management in its functionality:

* The specification mentions a **state file** under app data (e.g., `$env:APPDATA\MyExporter\state.json` or a location respecting `$XDG_STATE_HOME` on Linux). This is for the module’s own idempotence and state tracking, not specifically for AI.
* For example, if MyExporter performs an export that should not duplicate data if run twice in a short period, it might record the last run time or last output in the state file. Or it might store user preferences (like a consent to collect telemetry, if that were a feature).
* The `StateFile` class would handle reading and writing this JSON with file locks to prevent two processes from writing at the same time. This ensures that even if MyExporter is run in parallel (or by two different processes), the state updates don’t corrupt each other.
* This is part of being a well-behaved tool on a system: not leaving multiple processes to trample on the same file and providing a single place to look for persistent info (like "when was the last successful export?").

In summary, **state tracking** in MyExporter operates at two levels:

* *Development/Operation level:* things like `operation-context.xml` and checkpoints help manage complex changes and AI-human collaboration.
* *Runtime level:* the module’s use of a state file ensures stable behavior across multiple runs and can help resume or avoid repeated work when not necessary.

---

## 6. Meta-Prompts and Self-Correction Mechanisms

To complement the collaboration framework, MyExporter’s guidelines include meta-prompts – essentially templates and checklists that the AI (and developers) should use frequently. These act as both a playbook for common tasks and a safeguard to ensure the solutions remain practical and maintainable.

**6.1 Template Prompts for Common Scenarios:**

These are pre-defined structures for prompts to the AI for repetitive or complex scenarios, ensuring nothing important is forgotten:

* **Schema-Class Synchronization Prompt:**
  If a change in data structure is needed (say we add a new property to the SystemInfo class), the AI should follow a specific sequence:

  ```
  TASK: Sync schema and class for [ClassName].
  APPROACH:
    1. Read current class definition.
    2. Generate or update JSON schema from class (or vice versa).
    3. Validate that the schema covers all class properties.
    4. Update class if schema reveals gaps (e.g., missing property or different naming).
    5. Regenerate any derived artifacts (TypeScript definitions, documentation).
  BAILOUT_IF: More than 2 sync cycles are needed (i.e., if after two iterations the class and schema still differ, stop to seek clarification).
  ```

  This prompt ensures the AI methodically aligns class code with external contracts. It’s easy for documentation or schemas to fall behind – this keeps them in lockstep. It also ensures efficiency by preventing infinite back-and-forth (the **BAILOUT\_IF** clause).

* **Cross-Platform Implementation Prompt:**
  For features that must be implemented on multiple OS, a template like:

  ```
  TASK: Implement [Feature] for Windows, Linux, and macOS.
  APPROACH:
    1. Implement and test the feature on the current platform (assume Windows as default).
    2. Identify any platform-specific dependencies or calls.
    3. Abstract those behind an interface or conditional logic if necessary (only if it prevents code duplication).
    4. Implement the feature on the other platforms, reusing as much logic as possible or marking TODO where needed.
  BAILOUT_IF: The abstraction layer (common interface) is becoming more complex than the platform implementations themselves.
  ```

  This template reminds the AI not to over-engineer an abstraction if the platforms are too different – sometimes it's fine to have separate code for each OS. It also encourages starting with one (prove it works) then port, rather than trying a big bang approach for all OS at once.

* **Logging & Verbosity Adjustment Prompt (hypothetical):**
  If adjusting how logging works:

  ```
  TASK: Modify logging to use TraceSource in headless mode.
  APPROACH:
    1. Locate Write-Log function.
    2. Add logic to detect $PSStyle.OutputRendering. If 'Ansi', proceed with Write-Host, else use TraceSource.
    3. Ensure all calls to Write-Host in the module go through Write-Log (search and replace if any direct calls).
    4. Add tests or a manual verification step for headless logging (simulate $PSStyle or run in a non-ANSI environment).
  BAILOUT_IF: Using TraceSource introduces any new dependency or if output formatting becomes inconsistent.
  ```

  Templates like this keep tasks focused and ensure that changes align with the design (like centralizing all Write-Host usage into one place).

These meta-prompts can be part of the project documentation so any contributor can use them. They encapsulate best practices: a new contributor might not know to check for `$PSStyle.OutputRendering`, but the prompt template would guide them to it.

**6.2 Self-Check Checklist (AI and Developer Self-Correction):**

Before finalizing any major code contribution, the spec suggests running a **SELF\_CHECK** – essentially a quick QA done by the person or AI writing the code:

* The self-check questions listed act as a litmus test:

  1. **Am I solving the actual problem, not just following rules?** – This guards against a situation where the implementation is technically by-the-book but doesn’t truly meet the user's needs or the initial task. For example, maybe all architectural guidelines were followed but the output is in the wrong format or the feature doesn’t actually solve the user’s pain point.
  2. **Is the solution's complexity justified?** – Given the task, did we over-engineer? E.g., adding a new 3rd-party library for something simple would fail this check, or creating an elaborate class hierarchy for a trivial calculation would too.
  3. **Can this be explained simply?** – If one cannot explain how the solution works to a junior dev in 2 minutes, it might be too complex. This encourages simple, clean designs. If the solution is complicated, perhaps more comments or refactoring are needed.
  4. **Maintainability Impact:** Does this code make the system easier or harder to maintain? Sometimes a quick fix can introduce tech debt that makes future changes harder. If this solution does that, maybe rethink it.
  5. **Debuggability:** If you (or someone else) had to debug this months later, would it be clear what’s happening? This encourages good logging, clear error messages, and avoiding overly clever tricks that obscure the logic.

* **Proceed, Simplify, Escalate:**

  * If all answers are positive (meaning the solution is on-point, justified, clear, maintainable, and understandable), then **Proceed** with confidence – the change is ready or very close.
  * If any answer is negative, try to **Simplify**. This might mean refactoring the code to be clearer, removing an unnecessary layer of abstraction, or adding comments to clarify intent.
  * If simplifying would break an important requirement or you’re not sure how to simplify without losing a feature, **Escalate** – which in a team setting means ask a peer or lead for guidance. In an AI setting, it means the AI should ask the user if the approach is okay or if there's an alternative. Essentially, don’t force a solution that feels wrong; get a second opinion.

This self-correction mechanism ensures that even with all the rules and patterns, **pragmatism prevails**. The architecture is there to support the goals, not to become an academic exercise. By explicitly putting this in the design doc, it empowers developers and AI to occasionally step back from the rulebook and think about the bigger picture.

---

**Conclusion:**

The MyExporter project’s sections (1 through 6) lay out a comprehensive architecture that not only defines how the module functions technically, but also how it should be developed and evolved. The emphasis on passing variables through explicit arguments, strict design structures (manifest, folder layout, naming conventions), and listed requirements (guardrails) all serve to make the module predictable and reliable.

Crucially, this unified document doesn’t stop at describing a static system – it **orchestrates the development process**. By following this MCD, any contributor (human or AI) is effectively guided step-by-step in adhering to the project's standards. The result is a living codebase where the "what" (features and functionalities) is tightly coupled with the "how" (implementation approach), ensuring consistency, quality, and ease of collaboration for the lifetime of the project.
