#!/bin/bash

echo "** CERTBOT **"

certbot_base_dir="/tmp/certbot"
config_dir="$certbot_base_dir/config"
work_dir="$certbot_base_dir/work"
logs_dir="$certbot_base_dir/logs"

mkdir -p ${logs_dir}
echo "** STDIN DUMP **"
/usr/bin/tee ${logs_dir}/event.json

certbot_archive="${CERTBOT_FN_ARCHIVE_FILE_PREFIX}-${CERTBOT_FN_DOMAIN}.tar.gz"
echo "** CHECKING FOR EXISTING CERTBOT ARCHIVE **"
if oci --auth resource_principal os object head -ns $CERTBOT_FN_OS_NS -bn $CERTBOT_FN_OS_BN --name "${certbot_archive}" > /dev/null; then
  echo "** DOWNLOADING EXISTING CERTBOT ARCHIVE **"
  oci --auth resource_principal os object get -ns $CERTBOT_FN_OS_NS -bn $CERTBOT_FN_OS_BN --name "${certbot_archive}" --file "-" | tar -C /tmp -xz
  echo "** RENEWING CERTIFICATES IN CERTBOT ARCHIVE **"
  /usr/local/bin/certbot renew --config-dir $config_dir --work-dir $work_dir --logs-dir $logs_dir
else
  echo "** NO EXISTING CERTBOT ARCHIVE **"
  echo "** REQUESTING NEW CERTIFICATE **"
  certbot_opts=($CERTBOT_FN_NEWCERT_OPTS)
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
    "${certbot_opts[@]}"
fi

echo "** UPLOADING CERTBOT ARCHIVE **"
tar -C /tmp -czf "/tmp/$certbot_archive" certbot
oci --auth resource_principal os object put -ns $CERTBOT_FN_OS_NS -bn $CERTBOT_FN_OS_BN --file "/tmp/$certbot_archive" --force
echo "** UPLOADING CERTBOT CONTROL FILE **"
certbot_control="${certbot_archive}.control"
touch "/tmp/$certbot_control"
oci --auth resource_principal os object put -ns $CERTBOT_FN_OS_NS -bn $CERTBOT_FN_OS_BN --file "/tmp/$certbot_control" --force
rm -rf "$certbot_base_dir"
