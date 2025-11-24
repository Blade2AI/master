param(
  [string]$OutRoot = "$env:USERPROFILE\Documents\Sovereign\NodeAudit",
  [string[]]$ScanRoots = @($env:USERPROFILE, "$env:USERPROFILE\source\repos", "C:\source", "C:\repos"),
  [switch]$ScanAllDrives,                # If set, include all fixed drive roots automatically
  [int]$MaxFiles = 500000,
  [switch]$IncludeAllExtensions,         # If set, index ALL files (still bounded by MaxFiles)
  [string[]]$IndexExtensions = @(
    '.sln','.csproj','.vbproj','.vcxproj','.props','.targets',
    '.py','.ps1','.sh','.bat','.cmd','.psm1','.psd1',
    '.ts','.js','.jsx','.tsx','.mjs','.cjs',
    '.json','.yaml','.yml','.toml','.ini',
    '.md','.txt','.rst','.adoc',
    '.dockerfile','.docker','.compose','.env',
    '.gguf','.onnx','.pth','.ckpt','.safetensors','.bin'
  ),
  [int]$LargeModelMinMB = 100,           # Threshold for scanning large model artifacts in generic roots
  [string[]]$ExtraModelPaths = @(),       # Optional additional model directories
  [switch]$HashModels                    # Compute SHA256 for model files (slower)
)

$ErrorActionPreference = 'Continue'

