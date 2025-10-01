<#
Generates a passive income report from the Asset Schedule.

Inputs:
  - TrustOps/registers/Asset_Schedule.csv (UTF-8, header row)

Outputs:
  - TrustOps/reports/passive_income.md (Markdown summary)

Behavior:
  - Computes counts by Type and Owner
  - Sums IncomeMonthly when present (numeric)
  - Emits schema advisories when expected fields are missing
  - Creates the reports directory if needed

Exit codes: 0 success, 1 error
#>

[CmdletBinding()]
param(
  [string]$AssetCsv,
  [string]$OutDir,
  [string]$OutFile = 'passive_income.md'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Count {
  param($Value)
  return @($Value).Count
}

function Ensure-Directory {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { [void](New-Item -ItemType Directory -Path $Path) }
}

function Read-Assets {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { throw "Asset CSV not found: $Path" }
  return Import-Csv -LiteralPath $Path
}

function As-Decimal {
  param($Value)
  if ($null -eq $Value -or "$Value".Trim() -eq '') { return $null }
  try {
    return [decimal]::Parse("$Value", [System.Globalization.CultureInfo]::InvariantCulture)
  } catch {
    return $null
  }
}

function New-PassiveIncomeReport {
  param($rows)
  # Normalize to array to safely use .Count and index
  $rowsArr = @()
  if ($null -ne $rows) { $rowsArr = @($rows) }
  $expected = @('AssetID','Type','Description','Owner','Status','Next Step')
  # Optional columns (informational)
  # 'IncomeMonthly','IncomeCurrency','APR','Value','Account','Platform'

  $headers = @()
    if ((Get-Count $rowsArr) -gt 0) { $headers = $rowsArr[0].PSObject.Properties.Name }
  $missing = $expected | Where-Object { $_ -notin $headers }

  $now = Get-Date
  $lines = @()
  $lines += "# Passive Income Report"
  $lines += ""
  $lines += "Generated: $now"
  $lines += "Source: TrustOps/registers/Asset_Schedule.csv"
  $lines += ""

    if ((Get-Count $rowsArr) -eq 0) {
    $lines += "> No assets found. Populate the Asset Schedule to proceed."
    return ($lines -join "`r`n")
  }

  # Summary stats
    $total = (Get-Count $rowsArr)
  $byType = $rowsArr | Group-Object -Property Type | Sort-Object Count -Descending
  $byOwner = $rowsArr | Group-Object -Property Owner | Sort-Object Count -Descending

  # Income aggregation (if present)
  $incomeSum = 0
  $incomeRows = @()
  $hasIncomeCol = $headers -contains 'IncomeMonthly'

  if ($hasIncomeCol) {
    foreach ($r in $rowsArr) {
      $amt = As-Decimal $r.IncomeMonthly
  if ($null -ne $amt) {
        $incomeSum += $amt
        $incomeCurrency = ''
        $prop = $r.PSObject.Properties['IncomeCurrency']
        if ($prop) { $incomeCurrency = $prop.Value }
        $incomeRows += [PSCustomObject]@{
          AssetID = $r.AssetID
          Type = $r.Type
          Owner = $r.Owner
          IncomeMonthly = $amt
          IncomeCurrency = $incomeCurrency
        }
      }
    }
  }

  $lines += "## Summary"
  $lines += ""
  $lines += "- Total assets: $total"
  if ($hasIncomeCol) {
    $lines += ("- Total monthly income (declared): {0}" -f $incomeSum)
  } else {
    $lines += "- Total monthly income (declared): n/a (add IncomeMonthly column)"
  }
  $lines += ""

  $lines += "### Assets by Type"
  foreach ($g in $byType) { $lines += ("- {0}: {1}" -f $g.Name, $g.Count) }
  $lines += ""

  $lines += "### Assets by Owner"
  foreach ($g in $byOwner) { $lines += ("- {0}: {1}" -f $g.Name, $g.Count) }
  $lines += ""

  if ($incomeRows.Count -gt 0) {
    $lines += "## Income Breakdown"
    $lines += ""
    $lines += "AssetID | Type | Owner | IncomeMonthly | Currency"
    $lines += "---|---|---|---:|---"
    foreach ($i in $incomeRows | Sort-Object -Property IncomeMonthly -Descending) {
        $curr = ''
        if ($i.IncomeCurrency) { $curr = $i.IncomeCurrency }
      $lines += ("{0} | {1} | {2} | {3} | {4}" -f $i.AssetID, $i.Type, $i.Owner, $i.IncomeMonthly, $curr)
    }
    $lines += ""
  }

  if ($missing.Count -gt 0) {
    $lines += "## Schema Advisory"
    $lines += ""
    $lines += "Missing required columns: " + ($missing -join ', ')
    $lines += ""
  }

  # Rows needing enrichment (no income value)
  if ($hasIncomeCol) {
    $needs = $rowsArr | Where-Object { $null -eq (As-Decimal $_.IncomeMonthly) }
  } else {
    $needs = $rowsArr
  }
    if ((Get-Count $needs) -gt 0) {
    $lines += "## Data Enrichment Needed"
    $lines += ""
    $lines += "AssetID | Type | Description | Owner | Next Step"
    $lines += "---|---|---|---|---"
    foreach ($n in $needs) {
      $lines += ("{0} | {1} | {2} | {3} | {4}" -f $n.AssetID, $n.Type, $n.Description, $n.Owner, $n.'Next Step')
    }
    $lines += ""
  }

  $lines += "## Suggested Fields"
  $lines += ""
  $lines += "Add these columns to unlock automation:"
  $lines += "- IncomeMonthly (decimal)"
  $lines += "- IncomeCurrency (e.g., GBP, USD)"
  $lines += "- APR (percent)"
  $lines += "- Value (decimal)"
  $lines += "- Account (platform/broker/bank)"
  $lines += "- Platform (API source)"
  $lines += ""

  return ($lines -join "`r`n")
}

try {
  # Compute defaults for paths now (PS 5.1-friendly)
  $rootPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
  if (-not $AssetCsv -or $AssetCsv.Trim() -eq '') { $AssetCsv = Join-Path $rootPath 'registers\Asset_Schedule.csv' }
  if (-not $OutDir -or $OutDir.Trim() -eq '') { $OutDir = Join-Path $rootPath 'reports' }

  $rows = Read-Assets -Path $AssetCsv
  Ensure-Directory -Path $OutDir
  $md = New-PassiveIncomeReport -rows $rows
  $outPath = Join-Path $OutDir $OutFile
  $encoding = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($outPath, $md, $encoding)
  Write-Host "Report written: $outPath"
  exit 0
} catch {
  Write-Error $_
  exit 1
}
