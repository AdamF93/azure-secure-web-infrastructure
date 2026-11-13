#!/usr/bin/env bash
set -euo pipefail

hostname="${1:?Supply the public hostname}"
email="${2:?Supply the certificate contact email}"

if [[ ! "$hostname" =~ ^[a-z0-9.-]+$ ]]; then
  echo "Invalid hostname."
  exit 1
fi

site=/etc/nginx/sites-available/default

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
  --no-redirect \
  --keep-until-expiring

nginx -t