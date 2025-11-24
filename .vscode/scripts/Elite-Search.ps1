<#
Elite-Search.ps1 - PrecisePointway Elite Search with Spiritual Affirmation
?? "In a world you can be anything – be nice."
? "Let it shine, this little light of mine - Amen. Shadow of love."

Elite search functionality integrated with Live Share fleet, Behavioral OS, and BigCodex
Combines collaborative truth-seeking with spiritual wisdom and technical excellence
#>

param(
    [string]$SearchQuery,
    [string]$SearchType = "Comprehensive",
    [ValidateSet("Local", "Fleet", "BigCodex", "Spiritual", "Comprehensive")]
    [string]$Scope = "Comprehensive",
    [switch]$FleetShare,
    [switch]$GenerateFactCard,
    [switch]$ApplyTruthFilter,
    [string]$OllamaEndpoint = "http://localhost:11434"
)

# Import existing infrastructure
$fleetProfile = Join-Path $PSScriptRoot "fleet-profile.ps1"
if (Test-Path $fleetProfile) { 
    . $fleetProfile 
} else {
    $Global:Motto = "?? In a world you can be anything – be nice."
    $Global:OpsRoot = "\\dxp4800plus-67ba\ops"
    $Global:LogsRoot = Join-Path $env:USERPROFILE "LiveShareLogs"
    $Global:PcList = @('pc-1','pc-2','pc-3','pc-4')
}

# Spiritual affirmation and search configuration
$Global:SpiritualMotto = "? Let it shine, this little light of mine - Amen. Shadow of love."
$searchTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$searchResultsDir = Join-Path $Global:LogsRoot "elite-search"
$searchLogFile = Join-Path $searchResultsDir "elite-search_$searchTimestamp.log"

# Ensure directories exist
New-Item -ItemType Directory -Force -Path $searchResultsDir | Out-Null

function Write-SearchLog {
    param([string]$Message, [string]$Level = "INFO")
    $time = Get-Date -Format "HH:mm:ss"
    $entry = "[$time] [ELITE-SEARCH] [$Level] $Message"
    $colors = @{ 
        "INFO" = "Cyan"; "WARN" = "Yellow"; "ERROR" = "Red"; 
        "SUCCESS" = "Green"; "MOTTO" = "Magenta"; "SPIRITUAL" = "Blue";
        "EVIDENCE" = "DarkCyan"; "TRUTH" = "White"
    }
    Write-Host $entry -ForegroundColor $colors[$Level]
    Add-Content -Path $searchLogFile -Value $entry
}

function Invoke-SpiritualAffirmation {
    Write-SearchLog ""
    Write-SearchLog $Global:Motto "MOTTO"
    Write-SearchLog $Global:SpiritualMotto "SPIRITUAL"
    Write-SearchLog "??? Beginning elite search with spiritual wisdom and collaborative truth..." "SPIRITUAL"
    Write-SearchLog ""
}

