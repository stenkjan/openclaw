# Running OpenClaw with Docker

## Prerequisites
- Docker Desktop must be running.

## Quick Start (Windows)
Run the helper script:
```powershell
.\start_bot.ps1
```

## Manual Commands

### Start the Bot
```bash
docker compose up -d openclaw-gateway
```

### Restart the Bot
If you change `openclaw.json`, you must restart:
```bash
docker compose restart openclaw-gateway
```

### View Logs
```bash
docker compose logs -f openclaw-gateway
```

### Stop the Bot
```bash
docker compose down
```