function Ensure-Dir([string]$p){ if(-not (Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function NowStamp(){ (Get-Date).ToString('yyyyMMdd_HHmmss') }
function Safe-GetSize([string]$p){ try { (Get-Item -LiteralPath $p -ErrorAction Stop).Length } catch { 0 } }
function Safe-GetMTime([string]$p){ try { (Get-Item -LiteralPath $p -ErrorAction Stop).LastWriteTimeUtc.ToString('o') } catch { $null } }
function Write-CsvUtf8([object[]]$rows,[string]$path){ $rows | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath $path }
function Hash-SHA256([string]$p){ if(-not $HashModels){ return '' }; try { (Get-FileHash -Algorithm SHA256 -LiteralPath $p -ErrorAction Stop).Hash } catch { '' } }

# Prepare output folder
$stamp = NowStamp()
$node = $env:COMPUTERNAME
$OutDir = Join-Path $OutRoot ("_AUDIT_RESULTS_{0}_{1}" -f $node,$stamp)
Ensure-Dir $OutDir

Write-Host "Sovereign Node Auditor (Enhanced): $node" -ForegroundColor Cyan
Write-Host "Output: $OutDir" -ForegroundColor Gray

# Auto add all fixed drives if requested
if($ScanAllDrives){
  $fixed = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' } | ForEach-Object { $_.Root }
  foreach($d in $fixed){ if(-not ($ScanRoots -contains $d)){ $ScanRoots += $d } }
}

# Normalize scan roots
$roots = @()
foreach($r in $ScanRoots){ if($r -and (Test-Path $r)){ $roots += (Resolve-Path $r).Path } }
if($roots.Count -eq 0){ $roots = @($env:USERPROFILE) }

# ================== 1) Git Forensics (.git roots) ==================
$gitRows = New-Object System.Collections.Generic.List[object]
$gitSimple = New-Object System.Collections.Generic.List[object]
foreach($root in $roots){
  Write-Host "Scanning for .git under $root ..." -ForegroundColor DarkGray
  try {
    Get-ChildItem -LiteralPath $root -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq '.git' } | ForEach-Object {
      $gitDir = $_.FullName
      $repo = Split-Path $gitDir -Parent
      $remote = ''
      $branch = ''
      $head = ''
      $dirty = ''
      $configPath = Join-Path $gitDir 'config'
      if(Test-Path $configPath){
        try { $config = Get-Content -LiteralPath $configPath -Raw -ErrorAction SilentlyContinue; $remote = ($config | Select-String -Pattern 'url\s*=\s*(.+)' -AllMatches).Matches.Value -join '; ' } catch {}
      }
      $gitExe = Get-Command git -ErrorAction SilentlyContinue
      if($gitExe){
        try { $branch = (git -C "$repo" rev-parse --abbrev-ref HEAD 2>$null).Trim() } catch {}
        try { $head   = (git -C "$repo" rev-parse --short HEAD 2>$null).Trim() } catch {}
        try { $dirty  = if((git -C "$repo" status --porcelain 2>$null)){'YES'} else {'NO'} } catch {}
      } else {
        $headFile = Join-Path $gitDir 'HEAD'
        if(Test-Path $headFile){ try { $head = (Get-Content -LiteralPath $headFile -Raw).Trim() } catch {} }
      }
      $gitRows.Add([pscustomobject]@{
        Computer     = $node
        RepoPath     = $repo
        Remote       = $remote
        Branch       = $branch
        Head         = $head
        Dirty        = $dirty
        LastWriteUtc = (Get-Item -LiteralPath $repo -ErrorAction SilentlyContinue).LastWriteTimeUtc.ToString('o')
      })
      $gitSimple.Add([pscustomobject]@{ Computer=$node; RepoPath=$repo })
    }
  } catch {}
}

# ================== 2) AI Model Inventory (LM Studio, Ollama, GGUF) ==================
$models = New-Object System.Collections.Generic.List[object]
# LM Studio common + user path
$lmPaths = @(
  "$env:LOCALAPPDATA\LM Studio\cache\models",
  "$env:APPDATA\LM Studio\models",
  "$env:USERPROFILE\AppData\Local\Programs\LM Studio\models",
  "$env:USERPROFILE\.lmstudio\models"   # Added per comprehensive requirement
) + $ExtraModelPaths | Where-Object { $_ -and (Test-Path $_) }
foreach($p in $lmPaths){
  Write-Host "Indexing LM Studio path: $p" -ForegroundColor DarkGray
  Get-ChildItem -Path $p -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    if($_.Extension -in @('.gguf','.bin','.safetensors','.pth','.onnx')){
      $models.Add([pscustomobject]@{
        Computer=$node; Type='LMStudio'; Name=$_.Name; Path=$_.FullName; SizeBytes=$_.Length; ModifiedUtc=$_.LastWriteTimeUtc.ToString('o'); Hash=Hash-SHA256 $_.FullName; Source=$p
      })
    }
  }
}
# Ollama models directory
$ollamaDir = Join-Path $env:USERPROFILE '.ollama\models'
if(Test-Path $ollamaDir){
  Write-Host "Indexing Ollama models: $ollamaDir" -ForegroundColor DarkGray
  Get-ChildItem -Path $ollamaDir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $models.Add([pscustomobject]@{
      Computer=$node; Type='Ollama'; Name=$_.Name; Path=$_.FullName; SizeBytes=$_.Length; ModifiedUtc=$_.LastWriteTimeUtc.ToString('o'); Hash=Hash-SHA256 $_.FullName; Source=$ollamaDir
    })
  }
}
# Large model artifacts anywhere (GGUF / others) under scan roots
foreach($root in $roots){
  try {
    Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -ge ($LargeModelMinMB * 1MB) -and ($_.Extension -in @('.gguf','.bin','.safetensors','.pth','.onnx','.ckpt')) } | Select-Object -First 2000 | ForEach-Object {
      $models.Add([pscustomobject]@{
        Computer=$node; Type='LargeModel'; Name=$_.Name; Path=$_.FullName; SizeBytes=$_.Length; ModifiedUtc=$_.LastWriteTimeUtc.ToString('o'); Hash=Hash-SHA256 $_.FullName; Source=$root
      })
    }
  } catch {}
}
# Ollama list (registry) if available
$ollama = Get-Command ollama -ErrorAction SilentlyContinue
if($ollama){
  try {
    $list = (& $ollama.Source list) 2>$null
    if($list){
      $lines = $list -split "`n" | Where-Object { $_ -and -not $_.StartsWith('NAME') }
      foreach($ln in $lines){
        $name = ($ln -split '\s+')[0]
        $models.Add([pscustomobject]@{ Computer=$node; Type='OllamaRegistry'; Name=$name; Path='(registry)'; SizeBytes=0; ModifiedUtc=''; Hash=''; Source='ollama list' })
      }
    }
  } catch {}
}

