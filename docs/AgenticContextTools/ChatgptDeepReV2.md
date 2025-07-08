Understood. I will now expand the Model-Centric Document (MCD) for `MyExporter`, continuing through Sections 3 to 6. This will integrate environment discovery, dynamic context awareness, and task orchestration guidance across platforms and shells.

I’ll return shortly with a structured, detailed continuation that builds on the Unified Architecture and the execution-aware bootstrap system you provided.


# Environment Context Discovery for Claude’s Execution

**Problem:** By default, *Claude* (the AI assistant) is “blind” to the execution environment. It doesn’t inherently know critical context such as:

* **Shell Type:** Which shell is running (Bash, PowerShell, CMD, etc.)
* **Active Virtual Environments:** e.g. Python venv or Conda environment
* **Installed Modules/Packages:** What libraries or modules are accessible
* **System PATH Contents:** Which directories and executables are on the PATH
* **Operating Platform:** Whether it’s in Windows, Linux, macOS, or WSL
* **Permissions:** What level of privileges or restrictions are in place

Without this knowledge, Claude might run into errors or incorrect assumptions when executing tasks across different setups. To solve this, we propose an **Environmental Context Discovery Framework** that allows Claude to **discover, not assume**, the details of its environment. This framework consists of several components and steps as outlined below.

## 1. Automatic Environment Detection (Bootstrap Script)

The first step is a **bootstrap discovery script** (e.g. `bootstrap-env.ps1`) that Claude runs at the very beginning of any session. This script gathers information about the current shell, platform, environment variables, and available commands, then saves it for reference.

Key tasks of the bootstrap script include: identifying the shell (Bash, PowerShell, or CMD), determining the OS platform (Windows, Linux, macOS, or WSL), detecting if running under WSL (Windows Subsystem for Linux), checking for any active Python/Conda virtual environment, and probing common tool availability (`python`, `node`, `git`, etc.).

Below is an example PowerShell implementation of the bootstrap script:

```powershell
# bootstrap-env.ps1 – Claude runs this first, always
function Get-ExecutionContext {
    $Context = @{
        Shell = $null
        Platform = $null
        WorkingDirectory = $PWD
        VirtualEnv = $null
        AvailableCommands = @{}
        ModulePath = @()
        PythonPath = @()
        NodePath = @()
        Timestamp = Get-Date
    }

    # Detect shell
    if ($env:SHELL -match 'bash') { $Context.Shell = 'bash' }
    elseif ($PSVersionTable)     { $Context.Shell = 'pwsh' }   # PowerShell Core
    elseif ($env:PROMPT)         { $Context.Shell = 'cmd' }

    # Detect platform (OS)
    if ($IsWindows) { $Context.Platform = 'Windows' }
    elseif ($IsLinux) { $Context.Platform = 'Linux' }
    elseif ($IsMacOS) { $Context.Platform = 'macOS' }

    # Detect WSL specifically (check if running under Windows Subsystem for Linux)
    if ((Get-Content /proc/version -ErrorAction SilentlyContinue) -match 'microsoft|wsl') {
        $Context.Platform = 'WSL'
    }

    # Detect active Python virtual environments
    if ($env:VIRTUAL_ENV)       { $Context.VirtualEnv = $env:VIRTUAL_ENV }
    if ($env:CONDA_DEFAULT_ENV) { $Context.VirtualEnv = $env:CONDA_DEFAULT_ENV }

    # Probe for availability of common commands
    $ProbeCommands = @('python', 'python3', 'node', 'npm', 'docker', 'git', 'pwsh', 'powershell')
    foreach ($cmd in $ProbeCommands) {
        $path = Get-Command $cmd -ErrorAction SilentlyContinue
        if ($path) {
            $Context.AvailableCommands[$cmd] = $path.Source
        }
    }

    # Record module and library paths
    if ($env:PSModulePath) { 
        $Context.ModulePath = $env:PSModulePath -split [IO.Path]::PathSeparator 
    }
    if ($env:PYTHONPATH)   { 
        $Context.PythonPath = $env:PYTHONPATH -split [IO.Path]::PathSeparator 
    }

    return $Context
}

# Execute and save context for Claude to reference later
$ExecutionContext = Get-ExecutionContext
$ExecutionContext | Export-Clixml "$env:TEMP/claude-context.xml"
```

