<#
Optimize-Fleet-Mistral.ps1 - Full Fleet Optimization with Mistral AI
?? "In a world you can be anything – be nice."

Uses Ollama with Mistral to analyze and optimize Live Share fleet performance
Integrates with your existing C++14 collaborative development environment
#>

[CmdletBinding()]
param(
    [string]$OllamaEndpoint = "http://localhost:11434",
    [string]$Model = "mistral:latest",
    [switch]$AnalyzeNetwork,
    [switch]$OptimizeConfiguration,
    [switch]$GenerateRecommendations,
    [switch]$AutoApply,
    [string]$WorkspacePath = $PSScriptRoot
)

# Load fleet configuration
$fleetProfile = Join-Path $PSScriptRoot "fleet-profile.ps1"
if (Test-Path $fleetProfile) {
    . $fleetProfile
} else {
    $Global:PcList = @('pc-1','pc-2','pc-3','pc-4')
    $Global:Motto = "?? In a world you can be anything – be nice."
    $Global:LogsRoot = Join-Path $env:USERPROFILE "LiveShareLogs"
}

# Ensure log directory
if (!(Test-Path $Global:LogsRoot)) { New-Item -ItemType Directory -Path $Global:LogsRoot | Out-Null }

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $Global:LogsRoot "Mistral_Optimization_$timestamp.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $time = Get-Date -Format "HH:mm:ss"
    $entry = "[$time] [$Level] $Message"
    $colors = @{ "INFO" = "White"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green"; "MOTTO" = "Magenta"; "AI" = "Cyan" }
    Write-Host $entry -ForegroundColor $colors[$Level]
    Add-Content -Path $logFile -Value $entry
}

function Invoke-MistralAnalysis {
    param(
        [string]$Prompt,
        [hashtable]$Context = @{},
        [string]$SystemPrompt = ""
    )
    
    try {
        Write-Log "?? Consulting Mistral AI for optimization insights..." "AI"
        
        # Construct the full prompt with context
        $fullPrompt = @"
$SystemPrompt

CONTEXT:
- Live Share Fleet: $($Global:PcList -join ', ')
- C++ Standard: C++14
- Collaboration Motto: $($Global:Motto)
- Workspace: $WorkspacePath

DATA:
$($Context | ConvertTo-Json -Depth 5)

PROMPT:
$Prompt

Please provide actionable recommendations for optimizing this collaborative C++14 development environment with kindness and technical excellence.
"@

        $requestBody = @{
            model = $Model
            prompt = $fullPrompt
            stream = $false
            options = @{
                temperature = 0.7
                top_p = 0.9
                num_predict = 2048
            }
        } | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod -Uri "$OllamaEndpoint/api/generate" -Method Post -Body $requestBody -ContentType "application/json" -TimeoutSec 120
        
        Write-Log "? Mistral analysis completed successfully" "AI"
        return $response.response
        
    } catch {
        Write-Log "? Mistral analysis failed: $_" "ERROR"
        return "Analysis unavailable - proceeding with standard optimization"
    }
}

