# Sovereign Media + Close-Out Pipeline (Consolidated Specification)

Canonical production-grade specification for media transcription and operational close-out.

## 1. Transcript Directory (mandatory)
```powershell
$tdir = Join-Path $env:USERPROFILE "Documents\Sovereign\Transcripts"
if (-not (Test-Path $tdir)) {
    New-Item -ItemType Directory -Force -Path $tdir | Out-Null
}
Write-Host "[OK] Transcript directory ready: $tdir"
```
If directory exists it passes; otherwise created automatically.

## 2. VS Code Task: “00: Sovereign IDE Preflight”
Add to `.vscode/tasks.json`:
```json
{
  "label": "00: Sovereign IDE Preflight",
  "type": "shell",
  "command": "powershell",
  "args": ["-NoProfile","-ExecutionPolicy","Bypass","-File","C:/Users/andyj/AI_Agent_Research/sovereign_ide_preflight.ps1"],
  "presentation": {"reveal": "always", "panel": "shared"},
  "problemMatcher": []
}
```

## 3. Optional Makefile Target
```
preflight:
	powershell -NoProfile -ExecutionPolicy Bypass -File C:/Users/andyj/AI_Agent_Research/sovereign_ide_preflight.ps1
```
Run via `make preflight`.

## 4. Normalised Media Task Definitions
Transcribe Video:
```json
{
  "label": "Media: Transcribe Video",
  "type": "shell",
  "command": "powershell",
  "args": ["-NoProfile","-ExecutionPolicy","Bypass","-File","${workspaceFolder}/scripts/Transcribe-Video.ps1","-Input","${input:videoUrl}","-SplitParts","2","-ContinueOnError"],
  "presentation": {"reveal": "always", "panel": "shared"},
  "problemMatcher": []
}
```
Merge + Index:
```json
{
  "label": "Media: G-Transcript Merge",
  "type": "shell",
  "command": "powershell",
  "args": ["-NoProfile","-ExecutionPolicy","Bypass","-File","${workspaceFolder}/scripts/G-Transcript.ps1","-Inputs","${input:videoList}","-SplitParts","2","-EmitIndexJson","-ContinueOnError"],
  "presentation": {"reveal": "always", "panel": "shared"},
  "problemMatcher": []
}
```

## 5. Enhanced Index JSON Logic (G-Transcript.ps1)
```powershell
$index += [pscustomobject]@{
    Order          = $idx
    Source         = $srcLabel
    LocalPath      = $local
    TranscriptPath = $txt
    Lines          = ($contentRaw -split "\r?\n").Length
    FirstLine      = 1
    LastLine       = ($contentRaw -split "\r?\n").Length
    Model          = $Model
    TimestampUtc   = (Get-Date).ToUniversalTime().ToString("o")
}
$index | ConvertTo-Json -Depth 10 | Set-Content $indexJsonPath
```

## 6. README Snippet (Media / Transcript Prerequisites)
```
### Media / Transcript Prerequisites

Install core dependencies before running transcription tasks:

**Python**
pip install cryptography pyyaml

**Media extraction + Whisper**
pip install openai-whisper yt-dlp
You must have ffmpeg available on PATH.

Required for:
- Transcribe-Video.ps1
- G-Transcript.ps1
- Index JSON generation
```

## 7. SITREP Script (Get-ProjectSITREP.ps1)
```powershell
param(
    [string]$ProjectsRoot = "Z:/Forge/apps",
    [string]$OutputFile = "PROJECT_SITREP.md"
)
$branch = git rev-parse --abbrev-ref HEAD
$head = git rev-parse HEAD
$uncommitted = (git status --porcelain).Split("`n") | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
$sealDir = "Data/_seals"
$latestSeal = Get-ChildItem -LiteralPath $sealDir -Filter *.sha256 -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$latestManifest = Get-ChildItem -LiteralPath $sealDir -Filter *.manifest.json -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$lines = @()
$lines += "# Project SITREP"
$lines += "- Timestamp: $(Get-Date -Format o)"
$lines += "- Git Branch: $branch"
$lines += "- Git Head: $head"
$lines += "- Uncommitted Changes: $uncommitted"
if ($latestSeal) { $lines += "- Latest Seal: $($latestSeal.Name)" }
if ($latestManifest) { $lines += "- Latest Manifest: $($latestManifest.Name)" }
if (Test-Path $ProjectsRoot) {
    $sols = Get-ChildItem -LiteralPath $ProjectsRoot -Recurse -Filter *.sln -ErrorAction SilentlyContinue
    $lines += ""
    $lines += "## Solutions Discovered"
    foreach ($s in $sols) { $lines += "- $($s.FullName)" }
}
$lines | Set-Content -LiteralPath $OutputFile -Encoding UTF8
Write-Host "SITREP written: $OutputFile" -ForegroundColor Green
```

## 8. Collab End Structured Commit (End-Collab.ps1)
```powershell
$ts = (Get-Date).ToString('yyyy-MM-dd')
$short = (git rev-parse --short HEAD)
$structured = "Close-out: Sovereign Workspace – $ts – head:$short"
if (-not [string]::IsNullOrWhiteSpace($Message)) { $structured = "$structured – $Message" }
git add .
try { git commit -m $structured | Out-Host } catch { Write-Host "Nothing to commit or commit failed: $($_)" -ForegroundColor Yellow }
try { git push | Out-Host } catch { Write-Host "git push failed: $($_)" -ForegroundColor Yellow }
```

## 9. Transcript Directory Convention
```
Raw single transcription: Documents/Sovereign/Transcripts/<basename>.txt
Split segments: <basename>.partN.txt
Merged output: merged_transcript_<timestamp>.txt
Merged index JSON: merged_transcript_<timestamp>.index.json
```

## 10. Operational Run-Book
1. 00: Sovereign IDE Preflight
2. Media: Transcribe Video
3. Media: G-Transcript Merge
4. Policy: Validate Manifest
5. Policy: Sign Manifest
6. Sovereign: Healthcheck
7. Sovereign: Ledger Audit
8. Close-out: Master End-State (Dry Run)
9. Resolve failures
10. Close-out: Master End-State (Auditable)
11. SITREP: Project Status
12. Collab: End (Commit + Push)

Never run the Auditable close-out if Dry Run shows unresolved failures.
