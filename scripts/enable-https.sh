#!/usr/bin/env bash
set -euo pipefail

hostname="${1:?Supply the public hostname}"
email="${2:?Supply the certificate contact email}"

if [[ ! "$hostname" =~ ^[a-z0-9.-]+$ ]]; then
  echo "Invalid hostname."
  exit 1
fi

# Wait for first-boot package installation and webpage provisioning.
timeout 600 cloud-init status --wait

# Install certificate tooling when absent.
if ! dpkg -s certbot python3-certbot-nginx >/dev/null 2>&1; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive \
    apt-get install -y certbot python3-certbot-nginx
fi

site=/etc/nginx/sites-available/default
test -f "$site"

if [[ ! -f "${site}.before-https" ]]; then
  cp "$site" "${site}.before-https"
fi

sed -i "s/server_name _;/server_name ${hostname};/" "$site"

nginx -t
systemctl reload nginx

certbot --nginx \
  --non-interactive \
  --agree-tos \
  --email "$email" \
  --domain "$hostname" \
  --redirect \
  --keep-until-expiring

nginx -t

echo "HTTPS_SETUP_OK"