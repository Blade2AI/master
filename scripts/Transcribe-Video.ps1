param(
  [Parameter(Mandatory=$true)][string]$Input,
  [string]$OutDir = "${env:USERPROFILE}\Documents\Sovereign\Transcripts",
  [ValidateSet('tiny','base','small','medium','large')][string]$Model = "base",
  [int]$SplitParts = 2,
  [switch]$ContinueOnError
)

function Ensure-Dir($p){ if(-not (Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
Ensure-Dir $OutDir

$workFile = $null
$isUrl = $Input -match '^(https?|file)://'

try {
  if($isUrl){
    $yt = Get-Command yt-dlp -ErrorAction SilentlyContinue
    if($null -ne $yt){
      $tmp = Join-Path $env:TEMP ("sv_" + [guid]::NewGuid().ToString() + ".mp4")
      Write-Host "[INFO] Downloading media via yt-dlp..." -ForegroundColor Cyan
      & $yt.Source $Input -o $tmp | Write-Output
      if(-not (Test-Path $tmp)){ throw "yt-dlp failed to download: $Input" }
      $workFile = $tmp
    } else {
      throw "No downloader found. Install yt-dlp or download the media locally and pass a file path."
    }
  } else {
    if(-not (Test-Path $Input)){ throw "Input not found: $Input" }
    $workFile = (Resolve-Path $Input).Path
  }

  $whisper = Get-Command whisper -ErrorAction SilentlyContinue
  if($null -eq $whisper){ throw "whisper CLI not found. Install with: pip install openai-whisper && ensure ffmpeg is on PATH." }

  Write-Host "[INFO] Transcribing with model '$Model'..." -ForegroundColor Cyan
  & $whisper.Source $workFile --model $Model --task transcribe --output_dir $OutDir --verbose False --fp16 False | Write-Output

  $base = [System.IO.Path]::GetFileNameWithoutExtension($workFile)
  $txt = Join-Path $OutDir ("$base.txt")
  if(-not (Test-Path $txt)){
    $cand = Get-ChildItem -Path $OutDir -Filter "*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if($cand){ $txt = $cand.FullName } else { throw "Transcript .txt not found in $OutDir" }
  }

  if($SplitParts -gt 1){
    Write-Host "[INFO] Splitting transcript into $SplitParts parts..." -ForegroundColor Cyan
    $allLines = (Get-Content -LiteralPath $txt -Raw) -split "\r?\n"
    if($allLines.Length -eq 0){ throw "Transcript appears empty: $txt" }
    $partSize = [int][Math]::Ceiling($allLines.Length / $SplitParts)
    for($i=0; $i -lt $SplitParts; $i++){
      $start = $i * $partSize
      if($start -ge $allLines.Length){ break }
      $end = [Math]::Min($start + $partSize - 1, $allLines.Length - 1)
      $segment = $allLines[$start..$end] -join [Environment]::NewLine
      $out = Join-Path $OutDir ("$base.part$($i+1).txt")
      Set-Content -LiteralPath $out -Value $segment -Encoding UTF8
      Write-Host "Part$($i+1):  $out" -ForegroundColor Green
    }
    Write-Host "Transcript: $txt" -ForegroundColor Green
  } else {
    Write-Host "Transcript: $txt" -ForegroundColor Green
  }
}
catch {
  Write-Host "[ERROR] $_" -ForegroundColor Red
  if(-not $ContinueOnError){ throw }
}
finally {
  if($isUrl -and $workFile -and (Test-Path $workFile)){
    Remove-Item -LiteralPath $workFile -Force -ErrorAction SilentlyContinue
  }
}