**How it works:** When this script runs, it creates a hashtable `$Context` capturing all relevant info. For instance, to detect WSL, it checks the Linux kernel version string for “Microsoft/WSL” markers (a known reliable method to identify WSL). It also checks for a Python virtual environment by looking for the `$VIRTUAL_ENV` variable (set when a venv is activated) and for Conda by checking `$CONDA_DEFAULT_ENV` (Conda sets this on environment activation). The script uses `Get-Command` to see if certain executables are available in the PATH, storing their resolved paths if found. Finally, the context is exported to an XML file (e.g. in the temp directory) so that subsequent steps and commands can load this context and make decisions based on it.

This **automatic discovery** means Claude starts each session with a snapshot of the environment’s state – effectively giving it eyes on details that would otherwise be unknown.

## 2. Dynamic Path Resolution

The next piece is a **dynamic path resolver** function (e.g. `Resolve-ExecutionPath`) that helps Claude locate commands or resources without hardcoding paths. Instead of assuming a fixed installation path for tools, this function uses the discovered context and some smart guessing to find where a given command might be, regardless of platform differences.

```powershell
# path-resolver.ps1
function Resolve-ExecutionPath {
    param(
        [string] $Command, 
        [string] $PreferredPath = $null
    )

    $Context = Import-Clixml "$env:TEMP/claude-context.xml"

    # If command was found in the initial context, use that known path
    if ($Context.AvailableCommands.ContainsKey($Command)) {
        return $Context.AvailableCommands[$Command]
    }

    # If a preferred path is provided and exists, use it
    if ($PreferredPath -and (Test-Path $PreferredPath)) {
        return $PreferredPath
    }

    # Platform-specific fallback logic
    switch ($Context.Platform) {
        'WSL' {
            # In WSL, try converting a Linux path to Windows path (for Windows executables)
            $WindowsPath = wslpath -w $Command 2>$null
            if ($WindowsPath -and (Test-Path $WindowsPath)) {
                return $WindowsPath
            }
        }
        'Windows' {
            # On Windows, check common installation directories for the command
            $CommonPaths = @(
                "$env:ProgramFiles\$Command",
                "$env:ProgramFiles(x86)\$Command",
                "$env:LOCALAPPDATA\$Command"
            )
            foreach ($path in $CommonPaths) {
                if (Test-Path $path) { return $path }
            }
        }
    }

    throw "Command '$Command' not found in execution context"
}
```

**Explanation:** This function first checks the `AvailableCommands` map from the context for a direct hit (meaning the `bootstrap-env` script already found the command’s path). If not, it uses a provided hint (`$PreferredPath`) if available. Then it falls back to logic depending on platform:

* **WSL:** In a WSL environment, the script attempts to find a corresponding Windows path using `wslpath -w`. This accounts for scenarios where Claude (running in WSL) might need to invoke a Windows executable by converting paths from Linux format to Windows format.
* **Windows:** On Windows, it searches in standard locations like **Program Files**, **Program Files (x86)**, or **LocalAppData** for the executable’s folder. This is useful if a tool isn’t on the PATH but is installed in a typical location.

By resolving paths dynamically, Claude avoids using fixed paths. This aligns with PowerShell best practices to **avoid hard-coded paths and instead check for resources or use environment variables**. It improves portability since the script adapts to where things are actually installed on the system rather than assuming a one-size-fits-all path.

## 3. Dependency Validation

Before executing complex tasks, it’s wise to verify that all required tools and modules are present. The **dependency validator** (e.g. `Test-Dependencies` function) checks for the presence of required external commands and PowerShell modules, and provides a clear report of what’s missing along with suggestions on how to install them.