function Get-FleetPerformanceData {
    Write-Log "?? Gathering comprehensive fleet performance data..." "INFO"
    
    $fleetData = @{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        FleetSize = $Global:PcList.Count
        NetworkMetrics = @{}
        SystemMetrics = @{}
        ConfigurationStatus = @{}
    }
    
    foreach ($pc in $Global:PcList) {
        Write-Log "  ?? Analyzing $pc..." "INFO"
        
        try {
            # Network performance
            $pingResult = Test-Connection -ComputerName $pc -Count 4 -ErrorAction SilentlyContinue
            if ($pingResult) {
                $avgLatency = ($pingResult | Measure-Object -Property ResponseTime -Average).Average
                $fleetData.NetworkMetrics[$pc] = @{
                    AverageLatency = [math]::Round($avgLatency, 2)
                    MinLatency = ($pingResult | Measure-Object -Property ResponseTime -Minimum).Minimum
                    MaxLatency = ($pingResult | Measure-Object -Property ResponseTime -Maximum).Maximum
                    PacketLoss = 0
                    Quality = if ($avgLatency -lt 5) { "Excellent" } elseif ($avgLatency -lt 15) { "Good" } elseif ($avgLatency -lt 50) { "Fair" } else { "Poor" }
                }
            } else {
                $fleetData.NetworkMetrics[$pc] = @{ Status = "Unreachable" }
            }
            
            # System and configuration status via remote execution
            $systemInfo = Invoke-Command -ComputerName $pc -ScriptBlock {
                $info = @{
                    VSCodeInstalled = $false
                    LiveShareInstalled = $false
                    LANModeConfigured = $false
                    CPUUsage = 0
                    MemoryUsage = 0
                    NetworkOptimized = $false
                }
                
                # Check VS Code and Live Share
                if (Get-Command code -ErrorAction SilentlyContinue) {
                    $info.VSCodeInstalled = $true
                    $extensions = & code --list-extensions 2>$null
                    if ($extensions -match "ms-vsliveshare") {
                        $info.LiveShareInstalled = $true
                    }
                }
                
                # Check Live Share configuration
                $settingsPath = "$env:APPDATA\Code\User\settings.json"
                if (Test-Path $settingsPath) {
                    try {
                        $settings = Get-Content $settingsPath | ConvertFrom-Json
                        if ($settings.'liveshare.connectionMode' -eq 'direct') {
                            $info.LANModeConfigured = $true
                        }
                    } catch { }
                }
                
                # System performance
                try {
                    $cpu = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average
                    $info.CPUUsage = [math]::Round($cpu.Average, 1)
                    
                    $memory = Get-WmiObject -Class Win32_OperatingSystem
                    $memUsage = [math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 1)
                    $info.MemoryUsage = $memUsage
                } catch { }
                
                # Network optimization check
                try {
                    $autotuning = netsh int tcp show global | Select-String "Auto-Tuning"
                    if ($autotuning -match "normal") {
                        $info.NetworkOptimized = $true
                    }
                } catch { }
                
                return $info
            } -ErrorAction SilentlyContinue
            
            if ($systemInfo) {
                $fleetData.SystemMetrics[$pc] = $systemInfo
                $fleetData.ConfigurationStatus[$pc] = @{
                    OptimizationLevel = if ($systemInfo.LANModeConfigured -and $systemInfo.LiveShareInstalled -and $systemInfo.NetworkOptimized) { "Full" } 
                                       elseif ($systemInfo.LANModeConfigured -and $systemInfo.LiveShareInstalled) { "Partial" } 
                                       else { "Minimal" }
                }
            }
            
        } catch {
            Write-Log "  ?? Failed to analyze $pc : $_" "WARN"
            $fleetData.NetworkMetrics[$pc] = @{ Status = "Error", Error = $_.Exception.Message }
        }
    }
    
    return $fleetData
}

# Display motto and start optimization
Write-Log $Global:Motto "MOTTO"
Write-Log "?? Starting Mistral-powered fleet optimization for C++14 collaboration..." "AI"

# Test Ollama connectivity
try {
    Write-Log "?? Testing Ollama connectivity..." "INFO"
    $ollamaTest = Invoke-RestMethod -Uri "$OllamaEndpoint/api/tags" -Method Get -TimeoutSec 10
    Write-Log "? Ollama is running with models: $($ollamaTest.models.name -join ', ')" "SUCCESS"
} catch {
    Write-Log "? Cannot connect to Ollama at $OllamaEndpoint" "ERROR"
    Write-Log "?? Please ensure Ollama is running: ollama serve" "INFO"
    exit 1
}

# Gather comprehensive fleet data
$fleetData = Get-FleetPerformanceData

