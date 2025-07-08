<!-- GUARDRAIL: Always begin by reading docs/integration loop/GuardRails.md Part 2 (Architectural Layer) -->
<!-- MASTER CONTEXT VERSION: v1.2 (docs/MASTER-CONTEXT-FRAMEWORK.md) -->

# PowerShell Build Suite Discipline

**🚨 CONSTITUTIONAL GUARDRAIL BANNER 🚨**  
**Authority:** All build discipline below derives from `docs/integration loop/GuardRails.md` constitutional framework  
**Master Context:** Always validate against `docs/MASTER-CONTEXT-FRAMEWORK.md` before proceeding  
**Mandatory Reading:** GuardRails.md Parts 1-3 → CLAUDE.md → Isolate-Trace-Verify-Loop.md

**Framework Version:** 1.1  
**Created:** July 6, 2025  
**Updated:** [Current]  
**Purpose:** PowerShell build suite discipline with cross-edition compatibility

POWERSHELL BUILD SUITE

all "tasks," pipelines and gating rules together in the TaskLoop directory where work discipline is explicitly separated from constitutional docs, asset records, or AI-tool descriptionsERSHELL BUILD SUITE

all “tasks,” pipelines and gating rules together in the TaskLoop directory where work discipline is explicitly separated from constitutional docs, asset records, or AI-tool descriptions

(each illustrating a 5.1-only feature or behavior that may trip you up in 7.x) and five deeper details on how to build and validate a robust PowerShell 5.1–first build suite that remains forward-compatible.

---

## ⚠️ Expanded Forward Compatibility Gotchas (10 Examples)

1. **`Start-Transcript` with Legacy Encoding**

   * 5.1 defaults to ASCII; 7.x defaults to UTF-8. Transcripts you parse later may contain unexpected BOMs or character substitution.
   * Layer 3.5 (Logging & Verbosity): Transcript files are a form of log output. Your framework already gates console vs. file logging; we simply need to add an assertion in Write-Log to normalize transcript encoding to UTF-8 (or explicitly emit -Encoding UTF8).
   * Compliance Check: This respects the “wrap file writes” rule (Part 3.5) and the manifest’s RequiredAssemblies/PrivateData encoding policy.



2. **`New-WebServiceProxy` SOAP Clients**

   * In 5.1 this generates a working SOAP client against full .NET Framework. In 7.x you’ll hit missing assembly or TLS negotiation issues.
   * Part 1 (Manifest) & Part 3.1 (Data Contracts): Because this relies on .NET Framework–only assemblies, it must be declared in RequiredAssemblies in the .psd1 and wrapped with a guard clause in the private helper for non-Windows hosts.
   * Compliance Check: Matches the “throw descriptive error on non-Windows” rule in the constitutional layer.

