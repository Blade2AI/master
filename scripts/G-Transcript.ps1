param(
  [Parameter(Mandatory=$true)][Alias('Input','Urls')][object]$Inputs,
  [string]$OutDir = "$env:USERPROFILE\Documents\Sovereign\Transcripts",
  [ValidateSet('tiny','base','small','medium','large')][string]$Model = "base",
  [int]$SplitParts = 2,
  [switch]$ContinueOnError,
  [switch]$EmitIndexJson
)

function Ensure-Dir($p){ if(-not (Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function Split-Inputs([object]$raw){
  if($raw -is [Array]){ return @($raw | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ }) }
  $s = $raw.ToString()
  return @($s -split "[,;\r\n]" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
}
function Download-IfUrl([string]$src){
  if($src -match '^(https?|file)://'){
    $yt = Get-Command yt-dlp -ErrorAction SilentlyContinue
    if(-not $yt){ throw "yt-dlp not found. Install it or download media manually." }
    $tmp = Join-Path $env:TEMP ("sv_" + [guid]::NewGuid().ToString() + ".mp4")
    Write-Host "[INFO] Downloading $src" -ForegroundColor Cyan
    & $yt.Path $src -o $tmp | Write-Output
    if(-not (Test-Path $tmp)){ throw "yt-dlp failed to download: $src" }
    return ,@($tmp,$true)
  }
  if(-not (Test-Path $src)){ throw "Input not found: $src" }
  return ,@((Resolve-Path $src).Path,$false)
}

Ensure-Dir $OutDir

$whisper = Get-Command whisper -ErrorAction SilentlyContinue
if(-not $whisper){ throw "whisper CLI not found. Install: pip install openai-whisper (ffmpeg required)." }

$allText = New-Object System.Collections.Generic.List[string]
$tempsToDelete = @()
$index = @()

$items = Split-Inputs $Inputs
if(-not $items -or $items.Count -eq 0){ throw "No inputs provided." }

$idx = 0
foreach($item in $items){
  $idx++
  try {
    $local, $isTemp = Download-IfUrl $item
    if($isTemp){ $tempsToDelete += $local }

    Write-Host "[INFO] Transcribing ($idx/$($items.Count)) $item" -ForegroundColor Cyan
    & $whisper.Path $local --model $Model --task transcribe --output_dir $OutDir --verbose False --fp16 False | Write-Output

    $base = [System.IO.Path]::GetFileNameWithoutExtension($local)
    $txt = Join-Path $OutDir ("$base.txt")
    if(-not (Test-Path $txt)){
      $cand = Get-ChildItem -Path $OutDir -Filter "*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
      if($cand){ $txt = $cand.FullName } else { throw "Transcript .txt not found in $OutDir for $local" }
    }

    $srcLabel = if($item -match '^(https?|file)://'){ $item } else { $local }
    $contentRaw = Get-Content -LiteralPath $txt -Raw

    $allText.Add("===== Source ${idx}: ${srcLabel} =====")
    $allText.Add($contentRaw)

    $lineCount = ($contentRaw -split "\r?\n").Length
    $index += [pscustomobject]@{ Order=$idx; Source=$srcLabel; LocalPath=$local; TranscriptPath=$txt; Lines=$lineCount; Model=$Model; TimestampUtc=(Get-Date).ToUniversalTime().ToString('o') }
  }
  catch {
    Write-Host "[ERROR] ($idx) $item -> $_" -ForegroundColor Red
    if(-not $ContinueOnError){ throw }
  }
}

$stamp = (Get-Date -Format 'yyyyMMdd_HHmmss')
$mergedPath = Join-Path $OutDir ("merged_transcript_${stamp}.txt")
$allText -join [Environment]::NewLine | Out-File -LiteralPath $mergedPath -Encoding UTF8

if($SplitParts -gt 1){
  Write-Host "[INFO] Splitting merged transcript into $SplitParts parts" -ForegroundColor Cyan
  $content = Get-Content -LiteralPath $mergedPath -Raw
  $lines = $content -split "\r?\n"
  if($lines.Length -eq 0){ Write-Host "[WARN] Merged transcript appears empty." -ForegroundColor Yellow }

  $partSize = [int][Math]::Ceiling([double]$lines.Length / [double]$SplitParts)
  for($p=0; $p -lt $SplitParts; $p++){
    $start = $p * $partSize; if($start -ge $lines.Length){ break }
    $end = [Math]::Min($start + $partSize - 1, $lines.Length - 1)
    $slice = $lines[$start..$end] -join [Environment]::NewLine
    $outPart = Join-Path $OutDir ("merged_transcript_${stamp}.part$($p+1).txt")
    Set-Content -LiteralPath $outPart -Value $slice -Encoding UTF8
    Write-Host "Part$($p+1): $outPart" -ForegroundColor Green
  }
  Write-Host "Merged transcript: $mergedPath" -ForegroundColor Green
} else {
  Write-Host "Merged transcript: $mergedPath" -ForegroundColor Green
}

if($EmitIndexJson){
  $indexPath = Join-Path $OutDir ("merged_transcript_${stamp}.index.json")
  $index | ConvertTo-Json -Depth 6 | Out-File -LiteralPath $indexPath -Encoding UTF8
  Write-Host "Index JSON: $indexPath" -ForegroundColor Green
}

foreach($t in $tempsToDelete){ if(Test-Path $t){ Remove-Item -LiteralPath $t -Force -ErrorAction SilentlyContinue } }