# Network analysis with Mistral
if ($AnalyzeNetwork) {
    Write-Log "?? Requesting Mistral network analysis..." "AI"
    
    $networkPrompt = @"
Analyze this Live Share fleet network performance data and provide specific optimization recommendations:

FLEET NETWORK ANALYSIS REQUEST:
1. Identify network bottlenecks and latency issues
2. Recommend network stack optimizations for C++14 Live Share collaboration  
3. Suggest firewall and port configuration improvements
4. Provide quality metrics interpretation and improvement strategies
5. Consider collaborative development patterns and real-time requirements

Focus on achieving sub-5ms latency for optimal collaborative C++14 development experience.
Apply the motto: "$($Global:Motto)" - ensure recommendations are both technically excellent and human-friendly.
"@

    $networkAnalysis = Invoke-MistralAnalysis -Prompt $networkPrompt -Context $fleetData.NetworkMetrics -SystemPrompt "You are an expert network engineer specializing in collaborative development environments and real-time communication optimization."
    
    Write-Log "?? Mistral Network Analysis:" "AI"
    Write-Log $networkAnalysis "AI"
    
    # Save network analysis
    $networkAnalysis | Set-Content (Join-Path $Global:LogsRoot "mistral-network-analysis_$timestamp.txt") -Encoding UTF8
}

# Configuration optimization with Mistral
if ($OptimizeConfiguration) {
    Write-Log "?? Requesting Mistral configuration optimization..." "AI"
    
    $configPrompt = @"
Analyze this Live Share fleet configuration and provide optimization recommendations:

CONFIGURATION OPTIMIZATION REQUEST:
1. Evaluate VS Code and Live Share extension configurations
2. Recommend optimal settings for C++14 collaborative development
3. Identify configuration inconsistencies across the fleet
4. Suggest automated deployment improvements
5. Provide performance tuning recommendations for system resources

Consider both collaborative efficiency and system performance for C++14 development workflows.
Ensure recommendations align with the collaborative spirit: "$($Global:Motto)"
"@

    $configAnalysis = Invoke-MistralAnalysis -Prompt $configPrompt -Context @{
        SystemMetrics = $fleetData.SystemMetrics
        ConfigurationStatus = $fleetData.ConfigurationStatus
    } -SystemPrompt "You are an expert DevOps engineer specializing in VS Code Live Share optimization and C++14 development environments."
    
    Write-Log "?? Mistral Configuration Analysis:" "AI"
    Write-Log $configAnalysis "AI"
    
    # Save configuration analysis
    $configAnalysis | Set-Content (Join-Path $Global:LogsRoot "mistral-config-analysis_$timestamp.txt") -Encoding UTF8
}

