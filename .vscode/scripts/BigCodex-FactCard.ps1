<#
BigCodex-FactCard.ps1 - Evidence-Based Fact Card Generation
?? "In a world you can be anything – be nice."

Integrates with Live Share fleet and Behavioral OS for collaborative truth analysis
Maintains evidence integrity while fostering team collaboration and kindness
#>

param(
    [string]$Topic,
    [string]$ClaimId,
    [switch]$FleetShare,
    [switch]$ValidateEvidence,
    [string]$OllamaEndpoint = "http://localhost:11434",
    [string]$SourceUrl = "",
    [string]$Publisher = "",
    [string]$Confidence = "Medium"
)

# Import existing infrastructure
$fleetProfile = Join-Path $PSScriptRoot "fleet-profile.ps1"
if (Test-Path $fleetProfile) { 
    . $fleetProfile 
} else {
    $Global:Motto = "?? In a world you can be anything – be nice."
    $Global:OpsRoot = "\\dxp4800plus-67ba\ops"
    $Global:LogsRoot = Join-Path $env:USERPROFILE "LiveShareLogs"
}

# BigCodex configuration
$codexDir = Join-Path $PSScriptRoot "..\codex"
$outputDir = Join-Path $codexDir "outputs"
$ledgerFile = Join-Path $codexDir "ledgers\evidence.csv"
$promptFile = Join-Path $codexDir "prompts\collaborative-truth.system.md"

# Ensure directories exist
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $ledgerFile) | Out-Null

