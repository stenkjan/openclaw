# Start the OpenClaw Gateway container
Write-Host "Starting OpenClaw Gateway..."
docker compose up -d openclaw-gateway

# Check logs to see if it started correctly
Write-Host "Checking logs (press Ctrl+C to exit logs)..."
docker compose logs -f openclaw-gateway

