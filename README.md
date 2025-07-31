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
├── .env               # (copied to ~/n8n for Docker Compose variable substitution)
├── scripts/           # (optional) Custom scripts copied into the container at /home/node/scripts
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
N8N_ENV=prod   # Set to local, prod, or uat
SSL_CERT_PATH=/etc/letsencrypt/live/your.domain.com/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/your.domain.com/privkey.pem
GENERIC_TIMEZONE=Asia/Kolkata
TZ=Asia/Kolkata
```
- **N8N_USER/N8N_PASS**: Login credentials for n8n
- **N8N_DOMAIN**: Your domain (must point to this server)
- **N8N_DATA_DIR**: Must be a mounted, persistent volume (e.g., EBS)
- **ENCRYPTION_KEY**: Generate a strong random string
- **N8N_ENV**: Set to `local`, `prod`, or `uat` to define the environment (passed into the container)
- **SSL_CERT_PATH / SSL_KEY_PATH**: Full paths to your SSL certificate and key for your domain (e.g., Let's Encrypt). Used in the NGINX config for HTTPS.
- **GENERIC_TIMEZONE / TZ**: Set your timezone for n8n and the container.

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
     - Copy your .env file to the n8n working directory for Docker Compose variable substitution
     - Start n8n using Docker Compose

---

## Deployment Steps (Summary)
1. Point your domain's DNS to your server's public IP.
2. Ensure ports 80 and 443 are open.
3. Mount your persistent storage at the path in `N8N_DATA_DIR`.
4. Fill out the `env` file with your secrets and settings (including N8N_ENV, SSL_CERT_PATH, SSL_KEY_PATH, and timezone).
5. Run `sudo ./setup.sh` from the project root.
6. Access n8n at `https://your.domain.com`.

---

## Troubleshooting
- **Missing dependencies:** The script will install Docker, Docker Compose, and NGINX if missing.
- **Volume not mounted:** The script will exit if your data volume is not mounted.
- **SSL certificate errors:** Ensure your domain is pointed to the server and certificates exist at the paths set in `SSL_CERT_PATH` and `SSL_KEY_PATH`.
- **Permissions issues:** The script sets correct permissions for n8n data directories.
- **Environment variables not substituted:** Make sure your `.env` file is present and correctly copied to the n8n working directory (`~/n8n/.env`).
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
- **Rebuild the image (if you change Dockerfile or scripts):**
  ```bash
  cd ~/n8n && docker compose build --no-cache
  ```

---

## License
This project is provided as-is, without warranty. See [n8n.io](https://n8n.io/) for n8n's own license and terms.
