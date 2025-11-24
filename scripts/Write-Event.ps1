param (
    [Parameter(Mandatory=$true)][string]$EventType,
    [Parameter(Mandatory=$true)][hashtable]$Payload,
    [string]$ConfigPath = 'config/recorder_config.yaml'
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $ConfigPath)) { throw "Recorder config not found: $ConfigPath" }
try { $config = Get-Content $ConfigPath -Raw | ConvertFrom-Yaml } catch { throw "YAML parsing failed. Ensure PowerShell 7." }

$event = [ordered]@{
    event_id = [guid]::NewGuid().ToString()
    event_type = $EventType
    schema_version = $config.schema_version
    node_id = $config.node_id
    timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    payload = $Payload
}

# Temp file for validation
$tempFile = Join-Path ([System.IO.Path]::GetTempPath()) ("rec_evt_" + [guid]::NewGuid().ToString() + '.json')
$event | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath $tempFile -Encoding UTF8

# Determine schema name from event_type mapping
$schemaName = $EventType
$validatorPath = 'agi/core/validate_event.py'
if(Test-Path $validatorPath){
  python $validatorPath --schema $schemaName --file $tempFile
  if($LASTEXITCODE -ne 0){ throw "Schema validation failed for event_type=$EventType" }
} else {
  Write-Host "[WARN] Python validator missing ($validatorPath). Skipping schema validation." -ForegroundColor Yellow
}
Remove-Item $tempFile -ErrorAction SilentlyContinue

$ledger = $config.ledger_path
$dir = Split-Path -Parent $ledger
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
$jsonLine = $event | ConvertTo-Json -Depth 10 -Compress
Add-Content -LiteralPath $ledger -Value $jsonLine -Encoding utf8
Write-Host "[RECORDER] Event logged: $EventType id=$($event.event_id)" -ForegroundColor Cyan
