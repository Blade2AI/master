param(
  [Parameter(Mandatory=$true)][string]$Title,
  [Parameter(Mandatory=$true)][string]$Org,
  [Parameter(Mandatory=$true)][string]$RequesterName,
  [Parameter(Mandatory=$true)][string]$RequesterRole,
  [Parameter(Mandatory=$true)][string]$ContactEmail,
  [Parameter(Mandatory=$false)][string]$ContactPhone = "",
  [Parameter(Mandatory=$true)][ValidateSet('Prescription','Dental','Ophthalmic')][string]$Domain,
  [Parameter(Mandatory=$true)][ValidateSet('Public dataset','Ad hoc','Academic Research','Patient','NHSCFA/LCFS','FOI')][string]$Route,
  [Parameter(Mandatory=$true)][string]$LawfulBasis,
  [Parameter(Mandatory=$true)][string]$Purpose,
  [Parameter(Mandatory=$true)][string]$Benefit,
  [Parameter(Mandatory=$false)][string]$ImpactIfRefused = "",
  [Parameter(Mandatory=$true)][string]$DateFrom,
  [Parameter(Mandatory=$true)][string]$DateTo,
  [Parameter(Mandatory=$true)][string]$GeogScope,
  [Parameter(Mandatory=$false)][string]$Suppression = "",
  [Parameter(Mandatory=$false)][ValidateSet('one-off','monthly','quarterly')][string]$Frequency = 'one-off',
  [Parameter(Mandatory=$false)][string]$Codes = "",
  [Parameter(Mandatory=$false)][string]$FieldList = "",
  [Parameter(Mandatory=$false)][string]$DerivedFields = "",
  [Parameter(Mandatory=$false)][string]$Linkage = "",
  [Parameter(Mandatory=$true)][ValidateSet('Aggregated','De-identified','Pseudonymised','Patient identifiable')][string]$DataCategory,
  [Parameter(Mandatory=$false)][string]$Minimisation = "",
  [Parameter(Mandatory=$false)][string]$Retention = "",
  [Parameter(Mandatory=$false)][string]$StorageControls = "",
  [Parameter(Mandatory=$false)][ValidateSet('Secure email','SFTP','Portal')][string]$Transfer = 'Secure email',
  [Parameter(Mandatory=$false)][string]$DPIARefs = "",
  [Parameter(Mandatory=$false)][string]$LegalRefs = "",
  [Parameter(Mandatory=$false)][string]$LCFSContext = "",
  [Parameter(Mandatory=$false)][ValidateSet('yes','no')][string]$Approvals = 'no',
  [Parameter(Mandatory=$false)][string]$DashboardRefs = "",
  [Parameter(Mandatory=$false)][string]$ODPRefs = "",
  [Parameter(Mandatory=$false)][string]$PublicRefs = "",
  [Parameter(Mandatory=$false)][string]$Format = 'CSV',
  [Parameter(Mandatory=$false)][string]$Granularity = "",
  [Parameter(Mandatory=$false)][string]$Tolerances = "",
  [Parameter(Mandatory=$false)][string]$PrimaryContact = "",
  [Parameter(Mandatory=$false)][string]$SecureDispatchDetails = "",
  [Parameter(Mandatory=$false)][string]$DeliveryDate = "",
  [Parameter(Mandatory=$false)][string]$LCFSId = "",
  [Parameter(Mandatory=$false)][string]$Statute = "",
  [Parameter(Mandatory=$false)][string]$ControllerConfirmation = "",
  [Parameter(Mandatory=$false)][string]$SitemapLinks = "",
  [Parameter(Mandatory=$false)][string]$Datasets = ""
)

# Resolve template path
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Template = Join-Path $RepoRoot 'TrustOps\templates\NHSBSA_Proforma_Template.md'
if (-not (Test-Path $Template)) { throw "Template not found: $Template" }

# Output folder
$OutDir = Join-Path $RepoRoot 'TrustOps\out\nhsbsa'
New-Item -Path $OutDir -ItemType Directory -Force | Out-Null
$Date = Get-Date -Format 'yyyy-MM-dd'
$SafeTitle = ($Title -replace '[^A-Za-z0-9\-]+','_').Trim('_')
$OutFile = Join-Path $OutDir ("$Date-$SafeTitle.md")

# Load content
$content = Get-Content -LiteralPath $Template -Raw

