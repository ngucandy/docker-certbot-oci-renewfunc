#!/bin/bash

echo "** CERTBOT **"
echo

certbot_base_dir="/tmp/certbot"
config_dir="$certbot_base_dir/config"
work_dir="$certbot_base_dir/work"
logs_dir="$certbot_base_dir/logs"

mkdir -p ${logs_dir}
echo "** STDIN DUMP **"
/usr/bin/tee ${logs_dir}/event.json
echo

certbot_archive="${CERTBOT_FN_ARCHIVE_FILE_PREFIX}-${CERTBOT_FN_DOMAIN}.tar.gz"
if oci --auth resource_principal os object head -ns $CERTBOT_FN_OS_NS -bn $CERTBOT_FN_OS_BN --name "${certbot_archive}"; then
  oci --auth resource_principal os object get -ns $CERTBOT_FN_OS_NS -bn $CERTBOT_FN_OS_BN --name "${certbot_archive}" --file "-" | tar -C /tmp -xz
  /usr/local/bin/certbot renew --config-dir $config_dir --work-dir $work_dir --logs-dir $logs_dir
else
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
fi

#if [ -s /tmp/input.txt ]; then
#  echo "** DOWNLOAD EXISTING ARCHIVE FROM OBJECT STORAGE **"
#  certbot_archive_old=$(python3 -c "import sys, json, re; print(re.sub('\.control$', '', json.load(sys.stdin)['data']['resourceName']))")
#  oci --auth resource_principal os object get -ns $CERTBOT_FN_OS_NS -bn $CERTBOT_FN_OS_BN --name "${certbot_archive_old}" --file "/tmp/${certbot_archive_old}"
#  tar -C /tmp -xzf "/tmp/${certbot_archive_old}"
#fi

echo "** UPLOAD ARCHIVE TO OBJECT STORAGE **"
echo
certbot_control="${certbot_archive}.control"
tar -C /tmp -czf "/tmp/$certbot_archive" certbot
oci --auth resource_principal os object put -ns $CERTBOT_FN_OS_NS -bn $CERTBOT_FN_OS_BN --file "/tmp/$certbot_archive" --force
touch "/tmp/$certbot_control"
oci --auth resource_principal os object put -ns $CERTBOT_FN_OS_NS -bn $CERTBOT_FN_OS_BN --file "/tmp/$certbot_control" --force
