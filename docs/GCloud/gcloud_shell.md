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
> The VM gets a **new external IP** on every start. Update DuckDNS (Section 1b) after starting the VM, or the domain will point to the wrong IP.

## 2. SSH into the Server

```bash
gcloud compute ssh openclaw-server --project=durable-works-488417-t7 --zone=us-central1-a
```

---

## 1b. Update DuckDNS After Start

GCP assigns a **new external IP** on every VM start. Update DuckDNS immediately after starting:

1. Go to **https://www.duckdns.org** and log in
2. Update `openclawed` to the new IP shown in the `gcloud instances start` output

Or run from Cloud Shell:
```bash
# Get the new external IP
gcloud compute instances describe openclaw-server --zone=us-central1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

---

## 3. Start OpenClaw [SERVER]

```bash
cd openclaw
docker compose up -d
```

---

## 3b. Fix Docker Networking After Cold Start [SERVER]

If `docker compose up -d` fails with `operation not supported` on veth pair creation, Docker's network driver didn't survive the VM restart. Fix:

```bash
sudo systemctl restart docker
docker compose up -d
```

> After Docker restarts, proceed with `docker compose up -d` normally. No Caddy fix needed — container uses a static IP.

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

## 7. Caddy Config [SERVER]

OpenClaw runs in `mode: local`, meaning it binds to `127.0.0.1` inside the container.
Caddy must proxy via Docker's port mapping (`127.0.0.1:18789` on the host), **not** the container IP directly.

The Caddyfile should always contain:

```
openclawed.duckdns.org {
    reverse_proxy 127.0.0.1:18789
}
```

To restore it:
```bash
cat <<EOF | sudo tee /etc/caddy/Caddyfile
openclawed.duckdns.org {
    reverse_proxy 127.0.0.1:18789
}
EOF
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
| Server IP | dynamic — check after each start with `gcloud compute instances describe` |
| Container IP | `172.20.0.10` (static) — but Caddy uses `127.0.0.1:18789` via Docker port mapping |
| Domain | `openclawed.duckdns.org` |
| OpenClaw Port | `18789` |
| GCP Project | `durable-works-488417-t7` |
| GCP Zone | `us-central1-a` |
