# OpenClaw GCloud Shell Reference

All commands are run in **Google Cloud Shell** unless marked with `[SERVER]`.

---

## 1. Start / Stop the VM

```bash
# Start the server
gcloud compute instances start openclaw-server --zone=us-central1-a

# Stop the server (saves resources, no cost impact on free tier)
gcloud compute instances stop openclaw-server --zone=us-central1-a
```

---

> [!IMPORTANT]
> After every container restart, the container IP may change. If the website shows a 502 error, run the Caddy fix in Section 7.

## 2. SSH into the Server

```bash
gcloud compute ssh openclaw-server --project=durable-works-488417-t7 --zone=us-central1-a
```

---

## 3. Start OpenClaw [SERVER]

```bash
cd openclaw
docker compose up -d
```

---

## 4. Stop OpenClaw [SERVER]

```bash
cd openclaw
docker compose down
```

---

## 5. View Live Logs [SERVER]

```bash
# Gateway logs (Telegram, Web UI)
docker logs openclaw-openclaw-gateway-1 -f

# Last 50 lines, no follow
docker logs openclaw-openclaw-gateway-1 --tail 50
```

---

## 6. Debugging Commands [SERVER]

```bash
# Check running containers and their status
docker ps -a

# Check how many times the gateway restarted
docker inspect openclaw-openclaw-gateway-1 --format '{{.RestartCount}}'

# Test if OpenClaw is responding on its port
curl -v http://127.0.0.1:18789

# Test from inside the container
docker exec openclaw-openclaw-gateway-1 sh -c "wget -qO- http://127.0.0.1:18789 | head -3"

# Check environment variables inside the container
docker exec openclaw-openclaw-gateway-1 sh -c "env | grep OPENCLAW"

# Check what ports are open on the host
ss -tlnp | grep 18789

# Check Caddy (HTTPS reverse proxy) logs
sudo journalctl -u caddy --no-pager -n 30

# Restart Caddy
sudo systemctl restart caddy
```

---

## 7. Fix Caddy After Container Restart [SERVER]

OpenClaw binds to the container's internal IP (`172.18.x.x`), not `localhost`.
If the website shows 502, the container IP has changed. Fix it like this:

```bash
# 1. Get the current container IP
NEW_IP=$(docker inspect openclaw-openclaw-gateway-1 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
echo "Container IP: $NEW_IP"

# 2. Update Caddyfile with correct multiline format
cat << EOF | sudo tee /etc/caddy/Caddyfile
openclawed.duckdns.org {
    reverse_proxy ${NEW_IP}:18789
}
EOF

# 3. Restart Caddy
sudo systemctl restart caddy
```

---

## 8. Key Config Files [SERVER]

| File | Purpose |
|---|---|
| `~/openclaw/openclaw.json` | Main OpenClaw config (model, Telegram, bind mode) |
| `~/openclaw/.env` | API keys and Docker env vars  |
| `~/openclaw/docker-compose.yml` | Docker service definitions |
| `/etc/caddy/Caddyfile` | HTTPS reverse proxy config |

---

## 9. Important Values

| Item | Value |
|---|---|
| Server IP | `136.119.144.181` |
| Domain | `openclawed.duckdns.org` |
| OpenClaw Port | `18789` |
| GCP Project | `durable-works-488417-t7` |
| GCP Zone | `us-central1-a` |
