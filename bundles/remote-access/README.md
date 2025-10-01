# Remote Access Bundle (Portable)

This bundle gives you a one-click, TLS-secured web console and handy tasks for PDF export and quick verification. It’s designed to run from D:\RemoteAccessBundle or any removable drive.

## Contents
- .devcontainer/ — Dev container with ttyd + Chromium
- .vscode/tasks.json — Start/Stop web console, export PDF, quick verify
- scripts/console_start.sh — Start ttyd with self-signed TLS
- scripts/console_stop.sh — Stop ttyd
- scripts/export_pdf.ps1 — Render HTML to PDF via Edge/Chrome on Windows

## Quick start
1) Copy this folder to D:\RemoteAccessBundle (or use the deploy script).
2) Open the folder in VS Code and Reopen in Container.
3) Run task: “Console: Start TLS (localhost:7681)”.
4) Open https://localhost:7681 in a browser. You’ll see a shell inside the container.

Optional:
- Generate a new self-signed cert: run task “Console: Generate self-signed TLS cert”.
- Export a PDF: run task “Export PDF (host Edge/Chrome)”.

## Stop
- Run task: “Console: Stop”.

## Notes
- The TLS cert/key live in .console (workspace-local). Replace with your own certs for production use.
- The console runs with “--once” for safety. Start it again if you need another session.