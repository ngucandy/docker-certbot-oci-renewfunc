#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

echo "** CERTBOT **"
echo
echo "** STDIN DUMP **"
/usr/bin/tee /tmp/input.txt
echo

certbot_base_dir="/tmp/certbot"
config_dir="$certbot_base_dir/config"
work_dir="$certbot_base_dir/work"
logs_dir="$certbot_base_dir/logs"

/usr/local/bin/certbot certonly --manual --preferred-challenges=dns --agree-tos \
  --manual-auth-hook /auth.sh \
  --manual-cleanup-hook /cleanup.sh \
  --manual-public-ip-logging-ok \
  --config-dir $config_dir \
  --work-dir $work_dir \
  --logs-dir $logs_dir \
  --no-eff-email \
  --non-interactive \
  --domain "*.$CERTBOT_FN_DOMAIN" \
  --email "$CERTBOT_FN_EMAIL" \
  --test-cert

echo "** UPLOAD ARCHIVE TO OBJECT STORAGE **"
echo
certbot_archive="/tmp/certbot-$(date -Iminutes).tar.gz"
tar -C $certbot_base_dir -czf "$certbot_archive" .
oci --auth resource_principal os object put -ns $CERTBOT_FN_OS_NS -bn $CERTBOT_FN_OS_BN --file "$certbot_archive"
