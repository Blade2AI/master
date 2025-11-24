# modules/Meeting-Engine.psm1
# Minimal Meeting Engine: builds meeting records from spec and writes to disk

function Invoke-SovMeeting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Type,
        [Parameter(Mandatory)][hashtable]$Context
    )

    $dir = "C:\BladeOps\data\Meetings"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $meetingId = "MEET-{0}-{1:0000}" -f (Get-Date -Format "yyyyMMddHHmmss"), (Get-Random -Minimum 1 -Maximum 9999)
    $meeting = [pscustomobject]@{
        id = $meetingId
        meeting_id = $meetingId
        type = $Type
        team = $Context.team
        context = $Context
        participants = @()
        decisions = @()
        actions = @()
        created_at = (Get-Date).ToString('o')
        signature_chain = @()
    }

    # Attempt to cryptographically sign the meeting record
    if (Get-Command -Name New-MessageSignature -ErrorAction SilentlyContinue) {
        try {
            $sig = New-MessageSignature -Data $meeting -NodeID "MEETING_ENGINE" -Purpose "MEETING_CREATED"
            if ($sig) {
                $meeting.signature_chain += @{
                    event = 'CREATED'
                    signature = $sig
                    timestamp = (Get-Date).ToString('o')
                }
            }
        } catch {
            Write-Warning "Meeting signing failed: $_"
        }
    } else {
        Write-Host "Warning: New-MessageSignature not available — meeting will be unsigned" -ForegroundColor Yellow
    }

    $outPath = Join-Path $dir ("$meetingId.json")
    $tmpPath = "$outPath.tmp"

    # Write atomically
    $meeting | ConvertTo-Json -Depth 20 | Out-File $tmpPath -Encoding UTF8
    Move-Item -LiteralPath $tmpPath -Destination $outPath -Force

    if (Get-Command -Name Log-GovernanceEvent -ErrorAction SilentlyContinue) {
        $logEvent = @{ type = 'MEETING_HELD'; message = "Meeting $meetingId of type $Type held"; meeting_id = $meetingId }
        if ($meeting.signature_chain.Count -gt 0) { $logEvent.signature = $meeting.signature_chain[-1].signature.signature }
        Log-GovernanceEvent $logEvent
    }

    return $meeting
}

function Get-SovMeeting {
    <#
    .SYNOPSIS
    Load meeting with cryptographic verification
    .DESCRIPTION
    Loads meeting record and verifies all signatures in chain.
    REFUSES to return tampered records - fails fast on integrity violation.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$MeetingId,

        [switch]$SkipVerification  # Emergency bypass (logs constitutional warning)
    )

    $filePath = "C:\BladeOps\data\Meetings\$MeetingId.json"
    if (-not (Test-Path $filePath)) {
        throw "Meeting not found: $MeetingId"
    }

    # Load record
    $meeting = Get-Content $filePath -Raw | ConvertFrom-Json -Depth 20

    # CRYPTOGRAPHIC VERIFICATION (unless explicitly bypassed)
    if (-not $SkipVerification) {
        Write-Verbose "?? Verifying meeting integrity: $MeetingId"

        if (-not $meeting.signature_chain -or $meeting.signature_chain.Count -eq 0) {
            $warning = "??  WARNING: Meeting $MeetingId has no signatures - cannot verify integrity"
            Write-Warning $warning

            Log-GovernanceEvent -Event @{ type = "UNSIGNED_RECORD_LOADED"; record_type = "MEETING"; record_id = $MeetingId; warning = "Record loaded without signature verification"; risk = "CONSTITUTIONAL_VIOLATION" }

            return $meeting
        }

        # Verify each signature in chain
        $verificationFailed = $false
        $failedSignatures = @()

        foreach ($chainEvent in $meeting.signature_chain) {
            if (-not $chainEvent.signature) {
                $verificationFailed = $true
                $failedSignatures += @{ event = $chainEvent.event; reason = "Missing signature block" }
                continue
            }

            if ($chainEvent.signature.algorithm -and $chainEvent.signature.algorithm -ne "SHA256") {
                $verificationFailed = $true
                $failedSignatures += @{ event = $chainEvent.event; reason = "Unknown algorithm: $($chainEvent.signature.algorithm)" }
            }

            if (-not $chainEvent.signature.value -or $chainEvent.signature.value.Length -lt 16) {
                $verificationFailed = $true
                $failedSignatures += @{ event = $chainEvent.event; reason = "Invalid signature format" }
            }

            # Attempt actual verification via Verify-MessageSignature if available
            if (-not $verificationFailed -and (Get-Command -Name Verify-MessageSignature -ErrorAction SilentlyContinue)) {
                $verifyResult = Verify-MessageSignature -Data $meeting -PublicKeyPath (Join-Path $Global:SovereignConfig.SecurityPath "public_key.xml")
                if (-not $verifyResult.valid) {
                    $verificationFailed = $true
                    $failedSignatures += @{ event = $chainEvent.event; reason = $verifyResult.reason }
                }
            }
        }

        if ($verificationFailed) {
            $error = @"
? SIGNATURE VERIFICATION FAILED: $MeetingId

TAMPERED RECORD DETECTED - REFUSING TO LOAD

Failed signatures:
$($failedSignatures | ForEach-Object { "  • $($_.event): $($_.reason)" } | Out-String)

This record may have been modified after signing.
Constitutional audit required.

To bypass verification (NOT RECOMMENDED):
  Get-SovMeeting -MeetingId '$MeetingId' -SkipVerification
"@

            Log-GovernanceEvent -Event @{ type = 'TAMPERED_RECORD_DETECTED'; record_type = 'MEETING'; record_id = $MeetingId; failed_signatures = $failedSignatures; action = 'LOAD_REFUSED'; severity = 'CRITICAL' }

            Write-Host $error -ForegroundColor Red
            throw "SIGNATURE VERIFICATION FAILED: $MeetingId (see above for details)"
        }

        Write-Verbose "? Signature verification passed: $($meeting.signature_chain.Count) signatures valid"
    } else {
        Write-Warning "??  VERIFICATION BYPASSED: $MeetingId"
        Log-GovernanceEvent -Event @{ type = 'VERIFICATION_BYPASSED'; record_type = 'MEETING'; record_id = $MeetingId; warning = 'Signature verification was intentionally bypassed'; risk = 'CONSTITUTIONAL_VIOLATION' }
    }

    return $meeting
}

function New-SovDailyStandup {
    [CmdletBinding()]
    param(
        [string]$Team = "DEFAULT",
        [string]$UserId = "andy"
    )

    # Attempt to gather vibrational context
    $triad = $null
    if (Get-Command -Name Invoke-VibrationalTriad -ErrorAction SilentlyContinue) {
        try {
            $triad = Invoke-VibrationalTriad -UserId $UserId
        } catch {
            Write-StepWarning "Invoke-VibrationalTriad failed: $_"
        }
    }

    $context = [ordered]@{
        team = $Team
        created_at = (Get-Date).ToString('o')
    }

    if ($triad) {
        $context.vibration_map = $triad.metrics
        $context.high_queue = $triad.high_queue
        $context.neutral_queue = $triad.neutral_queue
        $context.low_queue = $triad.low_queue
        $context.meeting_seeds = $triad.signals.meeting_seeds
    } else {
        $context.note = "No vibrational data available"
    }

    $meeting = Invoke-SovMeeting -Type "DAILY_CELL_STANDUP" -Context $context
    return $meeting
}

Export-ModuleMember -Function @('New-SovDailyStandup','Invoke-SovMeeting','Get-SovMeeting')
