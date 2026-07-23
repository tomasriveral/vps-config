Uses debian 13 as I had difficulties setting up everything in nixos.

# Personal Server Setup Guide

This document explains how to rebuild and deploy the personal server stack on a fresh Debian VPS.

The server uses:

* Debian
* Docker CE
* Docker Compose
* Caddy as reverse proxy
* Containers for all self-hosted services
* Git as the source of truth for configuration

---

# 1. Create the VPS

Recommended:

* Debian 13
* SSH key authentication enabled
* Public IPv4 enabled
* Firewall enabled

After creation:

```bash
ssh root@SERVER_IP
```

---

# 2. Bootstrap the server

Copy the bootstrap script to the server:

```bash
scp bootstrap.sh root@SERVER_IP:
```

Connect:

```bash
ssh root@SERVER_IP
```

Run:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

This installs:

* Docker CE
* Docker Compose
* Git
* Basic administration tools
* Firewall rules

Verify:

```bash
docker --version
docker compose version
```

---

# 3. Create an administrator user

Do not run everything as root.

Create a user:

```bash
adduser USERNAME
```

Add permissions:

```bash
usermod -aG sudo,docker USERNAME
```

Copy SSH keys:

```bash
mkdir -p /home/USERNAME/.ssh
cp /root/.ssh/authorized_keys /home/USERNAME/.ssh/
chown -R USERNAME:USERNAME /home/USERNAME/.ssh
chmod 700 /home/USERNAME/.ssh
chmod 600 /home/USERNAME/.ssh/authorized_keys
```

Test:

```bash
ssh USERNAME@SERVER_IP
```

---

# 4. Clone the server configuration

Create the deployment directory:

```bash
mkdir -p /opt/server
cd /opt/server
```

Clone the configuration repository:

```bash
git clone YOUR_REPOSITORY_URL .
```

The structure should look like:

```
server/
├── compose.yml
├── Caddyfile
├── .env
├── scripts/
└── README.md
```

---

# 5. Configure secrets

Never store passwords or tokens in Git.

Create:

```bash
nano .env
```

Example:

```env
DOMAIN=example.com

FRESHRSS_ADMIN_PASSWORD=change_me

KDRIVE_USERNAME=user
KDRIVE_PASSWORD=password
```

Set permissions:

```bash
chmod 600 .env
```

---

# 6. Start the Docker stack

From `/opt/server`:

```bash
docker compose up -d
```

Check running containers:

```bash
docker ps
```

View logs:

```bash
docker compose logs -f
```

---

# 7. Reverse proxy

Caddy handles HTTPS automatically.

Example:

```
website.com
├── freshrss.website.com
├── archivebox.website.com
├── hledger.website.com
├── calendar.website.com
└── ntfy.website.com
```

The `Caddyfile` defines where traffic goes.

After changing it:

```bash
docker compose restart caddy
```

---

# 8. Updating services

Update images:

```bash
docker compose pull
```

Restart:

```bash
docker compose up -d
```

Remove unused images:

```bash
docker image prune
```

---

# 9. Backups

Important data is stored in Docker volumes.

List volumes:

```bash
docker volume ls
```

Back up using:

* restic
* kDrive
* another storage provider

Recommended backup targets:

```
FreshRSS database
ArchiveBox data
Calendar/contact data
hledger files
Caddy configuration
.env secrets
```

---

# 10. Disaster recovery

To rebuild:

1. Install Debian
2. Run `bootstrap.sh`
3. Clone this repository
4. Restore backups
5. Restore `.env`
6. Start Docker:

```bash
docker compose up -d
```

The complete server should be operational again.

---

# Planned services

Current stack:

* Caddy
* FreshRSS
* ArchiveBox
* hledger-web
* Calendar/contact server
* ntfy
* Monitoring

Possible additions:

* Uptime Kuma
* Authelia or Authentik
* Vaultwarden
* Gitea
* Miniflux
* Mealie
* Paperless-ngx

---

# Principles

* Configuration belongs in Git
* Data belongs in backups
* Secrets never go into Git
* Containers are disposable
* Volumes contain persistent data
* The server should be reproducible
