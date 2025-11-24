param(
  [Parameter(Mandatory=$true)][string]$NasRoot
)
$statusFile = Join-Path $NasRoot 'LiveShareStatus.json'
if (Test-Path $statusFile) {
  try {
    $status = Get-Content $statusFile -Raw | ConvertFrom-Json
    Write-Output "=== Live Share Status with Kindness ==="
    Write-Output "Status: $($status.Status)"
    Write-Output "Host: $($status.Host)"
    Write-Output "Time: $($status.Timestamp)"
    Write-Output "Connection Mode: $($status.ConnectionMode)"
    if ($status.GuestCount) { Write-Output "Guests: $($status.GuestCount)" }
    if ($status.Motto) { Write-Output "Motto: $($status.Motto)" }
    if ($status.Link) { Write-Output "Link: $($status.Link)" }
    if ($status.GuestLatencies) {
      Write-Output "Network Performance:"
      foreach ($guest in $status.GuestLatencies.PSObject.Properties) {
        $metrics = $guest.Value
        if ($metrics.Average) {
          Write-Output "  $($guest.Name): $($metrics.Average)ms ($($metrics.Quality))"
        } else {
          Write-Output "  $($guest.Name): Unreachable"
        }
      }
    }
  }
  catch {
    Write-Warning "Failed to parse status file: $($_.Exception.Message)"
  }
} else {
  Write-Output "No status file found - opportunities await"
}
