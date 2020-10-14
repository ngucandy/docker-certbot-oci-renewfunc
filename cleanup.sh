#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

echo "** CLEANUP HOOK **"

# Remove DNS TXT record
oci --auth resource_principal dns record domain delete \
    --force \
    --zone-name-or-id $CERTBOT_FN_DNS_ZONE_ID \
    --domain _acme-challenge.$CERTBOT_FN_DOMAIN
