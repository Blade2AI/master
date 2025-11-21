param(
  [Parameter(Mandatory=$true)][string]$FilePath,
  [string]$OutPath = "",
  [switch]$Force,
  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
function Emit($msg){ if(-not $Quiet){ Write-Host $msg } }
if(-not (Test-Path $FilePath)){ throw "Target file not found: $FilePath" }
$resolved = (Resolve-Path $FilePath).Path
if(-not $OutPath){ $OutPath = "$resolved.hash.txt" }

# Compute new hash
$hf = Get-FileHash -Algorithm SHA256 -LiteralPath $resolved
$newHash = $hf.Hash
$size = (Get-Item -LiteralPath $resolved).Length
$timestamp = (Get-Date).ToString('o')

# Read existing hash (if any)
$prevHash = ''
if(Test-Path $OutPath){
  try {
    $prevHash = (Get-Content -LiteralPath $OutPath -ErrorAction SilentlyContinue | Select-String -Pattern '^SHA256=' -SimpleMatch | ForEach-Object { ($_ -split '=')[1] })[0]
  } catch { $prevHash = '' }
  if($prevHash -and $prevHash -eq $newHash -and -not $Force){ Emit "Hash unchanged. Use -Force to rewrite."; return }
}

# Build lines
$lines = @(
  "FILE=$resolved",
  "SHA256=$newHash",
  "SIZE_BYTES=$size",
  "TIMESTAMP=$timestamp",
  "PREVIOUS_SHA256=$prevHash"
)
$lines | Out-File -LiteralPath $OutPath -Encoding UTF8 -Force
Emit "Ledger sealed: $OutPath"
Emit "SHA256: $newHash"