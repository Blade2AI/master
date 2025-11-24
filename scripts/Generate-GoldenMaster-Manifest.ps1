param(
  [string]$Root = 'D:\SOVEREIGN-2025-11-19',
  [string]$OutFile = 'D:\SOVEREIGN-2025-11-19\HASH_MANIFESTS\MASTER_SNAPSHOT.json'
)
# Create hash manifest (SHA256) for all files under Golden Master root.
if (-not (Test-Path $Root)) { Write-Error "Root not found: $Root"; exit 1 }
$destDir = Split-Path $OutFile -Parent
if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }

$items = Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue
$result = @()
foreach ($f in $items) {
  $hash = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
  $rel = $f.FullName.Substring($Root.Length).TrimStart('\\')
  $result += [pscustomobject]@{ path = $rel; sha256 = $hash; bytes = $f.Length }
}

[pscustomobject]@{
  generated = (Get-Date -Format o)
  root = $Root
  file_count = $result.Count
  total_bytes = ($result | Measure-Object -Property bytes -Sum).Sum
  files = $result
} | ConvertTo-Json -Depth 5 | Out-File $OutFile -Encoding UTF8
Write-Host "Golden Master manifest written: $OutFile" -ForegroundColor Green
