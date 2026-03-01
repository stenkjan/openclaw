# OpenClaw Manual: GCloud, Self-Hosting & File Sharing

This manual covers how to start and manage your OpenClaw server on Google Cloud, as well as how to migrate to a self-hosted network and share files with your bot.

---

## Part 1: Managing the Google Cloud VM

All commands are run in your **local terminal** unless marked with `[SERVER]`.

### 1. Start / Stop the VM

```bash
# Start the server
gcloud compute instances start openclaw-server --project=durable-works-488417-t7 --zone=us-central1-a

# Stop the server (saves resources, no cost impact on free tier)
gcloud compute instances stop openclaw-server --project=durable-works-488417-t7 --zone=us-central1-a
```

> [!IMPORTANT]
> The VM gets a **new external IP** on every start.

### 2. Update DuckDNS After Start

GCP assigns a **new external IP** on every VM start. Update DuckDNS immediately:

1. Go to **https://www.duckdns.org** and log in
2. Update `openclawed` to the new IP shown in the `gcloud instances start` output.

### 3. SSH into the Server

Make sure you are logging in as the correct user that owns the OpenClaw files (`m_janstenk`).

```bash
gcloud compute ssh m_janstenk@openclaw-server --project=durable-works-488417-t7 --zone=us-central1-a
```

---

## Part 2: Operating Docker & The Gateway [SERVER]

These commands must be run inside your SSH session on the remote server.

### 1. Fix Permissions & Restart Docker 

If you just started the VM, Docker's veth pairs might be broken, and the volume permissions need to be universal.

```bash
# Fix write permissions for the container
sudo chmod -R 777 ~/openclaw

# Restart the Docker daemon
sudo systemctl restart docker
```

### 2. Start OpenClaw

```bash
cd ~/openclaw
docker compose up -d
```

### 3. Stop OpenClaw

```bash
cd ~/openclaw
docker compose down
```

### 4. View Live Logs

```bash
# Gateway logs (Telegram, Web UI)
docker logs openclaw-openclaw-gateway-1 -f

# Last 50 lines, no follow
docker logs openclaw-openclaw-gateway-1 --tail 50
```

### 5. Pair Your Device (1008 Disconnected Error)

If the Web UI at `https://openclawed.duckdns.org` shows "1008 Disconnected (pairing required)":

1. Refresh the web page to generate a new request.
2. In your SSH terminal, list the pending connections:
   ```bash
   docker exec -it openclaw-openclaw-gateway-1 node dist/index.js devices list
   ```
3. Copy the ID of the pending request and approve it:
   ```bash
   docker exec -it openclaw-openclaw-gateway-1 node dist/index.js devices approve <YOUR_PAIRING_ID>
   ```

   ```

### 6. Troubleshooting 502 Bad Gateway & Container Hangs

**Windows SCP Corruption (CRLF)**
If you edit `.env` or `docker-compose.yml` on a Windows machine and push it to the Linux server using `gcloud compute scp`, Windows will append invisible `\r` carriage returns to every line. This will silently corrupt the port bindings and API keys, causing the Gateway to hang indefinitely on startup or fail to bind to its port, resulting in a **502 Bad Gateway** error.

**To fix Windows file corruption, run this on the server:**
```bash
sed -i 's/\r$//' ~/openclaw/.env ~/openclaw/docker-compose.yml
```

**Docker "Ghost IPs" / Network Desync**
Do NOT repeatedly run `docker compose restart`. Forcefully recreating the container multiple times can cause the Docker network bridge to desync, leaving Caddy trying to route your domain traffic to an old, non-existent "Ghost IP" for the container. 

**To fix a completely broken Docker network and 502 error:**
```bash
cd ~/openclaw
docker compose down      # Destroys the corrupted network bridge
docker compose up -d     # Rebuilds the network cleanly
sudo systemctl restart caddy # Forces Caddy to rescan for the new IP
```

---

## Part 3: File Sharing & Workflows

### 1. Sharing Files via Links
You do not need to upload files physically to the server if they are already hosted somewhere else. If you have a file accessible via a public link (e.g., a PDF on Google Drive with "Anyone with the link can view", a public Dropbox link, or a direct URL to a file), you can simply drop the link into your chat.

**Example:**
> "Please summarize this document: https://example.com/report.pdf"

*Note: The bot needs to have the `browser` or `fetch` tools enabled in its sandbox/configuration to download the page/file content.*

### 2. Uploading Files via SCP
If the file is local, you can push it securely to the VM's workspace volume (`~/workspace`), where the Docker container will immediately see it:

```bash
# Run this in your local terminal:
gcloud compute scp C:\path\to\your\file.pdf m_janstenk@openclaw-server:~/workspace/ --project=durable-works-488417-t7 --zone=us-central1-a
```

---

## Part 4: Self-Hosting Behind a 5G Router

If you ever want to move OpenClaw from Google Cloud to your own hardware at home (like a Raspberry Pi or an old laptop) connected to a 5G cellular router, you face a common network problem: **CGNAT (Carrier-Grade NAT)**. Cellular providers usually do not give you a public IP address, so DuckDNS and traditional port-forwarding won't work.

### The Solution: Tailscale

[Tailscale](https://tailscale.com) is a zero-config VPN that creates a secure, private network (a "tailnet") between all your devices, completely bypassing the 5G router's NAT and firewall restrictions.

1. **Install Tailscale on the server:**
   ```bash
   curl -fsSL https://tailscale.com/install.sh | sh
   sudo tailscale up
   ```
2. **Install Tailscale on your everyday devices:** Install the Tailscale app on your phone and laptop and log in to the same account.
3. **Proxy the OpenClaw UI securely:** Expose the OpenClaw Dashboard UI over HTTPS *only* to devices on your Tailnet.
   ```bash
   openclaw gateway --tailscale serve
   ```
4. **Connect from anywhere:** You can now access your OpenClaw dashboard by typing your server's Tailscale MagicDNS name into your browser (e.g., `https://my-home-server.tailnet-xyz.ts.net`), securely from anywhere in the world, straight through the 5G router.

*(Note: Telegram and Discord bots make outbound connections, so they will work perfectly behind a 5G router out of the box without any network configuration!)*
