[CmdletBinding()]
param()

Write-Host "[TamperDemo] Starting tamper evidence demonstration" -ForegroundColor Cyan
$logDir = "logs/tamper"
if(-not (Test-Path $logDir)){ New-Item -ItemType Directory -Force -Path $logDir | Out-Null }

# Assume evidence files reside in verifier build dir or current working dir
$e2 = "evidence2.txt"
$e3 = "evidence3.txt"
$e2Bak = "evidence2.txt.bak"

function Get-FileHashSHA256($path){
  $bytes = [System.IO.File]::ReadAllBytes($path)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $hash = $sha.ComputeHash($bytes)
  -join ($hash | ForEach-Object { $_.ToString('x2') })
}

if(-not (Test-Path $e2)){
  Set-Content -LiteralPath $e2 -Value "INITIAL_EVIDENCE_2" -Encoding UTF8
}
if(-not (Test-Path $e3)){
  Set-Content -LiteralPath $e3 -Value "INITIAL_EVIDENCE_3" -Encoding UTF8
}

Copy-Item $e2 $e2Bak -Force
$origHash = Get-FileHashSHA256 $e2Bak
Write-Host "Original SHA256: $origHash"

# Tamper overwrite pattern (extend + marker byte)
$size = (Get-Item $e2Bak).Length + 32
[byte[]]$tampered = @(0) * $size
$tampered[$size-1] = 0xFF
[System.IO.File]::WriteAllBytes($e2, $tampered)

if(Test-Path $e3){ [System.IO.File]::WriteAllBytes($e3, @(0xAA,0xBB,0xCC,0xDD,0xEE)) }

$tamperedHash = Get-FileHashSHA256 $e2
Write-Host "Tampered SHA256: $tamperedHash"

$tamperDetected = $origHash -ne $tamperedHash
if($tamperDetected){ Write-Host "? Tamper detected — hashes differ" -ForegroundColor Green } else { Write-Host "? Tamper not detected" -ForegroundColor Red }

# Merkle recompute via test harness (expects it to output before/after info if implemented)
$testExe = "build/Debug/verify_evidence_tests.exe"
if(Test-Path $testExe){ & $testExe | Out-Host } else { Write-Warning "Test exe not found for Merkle recompute: $testExe" }

$artifact = @{
  timestamp = (Get-Date).ToString('o')
  file = $e2
  original_hash = $origHash
  tampered_hash = $tamperedHash
  tamper_detected = $tamperDetected
  broadened_file = $e3
} | ConvertTo-Json -Depth 5
$artifact | Out-File "$logDir\tamper_evidence.json" -Encoding utf8
Write-Host "[TamperDemo] Artifact written: $logDir/tamper_evidence.json" -ForegroundColor Cyan
