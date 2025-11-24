[CmdletBinding()]param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot),
  [string]$OutDir = 'docs/dependencies'
)
$ErrorActionPreference='Stop'
if(-not (Test-Path $OutDir)){ New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }
$manifestPath = Join-Path $OutDir 'DependencyManifest.generated.md'

# Enumerate .csproj files
$csprojs = Get-ChildItem -Path $Root -Recurse -Filter *.csproj -ErrorAction SilentlyContinue
$rows = @()
foreach($proj in $csprojs){
  try {
    $xml = [xml](Get-Content -LiteralPath $proj.FullName -Raw)
    $tf = ($xml.Project.PropertyGroup.TargetFramework, $xml.Project.PropertyGroup.TargetFrameworks | Where-Object { $_ }) -join ';'
    $pkgRefs = $xml.Project.ItemGroup.PackageReference | ForEach-Object { "${($_.Include)}:${($_.Version)}" }
    $rows += [pscustomobject]@{ Project=(Split-Path $proj.FullName -Leaf); Path=$proj.FullName; TargetFramework=$tf; Packages=($pkgRefs -join ', ') }
  } catch { Write-Warning "Failed to parse $($proj.FullName): $_" }
}

# Write markdown
$md = @('# Dependency Manifest (Auto-Generated)',"Generated: $(Get-Date -Format o)","","## C# Projects")
if($rows.Count -eq 0){ $md += '*No C# projects found*' } else {
  $md += '| Project | TargetFramework(s) | Packages |'
  $md += '|---------|-------------------|----------|'
  foreach($r in $rows){ $md += "| $($r.Project) | $($r.TargetFramework) | $($r.Packages) |" }
}
$md += ''
($md -join "`n") | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Write-Host "Manifest written: $manifestPath" -ForegroundColor Green
