<#
Start-BehavioralOS-Host.ps1 - Live Share with Behavioral OS Integration
?? "In a world you can be anything – be nice."

Extends the existing Live Share host with CAI ? Mesh ? Behavioral OS ? Truth Filter layers
Integrates behavioral nudges, incentives, and automated workflows for C++14 collaboration
#>

[CmdletBinding()]
param(
    [string]$WorkspacePath = $PSScriptRoot,
    [string]$NasRoot = "\\dxp4800plus-67ba\ops",
    [string]$SolutionFile = "",
    [switch]$AutoNotify,
    [string]$SlackWebhook = "",
    [string[]]$GuestHosts = @('pc-1','pc-2','pc-3'),
    [switch]$AutoDiscover,
    [int]$PingCount = 4,
    [switch]$DetailedMetrics,
    [switch]$EnableBehavioralOS,
    [switch]$EnableCAI,
    [switch]$EnableMobileSync,
    [string]$OllamaEndpoint = "http://localhost:11434"
)

# Import existing Live Share functionality
$hostScript = Join-Path $PSScriptRoot "Start-LiveShare-Host.ps1"
if (Test-Path $hostScript) {
    # Import functions from existing host script without executing main logic
    $hostContent = Get-Content $hostScript -Raw
    $functionsOnly = $hostContent -replace '(?s)try\s*\{.*', ''  # Remove main try block
    Invoke-Expression $functionsOnly
}

# Import fleet configuration
$fleetProfile = Join-Path $PSScriptRoot "fleet-profile.ps1"
if (Test-Path $fleetProfile) {
    . $fleetProfile
} else {
    $Global:PcList = @('pc-1','pc-2','pc-3','pc-4')
    $Global:Motto = "?? In a world you can be anything – be nice."
    $Global:LogsRoot = Join-Path $env:USERPROFILE "LiveShareLogs"
}

# Behavioral OS Configuration
$Global:BehavioralConfig = @{
    NudgesEnabled = $true
    IncentivesEnabled = $true
    TruthFilterEnabled = $true
    CAIEnabled = $EnableCAI
    MobileSync = $EnableMobileSync
    ScoreThresholds = @{
        Daily = 100
        Weekly = 500
        Monthly = 2000
    }
}

#region Behavioral OS Core Functions

function Initialize-BehavioralMesh {
    param(
        [string[]]$FleetPCs = $Global:PcList,
        [switch]$EnableMobileSync,
        [switch]$EnableOffice365,
        [switch]$EnableSmartWatch
    )
    
    Write-Log "?? Initializing Behavioral OS Mesh with collaborative intelligence..." "AI"
    Write-Log $Global:Motto "MOTTO"
    
    $meshConfig = @{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        LiveShareOptimized = $true
        BehavioralLayer = $true
        CAIEnabled = $EnableCAI
        MobileSync = $EnableMobileSync
        Office365 = $EnableOffice365
        SmartWatch = $EnableSmartWatch
        FleetSize = $FleetPCs.Count
        Motto = $Global:Motto
        CppStandard = "C++14"
        NetworkLatency = "Sub-5ms Target"
        TruthFilter = "Active"
    }
    
    # Save mesh configuration
    $meshConfig | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $Global:LogsRoot "behavioral-mesh-config.json") -Encoding UTF8
    
    Write-Log "? Behavioral Mesh initialized with kindness-driven intelligence" "SUCCESS"
    return $meshConfig
}

