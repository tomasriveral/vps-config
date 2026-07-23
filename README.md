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
Clone the configuration repository:

```bash
git clone https://github.com/tomasriveral/vps-config
cd vps-config
```

---

# 5. Configure secrets

Never store passwords or tokens in Git.

Create:

```bash
nano .env
```

See `.env.example`

# 6. Init the system
```
./scripts/init.sh
```

# 7. Deploy
```
./scripts/deploy.sh
```
