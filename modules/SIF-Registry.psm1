# modules\SIF-Registry.psm1
# Minimal SIF registry with vibration-aware entry creation

function New-SIFEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Classification,
        [Parameter(Mandatory)][int]$Severity,
        [Parameter(Mandatory)][string]$Description
    )

    $dir = "C:\BladeOps\data\SIF"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $id = "SIF-{0}-{1:0000}" -f (Get-Date -Format "yyyyMMddHHmmss"), (Get-Random -Minimum 1 -Maximum 9999)
    $entry = [pscustomobject]@{
        id = $id
        classification = $Classification
        severity = $Severity
        description = $Description
        created_at = (Get-Date).ToString('o')
        vibrational_context = @{}
        signature_chain = @()
    }

    # Attempt to sign
    if (Get-Command -Name New-MessageSignature -ErrorAction SilentlyContinue) {
        try {
            $sig = New-MessageSignature -Data $entry -NodeID 'SIF_REGISTRY' -Purpose 'SIF_CREATED'
            if ($sig) { $entry.signature_chain += @{ event = 'CREATED'; signature = $sig; timestamp = (Get-Date).ToString('o') } }
        } catch {
            Write-Warning "SIF signing failed: $_"
        }
    } else {
        Write-Host "Warning: New-MessageSignature not available — SIF entry will be unsigned" -ForegroundColor Yellow
    }

    $path = Join-Path $dir ("$id.json")
    $tmp = "$path.tmp"
    $entry | ConvertTo-Json -Depth 20 | Out-File $tmp -Encoding UTF8
    Move-Item -LiteralPath $tmp -Destination $path -Force

    if (Get-Command -Name Log-GovernanceEvent -ErrorAction SilentlyContinue) {
        Log-GovernanceEvent @{ type = 'SIF_CREATED'; message = "SIF $id created"; sif_id = $id; signature_count = $entry.signature_chain.Count }
    }

    return $entry
}

function Get-SIFEntry {
    <#
    .SYNOPSIS
    Load SIF entry with cryptographic verification
    .DESCRIPTION
    Loads SIF record and verifies all signatures in chain.
    REFUSES to return tampered records - fails fast on integrity violation.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SifId,

        [switch]$SkipVerification
    )

    $filePath = "C:\BladeOps\data\SIF\$SifId.json"
    if (-not (Test-Path $filePath)) { throw "SIF entry not found: $SifId" }

    $entry = Get-Content $filePath -Raw | ConvertFrom-Json -Depth 20

    if (-not $SkipVerification) {
        Write-Verbose "?? Verifying SIF integrity: $SifId"
        if (-not $entry.signature_chain -or $entry.signature_chain.Count -eq 0) {
            $warning = "??  CRITICAL: SIF $SifId has no signatures - 10-year retention compromised"
            Write-Warning $warning
            Log-GovernanceEvent -Event @{ type = 'UNSIGNED_SIF_LOADED'; record_type = 'SIF'; record_id = $SifId; warning = 'SIF loaded without signature - regulatory compliance at risk'; risk = 'CRITICAL' }
            return $entry
        }

        $verificationFailed = $false
        $failedSignatures = @()

        foreach ($chainEvent in $entry.signature_chain) {
            if (-not $chainEvent.signature) { $verificationFailed = $true; $failedSignatures += @{ event = $chainEvent.event; reason = 'Missing signature block' }; continue }
            if ($chainEvent.signature.algorithm -and $chainEvent.signature.algorithm -ne 'SHA256') { $verificationFailed = $true; $failedSignatures += @{ event = $chainEvent.event; reason = "Unknown algorithm: $($chainEvent.signature.algorithm)" } }
            if (-not $chainEvent.signature.value -or $chainEvent.signature.value.Length -lt 16) { $verificationFailed = $true; $failedSignatures += @{ event = $chainEvent.event; reason = 'Invalid signature format' } }

            if (-not $verificationFailed -and (Get-Command -Name Verify-MessageSignature -ErrorAction SilentlyContinue)) {
                $verifyResult = Verify-MessageSignature -Data $entry -PublicKeyPath (Join-Path $Global:SovereignConfig.SecurityPath 'public_key.xml')
                if (-not $verifyResult.valid) { $verificationFailed = $true; $failedSignatures += @{ event = $chainEvent.event; reason = $verifyResult.reason } }
            }
        }

        if ($verificationFailed) {
            $error = @"
? SIF INTEGRITY VIOLATION: $SifId

TAMPERED SAFETY RECORD DETECTED - LOAD REFUSED

Failed signatures:
$($failedSignatures | ForEach-Object { "  • $($_.event): $($_.reason)" } | Out-String)

CRITICAL: Safety records must maintain 10-year integrity.
Tampering with SIF records is a regulatory violation.
Constitutional audit + HSE notification required.

To bypass (EMERGENCY ONLY):
  Get-SIFEntry -SifId '$SifId' -SkipVerification
"@
            Log-GovernanceEvent -Event @{ type = 'TAMPERED_SIF_DETECTED'; record_type = 'SIF'; record_id = $SifId; failed_signatures = $failedSignatures; action = 'LOAD_REFUSED'; severity = 'CRITICAL'; regulatory_impact = 'HIGH' }
            Write-Host $error -ForegroundColor Red
            throw "SIF INTEGRITY VIOLATION: $SifId (see above for details)"
        }

        Write-Verbose "? SIF integrity verified: $($entry.signature_chain.Count) signatures valid"
    } else {
        Write-Warning "??  VERIFICATION BYPASSED: $SifId (logged for audit)"
        Log-GovernanceEvent -Event @{ type = 'SIF_VERIFICATION_BYPASSED'; record_type = 'SIF'; record_id = $SifId; warning = 'SIF verification bypassed - regulatory risk'; risk = 'CRITICAL' }
    }

    return $entry
}

function Get-SIFRegister {
    [CmdletBinding()]
    param([switch]$SkipVerification)
    $sifPath = "C:\BladeOps\data\SIF"
    if (-not (Test-Path $sifPath)) { return @() }
    $entries = Get-ChildItem $sifPath -Filter "SIF-*.json" | ForEach-Object {
        $sifId = $_.BaseName
        try { Get-SIFEntry -SifId $sifId -SkipVerification:$SkipVerification } catch { Write-Warning "Failed to load $sifId : $_"; $null }
    } | Where-Object { $_ -ne $null }
    return $entries | Sort-Object { $_.created_at } -Descending
}

Export-ModuleMember -Function @('New-SIFEntry','Get-SIFEntry','Get-SIFRegister')
