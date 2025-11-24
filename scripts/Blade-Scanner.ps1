param(
  [string]$Root = 'D:\SOVEREIGN-2025-11-19',
  [string]$OutFile = 'C:\EliteTruthEngine\manifest.txt',
  [int]$MaxMB = 5
)
# Walk root, collect small-ish text like files for indexing. v0.1
$extensions = '.md','.txt','.log','.yml','.yaml','.json'
$files = Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $extensions -contains $_.Extension.ToLower() -and ($_.Length/1MB) -le $MaxMB }

"# Blade Scanner manifest generated $(Get-Date -Format o)" | Out-File $OutFile -Encoding UTF8
$files | ForEach-Object { $_.FullName } | Out-File $OutFile -Encoding UTF8 -Append
Write-Host "Manifest written: $OutFile (files: $($files.Count))" -ForegroundColor Green