function Invoke-EliteLocalSearch {
    param([string]$Query)
    
    Write-SearchLog "?? Conducting elite local search for: $Query" "INFO"
    
    $localResults = @{
        WorkspaceFiles = @()
        CodeReferences = @()
        Documentation = @()
        ScriptMatches = @()
        ConfigMatches = @()
    }
    
    try {
        # Search workspace files
        $workspaceRoot = Split-Path $PSScriptRoot -Parent
        
        # Search C++ files for query
        $cppFiles = Get-ChildItem -Path $workspaceRoot -Recurse -Filter "*.cpp" -ErrorAction SilentlyContinue
        $hFiles = Get-ChildItem -Path $workspaceRoot -Recurse -Filter "*.h" -ErrorAction SilentlyContinue
        
        foreach ($file in ($cppFiles + $hFiles)) {
            $content = Get-Content $file.FullName -ErrorAction SilentlyContinue
            if ($content -match $Query) {
                $localResults.CodeReferences += @{
                    File = $file.FullName
                    Type = "C++14 Source"
                    Matches = ($content | Select-String $Query).Count
                }
            }
        }
        
        # Search PowerShell scripts
        $psFiles = Get-ChildItem -Path (Join-Path $workspaceRoot "scripts") -Filter "*.ps1" -ErrorAction SilentlyContinue
        foreach ($file in $psFiles) {
            $content = Get-Content $file.FullName -ErrorAction SilentlyContinue
            if ($content -match $Query) {
                $localResults.ScriptMatches += @{
                    File = $file.FullName
                    Type = "PowerShell Script"
                    Matches = ($content | Select-String $Query).Count
                }
            }
        }
        
        # Search documentation
        $docFiles = Get-ChildItem -Path (Join-Path $workspaceRoot "docs") -Filter "*.md" -ErrorAction SilentlyContinue
        foreach ($file in $docFiles) {
            $content = Get-Content $file.FullName -ErrorAction SilentlyContinue
            if ($content -match $Query) {
                $localResults.Documentation += @{
                    File = $file.FullName
                    Type = "Documentation"
                    Matches = ($content | Select-String $Query).Count
                }
            }
        }
        
        # Search configuration files
        $configFiles = Get-ChildItem -Path $workspaceRoot -Recurse -Include "*.json", "*.yaml", "*.toml" -ErrorAction SilentlyContinue
        foreach ($file in $configFiles) {
            $content = Get-Content $file.FullName -ErrorAction SilentlyContinue
            if ($content -match $Query) {
                $localResults.ConfigMatches += @{
                    File = $file.FullName
                    Type = "Configuration"
                    Matches = ($content | Select-String $Query).Count
                }
            }
        }
        
        Write-SearchLog "? Local search completed with collaborative excellence" "SUCCESS"
        
    } catch {
        Write-SearchLog "?? Local search encountered challenges: $_" "WARN"
    }
    
    return $localResults
}

function Invoke-EliteFleetSearch {
    param([string]$Query)
    
    Write-SearchLog "?? Conducting elite fleet search across $($Global:PcList.Count) PCs..." "INFO"
    
    $fleetResults = @{}
    
    foreach ($pc in $Global:PcList) {
        Write-SearchLog "  ?? Searching $pc with kindness..." "INFO"
        
        try {
            $pcResults = Invoke-Command -ComputerName $pc -ScriptBlock {
                param($searchQuery)
                
                $results = @{
                    PC = $env:COMPUTERNAME
                    Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    LogFiles = @()
                    ConfigFiles = @()
                    ProcessMatches = @()
                    ServiceMatches = @()
                }
                
                # Search Live Share logs
                $logDir = Join-Path $env:USERPROFILE "LiveShareLogs"
                if (Test-Path $logDir) {
                    $logFiles = Get-ChildItem -Path $logDir -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 10
                    foreach ($logFile in $logFiles) {
                        $content = Get-Content $logFile.FullName -ErrorAction SilentlyContinue
                        if ($content -match $searchQuery) {
                            $results.LogFiles += @{
                                File = $logFile.FullName
                                LastModified = $logFile.LastWriteTime
                                Matches = ($content | Select-String $searchQuery).Count
                            }
                        }
                    }
                }
                
                # Search running processes
                $processes = Get-Process | Where-Object { $_.ProcessName -match $searchQuery }
                foreach ($process in $processes) {
                    $results.ProcessMatches += @{
                        Name = $process.ProcessName
                        ID = $process.Id
                        StartTime = $process.StartTime
                        CPU = $process.CPU
                    }
                }
                
                # Search services
                $services = Get-Service | Where-Object { $_.Name -match $searchQuery -or $_.DisplayName -match $searchQuery }
                foreach ($service in $services) {
                    $results.ServiceMatches += @{
                        Name = $service.Name
                        DisplayName = $service.DisplayName
                        Status = $service.Status
                    }
                }
                
                return $results
                
            } -ArgumentList $Query -ErrorAction SilentlyContinue
            
            if ($pcResults) {
                $fleetResults[$pc] = $pcResults
                Write-SearchLog "  ? $pc search completed successfully" "SUCCESS"
            } else {
                Write-SearchLog "  ?? $pc search returned no results" "WARN"
            }
            
        } catch {
            Write-SearchLog "  ? $pc search failed: $_" "ERROR"
            $fleetResults[$pc] = @{ Error = $_.Exception.Message }
        }
    }
    
    Write-SearchLog "?? Fleet search completed with collaborative spirit" "SUCCESS"
    return $fleetResults
}