# Expand datasets and fields (optional helpers)
function JoinLines($text) { if ([string]::IsNullOrWhiteSpace($text)) { return '' } ($text -split '[\r\n,]+' | Where-Object { $_.Trim() } | ForEach-Object { "- $_" }) -join "`n" }
$datasetLines = if ($Datasets) { JoinLines $Datasets } else { '' }
$fieldLines = if ($FieldList) { $i = 0; ($FieldList -split '[\r\n]+' | Where-Object { $_.Trim() } | ForEach-Object { $i++; "$i) $_" }) -join "`n" } else { '' }

# Domain links
$DomainLink = switch ($Domain) {
  'Prescription' { 'https://www.nhsbsa.nhs.uk/prescription-data/requesting-our-prescription-data' }
  'Dental' { 'https://www.nhsbsa.nhs.uk/dental-data/requesting-our-dental-data' }
  'Ophthalmic' { 'https://www.nhsbsa.nhs.uk/ophthalmic-data/requesting-our-ophthalmic-data' }
}

# Replacements
$map = @{
  '{{TITLE}}' = $Title
  '{{DATE}}' = $Date
  '{{ORG}}' = $Org
  '{{REQUESTER_NAME}}' = $RequesterName
  '{{REQUESTER_ROLE}}' = $RequesterRole
  '{{CONTACT_EMAIL}}' = $ContactEmail
  '{{CONTACT_PHONE}}' = $ContactPhone
  '{{DOMAIN}}' = $Domain
  '{{ROUTE}}' = $Route
  '{{LAWFUL_BASIS}}' = $LawfulBasis
  '{{PURPOSE}}' = $Purpose
  '{{BENEFIT}}' = $Benefit
  '{{IMPACT_IF_REFUSED}}' = $ImpactIfRefused
  '{{DATE_FROM}}' = $DateFrom
  '{{DATE_TO}}' = $DateTo
  '{{GEOG_SCOPE}}' = $GeogScope
  '{{SUPPRESSION}}' = $Suppression
  '{{FREQUENCY}}' = $Frequency
  '{{CODES}}' = $Codes
  '{{FIELD_1}}' = ''
  '{{JUSTIFICATION_1}}' = ''
  '{{FIELD_2}}' = ''
  '{{JUSTIFICATION_2}}' = ''
  '{{DERIVED_FIELDS}}' = $DerivedFields
  '{{LINKAGE}}' = $Linkage
  '{{DATA_CATEGORY}}' = $DataCategory
  '{{MINIMISATION}}' = $Minimisation
  '{{RETENTION}}' = $Retention
  '{{STORAGE_CONTROLS}}' = $StorageControls
  '{{TRANSFER}}' = $Transfer
  '{{DPIA_REFS}}' = $DPIARefs
  '{{LEGAL_REFS}}' = $LegalRefs
  '{{LCFS_CONTEXT}}' = $LCFSContext
  '{{APPROVALS}}' = $Approvals
  '{{DASHBOARD_REFS}}' = $DashboardRefs
  '{{ODP_REFS}}' = $ODPRefs
  '{{PUBLIC_REFS}}' = $PublicRefs
  '{{FORMAT}}' = $Format
  '{{GRANULARITY}}' = $Granularity
  '{{TOLERANCES}}' = $Tolerances
  '{{PRIMARY_CONTACT}}' = $PrimaryContact
  '{{SECURE_DISPATCH_DETAILS}}' = $SecureDispatchDetails
  '{{DELIVERY_DATE}}' = $DeliveryDate
  '{{LCFS_ID}}' = $LCFSId
  '{{STATUTE}}' = $Statute
  '{{CONTROLLER_CONFIRMATION}}' = $ControllerConfirmation
  '{{SITEMAP_LINK_1}}' = $DomainLink
  '{{SITEMAP_LINK_2}}' = 'https://www.nhsbsa.nhs.uk/sitemap'
  '{{SITEMAP_LINK_3}}' = $SitemapLinks
}

foreach ($k in $map.Keys) { $content = $content -replace [regex]::Escape($k), [System.Text.RegularExpressions.Regex]::Escape($map[$k]) -replace '\\n','`n' }

# Insert datasets and fields blocks if present
if ($datasetLines) { $content = $content -replace "- \{\{DATASET_1\}\}[\r\n]+\s*- \{\{DATASET_2\}\}", $datasetLines }
if ($fieldLines) { $content = $content -replace "1\) \{\{FIELD_1\}\} – \{\{JUSTIFICATION_1\}\}[\r\n]+\s*2\) \{\{FIELD_2\}\} – \{\{JUSTIFICATION_2\}\}", $fieldLines }

Set-Content -LiteralPath $OutFile -Value $content -Encoding UTF8
Write-Host "Generated: $OutFile"
