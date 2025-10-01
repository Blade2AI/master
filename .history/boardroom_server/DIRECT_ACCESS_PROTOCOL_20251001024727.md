# Sovereign Boardroom: Direct Access Protocol

This document explains how to access the Sovereign Boardroom services on this machine in a secure, Windows-friendly way. It aligns with the scripts in `boardroom_server`.

- HTTPS Dashboard (read-only): https://localhost:443/
  - Health JSON: https://localhost:443/status
- Idea Injection API (write-only): https://localhost:8444/inject (POST JSON)

Both endpoints are hosted via `HttpListener` with TLS certificates bound by `Setup-Server.ps1`.

---

## 1) Security model (what's enforced now)

- Loopback-only access policy
  - Enforced at the application layer: `verify_access.ps1` rejects any request where the remote IP is not loopback when `AllowedLoopbackOnly` is true in `config.json` (default: true).
  - Current http.sys binding listens on all interfaces (`0.0.0.0`); the app still rejects non-loopback traffic. You can optionally harden the binding and firewall (see Appendix A).
- Optional client certificate pinning
  - If `AllowedClientThumbprints` contains one or more thumbprints, requests without a pinned client certificate are rejected.
- Critical command presence gating
  - For commands listed under `CriticalCommands` in `config.json`, physical presence is required (checked via a recent entry in `BiometricLogPath`). The Injection API does not accept arbitrary commands, but the automation daemon will pause high-impact ideas until presence is confirmed.
- Vault logging
  - Logs are written to `C:\ProgramData\Boardroom\Vault_Log` (access, automation). Status JSON is at `C:\ProgramData\Boardroom\status.json`.

Config file: `boardroom_server/config.json`

```
{
  "AllowedLoopbackOnly": true,
  "BiometricLogPath": "C:\\Biometric\\access.log",
  "PhysicalPresenceWindowMinutes": 5,
  "CriticalCommands": ["deploy", "transfer", "authorize"],
  "AllowedClientThumbprints": []
}
```

---

## 2) Service lifecycle

These are registered by `Setup-Server.ps1` as scheduled tasks that start at logon:

- BoardroomHttpsServer -> runs `Start-BoardroomHttpsServer.ps1` on port 443
- BoardroomInjectionServer -> runs `Start-BoardroomInjectionServer.ps1` on port 8444
- BoardroomAutomationDaemon -> runs `automate_pulse.ps1` (15-minute loop)
- BoardroomPulse -> updates `status.json` every 15 minutes

To re-run setup safely (idempotent for bindings and rules):

```powershell
# Run from an elevated PowerShell in the repo
& "$PSScriptRoot\Setup-Server.ps1"
```

To start services immediately without waiting for next logon:

```powershell
Start-Job { & "$PSScriptRoot\Start-BoardroomHttpsServer.ps1" } | Out-Null
Start-Job { & "$PSScriptRoot\Start-BoardroomInjectionServer.ps1" } | Out-Null
Start-Job { & "$PSScriptRoot\automate_pulse.ps1" } | Out-Null
```

Note: In Windows PowerShell 5.1, background jobs are sufficient for local use. For persistence, rely on the scheduled tasks created by setup.

---

## 3) Verifying local access

Because the certificate is self-signed, you may see TLS trust warnings. For a quick smoke test, temporarily bypass validation in the current PowerShell session only:

```powershell
# TEMPORARY for this session only (do not use in production)
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) { return true; }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
```

Then:

```powershell
# Dashboard JSON
Invoke-RestMethod -Uri https://localhost:443/status -Method GET

# Inject a low-impact idea (queued)
Invoke-RestMethod -Uri https://localhost:8444/inject -Method Post -ContentType 'application/json' -Body '{"Text":"Test idea via loopback","Injector":"local"}'
```

You should receive status JSON from `/status` and `{ status = "Queued" ... }` from `/inject`.

To monitor logs:

```powershell
Get-Content -Path C:\ProgramData\Boardroom\Vault_Log\access.log -Tail 50 -Wait
Get-Content -Path C:\ProgramData\Boardroom\Vault_Log\automation.log -Tail 50 -Wait
```

---

## 4) Remote use via SSH tunnel (recommended)

When off the host, establish a loopback tunnel so the services still see the client as 127.0.0.1 and pass `AllowedLoopbackOnly`:

Windows (PowerShell 5.1) with built-in OpenSSH client:

```powershell
# Replace user@host with your machine credentials
ssh -N -L 8444:localhost:8444 -L 443:localhost:443 user@host
```

- Keep the SSH window open while in use.
- Then access from your local machine as if they were local:
  - https://localhost:443/status
  - POST https://localhost:8444/inject

Optional: add client certificate auth over SSH port forward if desired; pin the client cert thumbprint in `config.json` under `AllowedClientThumbprints`.

---

## 5) API quick reference

- GET /status -> returns Boardroom pulse and panels
- GET / -> serves `C:\ProgramData\Boardroom\wwwroot\index.html`
- POST /inject -> JSON body: { "Text": string, "Injector": string? }
  - Response: { status: "Queued", impact_est: "£...", pause: "..." }

Impact gating: ideas with estimated impact over the configured threshold require a recent biometric approval entry before the automation daemon executes them.

---

## Appendix A: Optional hardening (http.sys + firewall)

The application already blocks non-loopback IPs. To reduce exposure surface further:

- Restrict http.sys SSL binding to localhost only:

```powershell
# Rebind certificate to 127.0.0.1 for both ports
$thumb = (Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -like '*CN=Boardroom-Local*' } | Select-Object -First 1).Thumbprint
netsh http delete sslcert ipport=0.0.0.0:443 2>$null
netsh http add sslcert ipport=127.0.0.1:443 certhash=$thumb appid={7e1f7c4b-4c7d-47f1-bd6d-2e1c4f32a7aa} certstore=MY
netsh http delete sslcert ipport=0.0.0.0:8444 2>$null
netsh http add sslcert ipport=127.0.0.1:8444 certhash=$thumb appid={7e1f7c4b-4c7d-47f1-bd6d-2e1c4f32a7aa} certstore=MY
```

- Limit firewall rules to local address (if your Windows build supports it) or to the Private profile only:

```powershell
# Narrow scope (example: Private profile only)
Set-NetFirewallRule -DisplayName 'Boardroom HTTPS 443' -Profile Private
Set-NetFirewallRule -DisplayName 'Boardroom Injection 8444' -Profile Private
```

- Verify effective listeners:

```powershell
netsh http show sslcert
netstat -ano | findstr :443
netstat -ano | findstr :8444
```

Roll these changes back by re-running `Setup-Server.ps1` to restore defaults.

---

## Appendix B: Troubleshooting

- 404 on https://localhost:443/ -> Ensure `C:\ProgramData\Boardroom\wwwroot\index.html` exists (created by `Setup-Server.ps1`).
- 403 forbidden -> You are not connecting from loopback, or client certificate pinning is enabled and the certificate is missing/not authorized.
- TLS trust errors -> Import the self-signed certificate into Trusted Root or use the temporary bypass snippet for local testing only.
- No status updates -> Check Scheduled Task "BoardroomPulse" and `status.json` path; run `Update-BoardroomPulse.ps1` manually to test.

***

This protocol keeps the services private by default, usable locally or via an SSH tunnel, with optional certificate pinning and presence gating for sensitive paths.