function Write-CodexLog {
    param([string]$Message, [string]$Level = "INFO")
    $time = Get-Date -Format "HH:mm:ss"
    $entry = "[$time] [CODEX] [$Level] $Message"
    $colors = @{ "INFO" = "Cyan"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green"; "MOTTO" = "Magenta"; "EVIDENCE" = "Blue" }
    Write-Host $entry -ForegroundColor $colors[$Level]
    
    # Log to file if LogsRoot available
    if ($Global:LogsRoot) {
        $logFile = Join-Path $Global:LogsRoot "bigcodex_$(Get-Date -Format 'yyyyMMdd').log"
        Add-Content -Path $logFile -Value $entry
    }
}

function Invoke-TruthFilterValidation {
    param([hashtable]$EvidenceData)
    
    Write-CodexLog "?? Applying Truth Filter validation to evidence..." "INFO"
    
    $truthCheck = @{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        EvidenceId = $EvidenceData.ClaimId
        Verified = $false
        Score = 0
        Issues = @()
    }
    
    # Evidence quality checks
    $checks = @{
        "SourceProvided" = @{ Weight = 30; Pass = (-not [string]::IsNullOrEmpty($EvidenceData.SourceUrl)) }
        "PublisherKnown" = @{ Weight = 25; Pass = (-not [string]::IsNullOrEmpty($EvidenceData.Publisher)) }
        "DateProvided" = @{ Weight = 20; Pass = ($EvidenceData.DatePublished -and $EvidenceData.DatePublished -ne "Unknown") }
        "KindnessAlignment" = @{ Weight = 15; Pass = ($EvidenceData.Approach -eq "Collaborative") }
        "DefamationSafe" = @{ Weight = 10; Pass = (-not ($EvidenceData.Summary -match "(pedo|terrorist|criminal)" -and -not $EvidenceData.Summary -match "convicted")) }
    }
    
    $totalScore = 0
    $maxScore = ($checks.Values | Measure-Object -Property Weight -Sum).Sum
    
    foreach ($checkName in $checks.Keys) {
        $check = $checks[$checkName]
        if ($check.Pass) {
            $totalScore += $check.Weight
            Write-CodexLog "  ? $checkName passed (+$($check.Weight) points)" "SUCCESS"
        } else {
            $truthCheck.Issues += $checkName
            Write-CodexLog "  ?? $checkName requires attention" "WARN"
        }
    }
    
    $truthCheck.Score = [math]::Round(($totalScore / $maxScore) * 100, 1)
    
    if ($truthCheck.Score -ge 80) {
        $truthCheck.Verified = $true
        Write-CodexLog "?? Truth Filter PASSED: Evidence verified with $($truthCheck.Score)% integrity" "SUCCESS"
    } elseif ($truthCheck.Score -ge 60) {
        $truthCheck.Verified = $true
        Write-CodexLog "?? Truth Filter CONDITIONAL: Evidence passed with guidance ($($truthCheck.Score)% score)" "WARN"
    } else {
        $truthCheck.Verified = $false
        Write-CodexLog "? Truth Filter REQUIRES ATTENTION: Evidence needs strengthening ($($truthCheck.Score)% score)" "ERROR"
    }
    
    return $truthCheck
}

function Invoke-CodexAnalysis {
    param([string]$Query, [string]$SystemPrompt)
    
    try {
        Write-CodexLog "?? Generating evidence-based fact card with collaborative wisdom..." "INFO"
        
        $fullPrompt = @"
$SystemPrompt

COLLABORATIVE CONTEXT:
- Live Share Fleet: Direct LAN optimized for real-time collaboration
- Development Environment: C++14 standard
- Behavioral OS: Active with kindness-driven workflows
- Collaboration Motto: $($Global:Motto)

EVIDENCE REQUEST: $Query

Generate a FACT CARD that maintains both evidence integrity and collaborative kindness.
Format: 
**FACT:** [Clear, verifiable statement]
**SOURCE:** [Publisher, Date - URL]
**CONTEXT:** [Background and relevance]
**COLLABORATION NOTE:** [Guidance for team review]
**CONFIDENCE:** [High/Medium/Low with reasoning]

Requirements:
- Every substantive claim must have a verifiable source
- Use precise, court-appropriate language
- Encourage team discussion and peer review
- Maintain collaborative spirit throughout
- If evidence is insufficient, state clearly: "No record. Integrity demands silence here."
"@

        $requestBody = @{
            model = "mistral:latest"
            prompt = $fullPrompt
            stream = $false
            options = @{
                temperature = 0.3  # Lower for factual accuracy
                top_p = 0.9
                num_predict = 1024
            }
        } | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod -Uri "$OllamaEndpoint/api/generate" -Method Post -Body $requestBody -ContentType "application/json" -TimeoutSec 120
        
        Write-CodexLog "? Evidence analysis completed with collaborative integrity" "SUCCESS"
        return $response.response
        
    } catch {
        Write-CodexLog "? Evidence analysis failed: $_" "ERROR"
        return "Analysis unavailable - maintaining evidence standards with patience. Please verify sources manually and apply collaborative review."
    }
}

function Add-EvidenceLedgerEntry {
    param([hashtable]$EvidenceData)
    
    Write-CodexLog "?? Adding entry to evidence ledger..." "EVIDENCE"
    
    # Create CSV if it doesn't exist
    if (-not (Test-Path $ledgerFile)) {
        $csvHeader = "claim_id,topic,summary,source_url,publisher,date_published,confidence,collaboration_notes,truth_filter_score,timestamp"
        $csvHeader | Set-Content $ledgerFile -Encoding UTF8
    }
    
    # Prepare CSV entry
    $csvEntry = @(
        $EvidenceData.ClaimId,
        $EvidenceData.Topic,
        "`"$($EvidenceData.Summary -replace '"', '""')`"",  # Escape quotes
        $EvidenceData.SourceUrl,
        $EvidenceData.Publisher,
        $EvidenceData.DatePublished,
        $EvidenceData.Confidence,
        "`"$($EvidenceData.CollaborationNotes -replace '"', '""')`"",
        $EvidenceData.TruthFilterScore,
        $EvidenceData.Timestamp
    ) -join ","
    
    Add-Content -Path $ledgerFile -Value $csvEntry -Encoding UTF8
    Write-CodexLog "? Evidence ledger updated with new entry" "SUCCESS"
}

function New-FactCard {
    param([string]$Topic, [string]$Analysis, [hashtable]$EvidenceData, [object]$TruthCheck)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $factCardId = if ($ClaimId) { $ClaimId } else { "FC-$(Get-Date -Format 'yyyyMMdd-HHmmss')" }
    
    # Apply Truth Filter validation
    $truthStatus = if ($TruthCheck.Verified) { 
        "? VERIFIED (Score: $($TruthCheck.Score)%)" 
    } else { 
        "?? REQUIRES REVIEW (Score: $($TruthCheck.Score)%)" 
    }
    
    $issuesText = if ($TruthCheck.Issues.Count -gt 0) {
        "**Issues to Address:** " + ($TruthCheck.Issues -join ", ")
    } else {
        "**Validation:** All checks passed"
    }
    
    $factCard = @"
# FACT CARD: $Topic
**ID:** $factCardId
**Generated:** $timestamp
**Truth Filter Status:** $truthStatus
**Collaboration Motto:** $($Global:Motto)

---

$Analysis

---

## EVIDENCE METADATA
- **Confidence Level:** $($EvidenceData.Confidence)
- **Source Quality:** $(if ($EvidenceData.SourceUrl) { "URL Provided" } else { "No Source" })
- **Publisher:** $(if ($EvidenceData.Publisher) { $EvidenceData.Publisher } else { "Unknown" })
- **Collaborative Approach:** Peer review encouraged

## TRUTH FILTER VALIDATION
$issuesText

**Verification Score:** $($TruthCheck.Score)% 
**Recommended Action:** $(if ($TruthCheck.Verified) { "Approved for collaborative sharing" } else { "Requires additional evidence or team review" })

---

## COLLABORATION GUIDELINES
- **Team Review:** All members encouraged to validate sources and evidence quality
- **Discussion Welcome:** Questions and additional evidence contributions appreciated
- **Kindness Required:** Maintain respectful discourse in all evidence discussions
- **Standards:** Court-level precision required for serious allegations

## NEXT STEPS
1. Share with Live Share team for peer review
2. Validate sources independently where possible  
3. Encourage team discussion of evidence quality
4. Update evidence ledger with team findings
5. Apply collaborative wisdom to strengthen analysis

---
**Integration Note:** This fact card was generated within the PrecisePointway Live Share collaborative environment, integrating BigCodex evidence standards with Behavioral OS truth validation.

*Generated by BigCodex Truth Engine with collaborative safeguards*
*"In a world you can be anything – be nice."*
"@

    $outputFile = Join-Path $outputDir "factcard_$factCardId.md"
    $factCard | Set-Content $outputFile -Encoding UTF8
    
    Write-CodexLog "?? Fact card created: $outputFile" "SUCCESS"
    
    # Add to evidence ledger
    $evidenceEntry = @{
        ClaimId = $factCardId
        Topic = $Topic
        Summary = $Analysis.Substring(0, [Math]::Min(200, $Analysis.Length)) + "..."
        SourceUrl = $EvidenceData.SourceUrl
        Publisher = $EvidenceData.Publisher
        DatePublished = $EvidenceData.DatePublished
        Confidence = $EvidenceData.Confidence
        CollaborationNotes = "Generated with collaborative review encouraged"
        TruthFilterScore = $TruthCheck.Score
        Timestamp = $timestamp
    }
    
    Add-EvidenceLedgerEntry -EvidenceData $evidenceEntry
    
    # Share with fleet if requested
    if ($FleetShare) {
        try {
            $nasOutputDir = Join-Path $Global:OpsRoot "codex\outputs"
            New-Item -ItemType Directory -Force -Path $nasOutputDir | Out-Null
            Copy-Item $outputFile $nasOutputDir -Force
            
            # Also copy to Live Share coordination directory
            $liveShareDir = Join-Path $Global:OpsRoot "LiveShare"
            if (Test-Path $liveShareDir) {
                Copy-Item $outputFile $liveShareDir -Force
            }
            
            Write-CodexLog "?? Fact card shared with Live Share fleet for collaborative review" "SUCCESS"
        } catch {
            Write-CodexLog "?? Failed to share with fleet: $_" "WARN"
        }
    }
    
    return $outputFile
}

# Main execution
Write-CodexLog $Global:Motto "MOTTO"
Write-CodexLog "?? Starting BigCodex fact card generation with collaborative truth-seeking..." "INFO"

# Get topic if not provided
if (-not $Topic) {
    $Topic = Read-Host "Enter topic for fact card analysis"
}

if (-not $Topic) {
    Write-CodexLog "? Topic required for evidence analysis" "ERROR"
    exit 1
}

# Prepare evidence data
$evidenceData = @{
    ClaimId = if ($ClaimId) { $ClaimId } else { "FC-$(Get-Date -Format 'yyyyMMdd-HHmmss')" }
    Topic = $Topic
    SourceUrl = $SourceUrl
    Publisher = $Publisher
    DatePublished = if ($SourceUrl) { (Get-Date).ToString("yyyy-MM-dd") } else { "Unknown" }
    Confidence = $Confidence
    Approach = "Collaborative"
}

# Load system prompt
$systemPrompt = if (Test-Path $promptFile) { 
    Get-Content $promptFile -Raw 
} else { 
    Write-CodexLog "?? System prompt not found, using default collaborative truth guidelines" "WARN"
    @"
Generate evidence-based fact cards with collaborative integrity.
Requirements: Verifiable sources, court-precise language, team review encouraged.
Motto: $($Global:Motto)
"@
}

# Validate evidence quality with Truth Filter
$truthCheck = Invoke-TruthFilterValidation -EvidenceData $evidenceData

# Generate analysis only if evidence meets minimum standards
if ($truthCheck.Score -ge 40 -or -not $ValidateEvidence) {
    $analysisQuery = "Generate evidence-based fact card for: $Topic"
    if ($SourceUrl) { $analysisQuery += " (Source: $SourceUrl)" }
    
    $analysis = Invoke-CodexAnalysis -Query $analysisQuery -SystemPrompt $systemPrompt
    
    # Create fact card with evidence validation
    $factCardFile = New-FactCard -Topic $Topic -Analysis $analysis -EvidenceData $evidenceData -TruthCheck $truthCheck
    
    Write-CodexLog "?? Fact card generation completed with evidence integrity!" "SUCCESS"
    Write-CodexLog "?? Output: $factCardFile" "INFO"
    
    if ($FleetShare) {
        Write-CodexLog "?? Fact card shared with Live Share fleet for collaborative review" "INFO"
        Write-CodexLog "?? Team members can now validate evidence and contribute additional sources" "INFO"
    }
    
    if (-not $truthCheck.Verified) {
        Write-CodexLog ""
        Write-CodexLog "?? COLLABORATIVE REVIEW NEEDED:" "WARN"
        Write-CodexLog "   This fact card requires team review to strengthen evidence quality" "WARN"
        Write-CodexLog "   Consider: Additional sources, date verification, collaborative validation" "WARN"
        Write-CodexLog "   Remember: $($Global:Motto)" "MOTTO"
    }
    
} else {
    Write-CodexLog ""
    Write-CodexLog "? Evidence quality insufficient for fact card generation" "ERROR"
    Write-CodexLog "   Truth Filter Score: $($truthCheck.Score)% (minimum 40% required)" "ERROR"
    Write-CodexLog "   Missing elements: $($truthCheck.Issues -join ', ')" "ERROR"
    Write-CodexLog ""
    Write-CodexLog "?? Suggestions for improvement:" "INFO"
    Write-CodexLog "   - Provide verifiable source URL" "INFO"
    Write-CodexLog "   - Include publisher information" "INFO"
    Write-CodexLog "   - Use collaborative, non-inflammatory language" "INFO"
    Write-CodexLog "   - Apply court-level precision to claims" "INFO"
    Write-CodexLog ""
    Write-CodexLog "?? Consider team collaboration to gather stronger evidence" "INFO"
}

Write-CodexLog ""
Write-CodexLog $Global:Motto "MOTTO"
Write-CodexLog "?? Evidence ledger location: $ledgerFile" "INFO"
Write-CodexLog "?? For collaborative review, share fact cards via Live Share session" "INFO"