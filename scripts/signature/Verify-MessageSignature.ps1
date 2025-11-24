<#
.SYNOPSIS
Verify a JSON object's signature using RSA public key stored in XML format.

.PARAMETER Data
A PowerShell object (from ConvertFrom-Json) or path to a JSON file containing the object with a `signature` field.

.PARAMETER PublicKeyPath
Path to public key XML (default: C:\BladeOps\Security\public_key.xml).

.RETURNS
A hashtable: @{ valid = $true|$false; reason = '<message>' }
#>

param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [AllowNull()][Parameter(ValueFromPipelineByPropertyName=$true)][object]$Data,

    [string]$PublicKeyPath = "C:\BladeOps\Security\public_key.xml"
)

function Convert-HexStringToBytes {
    param([string]$hex)
    $hex = $hex -replace "^0x", ""
    if ($hex.Length % 2 -ne 0) { throw "Invalid hex length" }
    $len = $hex.Length / 2
    $bytes = New-Object 'System.Byte[]' $len
    for ($i=0; $i -lt $len; $i++) {
        $bytes[$i] = [Convert]::ToByte($hex.Substring($i*2,2),16)
    }
    return $bytes
}

try {
    # If Data is a file path, load JSON
    if ($Data -is [string] -and (Test-Path $Data)) {
        $json = Get-Content -Path $Data -Raw
        $obj = $json | ConvertFrom-Json -Depth 10
    } elseif ($Data -is [string]) {
        # treat as inline JSON
        try { $obj = $Data | ConvertFrom-Json -Depth 10 } catch { $obj = $Data }
    } else {
        $obj = $Data
    }

    if (-not $obj) {
        return @{ valid = $false; reason = 'No data provided or could not parse JSON' }
    }

    if (-not (Test-Path $PublicKeyPath)) {
        return @{ valid = $false; reason = "Public key not found at $PublicKeyPath" }
    }

    $pubXml = Get-Content -Path $PublicKeyPath -Raw

    # Extract signature field
    $sigField = $null
    if ($obj -is [System.Management.Automation.PSCustomObject]) {
        if ($obj.PSObject.Properties.Match('signature')) {
            $sigField = $obj.signature
        }
    } elseif ($obj -is [hashtable]) {
        if ($obj.ContainsKey('signature')) { $sigField = $obj['signature'] }
    }

    if (-not $sigField) {
        return @{ valid = $false; reason = 'Signature field missing' }
    }

    # If signature field is an object with .signature, prefer that
    if ($sigField -is [System.Management.Automation.PSCustomObject] -or $sigField -is [hashtable]) {
        if ($sigField.PSObject -and $sigField.PSObject.Properties.Match('signature')) {
            $sigValue = $sigField.signature
        } elseif ($sigField.ContainsKey('signature')) {
            $sigValue = $sigField['signature']
        } else {
            # fallback: convert object to string
            $sigValue = $sigField.ToString()
        }
    } else {
        $sigValue = $sigField
    }

    # Determine encoding: try base64, then hex
    $sigBytes = $null
    try {
        $sigBytes = [Convert]::FromBase64String($sigValue)
    } catch {
        try {
            if ($sigValue -match '^[0-9a-fA-F]+$') {
                $sigBytes = Convert-HexStringToBytes -hex $sigValue
            } else {
                throw 'Signature not base64 or hex'
            }
        } catch {
            return @{ valid = $false; reason = "Signature decoding failed: $($_)" }
        }
    }

    # Build payload without signature property
    $payload = @{}
    foreach ($p in $obj.PSObject.Properties) {
        if ($p.Name -ne 'signature') { $payload[$p.Name] = $p.Value }
    }
    $payloadJson = $payload | ConvertTo-Json -Depth 20 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($payloadJson)

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha256.ComputeHash($bytes)

    $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider
    $rsa.PersistKeyInCsp = $false
    $rsa.FromXmlString($pubXml)

    $oid = [System.Security.Cryptography.CryptoConfig]::MapNameToOID('SHA256')

    try {
        $ok = $rsa.VerifyHash($hash, $oid, $sigBytes)
        if ($ok) { return @{ valid = $true; reason = 'Valid signature' } }
        else { return @{ valid = $false; reason = 'Invalid signature' } }
    } catch {
        return @{ valid = $false; reason = "Verification error: $($_)" }
    }
} catch {
    return @{ valid = $false; reason = "Unexpected error: $($_)" }
}
