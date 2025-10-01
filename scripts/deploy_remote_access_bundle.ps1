param(
  [string]$TargetRoot = 'D:\\RemoteAccessBundle',
  [switch]$Zip,
  [string]$ZipPath = 'D:\\RemoteAccessBundle.zip'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Copy-ItemSafe {
  param([string]$Source, [string]$Dest)
  New-Item -ItemType Directory -Path (Split-Path -Parent $Dest) -Force | Out-Null
  Copy-Item -Path $Source -Destination $Dest -Recurse -Force
}

$bundleSrc = Join-Path $PSScriptRoot '..' | Resolve-Path | ForEach-Object { $_.Path }
$bundleSrc = Join-Path $bundleSrc 'bundles/remote-access'
if (-not (Test-Path -LiteralPath $bundleSrc)) { throw "Bundle source not found: $bundleSrc" }

Write-Host "Deploying Remote Access bundle to $TargetRoot" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $TargetRoot -Force | Out-Null

Copy-ItemSafe -Source (Join-Path $bundleSrc '.devcontainer') -Dest (Join-Path $TargetRoot '.devcontainer')
Copy-ItemSafe -Source (Join-Path $bundleSrc '.vscode') -Dest (Join-Path $TargetRoot '.vscode')
Copy-ItemSafe -Source (Join-Path $bundleSrc 'scripts') -Dest (Join-Path $TargetRoot 'scripts')
Copy-Item -Path (Join-Path $bundleSrc 'README.md') -Destination (Join-Path $TargetRoot 'README.md') -Force

if ($Zip) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  if (Test-Path -LiteralPath $ZipPath) { Remove-Item -LiteralPath $ZipPath -Force }
  [System.IO.Compression.ZipFile]::CreateFromDirectory($TargetRoot, $ZipPath)
  Write-Host "Bundle zipped to $ZipPath" -ForegroundColor Green
}

Write-Host "Deployment complete." -ForegroundColor Green