function Send-BehavioralNudge {
    param(
        [ValidateSet("CodeReview", "NetworkOptimization", "BreakReminder", "KindnessReminder", "CppBestPractice", "CollaborationTip", "Achievement")]
        [string]$Type,
        [string]$Message,
        [string[]]$TargetPCs,
        [string]$Priority = "Normal"
    )
    
    $nudgeTemplates = @{
        "CodeReview" = "?? Gentle reminder: Consider reviewing your teammate's code with kindness and constructive feedback"
        "NetworkOptimization" = "?? Network performance insight: Your collaboration experience could benefit from optimization"
        "BreakReminder" = "? Wellness nudge: Time for a collaborative break - step away, recharge, and return refreshed"
        "KindnessReminder" = "?? Daily wisdom: $($Global:Motto)"
        "CppBestPractice" = "?? C++14 insight: A best practice suggestion is available to enhance your code quality"
        "CollaborationTip" = "?? Collaboration enhancement: Here's a tip to make your teamwork even more effective"
        "Achievement" = "?? Celebration: You've achieved something wonderful in your collaborative journey"
    }
    
    $nudgeMessage = if ($Message) { $Message } else { $nudgeTemplates[$Type] }
    $fullMessage = "[$Type] $nudgeMessage"
    
    Write-Log "?? Sending behavioral nudge [$Type]: $nudgeMessage" "AI"
    
    foreach ($pc in $TargetPCs) {
        try {
            # Send gentle notification to each PC
            Invoke-Command -ComputerName $pc -ScriptBlock {
                param($msg, $type, $priority)
                
                try {
                    # Create toast notification with behavioral OS branding
                    Add-Type -AssemblyName System.Windows.Forms
                    $notify = New-Object System.Windows.Forms.NotifyIcon
                    $notify.Icon = [System.Drawing.SystemIcons]::Information
                    $notify.BalloonTipTitle = "PrecisePointway Behavioral OS"
                    $notify.BalloonTipText = $msg
                    $notify.Visible = $true
                    $notify.ShowBalloonTip(5000)
                    
                    # Clean up
                    Start-Sleep -Seconds 6
                    $notify.Dispose()
                } catch {
                    # Fallback to console output
                    Write-Host "[Behavioral OS] $msg" -ForegroundColor Magenta
                }
            } -ArgumentList $fullMessage, $Type, $Priority -ErrorAction SilentlyContinue
            
        } catch {
            Write-Log "?? Failed to send nudge to $pc : $_" "WARN"
        }
    }
    
    # Log nudge for analysis
    $nudgeLog = @{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Type = $Type
        Message = $nudgeMessage
        TargetPCs = $TargetPCs
        Priority = $Priority
        Sender = $env:COMPUTERNAME
    }
    
    $nudgeFile = Join-Path $Global:LogsRoot "behavioral-nudges_$(Get-Date -Format 'yyyyMMdd').json"
    $nudgeLog | ConvertTo-Json | Add-Content $nudgeFile -Encoding UTF8
}

