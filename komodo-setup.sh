#!/usr/bin/env bash
set -euo pipefail

# Komodo-compatible setup script for mailcow
# This script initializes mailcow.conf from the template with generated secrets.
# Run once on initial deployment. Subsequent deploys (via Komodo webhook) only
# need `docker compose up -d` which Komodo handles automatically.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd)"
cd "$SCRIPT_DIR"

echo "=== mailcow Komodo Setup for mail.lgucalapan.ph ==="

# Check if mailcow.conf already exists
if [ -f mailcow.conf ]; then
  echo "mailcow.conf already exists."
  read -r -p "Overwrite? This will back up the current config. [y/N] " response
  case $response in
    [yY][eE][sS]|[yY])
      cp mailcow.conf "mailcow.conf.bak.$(date +%s)"
      echo "Backed up existing config."
      ;;
    *)
      echo "Keeping existing config. Exiting."
      exit 0
      ;;
  esac
fi

# Generate random secrets
gen_secret() {
  openssl rand -base64 48 | LC_ALL=C tr -dc A-Za-z0-9 | head -c "${1:-28}" || true
}

DBPASS=$(gen_secret 28)
DBROOT=$(gen_secret 28)
REDISPASS=$(gen_secret 28)
SOGO_KEY=$(gen_secret 16)

echo "Generating mailcow.conf from template..."

sed \
  -e "s/__DBPASS__/${DBPASS}/" \
  -e "s/__DBROOT__/${DBROOT}/" \
  -e "s/__REDISPASS__/${REDISPASS}/" \
  -e "s/__SOGO_KEY__/${SOGO_KEY}/" \
  mailcow.conf.template > mailcow.conf

chmod 600 mailcow.conf

# Create .env symlink if not present
if [ ! -L .env ]; then
  ln -sf mailcow.conf .env
  echo "Created .env -> mailcow.conf symlink."
fi

# Create required directories
mkdir -p data/assets/ssl

# Generate snake-oil certificate if no cert exists
if [ ! -f data/assets/ssl/cert.pem ]; then
  echo "Generating snake-oil SSL certificate..."
  openssl req -x509 -newkey rsa:4096 \
    -keyout data/assets/ssl/key.pem \
    -out data/assets/ssl/cert.pem \
    -days 365 \
    -subj "/C=PH/ST=Calapan/L=Calapan/O=lgucalapan/OU=mail/CN=mail.lgucalapan.ph" \
    -sha256 -nodes 2>/dev/null
  echo "Snake-oil certificate generated. Let's Encrypt will replace it automatically."
fi

# Create rspamd password placeholder if missing
mkdir -p ./data/conf/rspamd/override.d
[ ! -f ./data/conf/rspamd/override.d/worker-controller-password.inc ] && \
  echo '# Placeholder' > ./data/conf/rspamd/override.d/worker-controller-password.inc

# Set app_info
mkdir -p data/web/inc
mailcow_git_version=$(git describe --tags "$(git rev-list --tags --max-count=1)" 2>/dev/null || git rev-parse --short HEAD)
mailcow_git_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
mailcow_git_commit_date=$(git log -1 --format=%ci 2>/dev/null || echo "unknown")
git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "master")

cat > data/web/inc/app_info.inc.php << APPEOF
<?php
  \$MAILCOW_GIT_VERSION="${mailcow_git_version}";
  \$MAILCOW_LAST_GIT_VERSION="";
  \$MAILCOW_GIT_OWNER="bonitobonita24";
  \$MAILCOW_GIT_REPO="mail_lgucalapan_ph";
  \$MAILCOW_GIT_URL="https://github.com/bonitobonita24/mail_lgucalapan_ph";
  \$MAILCOW_GIT_COMMIT="${mailcow_git_commit}";
  \$MAILCOW_GIT_COMMIT_DATE="${mailcow_git_commit_date}";
  \$MAILCOW_BRANCH="${git_branch}";
  \$MAILCOW_UPDATEDAT=$(date +%s);
?>
APPEOF

echo ""
echo "=== Setup Complete ==="
echo ""
echo "  Hostname: mail.lgucalapan.ph"
echo "  Timezone: Asia/Manila"
echo "  Config:   mailcow.conf (chmod 600)"
echo "  HTTP:     127.0.0.1:8080 (behind Traefik)"
echo "  HTTPS:    127.0.0.1:8443 (behind Traefik)"
echo ""
echo "Next steps:"
echo "  1. Configure Traefik to route mail.lgucalapan.ph -> http://127.0.0.1:8080"
echo "  2. Deploy stack from Komodo"
echo "  3. Access https://mail.lgucalapan.ph"
echo "  4. Login: admin / moohoo (change immediately!)"
echo ""
echo "DNS records required:"
echo "  A/AAAA  mail.lgucalapan.ph          -> your server IP"
echo "  MX      lgucalapan.ph               -> mail.lgucalapan.ph (priority 10)"
echo "  TXT     lgucalapan.ph               -> v=spf1 mx a -all"
echo "  TXT     _dmarc.lgucalapan.ph        -> v=DMARC1; p=reject; rua=mailto:admin@lgucalapan.ph"
echo "  TXT     dkim._domainkey.lgucalapan.ph -> (get from mailcow admin UI after first start)"
echo "  CNAME   autodiscover.lgucalapan.ph  -> mail.lgucalapan.ph"
echo "  CNAME   autoconfig.lgucalapan.ph    -> mail.lgucalapan.ph"
echo "  SRV     _autodiscover._tcp.lgucalapan.ph -> 0 1 443 mail.lgucalapan.ph"