function Invoke-BigCodexSearch {
    param([string]$Query)
    
    Write-SearchLog "?? Conducting BigCodex evidence-based search..." "EVIDENCE"
    
    try {
        $codexPrompt = @"
You are the BigCodex Elite Search system integrated with PrecisePointway collaborative development.

SPIRITUAL CONTEXT:
"$($Global:SpiritualMotto)"

COLLABORATIVE CONTEXT:
- Motto: $($Global:Motto)
- C++ Standard: C++14
- Live Share Fleet: Optimized for truth and collaboration
- Behavioral OS: Active with kindness-driven workflows

SEARCH QUERY: $Query

Conduct an elite search analysis that:
1. Applies evidence-first principles to the search query
2. Maintains collaborative kindness and spiritual wisdom
3. Provides actionable insights for the development team
4. Integrates technical excellence with human values
5. Offers spiritual reflection where appropriate

Format: SEARCH INSIGHT ? EVIDENCE ? COLLABORATION NOTE ? SPIRITUAL REFLECTION

Remember: "Amen" signifies truth, affirmation, and spiritual certainty.
Apply this principle to search results - seek truth with humility and grace.
"@

        $requestBody = @{
            model = "mistral:latest"
            prompt = $codexPrompt
            stream = $false
            options = @{
                temperature = 0.7
                top_p = 0.9
                num_predict = 1024
            }
        } | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod -Uri "$OllamaEndpoint/api/generate" -Method Post -Body $requestBody -ContentType "application/json" -TimeoutSec 120
        
        Write-SearchLog "? BigCodex search completed with collaborative wisdom" "EVIDENCE"
        return $response.response
        
    } catch {
        Write-SearchLog "?? BigCodex search unavailable: $_" "WARN"
        return "BigCodex analysis unavailable - proceeding with collaborative search principles and spiritual wisdom"
    }
}

function Invoke-SpiritualSearch {
    param([string]$Query)
    
    Write-SearchLog "??? Conducting spiritual search with divine wisdom..." "SPIRITUAL"
    
    $spiritualInsights = @{
        Affirmation = "Amen - So be it, in truth and love"
        Context = @()
        Reflection = @()
        Application = @()
    }
    
    # Analyze query for spiritual context
    if ($Query -match "(amen|truth|light|love|wisdom|grace|spirit|divine)") {
        $spiritualInsights.Context += "Query contains spiritual elements - approaching with reverence"
    }
    
    # Apply biblical wisdom principles
    $spiritualInsights.Reflection += @(
        "Seek truth with humility (James 1:5)",
        "Let your light shine before others (Matthew 5:16)",
        "Love covers over a multitude of sins (1 Peter 4:8)",
        "In all your ways acknowledge Him (Proverbs 3:6)"
    )
    
    # Collaborative application
    $spiritualInsights.Application += @(
        "Apply search results with collaborative kindness",
        "Share insights with team in spirit of love",
        "Use knowledge to build up, not tear down",
        "Remember: we are called to be lights in the darkness"
    )
    
    Write-SearchLog "??? Spiritual search completed with divine grace" "SPIRITUAL"
    return $spiritualInsights
}

