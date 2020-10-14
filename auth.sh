#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

echo "** PRE AUTHORIZATION HOOK **"
quote=$'\042'

# Create DNS TXT record
oci --auth resource_principal dns record domain update \
    --force \
    --zone-name-or-id $CERTBOT_FN_DNS_ZONE_ID \
    --domain _acme-challenge.$CERTBOT_FN_DOMAIN \
    --items "[{${quote}domain${quote}: ${quote}_acme-challenge.${CERTBOT_FN_DOMAIN}${quote}, \
               ${quote}rdata${quote}: ${quote}${CERTBOT_VALIDATION}${quote}, \
               ${quote}rtype${quote}: ${quote}TXT${quote}, \
               ${quote}ttl${quote}: 60}]"

# Give the record some time to propogate
sleep 20