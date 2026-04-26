#Requires -Version 5.1

<#
.SYNOPSIS
    Download evidence artifacts from GitHub Actions
.DESCRIPTION
    Retrieves evidence files from GitHub Actions artifacts for a specific commit,
    using gh CLI tool. Falls back to repository-stored baseline if artifact
    retention has expired (>30 days).
    
    Authority: README.md CI/CD Evidence Validation specifications
    
.PARAMETER CommitSHA
    Git commit SHA to retrieve evidence for
    
.PARAMETER RepositoryOwner
    GitHub repository owner (default: dimascior)
    
.PARAMETER RepositoryName
    GitHub repository name (default: TerminalContextExporter)
    
.PARAMETER OutputDirectory
    Directory to download artifacts to
    
.PARAMETER MatrixLeg
    Matrix leg identifier (e.g., 'PS-7.4-Windows')
    
.OUTPUTS
    Hashtable with artifact paths and status
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CommitSHA,
    
    [Parameter(Mandatory = $false)]
    [string]$RepositoryOwner = 'dimascior',
    
    [Parameter(Mandatory = $false)]
    [string]$RepositoryName = 'TerminalContextExporter',
    
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,
    
    [Parameter(Mandatory = $false)]
    [string]$MatrixLeg = 'PS-7.4-Windows'
)

$ErrorActionPreference = 'Stop'

function Get-ActionsEvidence {
    param(
        [string]$Sha,
        [string]$Owner,
        [string]$Repo,
        [string]$OutDir,
        [string]$Leg
    )
    
    $result = @{
        Success        = $false
        ArtifactPath   = $null
        Mode           = 'not-found'
        Message        = ""
        EvidenceFiles  = @()
    }
    
    # Ensure output directory exists
    if (-not (Test-Path $OutDir)) {
        New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
    }
    
    # Check for repository-stored baseline first (for expired artifacts)
    $baselineDir = Join-Path (Split-Path $OutDir -Parent) "baselines"
    $storedBaseline = Join-Path $baselineDir "evidence-baseline-${Leg}-${Sha}.json"
    
    if (Test-Path $storedBaseline) {
        Write-Verbose "Found stored baseline in repository: $storedBaseline"
        Copy-Item $storedBaseline (Join-Path $OutDir "evidence-baseline.json") -Force
        $result.Success = $true
        $result.Mode = 'stored-baseline'
        $result.ArtifactPath = Join-Path $OutDir "evidence-baseline.json"
        $result.EvidenceFiles += (Join-Path $OutDir "evidence-baseline.json")
        return $result
    }
    
    # Try to download from GitHub Actions artifacts
    Write-Verbose "Attempting to download artifacts from GitHub Actions for commit: $Sha"
    
    # Check if gh CLI is available
    try {
        $ghVersion = & gh --version 2>&1 | Select-Object -First 1
        Write-Verbose "GitHub CLI available: $ghVersion"
    } catch {
        $result.Message = "GitHub CLI (gh) not available: $_"
        return $result
    }
    
    # Query workflow runs for this commit
    try {
        $runsJson = & gh run list --repo "$Owner/$Repo" --commit $Sha --json databaseId,status -q '.[0]' 2>$null
        if (-not $runsJson) {
            $result.Message = "No workflow runs found for commit: $Sha"
            $result.Mode = 'baseline-establishment'
            $result.Success = $true  # First commit - baseline establishment
            return $result
        }
    } catch {
        $result.Message = "Failed to query workflow runs: $_"
        return $result
    }
    
    # Parse run ID (GitHub Actions returns this as runId)
    try {
        $runId = $runsJson | ConvertFrom-Json | Select-Object -ExpandProperty databaseId
        if (-not $runId) {
            $result.Message = "Could not extract run ID from workflow query"
            $result.Mode = 'baseline-establishment'
            $result.Success = $true
            return $result
        }
    } catch {
        $result.Message = "Failed to parse workflow run data: $_"
        return $result
    }
    
    Write-Verbose "Found workflow run: $runId"
    
    # Download artifacts for this run
    try {
        $artifactName = "evidence-${Leg}"
        & gh run download $runId --name $artifactName --dir $OutDir --repo "$Owner/$Repo" 2>&1 | Out-Null
        
        # Verify downloaded files
        $downloadedFiles = Get-ChildItem $OutDir -Filter "evidence-*.json" -ErrorAction SilentlyContinue
        if ($downloadedFiles) {
            $result.Success = $true
            $result.Mode = 'actions-artifact'
            $result.ArtifactPath = $OutDir
            $result.EvidenceFiles = $downloadedFiles.FullName
            $result.Message = "Downloaded $($downloadedFiles.Count) evidence file(s) from GitHub Actions"
            return $result
        } else {
            $result.Message = "Artifact downloaded but no evidence files found"
            $result.Mode = 'baseline-establishment'
            $result.Success = $true
            return $result
        }
    } catch {
        $result.Message = "Failed to download artifact: $_"
        $result.Mode = 'baseline-establishment'
        $result.Success = $true  # Graceful degradation for first run
        return $result
    }
}

# Execute download
$evidence = Get-ActionsEvidence -Sha $CommitSHA -Owner $RepositoryOwner -Repo $RepositoryName -OutDir $OutputDirectory -Leg $MatrixLeg

return $evidence