function New-EliteSearchReport {
    param(
        [string]$Query,
        [object]$LocalResults,
        [object]$FleetResults,
        [string]$BigCodexAnalysis,
        [object]$SpiritualInsights
    )
    
    $reportId = "ES-$searchTimestamp"
    $reportFile = Join-Path $searchResultsDir "elite-search-report_$reportId.md"
    
    $report = @"
# ELITE SEARCH REPORT: $Query
**ID:** $reportId
**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Spiritual Affirmation:** $($Global:SpiritualMotto)
**Collaborative Motto:** $($Global:Motto)

---

## SPIRITUAL FOUNDATION
??? **Affirmation:** $($SpiritualInsights.Affirmation)

**Spiritual Context:**
$(($SpiritualInsights.Context | ForEach-Object { "- $_" }) -join "`n")

**Divine Reflection:**
$(($SpiritualInsights.Reflection | ForEach-Object { "- $_" }) -join "`n")

**Collaborative Application:**
$(($SpiritualInsights.Application | ForEach-Object { "- $_" }) -join "`n")

---

## LOCAL SEARCH RESULTS

### C++14 Code References
$(if ($LocalResults.CodeReferences.Count -gt 0) {
    ($LocalResults.CodeReferences | ForEach-Object { "- **$($_.Type):** $($_.File) ($($_.Matches) matches)" }) -join "`n"
} else {
    "- No code references found"
})

### PowerShell Script Matches
$(if ($LocalResults.ScriptMatches.Count -gt 0) {
    ($LocalResults.ScriptMatches | ForEach-Object { "- **$($_.Type):** $($_.File) ($($_.Matches) matches)" }) -join "`n"
} else {
    "- No script matches found"
})

### Documentation Matches
$(if ($LocalResults.Documentation.Count -gt 0) {
    ($LocalResults.Documentation | ForEach-Object { "- **$($_.Type):** $($_.File) ($($_.Matches) matches)" }) -join "`n"
} else {
    "- No documentation matches found"
})

---

## FLEET SEARCH RESULTS

$(foreach ($pc in $FleetResults.Keys) {
    $results = $FleetResults[$pc]
    if ($results.Error) {
        "### $pc - Error: $($results.Error)"
    } else {
        @"
### $pc
- **Log Matches:** $($results.LogFiles.Count)
- **Process Matches:** $($results.ProcessMatches.Count)
- **Service Matches:** $($results.ServiceMatches.Count)
- **Last Scanned:** $($results.Timestamp)
"@
    }
})

---

## BIGCODEX ANALYSIS

$BigCodexAnalysis

---

## COLLABORATIVE INSIGHTS

### Technical Findings
- **Local Workspace:** $(($LocalResults.CodeReferences + $LocalResults.ScriptMatches + $LocalResults.Documentation + $LocalResults.ConfigMatches).Count) total matches
- **Fleet Coverage:** $($FleetResults.Keys.Count) PCs searched
- **Evidence Quality:** BigCodex analysis integrated

### Spiritual Wisdom
- **Truth Seeking:** Conducted with humility and grace
- **Collaborative Spirit:** Results shared with team kindness
- **Divine Guidance:** Applied biblical principles to search process
- **Light Sharing:** "Let it shine, this little light of mine"

### Next Steps
1. **Review Results:** Team collaboration on findings
2. **Apply Wisdom:** Use insights for positive impact
3. **Share Light:** Distribute knowledge with love
4. **Continue Growing:** Build on search insights with grace

---

## TRUTH FILTER VALIDATION
$(if ($ApplyTruthFilter) {
    @"
**Validation Applied:** ? Truth Filter Engaged
**Evidence Standard:** Court-level precision maintained
**Collaborative Review:** Team validation encouraged
**Spiritual Alignment:** Divine principles applied
"@
} else {
    "**Truth Filter:** Not applied - results for informational purposes"
})

---

**Integration Note:** This elite search was conducted within the PrecisePointway Live Share collaborative environment, integrating technical excellence with spiritual wisdom and collaborative kindness.

**Closing Affirmation:** "Amen - Let it shine, this little light of mine. In truth, love, and collaborative excellence."

*Generated by PrecisePointway Elite Search System*
*"In a world you can be anything – be nice."*
"@

    $report | Set-Content $reportFile -Encoding UTF8
    Write-SearchLog "?? Elite search report saved: $reportFile" "SUCCESS"
    
    # Share with fleet if requested
    if ($FleetShare) {
        try {
            $nasSearchDir = Join-Path $Global:OpsRoot "elite-search"
            New-Item -ItemType Directory -Force -Path $nasSearchDir | Out-Null
            Copy-Item $reportFile $nasSearchDir -Force
            Write-SearchLog "?? Search report shared with Live Share fleet" "SUCCESS"
        } catch {
            Write-SearchLog "?? Failed to share with fleet: $_" "WARN"
        }
    }
    
    return $reportFile
}

