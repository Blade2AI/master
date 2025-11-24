<#
.SYNOPSIS
Invoke Bundlr CLI to anchor a manifest (and optional extra files).

- Respects -DryRun (no network calls).
- Guards against oversized manifests.
- Retries transient failures with backoff.
- Extracts TxId via JSON or regex.
- Always returns a consistent object:
  Status, File, TxId, RawOutput, Error, Attempts, ResultsFile.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,

    [string[]]$ExtraFiles,

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Invoke-ArweaveAnchor (Bundlr) ===" -ForegroundColor Cyan
Write-Host "Manifest : $ManifestPath"
Write-Host "DryRun   : $($DryRun.IsPresent)"

if (-not (Test-Path $ManifestPath)) {
    throw "Manifest not found: $ManifestPath"
}

# Size guard – don’t accidentally upload a full ledger
$manifestInfo = Get-Item $ManifestPath
if ($manifestInfo.Length -gt 1MB) {
    throw "Refusing manifest > 1MB (size = $($manifestInfo.Length) bytes)."
}

# Dry run → no network calls at all
if ($DryRun) {
    Write-Host "[DRY-RUN] Skipping Bundlr upload." -ForegroundColor Yellow
    $fakeTx = "dryrun-" + (Get-Date -Format "yyyyMMddHHmmss")
    $resultsFile = "$ManifestPath.bundlr_result.json"

    $obj = [PSCustomObject]@{
        Status      = "DRYRUN"
        File        = $ManifestPath
        TxId        = $fakeTx
        RawOutput   = "Dry-run only – no Bundlr call performed."
        Error       = $null
        Attempts    = 0
        ResultsFile = $resultsFile
    }

    $obj | ConvertTo-Json -Depth 10 | Set-Content $resultsFile -Encoding UTF8
    Write-Host "[INFO] Dry-run results written to $resultsFile" -ForegroundColor Cyan
    return $obj
}

# Env guards
if (-not $env:BUNDLR_CURRENCY -or -not $env:BUNDLR_NODE_URL) {
    throw "Bundlr env not configured. Require BUNDLR_CURRENCY and BUNDLR_NODE_URL."
}

if ($env:BUNDLR_KEYFILE -and -not (Test-Path $env:BUNDLR_KEYFILE)) {
    throw "Bundlr key file not found: $($env:BUNDLR_KEYFILE)"
}

# Bundlr CLI presence
if (-not (Get-Command bundlr -ErrorAction SilentlyContinue)) {
    throw "Bundlr CLI not found on PATH (expected 'bundlr' executable)."
}

# Build payload list: manifest + optional extra files
$payloads = @(
    [PSCustomObject]@{
        Path = (Resolve-Path $ManifestPath).Path
        Type = "manifest"
    }
)

if ($ExtraFiles) {
    foreach ($f in $ExtraFiles) {
        if (-not (Test-Path $f)) {
            Write-Host "[WARN] Extra file does not exist, skipping: $f" -ForegroundColor DarkYellow
            continue
        }
        $payloads += [PSCustomObject]@{
            Path = (Resolve-Path $f).Path
            Type = "extra"
        }
    }
}

$results  = @()
$tempDir  = [System.IO.Path]::GetTempPath()

foreach ($payload in $payloads) {
    Write-Host ""
    Write-Host "[INFO] Anchoring via Bundlr: $($payload.Path)" -ForegroundColor Cyan

    $status    = "ERROR"
    $txId      = $null
    $rawOutput = $null
    $errorMsg  = $null
    $attempts  = 0

    # Retry with exponential backoff (3 attempts)
    for ($i = 0; $i -lt 3; $i++) {
        $attempts = $i + 1

        $outFile = Join-Path $tempDir ("bundlr_out_{0}.txt" -f ([guid]::NewGuid()))
        $errFile = Join-Path $tempDir ("bundlr_err_{0}.txt" -f ([guid]::NewGuid()))

        $cmd = @(
            "bundlr", "upload",
            $payload.Path,
            "-c", $env:BUNDLR_CURRENCY,
            "-h", $env:BUNDLR_NODE_URL,
            "--json",
            "--tags", "Content-Type:application/json"
        )

        if ($env:BUNDLR_KEYFILE) {
            $cmd += @("-w", $env:BUNDLR_KEYFILE)
        }

        Write-Host "[DEBUG] Attempt $attempts: $($cmd -join ' ')" -ForegroundColor DarkGray

        $proc = Start-Process -FilePath $cmd[0] `
                              -ArgumentList $cmd[1..($cmd.Count-1)] `
                              -NoNewWindow -Wait -PassThru `
                              -RedirectStandardOutput $outFile `
                              -RedirectStandardError  $errFile

        $rawOutput = ""
        $errorMsg  = ""

        if (Test-Path $outFile) {
            $rawOutput = Get-Content $outFile -Raw
        }
        if (Test-Path $errFile) {
            $errorMsg = Get-Content $errFile -Raw
        }

        Remove-Item $outFile,$errFile -ErrorAction SilentlyContinue

        if ($proc.ExitCode -eq 0) {
            # Try JSON first
            try {
                if ($rawOutput) {
                    $jsonOut = $rawOutput | ConvertFrom-Json
                    if ($jsonOut.id) {
                        $txId = $jsonOut.id
                    }
                }
            }
            catch {
                # JSON parse failed; fall through to regex
            }

            # Fallback: regex for base64url-like token
            if (-not $txId -and $rawOutput) {
                $txMatch = [regex]::Match($rawOutput, '[A-Za-z0-9_-]{43,100}')
                if ($txMatch.Success) {
                    $txId = $txMatch.Value
                }
            }

            $status = "OK"
            Write-Host "[OK] Anchored: $($payload.Path)" -ForegroundColor Green
            if ($txId) {
                Write-Host "TxId: $txId" -ForegroundColor Green
            } else {
                Write-Host "[WARN] Unable to parse TxId from Bundlr output." -ForegroundColor DarkYellow
            }
            break
        }
        else {
            Write-Host "[WARN] Bundlr upload failed (attempt $attempts / 3)" -ForegroundColor Yellow
            if ($errorMsg) {
                Write-Host $errorMsg -ForegroundColor DarkRed
            }

            if ($i -lt 2) {
                $sleep = 2 * [math]::Pow(2, $i)  # 2, 4, 8
                Write-Host "Backing off for $sleep seconds..." -ForegroundColor DarkYellow
                Start-Sleep -Seconds $sleep
            }
        }
    }

    $results += [PSCustomObject]@{
        Status    = $status
        File      = $payload.Path
        TxId      = $txId
        RawOutput = $rawOutput
        Error     = $errorMsg
        Attempts  = $attempts
    }
}

# Persist results next to manifest
$resultsFile = "$ManifestPath.bundlr_result.json"
$results | ConvertTo-Json -Depth 10 | Set-Content $resultsFile -Encoding UTF8
Write-Host "`n[INFO] Results written to $resultsFile" -ForegroundColor Cyan

# Return first payload summary
$first = $results | Select-Object -First 1

return [PSCustomObject]@{
    Status      = $first.Status
    File        = $first.File
    TxId        = $first.TxId
    RawOutput   = $first.RawOutput
    Error       = $first.Error
    Attempts    = $first.Attempts
    ResultsFile = $resultsFile
}