```powershell
# dependency-validator.ps1
function Test-Dependencies {
    param(
        [string[]] $RequiredCommands, 
        [string[]] $RequiredModules = @()
    )

    $Context = Import-Clixml "$env:TEMP/claude-context.xml"
    $MissingDeps = @()

    # Check each required command
    foreach ($cmd in $RequiredCommands) {
        if (-not $Context.AvailableCommands.ContainsKey($cmd)) {
            $MissingDeps += "Command: $cmd"
        }
    }

    # Check each required PowerShell module
    foreach ($module in $RequiredModules) {
        if (-not (Get-Module -ListAvailable $module)) {
            $MissingDeps += "Module: $module"
        }
    }

    if ($MissingDeps) {
        # If something is missing, prepare a report including suggestions
        $Report = @{
            Status      = 'Missing Dependencies'
            Missing     = $MissingDeps
            Suggestions = Get-InstallSuggestions $MissingDeps $Context
        }
        return $Report
    }

    # If everything is present, indicate readiness
    return @{ Status = 'Ready'; Missing = @() }
}

function Get-InstallSuggestions {
    param(
        [string[]] $MissingDeps, 
        [hashtable] $Context
    )

    $Suggestions = @()

    foreach ($dep in $MissingDeps) {
        switch -Regex ($dep) {
            'python' {
                if ($Context.Platform -eq 'WSL') {
                    $Suggestions += "sudo apt install python3 python3-pip"
                } else {
                    $Suggestions += "Download from python.org or use winget install Python.Python.3"
                }
            }
            'node' {
                if ($Context.Platform -eq 'WSL') {
                    $Suggestions += "curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt install -y nodejs"
                } else {
                    $Suggestions += "Download from nodejs.org or use winget install OpenJS.NodeJS"
                }
            }
            'Module:' {
                # If a PowerShell module is missing, suggest using Install-Module
                $moduleName = $dep -replace 'Module: ', ''
                $Suggestions += "Install-Module $moduleName -Scope CurrentUser"
            }
        }
    }

    return $Suggestions
}
```

**How it works:** `Test-Dependencies` takes a list of required command names and module names for a given task. It loads the saved context (from `claude-context.xml`) to see which commands were available. If any required command isn’t in `AvailableCommands`, it flags it as missing. Similarly, it checks for each PowerShell module (with `Get-Module -ListAvailable`) and flags missing ones.

If nothing is missing, it returns a status `"Ready"`. If there are missing dependencies, it uses `Get-InstallSuggestions` to generate human-friendly suggestions on how to install each missing item, tailored to the platform:

* For example, if **Python** is missing, it suggests either using apt (on WSL/Linux) or downloading from python.org / using Winget (on Windows).
* If **Node.js** is missing, it suggests the NodeSource setup script on Linux vs. the official download or Winget on Windows.
* If a **PowerShell module** is missing, it suggests the `Install-Module <Name> -Scope CurrentUser` command.

The output could be a structured object, e.g., indicating `Status: "Missing Dependencies"`, listing `Missing: ["Command: python", "Module: AzureAD"]`, and `Suggestions: [...]` for how to get them installed. This proactive check ensures Claude doesn’t blindly proceed when something crucial is unavailable. It’s a form of “pre-flight check,” improving reliability by handling missing prerequisites up front.

## 4. Smart Environment Setup

After validating dependencies, the next step is to **initialize and configure the working environment** for the specific project or task. This involves activating virtual environments or loading modules as needed. The function `Initialize-WorkingEnvironment` automates this setup by detecting project type and applying environment-specific initialization:

```powershell
# environment-setup.ps1
function Initialize-WorkingEnvironment {
    param([string] $ProjectType = 'Auto')

    $Context = Import-Clixml "$env:TEMP/claude-context.xml"

    # Auto-detect project type if not explicitly provided
    if ($ProjectType -eq 'Auto') {
        if    (Test-Path 'requirements.txt') { $ProjectType = 'Python' }
        elseif(Test-Path 'package.json')    { $ProjectType = 'Node' }
        elseif(Test-Path '*.psd1')         { $ProjectType = 'PowerShell' }
    }

    switch ($ProjectType) {
        'Python' {
            # If a Python virtual environment exists, activate it
            if (Test-Path '.venv/Scripts/Activate.ps1') {
                & .venv/Scripts/Activate.ps1
                Write-Host "Activated Python virtual environment" -ForegroundColor Green
            }
            elseif (Test-Path '.venv/bin/activate') {
                & .venv/bin/activate    # For Linux/macOS virtual env activate script
                Write-Host "Activated Python virtual environment" -ForegroundColor Green
            }
            else {
                Write-Warning "No virtual environment found. Consider creating one with: python -m venv .venv"
            }
        }
        'Node' {
            # If a Node.js project and an .nvmrc is present, try to use nvm to switch Node versions
            if (Test-Path '.nvmrc') {
                if (Get-Command nvm -ErrorAction SilentlyContinue) {
                    nvm use
                    Write-Host "Activated Node version from .nvmrc" -ForegroundColor Green
                }
            }
        }
        'PowerShell' {
            # If a PowerShell project, check for a requirements file listing required modules
            if (Test-Path 'requirements.psd1') {
                $Requirements = Import-PowerShellDataFile 'requirements.psd1'
                foreach ($module in $Requirements.RequiredModules) {
                    if (-not (Get-Module -ListAvailable $module)) {
                        Write-Host "Installing missing module: $module" -ForegroundColor Yellow
                        Install-Module $module -Scope CurrentUser -Force
                    }
                }
            }
        }
    }

    # After setup, refresh the context to capture any changes (e.g., activated venv)
    $Context = Get-ExecutionContext
    $Context | Export-Clixml "$env:TEMP/claude-context.xml"
}
```