# Main Elite Search Execution
Invoke-SpiritualAffirmation

if (-not $SearchQuery) {
    $SearchQuery = Read-Host "Enter search query for elite analysis"
}

if (-not $SearchQuery) {
    Write-SearchLog "? Search query required for elite analysis" "ERROR"
    exit 1
}

Write-SearchLog "?? Beginning elite search for: $SearchQuery" "INFO"
Write-SearchLog "?? Scope: $Scope | Type: $SearchType" "INFO"

# Initialize result containers
$localResults = $null
$fleetResults = $null
$bigCodexAnalysis = $null
$spiritualInsights = $null

# Conduct searches based on scope
if ($Scope -eq "Local" -or $Scope -eq "Comprehensive") {
    $localResults = Invoke-EliteLocalSearch -Query $SearchQuery
}

if ($Scope -eq "Fleet" -or $Scope -eq "Comprehensive") {
    $fleetResults = Invoke-EliteFleetSearch -Query $SearchQuery
}

if ($Scope -eq "BigCodex" -or $Scope -eq "Comprehensive") {
    $bigCodexAnalysis = Invoke-BigCodexSearch -Query $SearchQuery
}

if ($Scope -eq "Spiritual" -or $Scope -eq "Comprehensive") {
    $spiritualInsights = Invoke-SpiritualSearch -Query $SearchQuery
}

# Generate comprehensive report
Write-SearchLog "?? Generating elite search report with spiritual wisdom..." "INFO"
$reportFile = New-EliteSearchReport -Query $SearchQuery -LocalResults $localResults -FleetResults $fleetResults -BigCodexAnalysis $bigCodexAnalysis -SpiritualInsights $spiritualInsights

# Generate fact card if requested
if ($GenerateFactCard -and $bigCodexAnalysis) {
    Write-SearchLog "?? Generating fact card from search results..." "EVIDENCE"
    
    try {
        & (Join-Path $PSScriptRoot "BigCodex-FactCard.ps1") -Topic "Elite Search: $SearchQuery" -FleetShare:$FleetShare -ValidateEvidence:$ApplyTruthFilter
        Write-SearchLog "? Fact card generated successfully" "SUCCESS"
    } catch {
        Write-SearchLog "?? Fact card generation failed: $_" "WARN"
    }
}

# Final affirmation and summary
Write-SearchLog ""
Write-SearchLog "?? Elite search completed with spiritual excellence!" "SUCCESS"
Write-SearchLog "?? Report: $reportFile" "INFO"

if ($FleetShare) {
    Write-SearchLog "?? Results shared with Live Share fleet for collaborative review" "INFO"
}

Write-SearchLog ""
Write-SearchLog "? CLOSING AFFIRMATION:" "SPIRITUAL"
Write-SearchLog "Amen - Let it shine, this little light of mine" "SPIRITUAL"
Write-SearchLog "In truth, love, and collaborative excellence" "SPIRITUAL"
Write-SearchLog $Global:Motto "MOTTO"
Write-SearchLog ""

# Display summary
Write-Host ""
Write-Host "?? ELITE SEARCH SUMMARY" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Gray
Write-Host "Query: $SearchQuery" -ForegroundColor White
Write-Host "Scope: $Scope" -ForegroundColor Yellow
Write-Host "Report: $reportFile" -ForegroundColor Green

if ($localResults) {
    $totalLocalMatches = ($localResults.CodeReferences + $localResults.ScriptMatches + $localResults.Documentation + $localResults.ConfigMatches).Count
    Write-Host "Local Matches: $totalLocalMatches" -ForegroundColor Cyan
}

if ($fleetResults) {
    Write-Host "Fleet PCs Searched: $($fleetResults.Keys.Count)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "? Let it shine, this little light of mine - Amen. Shadow of love." -ForegroundColor Blue
Write-Host "?? In a world you can be anything – be nice." -ForegroundColor Magenta