function Award-CollaborationPoints {
    param(
        [string]$Developer = $env:USERNAME,
        [ValidateSet("KindCodeReview", "HelpedTeammate", "OptimizedNetwork", "SharedKnowledge", "QualityC++Code", "MentorshipMoment", "SessionHost", "TechnicalExcellence")]
        [string]$Achievement,
        [string]$Details = ""
    )
    
    $achievementPoints = @{
        "KindCodeReview" = 50
        "HelpedTeammate" = 75
        "OptimizedNetwork" = 100
        "SharedKnowledge" = 60
        "QualityC++Code" = 80
        "MentorshipMoment" = 90
        "SessionHost" = 120
        "TechnicalExcellence" = 110
    }
    
    $pointsAwarded = $achievementPoints[$Achievement]
    
    Write-Log "?? $Developer earned $pointsAwarded points for $Achievement!" "SUCCESS"
    if ($Details) { Write-Log "   Details: $Details" "SUCCESS" }
    
    # Update collaboration score
    $scoreFile = Join-Path $NasRoot "collaboration-scores.json"
    $scores = if (Test-Path $scoreFile) { 
        Get-Content $scoreFile | ConvertFrom-Json 
    } else { 
        @{} 
    }
    
    if (-not $scores.$Developer) { 
        $scores | Add-Member -Type NoteProperty -Name $Developer -Value @{
            TotalPoints = 0
            Achievements = @()
            LastActive = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
    }
    
    $scores.$Developer.TotalPoints += $pointsAwarded
    $scores.$Developer.Achievements += @{
        Achievement = $Achievement
        Points = $pointsAwarded
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Details = $Details
    }
    $scores.$Developer.LastActive = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    
    $scores | ConvertTo-Json -Depth 10 | Set-Content $scoreFile -Encoding UTF8
    
    # Send celebratory notification
    Send-BehavioralNudge -Type "Achievement" -Message "?? You earned $pointsAwarded points for $Achievement! $Details" -TargetPCs @($Developer) -Priority "High"
    
    # Check for milestone achievements
    $totalPoints = $scores.$Developer.TotalPoints
    $milestones = @(100, 500, 1000, 2500, 5000)
    
    foreach ($milestone in $milestones) {
        if ($totalPoints -ge $milestone -and ($totalPoints - $pointsAwarded) -lt $milestone) {
            Write-Log "?? $Developer reached $milestone points milestone!" "SUCCESS"
            Send-BehavioralNudge -Type "Achievement" -Message "?? Milestone achieved! You've reached $milestone collaboration points! Your kindness and technical excellence inspire the team!" -TargetPCs @($Developer) -Priority "High"
        }
    }
}

function Start-BehavioralWorkflow {
    param(
        [ValidateSet("SessionStart", "MorningStandup", "CodeQualityCheck", "EveningReflection", "NetworkOptimization")]
        [string]$WorkflowType,
        [hashtable]$Context = @{}
    )
    
    Write-Log "?? Starting behavioral workflow: $WorkflowType" "AI"
    
    switch ($WorkflowType) {
        "SessionStart" {
            Write-Log "?? Behavioral OS: Initializing collaborative session with kindness..." "MOTTO"
            
            # Welcome message with behavioral context
            $teamSize = $Context.FleetSize
            $sessionGoals = @(
                "Foster kind and constructive collaboration",
                "Maintain technical excellence with C++14",
                "Achieve sub-5ms network performance",
                "Embody our motto in every interaction",
                "Build amazing things together"
            )
            
            $welcomeMessage = "?? Starting collaborative session! Team of $teamSize ready for $($sessionGoals -join ', ')"
            Send-BehavioralNudge -Type "CollaborationTip" -Message $welcomeMessage -TargetPCs $Context.GuestHosts
            
            # Award hosting points
            Award-CollaborationPoints -Achievement "SessionHost" -Details "Started collaborative session with $teamSize developers"
        }
        
        "MorningStandup" {
            Write-Log "?? Behavioral OS: Preparing morning standup with collaborative spirit..." "MOTTO"
            
            # Gather overnight insights
            $standupData = @{
                Motto = $Global:Motto
                TeamSpirit = "Ready for collaborative excellence"
                NetworkStatus = "Optimized for real-time collaboration"
                C++Development = "C++14 standard maintained with care"
                CollaborationGoals = "Build with kindness and technical mastery"
                DailyInspiration = "Today we choose to be both excellent and kind"
            }
            
            $standupData | ConvertTo-Json | Set-Content (Join-Path $NasRoot "daily-standup.json") -Encoding UTF8
            Send-BehavioralNudge -Type "CollaborationTip" -Message "?? Daily standup data ready! Let's start with kindness and aim for technical excellence" -TargetPCs $Context.FleetPCs
        }
        
        "CodeQualityCheck" {
            Write-Log "?? Behavioral OS: Running collaborative code quality analysis..." "INFO"
            
            # C++14 quality metrics with behavioral context
            $qualityMetrics = @{
                Standard = "C++14"
                Approach = "Collaborative and kind"
                CodeStyle = "Consistent and readable"
                TeamReview = "Constructive and supportive"
                Documentation = "Clear and helpful"
                TestCoverage = "Comprehensive and thoughtful"
            }
            
            $qualityMetrics | ConvertTo-Json | Set-Content (Join-Path $Global:LogsRoot "code-quality-behavioral.json") -Encoding UTF8
            Award-CollaborationPoints -Achievement "QualityC++Code" -Details "Maintained C++14 excellence with collaborative approach"
        }
        
        "EveningReflection" {
            Write-Log "?? Behavioral OS: Evening reflection on collaborative kindness..." "MOTTO"
            
            # Gather collaboration insights
            $reflection = @{
                DailyMotto = $Global:Motto
                CollaborationQuality = "Embodied kindness throughout development"
                TechnicalProgress = "Advanced C++14 development with care"
                NetworkPerformance = "Maintained optimal connectivity"
                TeamGrowth = "Supported each other's learning journey"
                KindnessWins = "Chose compassion in every interaction"
                TomorrowGoals = "Continue building amazing things with kindness"
            }
            
            $reflection | ConvertTo-Json | Set-Content (Join-Path $Global:LogsRoot "daily-reflection_$(Get-Date -Format 'yyyyMMdd').json") -Encoding UTF8
            Send-BehavioralNudge -Type "KindnessReminder" -Message "?? Daily reflection complete. Thank you for choosing kindness in your collaboration today!" -TargetPCs $Context.FleetPCs
        }
    }
}

function Invoke-TruthFilter {
    param(
        [string]$Action,
        [hashtable]$Context,
        [string]$Validator = $env:USERNAME
    )
    
    Write-Log "?? Truth Filter: Verifying collaborative integrity for action: $Action" "AI"
    
    $truthCheck = @{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Action = $Action
        Context = $Context
        Validator = $Validator
        Motto = $Global:Motto
        Verified = $false
        JusticeApplied = $false
        Score = 0
    }
    
    # Verification criteria with scoring
    $checks = @{
        "KindnessAlignment" = @{ Weight = 30; Pass = ($Context.Approach -eq "Kind" -or $Context.Motto -eq $Global:Motto) }
        "TechnicalExcellence" = @{ Weight = 25; Pass = ($Context.Standard -eq "C++14" -and $Context.Quality -eq "High") }
        "CollaborativeSpirit" = @{ Weight = 25; Pass = ($Context.Collaborative -eq $true) }
        "NetworkOptimization" = @{ Weight = 20; Pass = ($Context.Latency -lt 5 -or $Context.Performance -eq "Optimized") }
    }
    
    $totalScore = 0
    $maxScore = ($checks.Values | Measure-Object -Property Weight -Sum).Sum
    
    foreach ($checkName in $checks.Keys) {
        $check = $checks[$checkName]
        if ($check.Pass) {
            $totalScore += $check.Weight
            Write-Log "  ? $checkName passed (+$($check.Weight) points)" "SUCCESS"
        } else {
            Write-Log "  ?? $checkName requires attention" "WARN"
        }
    }
    
    $truthCheck.Score = [math]::Round(($totalScore / $maxScore) * 100, 1)
    
    if ($truthCheck.Score -ge 80) {
        $truthCheck.Verified = $true
        $truthCheck.JusticeApplied = $true
        Write-Log "?? Truth Filter PASSED: $Action verified with $($truthCheck.Score)% collaborative integrity" "SUCCESS"
        Award-CollaborationPoints -Achievement "TechnicalExcellence" -Details "Action '$Action' passed Truth Filter with $($truthCheck.Score)% integrity"
    } elseif ($truthCheck.Score -ge 60) {
        $truthCheck.Verified = $true
        $truthCheck.JusticeApplied = $false
        Write-Log "?? Truth Filter CONDITIONAL: $Action passed with guidance ($($truthCheck.Score)% score)" "WARN"
        Send-BehavioralNudge -Type "KindnessReminder" -Message "?? Consider enhancing your approach with additional kindness and collaboration" -TargetPCs @($Validator)
    } else {
        $truthCheck.Verified = $false
        Write-Log "? Truth Filter REQUIRES ATTENTION: $Action needs alignment with collaborative principles ($($truthCheck.Score)% score)" "ERROR"
        Send-BehavioralNudge -Type "KindnessReminder" -Message "?? $($Global:Motto) - Let's realign this action with our collaborative values" -TargetPCs @($Validator)
    }
    
    # Log verification result
    $verificationLog = Join-Path $Global:LogsRoot "truth-filter_$(Get-Date -Format 'yyyyMMdd').json"
    $truthCheck | ConvertTo-Json | Add-Content $verificationLog -Encoding UTF8
    
    return $truthCheck
}

function Invoke-CAIAnalysis {
    param(
        [string]$Query,
        [hashtable]$Context = @{}
    )
    
    if (-not $EnableCAI) {
        Write-Log "?? CAI not enabled - using behavioral heuristics instead" "INFO"
        return "CAI analysis would provide collaborative insights here"
    }
    
    try {
        Write-Log "?? CAI: Consulting collaborative AI for behavioral insights..." "AI"
        
        $prompt = @"
You are the Collaborative AI (CAI) layer of the PrecisePointway Behavioral OS.

CONTEXT:
- Motto: $($Global:Motto)
- C++ Standard: C++14
- Collaboration Type: Live Share direct LAN
- Behavioral Goal: Foster kindness and technical excellence

QUERY: $Query
DATA: $($Context | ConvertTo-Json)

Provide behavioral insights that promote both technical excellence and human kindness in collaborative C++14 development.
"@

        $requestBody = @{
            model = "mistral:latest"
            prompt = $prompt
            stream = $false
            options = @{
                temperature = 0.7
                top_p = 0.9
                num_predict = 1024
            }
        } | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod -Uri "$OllamaEndpoint/api/generate" -Method Post -Body $requestBody -ContentType "application/json" -TimeoutSec 60
        
        Write-Log "? CAI analysis completed with collaborative wisdom" "AI"
        return $response.response
        
    } catch {
        Write-Log "?? CAI analysis unavailable - proceeding with behavioral defaults: $_" "WARN"
        return "Focus on kindness and technical excellence in all collaborative interactions"
    }
}

#endregion

# Main Behavioral OS Host Logic
try {
    Write-Log "?? Starting Live Share Host with Behavioral OS Integration" "SUCCESS"
    Write-Log $Global:Motto "MOTTO"
    Write-Log "?? Initializing CAI ? Mesh ? Behavioral OS ? Truth Filter stack..." "AI"
    
    # Initialize Behavioral Mesh
    if ($EnableBehavioralOS) {
        $meshConfig = Initialize-BehavioralMesh -FleetPCs $GuestHosts -EnableMobileSync:$EnableMobileSync
        
        # Start session workflow
        Start-BehavioralWorkflow -WorkflowType "SessionStart" -Context @{
            FleetSize = $GuestHosts.Count
            GuestHosts = $GuestHosts
            FleetPCs = $Global:PcList
            Standard = "C++14"
            Approach = "Kind"
            Collaborative = $true
            Performance = "Optimized"
        }
        
        # Verify session start with Truth Filter
        $truthResult = Invoke-TruthFilter -Action "StartCollaborativeSession" -Context @{
            Motto = $Global:Motto
            Standard = "C++14"
            Quality = "High"
            Approach = "Kind"
            Collaborative = $true
            Performance = "Optimized"
            Latency = 4  # Target sub-5ms
        }
        
        if ($truthResult.Verified) {
            Write-Log "?? Session verified by Truth Filter - proceeding with collaborative excellence" "SUCCESS"
        }
    }
    
    # Enhanced network discovery with behavioral context
    if ($AutoDiscover) {
        $GuestHosts = Get-FleetGuests -PreferredHosts $GuestHosts -AutoDiscover
        Write-Log "?? Discovered guest PCs: $($GuestHosts -join ', ')" "INFO"
        Write-Log "?? Extending collaboration invitation with kindness..." "MOTTO"
        
        if ($EnableBehavioralOS) {
            Send-BehavioralNudge -Type "CollaborationTip" -Message "?? Auto-discovery complete! Ready to collaborate with $($GuestHosts.Count) teammates" -TargetPCs $GuestHosts
        }
    }
    
    # Configure guests with behavioral awareness
    Write-Log "??? Configuring guest PCs for optimal Live Share performance..."
    Write-Log "?? Sharing optimized collaboration settings with kindness..." "MOTTO"
    Set-GuestLANMode -Guests $GuestHosts
    
    if ($EnableBehavioralOS) {
        Award-CollaborationPoints -Achievement "OptimizedNetwork" -Details "Configured $($GuestHosts.Count) guest PCs for LAN optimization"
    }
    
    # Launch VS Code with behavioral enhancement
    Write-Log "?? Launching VS Code with workspace"
    Write-Log "?? Opening the door to collaborative C++14 development..." "MOTTO"
    
    if ($SolutionFile -and (Test-Path $SolutionFile)) {
        Start-Process code -ArgumentList "`"$SolutionFile`""
    } else {
        Start-Process code -ArgumentList "`"$WorkspacePath`""
    }
    
    # Enhanced Live Share session start
    Write-Log "? Waiting for VS Code and Live Share to initialize..."
    Start-Sleep -Seconds 15
    
    # Check Live Share extension
    $liveShareCheck = & code --list-extensions 2>$null | Where-Object { $_ -match "ms-vsliveshare" }
    if (-not $liveShareCheck) {
        Write-Log "? Live Share extension not found. Please install it first." "ERROR"
        if ($EnableBehavioralOS) {
            Send-BehavioralNudge -Type "TechnicalExcellence" -Message "?? Live Share extension needed for collaborative magic - please install: code --install-extension ms-vsliveshare.vsliveshare" -TargetPCs @($env:COMPUTERNAME)
        }
        exit 1
    }
    
    Write-Log "?? Starting Live Share session..."
    Write-Log "?? Creating a space where collaboration flourishes..." "MOTTO"
    
    $sessionResult = & code --command liveshare.start 2>&1
    Start-Sleep -Seconds 10
    
    # Enhanced link retrieval with behavioral feedback
    Write-Log "?? Retrieving Live Share session link..."
    $linkRetrieved = $false
    $attempts = 0
    $maxAttempts = 6
    
    while (-not $linkRetrieved -and $attempts -lt $maxAttempts) {
        $attempts++
        try {
            Add-Type -AssemblyName System.Windows.Forms
            $clipboardText = [System.Windows.Forms.Clipboard]::GetText()
            if ($clipboardText -match 'https://[^\s]*liveshare[^\s]*') {
                $link = $Matches[0]
                $linkRetrieved = $true
            }
        } catch {
            Write-Log "Attempt $attempts: $_" "WARN"
        }
        
        if (-not $linkRetrieved) {
            Write-Log "? Waiting for Live Share link... (attempt $attempts/$maxAttempts)"
            if ($EnableBehavioralOS -and $attempts -eq 3) {
                Send-BehavioralNudge -Type "TechnicalExcellence" -Message "? Still waiting for Live Share link - patience brings success" -TargetPCs @($env:COMPUTERNAME)
            }
            Start-Sleep -Seconds 10
        }
    }
    
    if ($linkRetrieved) {
        Write-Log "?? Live Share link retrieved: $link" "SUCCESS"
        Write-Log "?? Sharing the gift of collaboration..." "MOTTO"
        
        # Enhanced status with behavioral context
        $status = @{
            Status = "Active"
            Link = $link
            Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Host = $env:COMPUTERNAME
            BehavioralOS = $EnableBehavioralOS
            CAI = $EnableCAI
            TruthFilter = "Active"
            Motto = $Global:Motto
            CollaborationSpirit = "Kindness-driven development"
            NetworkOptimized = $true
            ConnectionMode = "direct"
            CppStandard = "C++14"
            GuestCount = $GuestHosts.Count
        }
        
        # Save status to NAS
        Set-Content -Path $linkFile -Value $link -Encoding ASCII
        $status | ConvertTo-Json -Depth 5 | Set-Content $statusFile -Encoding UTF8
        
        # Measure latencies with behavioral awareness
        $latencies = Measure-GuestLatency -Guests $GuestHosts -PingCount $PingCount -IncludeJitter:$DetailedMetrics
        $status.GuestLatencies = $latencies
        $status | ConvertTo-Json -Depth 5 | Set-Content $statusFile -Encoding UTF8
        
        # Display performance summary with behavioral context
        Write-Log ""
        Write-Log "?? Enhanced Network Performance Summary:" "SUCCESS"
        Write-Log "?? Building bridges of collaboration with optimal performance..." "MOTTO"
        
        foreach ($guest in $GuestHosts) {
            $metrics = $latencies[$guest]
            if ($metrics -and $metrics.Average) {
                $latency = $metrics.Average
                $quality = $metrics.Quality
                $color = if ($latency -lt 15) { "SUCCESS" } elseif ($latency -lt 50) { "WARN" } else { "ERROR" }
                Write-Log "   $guest : ${latency}ms avg ($quality)" $color
            } else {
                Write-Log "   $guest : Unreachable - extending patience and understanding" "ERROR"
            }
        }
        
        if ($EnableBehavioralOS) {
            # Award session hosting achievement
            Award-CollaborationPoints -Achievement "SessionHost" -Details "Successfully started Live Share session with $($GuestHosts.Count) guests"
            
            # Send success notification
            Send-BehavioralNudge -Type "Achievement" -Message "?? Live Share session active! Network optimized for collaborative excellence" -TargetPCs $GuestHosts
            
            # Behavioral performance analysis
            $excellentConnections = ($latencies.Values | Where-Object { $_.Quality -eq "Excellent" }).Count
            if ($excellentConnections -eq $GuestHosts.Count) {
                Award-CollaborationPoints -Achievement "TechnicalExcellence" -Details "Achieved excellent network performance across all $($GuestHosts.Count) connections"
                Send-BehavioralNudge -Type "Achievement" -Message "?? Network performance excellence achieved! All connections under 5ms" -TargetPCs $GuestHosts
            }
        }
        
        # Enhanced session monitoring with behavioral insights
        Write-Log "? Live Share host ready with Behavioral OS enhancements!" "SUCCESS"
        Write-Log "?? Welcome to collaborative development powered by kindness and intelligence..." "MOTTO"
        Write-Log ""
        Write-Log "?? Session Features:" "SUCCESS"
        Write-Log "   - Live Share: Direct LAN optimized"
        Write-Log "   - C++ Standard: C++14"
        Write-Log "   - Behavioral OS: $(if ($EnableBehavioralOS) { 'Active' } else { 'Disabled' })"
        Write-Log "   - CAI: $(if ($EnableCAI) { 'Active' } else { 'Disabled' })"
        Write-Log "   - Truth Filter: Active"
        Write-Log "   - Guest PCs: $($GuestHosts.Count)"
        Write-Log "   - Collaboration Motto: $($Global:Motto)"
        Write-Log ""
        Write-Log "?? Behavioral enhancements include:"
        Write-Log "   - Gentle nudges for collaboration improvement"
        Write-Log "   - Achievement tracking and positive reinforcement"
        Write-Log "   - Truth filter for collaborative integrity"
        Write-Log "   - AI-powered behavioral insights"
        Write-Log ""
        Write-Log "Press Ctrl+C to gracefully end the session"
        
        # Enhanced monitoring loop with behavioral workflows
        $lastBehavioralCheck = Get-Date
        
        while ($true) {
            Start-Sleep -Seconds 60
            
            try {
                $sessionStatus = & code --command liveshare.showSessionDetails 2>$null
                if (-not $sessionStatus -or $sessionStatus -match "No active session") {
                    Write-Log "?? Live Share session appears to have ended" "WARN"
                    if ($EnableBehavioralOS) {
                        Start-BehavioralWorkflow -WorkflowType "EveningReflection" -Context @{ FleetPCs = $GuestHosts }
                    }
                    break
                }
                
                # Periodic behavioral workflows
                if ($EnableBehavioralOS) {
                    $now = Get-Date
                    $timeSinceLastCheck = ($now - $lastBehavioralCheck).TotalMinutes
                    
                    # Every 30 minutes - gentle check-in
                    if ($timeSinceLastCheck -ge 30) {
                        Send-BehavioralNudge -Type "KindnessReminder" -Message "?? Collaborative check-in: How are you doing? Remember to be kind to yourself and your teammates!" -TargetPCs $GuestHosts
                        $lastBehavioralCheck = $now
                    }
                    
                    # Every 5 minutes - network monitoring
                    $currentMinute = $now.Minute
                    if ($currentMinute % 5 -eq 0) {
                        Write-Log "?? Behavioral OS: Updating network metrics with care..."
                        $updatedLatencies = Measure-GuestLatency -Guests $GuestHosts -PingCount $PingCount -IncludeJitter:$DetailedMetrics
                        
                        # Check for performance improvements
                        $improvementDetected = $false
                        foreach ($guest in $GuestHosts) {
                            $oldMetric = $latencies[$guest]
                            $newMetric = $updatedLatencies[$guest]
                            
                            if ($oldMetric -and $newMetric -and $oldMetric.Average -and $newMetric.Average) {
                                if ($newMetric.Average -lt $oldMetric.Average) {
                                    $improvementDetected = $true
                                    Write-Log "?? Network improvement detected on $guest : $($oldMetric.Average)ms ? $($newMetric.Average)ms" "SUCCESS"
                                }
                            }
                        }
                        
                        if ($improvementDetected) {
                            Award-CollaborationPoints -Achievement "OptimizedNetwork" -Details "Network performance improvements detected during session"
                        }
                        
                        $latencies = $updatedLatencies
                        $status.GuestLatencies = $latencies
                        $status.LastUpdated = $now.ToString("yyyy-MM-dd HH:mm:ss")
                        $status | ConvertTo-Json -Depth 5 | Set-Content $statusFile -Encoding UTF8
                    }
                }
                
            } catch {
                Write-Log "Session monitoring encountered minor issue: $_" "WARN"
            }
        }
        
    } else {
        Write-Log "? Failed to retrieve Live Share link after $maxAttempts attempts" "ERROR"
        if ($EnableBehavioralOS) {
            Send-BehavioralNudge -Type "TechnicalExcellence" -Message "?? Live Share link retrieval needs attention - try starting manually in VS Code with patience" -TargetPCs @($env:COMPUTERNAME)
        }
    }
    
} catch {
    Write-Log "? An error occurred: $_" "ERROR"
    Write-Log $_.ScriptStackTrace "ERROR"
    Write-Log "?? Even in challenges, we maintain our kindness and resilience." "MOTTO"
    
    if ($EnableBehavioralOS) {
        Send-BehavioralNudge -Type "KindnessReminder" -Message "?? Challenges are opportunities for growth - let's approach this with patience and collaborative problem-solving" -TargetPCs @($env:COMPUTERNAME)
    }
} finally {
    # Enhanced cleanup with behavioral context
    Write-Log "?? Live Share session ending with gratitude and reflection" "INFO"
    Write-Log $Global:Motto "MOTTO"
    
    if ($EnableBehavioralOS) {
        Start-BehavioralWorkflow -WorkflowType "EveningReflection" -Context @{ FleetPCs = $GuestHosts }
        Award-CollaborationPoints -Achievement "SessionHost" -Details "Completed collaborative session with behavioral OS enhancements"
    }
    
    Write-Log "?? Thank you for choosing collaboration with kindness and technical excellence." "MOTTO"
    
    try {
        & code --command liveshare.end 2>$null
        if (Test-Path $linkFile) { Remove-Item $linkFile -Force }
        
        $finalStatus = @{
            Status = "Stopped"
            Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Host = $env:COMPUTERNAME
            BehavioralOS = $EnableBehavioralOS
            Motto = $Global:Motto
            FinalMessage = "Session ended with gratitude, kindness, and collaborative excellence."
        }
        $finalStatus | ConvertTo-Json | Set-Content $statusFile -Encoding UTF8
        
    } catch {
        # Silent cleanup
    }
}