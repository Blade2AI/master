# AIOutputHasher.psm1
# Writes AI output to NAS and logs a SHA-256 hash for each artifact.

function Initialize-AIOutputRoot {
    [CmdletBinding()]
    param(
        [string]$RootPath = "\\NAS01\Sovereign\ai_output"
    )

    if (-not (Test-Path $RootPath)) {
        New-Item -ItemType Directory -Force -Path $RootPath | Out-Null
    }

    $logDir = Join-Path $RootPath "logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    }

    return @{
        RootPath = $RootPath
        LogPath  = Join-Path $logDir "ai_output_log.jsonl"
    }
}

function Write-AIOutputWithHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Purpose,          # e.g. "ValuationPromptDraft", "SafeModeSpec", "InvestorMemo"

        [string]$SourceAgent = "GPT-5.1-Thinking",  # or "Boardroom-13", etc.
        [string]$Context     = "",                  # short description of conversation or task
        [string]$RootPath    = "\\NAS01\Sovereign\ai_output"
    )

    $envInfo = Initialize-AIOutputRoot -RootPath $RootPath

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $isoTime   = Get-Date -Format "o"
    $node      = $env:COMPUTERNAME

    # Create date-based folder: ai_output/YYYY-MM-DD/
    $dateFolder = Join-Path $envInfo.RootPath (Get-Date -Format "yyyy-MM-dd")
    if (-not (Test-Path $dateFolder)) {
        New-Item -ItemType Directory -Force -Path $dateFolder | Out-Null
    }

    # File name: PURPOSE_timestamp_node.txt
    $safePurpose = $Purpose -replace '[^a-zA-Z0-9_\-]', '_'
    $fileName    = "{0}_{1}_{2}.txt" -f $safePurpose, $timestamp, $node
    $filePath    = Join-Path $dateFolder $fileName

    $Content | Set-Content -Path $filePath -Encoding UTF8

    # Compute hash
    $hash = Get-FileHash -Path $filePath -Algorithm SHA256

    # Prepare log entry
    $entry = [ordered]@{
        timestamp_iso = $isoTime
        node          = $node
        purpose       = $Purpose
        source_agent  = $SourceAgent
        context       = $Context
        file_path     = $filePath
        hash_algo     = $hash.Algorithm
        hash_value    = $hash.Hash
    }

    $jsonLine = ($entry | ConvertTo-Json -Depth 4 -Compress)

    # Append to JSONL ledger
    $logPath = $envInfo.LogPath
    Add-Content -Path $logPath -Value $jsonLine

    Write-Host "AI output written and hashed." -ForegroundColor Green
    Write-Host "File: $filePath" -ForegroundColor Cyan
    Write-Host "SHA256: $($hash.Hash)" -ForegroundColor Yellow

    return $entry
}

Export-ModuleMember -Function *
