#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

echo "** CLEANUP HOOK START **"

# Remove DNS TXT record
echo "** REMOVING DNS TXT RECORD **"
oci --auth resource_principal dns record domain delete \
    --force \
    --zone-name-or-id $CERTBOT_FN_DNS_ZONE_ID \
    --domain _acme-challenge.$CERTBOT_FN_DNS_ZONE_NAME

echo "** CLEANUP HOOK FINISH **"