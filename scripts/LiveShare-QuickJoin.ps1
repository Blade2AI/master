param(
  [Parameter(Mandatory=$true)][string]$NasRoot
)
$linkFile = Join-Path $NasRoot 'LiveShareLink.txt'
if (Test-Path $linkFile) {
  $link = Get-Content $linkFile -First 1
  Write-Output "Joining with kindness: $link"
  Start-Process code -ArgumentList "--command","liveshare.join","$link"
} else {
  Write-Output "No session link found at $linkFile - patience brings opportunities"
}
