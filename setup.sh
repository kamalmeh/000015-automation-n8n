#!/bin/bash
set -euo pipefail

# --- Helper Functions ---
error_exit() { echo "❌ $1" >&2; exit 1; }
info() { echo "➡️  $1"; }
success() { echo "✅ $1"; }

# --- Load and Validate Environment ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
[ -f "$ENV_FILE" ] || error_exit ".env file not found in $SCRIPT_DIR"
. "$ENV_FILE"

REQUIRED_VARS=(N8N_USER N8N_PASS N8N_PORT N8N_DOMAIN POSTGRES_HOST POSTGRES_DB POSTGRES_USER POSTGRES_PASS ENCRYPTION_KEY N8N_DATA_DIR)
REQUIRED_VARS=(N8N_USER N8N_PASS N8N_PORT N8N_DOMAIN POSTGRES_HOST POSTGRES_DB POSTGRES_USER POSTGRES_PASS ENCRYPTION_KEY N8N_DATA_DIR SSL_CERT_PATH SSL_KEY_PATH)
MISSING=()
for VAR in "${REQUIRED_VARS[@]}"; do
  [ -z "${!VAR:-}" ] && MISSING+=("$VAR")
done
[ ${#MISSING[@]} -eq 0 ] || error_exit "Missing required env vars: ${MISSING[*]}"

# --- Install Dependencies ---

# --- Improved Install Dependencies ---
MISSING_PKGS=()
for pkg in docker.io docker-compose nginx; do
  if ! command -v "${pkg%%.*}" &>/dev/null; then
    MISSING_PKGS+=("$pkg")
  fi
done
if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
  info "Installing missing packages: ${MISSING_PKGS[*]}"
  sudo apt update
  sudo apt install -y "${MISSING_PKGS[@]}"
else
  success "All required packages are already installed."
fi

# --- Check Data Volume ---
mount | grep -q "$N8N_DATA_DIR" || error_exit "Volume not mounted at $N8N_DATA_DIR. Please mount your EBS volume."

# --- Validate Compose Files ---
[ -f "$SCRIPT_DIR/docker-compose.yml" ] || error_exit "docker-compose.yml not found in $SCRIPT_DIR"
[ -f "$SCRIPT_DIR/Dockerfile" ] || error_exit "Dockerfile not found in $SCRIPT_DIR"

# --- Prepare n8n Directory ---
WORK_DIR="$HOME/n8n"
mkdir -p "$WORK_DIR"
cp -p "$SCRIPT_DIR/docker-compose.yml" "$WORK_DIR/"
cp -p "$SCRIPT_DIR/Dockerfile" "$WORK_DIR/"
cp -ap "$SCRIPT_DIR/scripts" "$WORK_DIR/"
cd "$WORK_DIR"

# echo "Change network mode to bridge in docker-compose.yml"
# perl -pi -e "s|network_mode: \"bridge\"|network_mode: \"host\"|g" "$WORK_DIR/docker-compose.yml"

# --- Set Permissions ---
sudo chown -R 1000:1000 "$N8N_DATA_DIR"
if [ ! -d "$N8N_DATA_DIR/files" ]
then
  mkdir -p "$N8N_DATA_DIR/files"
fi
sudo chown -R 1000:1000 "$N8N_DATA_DIR/files"
ls -ltr "$N8N_DATA_DIR"

# --- NGINX Reverse Proxy Setup ---
NGINX_CONF="/etc/nginx/sites-available/${N8N_DOMAIN}"
sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 80;
    server_name ${N8N_DOMAIN};
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    server_name ${N8N_DOMAIN};
    ssl_certificate ${SSL_CERT_PATH};
    ssl_certificate_key ${SSL_KEY_PATH};
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

[ -f "/etc/nginx/sites-enabled/$N8N_DOMAIN" ] || sudo ln -s "$NGINX_CONF" /etc/nginx/sites-enabled/
sudo nginx -t || error_exit "NGINX config test failed"
sudo systemctl restart nginx

# --- Ensure .env is present for Docker Compose variable substitution ---
cp "$ENV_FILE" "$WORK_DIR/.env"

# --- Start n8n ---
sudo docker compose up --pull always -d --build

# --- Done ---
success "n8n is now running on: https://${N8N_DOMAIN}"
echo "🔐 Login: ${N8N_USER} / ${N8N_PASS}"