**Details:** This function tries to simplify environment setup in a variety of scenarios:

* If the project appears to be **Python** (detected by a `requirements.txt` file), it looks for a local virtual environment. By convention, if a project has a `.venv` folder, it will try to activate it. The script checks both Windows-style path (`.venv/Scripts/Activate.ps1`) and POSIX-style (`.venv/bin/activate`) to handle virtual environments on Windows vs. Linux/macOS. If found, it activates the venv (so that the correct Python interpreter and libraries are used) and prints a confirmation. If no venv is found, it issues a warning suggesting to create one (this nudges the user toward best practice of isolating Python deps).
* If the project is **Node.js** (indicated by `package.json`), it looks for an `.nvmrc` file. If present, and if Node Version Manager (nvm) is available, it runs `nvm use` to switch to the Node version specified in the project. This ensures the Node environment matches the project’s expected version.
* If the project is a **PowerShell module/script** (e.g., presence of a PowerShell module manifest `*.psd1` or a requirements file), it tries to ensure required PowerShell modules are installed. The example shows reading a `requirements.psd1` (which could list module dependencies in a structured way) and installing any that are missing via `Install-Module`.

After making these adjustments, it calls `Get-ExecutionContext` again to refresh the context data. This is important because the environment may have changed (for example, after activating a Python venv, the PATH and `VIRTUAL_ENV` have changed, or after loading modules, new commands are available). By updating and re-saving `claude-context.xml`, subsequent steps or commands will have an up-to-date view of the environment.

Overall, this automated setup means Claude can **adapt to the project on-the-fly**. If a user opens a Python project, Claude will automatically activate the venv (if available) rather than using the global Python environment. If it’s a Node project, it ensures the right Node version. This reduces manual setup overhead and errors.

## Integration with Claude’s Workflow

With the above components in place (environment discovery, path resolving, dependency checking, and auto-setup), we need to integrate this framework into Claude’s overall workflow. The idea is to *always* perform environment discovery and preparation steps before attempting the actual user task. This can be done by structuring Claude’s internal prompt or command sequence to include these steps every time.

A **modified prompt template** or workflow could look like:

* **CONTEXT\_DISCOVERY:** Always run the `bootstrap-env.ps1` script first to gather environment context.
* **DEPENDENCY\_CHECK:** Next, validate that required tools are present by calling `Test-Dependencies` with the specific commands or modules needed for the task.
* **ENVIRONMENT\_SETUP:** Then, call `Initialize-WorkingEnvironment` (with auto-detection or a specified project type) to activate any virtual environments or load necessary modules.
* **EXECUTION\_CONTEXT:** Throughout execution, always reference the updated `claude-context.xml` for decisions on paths or environment-specific logic (via the `Resolve-ExecutionPath` helper and the context info).

In practice, Claude’s internal workflow for any task could be scripted as follows:

```powershell
# Claude's internal workflow for a new task/request
& bootstrap-env.ps1             # 1. Discover current environment and context
$deps = Test-Dependencies -RequiredCommands @('python', 'node')   # 2. Check key dependencies (example)
if ($deps.Status -eq 'Missing Dependencies') {
    # 3. If anything is missing, inform the user and suggest installation, then stop
    Write-Host "Missing: $($deps.Missing -join ', ')"
    Write-Host "Suggestions: $($deps.Suggestions -join '; ')"
    return   # halt further execution until dependencies are resolved
}
Initialize-WorkingEnvironment -ProjectType Auto   # 4. Prepare environment (auto-detect project type)
# 5. Proceed with the actual user task, now that environment is ready...
```