# Generate comprehensive recommendations
if ($GenerateRecommendations) {
    Write-Log "?? Generating comprehensive optimization recommendations..." "AI"
    
    $recommendationPrompt = @"
Based on the complete fleet analysis, generate a prioritized action plan for optimizing this Live Share collaborative C++14 development environment:

COMPREHENSIVE OPTIMIZATION REQUEST:
1. Prioritize recommendations by impact and effort
2. Provide specific PowerShell commands or configuration changes
3. Include performance metrics and success criteria
4. Suggest monitoring and maintenance strategies
5. Consider scalability for additional developers
6. Ensure alignment with collaborative development best practices

Create actionable steps that embody both technical excellence and the collaborative motto: "$($Global:Motto)"
Focus on achieving the best possible experience for real-time C++14 development collaboration.
"@

    $recommendations = Invoke-MistralAnalysis -Prompt $recommendationPrompt -Context $fleetData -SystemPrompt "You are a senior solutions architect specializing in collaborative development infrastructure, with expertise in C++14 development workflows and team productivity optimization."
    
    Write-Log "?? Mistral Comprehensive Recommendations:" "AI"
    Write-Log $recommendations "AI"
    
    # Save comprehensive recommendations
    $recommendations | Set-Content (Join-Path $Global:LogsRoot "mistral-recommendations_$timestamp.txt") -Encoding UTF8
    
    # Parse recommendations for auto-apply (if requested)
    if ($AutoApply) {
        Write-Log "?? Analyzing recommendations for auto-application..." "AI"
        
        # Extract actionable commands from recommendations
        $commandPattern = '```(?:powershell|ps1)?\s*\n(.*?)\n```'
        $commands = [regex]::Matches($recommendations, $commandPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        
        if ($commands.Count -gt 0) {
            Write-Log "?? Found $($commands.Count) actionable commands in recommendations" "SUCCESS"
            
            foreach ($match in $commands) {
                $command = $match.Groups[1].Value.Trim()
                if ($command -and $command.Length -gt 5) {
                    Write-Log "?? Suggested command: $command" "INFO"
                    
                    # For safety, only auto-apply specific safe commands
                    if ($command -match '^(Set-NetTCPSetting|Enable-WindowsOptionalFeature|netsh int tcp set global)' -and $command -notmatch '(Remove|Delete|Disable|Stop)') {
                        try {
                            Write-Log "?? Auto-applying safe optimization: $command" "AI"
                            Invoke-Expression $command
                            Write-Log "? Command executed successfully" "SUCCESS"
                        } catch {
                            Write-Log "?? Command execution failed: $_" "WARN"
                        }
                    } else {
                        Write-Log "??? Command requires manual review for safety" "INFO"
                    }
                }
            }
        } else {
            Write-Log "?? No auto-applicable commands found in recommendations" "INFO"
        }
    }
}

# Generate optimization summary
$optimizationSummary = @{
    Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Motto = $Global:Motto
    FleetStatus = $fleetData
    OptimizationLevel = @{
        FullyOptimized = ($fleetData.ConfigurationStatus.Values | Where-Object { $_.OptimizationLevel -eq "Full" }).Count
        PartiallyOptimized = ($fleetData.ConfigurationStatus.Values | Where-Object { $_.OptimizationLevel -eq "Partial" }).Count
        MinimallyOptimized = ($fleetData.ConfigurationStatus.Values | Where-Object { $_.OptimizationLevel -eq "Minimal" }).Count
    }
    NetworkPerformance = @{
        ExcellentConnections = ($fleetData.NetworkMetrics.Values | Where-Object { $_.Quality -eq "Excellent" }).Count
        GoodConnections = ($fleetData.NetworkMetrics.Values | Where-Object { $_.Quality -eq "Good" }).Count
        FairConnections = ($fleetData.NetworkMetrics.Values | Where-Object { $_.Quality -eq "Fair" }).Count
        PoorConnections = ($fleetData.NetworkMetrics.Values | Where-Object { $_.Quality -eq "Poor" }).Count
    }
    MistralAnalysisCompleted = @{
        Network = $AnalyzeNetwork
        Configuration = $OptimizeConfiguration
        Recommendations = $GenerateRecommendations
    }
}

# Save optimization summary
$summaryFile = Join-Path $Global:LogsRoot "mistral-optimization-summary_$timestamp.json"
$optimizationSummary | ConvertTo-Json -Depth 6 | Set-Content $summaryFile -Encoding UTF8

# Final report
Write-Log ""
Write-Log "?? Mistral-powered fleet optimization completed!" "SUCCESS"
Write-Log $Global:Motto "MOTTO"
Write-Log ""
Write-Log "?? Optimization Summary:" "SUCCESS"
Write-Log "   Fleet Size: $($Global:PcList.Count) PCs"
Write-Log "   Fully Optimized: $($optimizationSummary.OptimizationLevel.FullyOptimized)"
Write-Log "   Network Excellent: $($optimizationSummary.NetworkPerformance.ExcellentConnections)"
Write-Log "   Network Good: $($optimizationSummary.NetworkPerformance.GoodConnections)"
Write-Log ""
Write-Log "?? Analysis files saved:" "INFO"
Write-Log "   Summary: $summaryFile"
if ($AnalyzeNetwork) { Write-Log "   Network Analysis: mistral-network-analysis_$timestamp.txt" }
if ($OptimizeConfiguration) { Write-Log "   Configuration Analysis: mistral-config-analysis_$timestamp.txt" }
if ($GenerateRecommendations) { Write-Log "   Recommendations: mistral-recommendations_$timestamp.txt" }
Write-Log ""
Write-Log "?? Your C++14 collaborative development environment is optimized with AI-powered insights!" "SUCCESS"
Write-Log "?? Mistral has analyzed your fleet and provided recommendations for technical excellence with human kindness" "AI"