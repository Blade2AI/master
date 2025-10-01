# Sovereign Boardroom – Direct Access Protocol

This server exposes a local-only HTTPS dashboard on :443 and an idea injection endpoint on :8444. Access is intended via a direct SSH tunnel from your device to the boardroom server. No cloud components, no third-party relays.

## Endpoints
- Dashboard: https://<server>:443/ (serves `wwwroot/index.html`)
- Status API: https://<server>:443/status
- Idea injection: https://<server>:8444/inject (POST JSON: { "Text": "...", "Injector": "..." })

## Setup (run on the physical server)
- `boardroom_server/Setup-Server.ps1` — installs prerequisites, binds TLS certs, opens firewall, schedules 15-min pulse.
- `boardroom_server/Start-BoardroomHttpsServer.ps1` — start dashboard API.
- `boardroom_server/Start-BoardroomInjectionServer.ps1` — start idea injection API.

## SSH tunnel (run on your device)
Forward ports 8443 (to 443) and 8444 (to 8444):

```powershell
ssh -N -L 8443:192.168.10.100:443 -L 8444:192.168.10.100:8444 -i $env:USERPROFILE\.ssh\boardroom_key admin@192.168.10.100
```

Then access:
- Dashboard: https://localhost:8443/
- Status: https://localhost:8443/status
- Injection: `curl -k -X POST https://localhost:8444/inject -H "Content-Type: application/json" -d '{"Text":"AI co-op for energy leak plug","Injector":"Blade/Andy"}'`

## Verification
```powershell
# Confirm local tunnel port
netstat -ano | findstr "8443"
# Confirm status responds
curl -k https://localhost:8443/status | ConvertFrom-Json
```

## Sovereign checks
- Loopback-only enforcement for requests (configurable in `config.json`).
- Optional client certificate pinning via thumbprints in `config.json`.
- Critical operations (> threshold) require physical presence (biometric recent approval).
