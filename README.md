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

# 1. Setup the VPS

Recommended:

* Debian 13
* SSH key authentication enabled
* Public IPv4 enabled
* Firewall enabled

After creation:


```bash
read IP_ADDRESS
scp bootstrap.sh root@$IP_ADDRESS:
ssh root@$IP_ADDRESS
./bootstrap.sh
```

# 2. Deploy
```
./scripts/deploy.sh
```