3. **`Out-GridView` / `Show-Command` GUI Cmdlets**

   * Windows-only GUI popups; no equivalent on Linux or headless PowerShell 7.
   * Part 2 (/Public) & Part 4.1 (Prompt Levels): GUI pop-ups belong in interactive demos only (Level 3). Public cmdlets must not invoke them by default. The PSScriptAnalyzer rules (deep-dive #2) will flag any GUI calls in /Public.
   * Compliance Check: Enforced by the architectural rule “no GUI in orchestration scripts.”


4. **`Get-EventLog` vs. `Get-WinEvent`**

   * 5.1: `Get-EventLog -LogName Application` works. 7.x on Windows replaces it, but on Linux it’s entirely absent.
   * Part 2 (/Private) & Part 3.2 (Telemetry Exception Model): Replace Get-EventLog with a private dispatcher that calls Get-WinEvent on Windows and errors or no-ops on Linux. Telemetry will record which provider was used.
   * Compliance Check: Adheres to the platform-dispatch pattern (verb-noun-platform.ps1).

5. **`Add-Type -AssemblyName “System.Windows.Forms”`**

   * Pulls in Windows Forms libraries on 5.1/.NET Framework. On 7.x/.NET Core, requires manual NuGet import or simply fails.
   * Part 1 (RequiredAssemblies) & Part 3.2: GuardRails mandates listing any native DLLs. We’ll declare System.Windows.Forms in the manifest and wrap its Add-Type in a PlatformGuard block.
   * Compliance Check: Satisfies the “guard clauses for native DLLs” rule under the constitutional layer.

6. **Implicit Remoting to Legacy Hosts**

   * Part 11.2 (Run-space Boundaries) & Part 3.4 (Concurrency): Our perimeter rules already forbid mutable objects across $using:. We extend them to forbid implicit WinRM sessions—forcing explicit -UseSSL, -ConfigurationName, and parameterized credential forwarding.
   * Compliance Check: Consistent with the “no mutable using” and “strict argument list” rules.
   * 5.1 can connect over WinRM to older servers. 7.x uses OpenSSH by default on Linux, so your old session configurations may break.

7. **`Get-PSDrive -PSProvider Registry`**

    * 5.1 enumerates HKEY\_ paths; on non-Windows hosts or in 7.x Core on Linux, the Registry provider is absent.
    * Part 2 (/Private) & Part 3.1: Registry access must be wrapped in a Linux skip branch. The dispatcher will call Test-Path HKLM: only on $IsWindows.
    * Compliance Check: Follows the private-script dispatch pattern and PlatformGuard rules

8. **`Import-Module ActiveDirectory`**

   * Relies on the RSAT snap-in on Windows. No cross-platform equivalent and fails silently or with cryptic errors in 7.x Linux.
   * Part 1 (RequiredModules) & Part 4.2 (Dependency Validation): Declare ActiveDirectory as a prereq in RequiredModules if you intend to ship it; otherwise move it to PrerequisiteModules and have the pre-flight check abort with install instructions.
   * Compliance Check: Leverages the “soft dependencies” mechanism in the manifest.

9. **`Write-Progress -Activity` Animation Differences**

   * 5.1 writes carriage returns; 7.x on Linux may render flickering or fail to clear old text in some terminals.
   * Part 3.5 (Logging & Verbosity): Our central Write-Log already conditions on output rendering. We add a special case for Write-Progress in non-ANSI hosts to degrade to simple verbose messages.
   * Compliance Check: Extends the existing verbosity mapping without breaking the rule that only Write-Debug/Write-Verbose surface diagnostics.

10. **`[System.Data.DataSet]` Serialization**

    * DataSet XML serialization works in .NET Framework but may require `System.Data.Common` package references in Core to avoid “type load” errors.
    * Part 3.1 (Data Contracts) & Part 11.4 (Process-to-Language Bridges): Since DataSet lives in .NET Framework only, we wrap it behind a private shim that, on Core, falls back to manual XML serialization via System.Xml. We update the JSON schema accordingly.
    * Compliance Check: Aligns with the “schema-first” contract and prevents CLIXML corruption.



---

## 🔧 Building a 5.1-First, Forward-Compatible Build Suite (5 Deep-Dive Details)

1. **Pester with Dual PowerShell Runners**

   * Configure your `Invoke-Pester` call to spawn two runners: one in-process under 5.1 (`-AsJob`) and one under 7.x, then diff their object outputs to catch behavior drifts.
   * Part 2 (Pipeline Definition) & Part 4.1: This directly implements the CI matrix strategy in the manifest’s pipeline mandate, ensuring both 5.1 and 7.x runners’ outputs are diffed.
   * Compliance Check: Satisfies the “matrix builds” rule and guards against regressions in either host.

2. **PSScriptAnalyzer Ruleset Tuning**

   * Extend the default ruleset to flag use of Windows-only providers (`-PSProvider Registry`, `WMI*`) and GUI cmdlets. Fail the build if any forbidden commands are detected in code intended for cross-platform.
   * Part 4.2 (Anti-Tail-Chasing) & Part 3.2: Extends the linter to enforce architectural constraints at commit time, preventing over-scoping or disallowed cmdlets.
   * Compliance Check: Automates pre-commit guardrails for both human and AI contributions.

3. **Module Compatibility Shim**

   * Create a small helper module (`CompatShim.psm1`) that conditionally imports or aliases commands:

   ```powershell
   if ($IsLinux) {
     function Get-WmiObject { throw "Use Get-CimInstance instead" }
     function Out-GridView { param($x) throw "GridView not available" }
   }
   ```

   * Include this at the top of every public script via `Requires -Module CompatShim`.
   * Part 1 & Part 3.2: Implements the CompatShim.psm1 as a “constitutional” fallback layer. Public scripts Requires it, so any unsupported call errors early.
   * Compliance Check: Uses the manifest’s RequiredModules and “private data” clauses to declare and enforce platform compatibility.

4. **Containerized Smoke Tests**

   * Spin up Windows Server Core and Ubuntu containers in CI to run fastest smoke-tests (FastPath export) in under 30 seconds each. This ensures your basic `Export-SystemInfo` cmdlet works in each OS host before deep Pester runs.
   * Part 2 (Pipeline Definition) & Part 3.4: Runs a FastPath export inside both Windows Server Core and Ubuntu containers before full Pester runs.
   * Compliance Check: Provides a quick CI feedback loop that aligns with the “fast-path” testing pattern in GuardRails

5. **Automated “Forward‐Port” Backports**

   * Maintain a “branches/5.1” branch where any Core-only code must be back-ported manually. Use a GitHub Action that listens for PRs merging into `main` and auto-opens a backport PR to `branches/5.1` when files contain `[Requires -Version 7.0]` or `using module` statements.
   * Part 4.1 & Part 6.2 (Meta-Prompt / Self-Correction): Automating backports ensures that Core-only code is never accidentally merged without 5.1 support. The pre-merge AI self-check will refuse to proceed if backport PRs aren’t open.
   * Compliance Check: Embeds into the adaptive collaboration lifecycle, preventing drift between main and 5.1 branches.
   

