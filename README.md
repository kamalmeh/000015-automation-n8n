# n8n Self-Hosted Automation Platform

This project provides a robust, production-ready setup for self-hosting [n8n](https://n8n.io/) (an open-source workflow automation tool) on a Linux server using Docker, Docker Compose, PostgreSQL, and NGINX as a reverse proxy with SSL.

---

## Table of Contents
- [Features](#features)
- [Requirements](#requirements)
- [Folder Structure](#folder-structure)
- [Environment Variables](#environment-variables)
- [Setup Instructions](#setup-instructions)
- [Deployment Steps](#deployment-steps)
- [Troubleshooting](#troubleshooting)
- [Useful Commands](#useful-commands)
- [License](#license)

---

## Features
- Automated installation of Docker, Docker Compose, and NGINX
- Secure n8n deployment with PostgreSQL database
- NGINX reverse proxy with SSL (Let's Encrypt)
- All configuration via `.env` file
- Volume and file permission checks for production safety
- One-command setup via `setup.sh`

---

## Requirements
- Ubuntu/Debian-based Linux server (tested on Ubuntu 20.04+)
- Root or sudo privileges
- Domain name pointed to your server (for SSL and NGINX)
- EBS or other persistent storage mounted at the path you specify in `.env`
- Ports 80 and 443 open in your firewall

---

## Folder Structure
```
project-root/
├── Dockerfile
├── docker-compose.yml
├── env                # Your environment variables file (see below)
├── setup.sh           # Main setup script
└── README.md
```

---

## Environment Variables
Create a file named `env` in the project root with the following variables:

```env
N8N_USER=admin
N8N_PASS=yourStrongPassword
N8N_PORT=5678
N8N_DOMAIN=your.domain.com
POSTGRES_HOST=localhost
POSTGRES_DB=n8n_db
POSTGRES_USER=n8n_user
POSTGRES_PASS=yourPostgresPassword
ENCRYPTION_KEY=yourRandomEncryptionKey
N8N_DATA_DIR=/data/n8n
SSL_CERT_PATH=/etc/letsencrypt/live/your.domain.com/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/your.domain.com/privkey.pem
```
- **N8N_USER/N8N_PASS**: Login credentials for n8n
- **N8N_DOMAIN**: Your domain (must point to this server)
- **N8N_DATA_DIR**: Must be a mounted, persistent volume (e.g., EBS)
- **ENCRYPTION_KEY**: Generate a strong random string
- **SSL_CERT_PATH / SSL_KEY_PATH**: Full paths to your SSL certificate and key for your domain (e.g., Let's Encrypt). These are used in the NGINX config for HTTPS.

---

## Setup Instructions

1. **Clone the repository and enter the directory:**
   ```bash
   git clone <your-repo-url>
   cd <project-root>
   ```

2. **Create and edit the `env` file:**
   ```bash
   cp env.example env
   nano env
   # Fill in all required variables
   ```

3. **Mount your persistent storage (EBS, etc.) at the path specified by `N8N_DATA_DIR` in your `env` file.**
   - Example: `/data/n8n` must be mounted and writable.

4. **Make the setup script executable:**
   ```bash
   chmod +x setup.sh
   ```

5. **Run the setup script:**
   ```bash
   sudo ./setup.sh
   ```
   - The script will:
     - Check/install Docker, Docker Compose, and NGINX
     - Validate your environment and files
     - Set up file permissions
     - Configure NGINX as a reverse proxy with SSL
     - Start n8n using Docker Compose

---

## Deployment Steps (Summary)
1. Point your domain's DNS to your server's public IP.
2. Ensure ports 80 and 443 are open.
3. Mount your persistent storage at the path in `N8N_DATA_DIR`.
4. Fill out the `env` file with your secrets and settings.
5. Run `sudo ./setup.sh` from the project root.
6. Access n8n at `https://your.domain.com`.

---

## Troubleshooting
- **Missing dependencies:** The script will install Docker, Docker Compose, and NGINX if missing.
- **Volume not mounted:** The script will exit if your data volume is not mounted.
- **SSL certificate errors:** Ensure your domain is pointed to the server and certificates exist at `/etc/letsencrypt/live/your.domain.com/`.
- **Permissions issues:** The script sets correct permissions for n8n data directories.
- **Check logs:**
  ```bash
  docker compose logs n8n
  sudo journalctl -u nginx
  ```

---

## Useful Commands
- **Start n8n:**
  ```bash
  cd ~/n8n && docker compose up -d
  ```
- **Stop n8n:**
  ```bash
  cd ~/n8n && docker compose down
  ```
- **Check n8n logs:**
  ```bash
  cd ~/n8n && docker compose logs n8n
  ```
- **Restart NGINX:**
  ```bash
  sudo systemctl restart nginx
  ```

---

## License
This project is provided as-is, without warranty. See [n8n.io](https://n8n.io/) for n8n's own license and terms.
