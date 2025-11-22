Param(
    [string]$Root = "${PSScriptRoot}/..",
    [string]$ManifestPath = "dependency_manifest.json",
    [string]$Readme = "README.md"
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path $Root).Path
$manifestFile = Join-Path $root $ManifestPath
$readmeFile = Join-Path $root $Readme

if (-not (Test-Path $manifestFile)){
    Write-Host "Manifest not found: $manifestFile" -ForegroundColor Yellow
    exit 1
}

$manifest = Get-Content -Raw -Path $manifestFile | ConvertFrom-Json

# Build simple mermaid graph
$lines = @()
$lines += "```mermaid"
$lines += "flowchart TD"

# Projects
if ($manifest.projects) {
    foreach ($p in $manifest.projects) {
        $id = ($p.name -replace '[^a-zA-Z0-9]','_')
        $label = $p.name
        $lines += "    $id[\"$label\"]"
        if ($p.package_references) {
            foreach ($pkg in $p.package_references) {
                $pkgId = ("pkg_" + ($pkg.id -replace '[^a-zA-Z0-9]','_'))
                $pkgLabel = "$($pkg.id)\n$($pkg.version)"
                $lines += "    $pkgId[\"$pkgLabel\"]"
                $lines += "    $id --> $pkgId"
            }
        }
    }
}

$lines += "```"

# Replace markers in README
$start = '<!-- DEP_MANIFEST_MERMAID_START -->'
$end = '<!-- DEP_MANIFEST_MERMAID_END -->'

if (-not (Test-Path $readmeFile)){
    Write-Host "README not found: $readmeFile. Creating new README with mermaid block." -ForegroundColor Yellow
    $content = @()
    $content += $start
    $content += $lines
    $content += $end
    $content -join "`n" | Set-Content -Path $readmeFile -Encoding UTF8
    Write-Host "Inserted mermaid block into $readmeFile" -ForegroundColor Green
    exit 0
}

$readme = Get-Content -Raw -Path $readmeFile

if ($readme -notmatch [regex]::Escape($start)){
    # append
    $readme +="`n`n$start`n$($lines -join "`n")`n$end`n" | Set-Content -Path $readmeFile -Encoding UTF8
    Write-Host "Appended mermaid block to $readmeFile" -ForegroundColor Green
    exit 0
}

$pattern = "(?s)" + [regex]::Escape($start) + ".*?" + [regex]::Escape($end)
$replacement = "$start`n$($lines -join "`n")`n$end"
$new = [regex]::Replace($readme, $pattern, $replacement)
$new | Set-Content -Path $readmeFile -Encoding UTF8
Write-Host "Updated mermaid block in $readmeFile" -ForegroundColor Green