In this example, before doing the “real” work, Claude ensures it is in the right state. If dependencies are missing, it doesn’t blindly continue; it provides a message about what’s missing and how to fix it (which could be relayed to the user, perhaps as an error or help message). Only if the status is ready does it move on to run the user’s commands or code. This approach is analogous to how a cautious engineer works: check the environment, load the right tools, verify prerequisites, then execute. It makes Claude’s behavior more **robust and context-aware**.

## Natural Knowledge Integration

One powerful extension of this framework is to have Claude **remember and learn from the environment** over time. Rather than treating each session as isolated, Claude can persist context information and even accumulate knowledge of patterns across projects and environments. This helps it make smarter decisions in the future without always starting from scratch.

### Context Persistence Across Sessions

To avoid repeating the full environment discovery every single time or to carry forward knowledge (like where certain tools are located), Claude can save the context data to a more permanent location (for example, in the user’s profile directory) at the end of a session, and load it at the start of the next session.

For instance, after running the discovery and setup, we could save the context to a JSON file in Claude’s config:

```powershell
# Save context across sessions (e.g., at session end or periodically)
$ContextFile = "$env:USERPROFILE/.claude/session-context.json"
$Context | ConvertTo-Json | Out-File $ContextFile
```

When a new session starts, Claude could check if this file exists and load it to pre-populate its context. Persistent context means that if a user installed a new tool or changed something in the environment in a previous session, Claude “remembers” it next time. This caching can make the discovery phase faster and allow Claude to notice changes or trends (for example, if a user always works in a Python venv named `.venv`).

### Learning from the Environment Patterns

Over time, Claude can build a simple internal knowledge base of environment patterns and preferred settings. This could be a hard-coded table or learned dynamically. For example:

```powershell
# Build knowledge base of environment patterns
$KnowledgeBase = @{
    "WSL + Python" = @{
        VirtualEnvPath  = ".venv/bin/activate"
        InstallCommand  = "sudo apt install python3-pip"
        PathSeparator   = ":"
    }
    "Windows + Python" = @{
        VirtualEnvPath  = ".venv/Scripts/Activate.ps1"
        InstallCommand  = "py -m pip install"
        PathSeparator   = ";"
    }
    # ... (could include Node, PowerShell, etc., and Linux/macOS variants)
}
```

In this hypothetical `$KnowledgeBase`, Claude knows that when running in **WSL with a Python project**, the typical conventions are: the Python virtual environment activation script is at `.venv/bin/activate`, installing Python packages uses apt/PIP on Linux, and the PATH separator is `:`. Whereas on **Windows with Python**, the venv activation is a PowerShell script under `Scripts`, package installation might use the `py -m pip` command (or Chocolatey/Winget for Python itself), and the PATH separator is `;`. Similar entries could be made for Node on Windows vs WSL (different install instructions or nvm usage), or other frameworks.

This knowledge base can be consulted to give more tailored advice or actions. For example, `Get-InstallSuggestions` could leverage it: if Python is missing and the platform is WSL, it already suggests `apt install python3-pip`, which matches the knowledge base. If the environment was macOS, a suggestion might be `brew install python` (which could be another entry in the knowledge base).

By learning these patterns, Claude’s assistance becomes smarter and more **natural** – it behaves like an experienced user who knows the quirks of each platform. It can proactively adjust its strategies (like which command to run or which path to look in) based on past knowledge.

## Making It Natural

The key insight of this framework is that **Claude should discover, not assume**. Instead of hardcoding environment assumptions, the architecture relies on detection and adapts dynamically. This makes interactions more natural and error-resistant.

By combining automatic discovery, environment-specific adjustments, and memory of past contexts, Claude can smoothly handle tasks in diverse scenarios. It knows, for example, when to use `./venv/bin/activate` versus a Windows activation script, or when to suggest `apt-get` versus `winget` for installing a missing tool. All of this happens because Claude is systematically **aware of its surroundings** and even retains knowledge over time.

In summary, this environment discovery framework transforms Claude from a one-size-fits-all script runner into a context-sensitive assistant. It ensures reliability and portability by minimizing fixed assumptions (a known best practice for scripts), verifying conditions before acting, and continuously learning about the user’s system. By discovering the environment and adjusting accordingly, Claude can execute user requests **more confidently and efficiently**, providing a seamless experience regardless of where it’s running.