# ================== 3) Workspace Audit (.sln / .code-workspace) ==================
$workspaces = New-Object System.Collections.Generic.List[object]
foreach($root in $roots){
  try {
    Get-ChildItem -Path $root -Recurse -File -Include *.sln,*.code-workspace -ErrorAction SilentlyContinue | ForEach-Object {
      $workspaces.Add([pscustomobject]@{
        Computer=$node; Type=([IO.Path]::GetExtension($_.Name)); Path=$_.FullName; SizeBytes=$_.Length; ModifiedUtc=$_.LastWriteTimeUtc.ToString('o')
      })
    }
  } catch {}
}

# ================== 4) File Index ==================
$fileIndex = New-Object System.Collections.Generic.List[object]
$extSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$IndexExtensions | ForEach-Object { [void]$extSet.Add($_) }
$added = 0
foreach($root in $roots){
  Write-Host "Indexing files under $root ..." -ForegroundColor DarkGray
  try {
    Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
      if($added -ge $MaxFiles){ return }
      $ext = $_.Extension
      if($IncludeAllExtensions -or [string]::IsNullOrEmpty($ext) -or $extSet.Contains($ext)){
        $fileIndex.Add([pscustomobject]@{
          Computer=$node; Path=$_.FullName; SizeBytes=$_.Length; ModifiedUtc=$_.LastWriteTimeUtc.ToString('o')
        })
        $added++
      }
    }
  } catch {}
}

# ================== OUTPUTS ==================
$deepForgeCsv = Join-Path $OutDir ("{0}_DEEP_FORGE.csv" -f $node)
$aiModelsCsv  = Join-Path $OutDir ("{0}_AI_MODELS.csv"  -f $node)
$gitCsv       = Join-Path $OutDir ("{0}_GIT_FORENSICS.csv" -f $node)
$gitSimpleCsv = Join-Path $OutDir ("{0}_GIT_REPOS.csv" -f $node)          # Added simple repo list
$wsCsv        = Join-Path $OutDir ("{0}_WORKSPACES.csv" -f $node)
$vsStdCsv     = Join-Path $OutDir ("{0}_VS_WORKSPACES.csv" -f $node)      # Standardized naming for consolidation scripts

Write-CsvUtf8 $fileIndex $deepForgeCsv
Write-CsvUtf8 $models    $aiModelsCsv
Write-CsvUtf8 $gitRows   $gitCsv
Write-CsvUtf8 $gitSimple $gitSimpleCsv
Write-CsvUtf8 $workspaces $wsCsv
Write-CsvUtf8 $workspaces $vsStdCsv

Write-Host "Wrote:" -ForegroundColor Green
Write-Host "  $deepForgeCsv" -ForegroundColor Green
Write-Host "  $aiModelsCsv"  -ForegroundColor Green
Write-Host "  $gitCsv"       -ForegroundColor Green
Write-Host "  $gitSimpleCsv" -ForegroundColor Green
Write-Host "  $wsCsv"        -ForegroundColor Green
Write-Host "  $vsStdCsv"     -ForegroundColor Green

Write-Host "Indexed Files: $($fileIndex.Count) (MaxFiles=$MaxFiles, AllExt=$IncludeAllExtensions)" -ForegroundColor Gray
Write-Host "Models Indexed: $($models.Count) (Hashing=$HashModels)" -ForegroundColor Gray
Write-Host "Git Repositories: $($gitRows.Count)" -ForegroundColor Gray
Write-Host "Workspaces: $($workspaces.Count)" -ForegroundColor Gray

