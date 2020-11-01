#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

echo "** PRE AUTHORIZATION HOOK START **"
quote=$'\042'

# Create DNS TXT record
echo "** CREATING DNS TXT RECORD **"
oci --auth resource_principal dns record domain update \
    --force \
    --zone-name-or-id $CERTBOT_FN_DNS_ZONE_ID \
    --domain _acme-challenge.$CERTBOT_FN_DNS_ZONE_NAME \
    --items "[{${quote}domain${quote}: ${quote}_acme-challenge.${CERTBOT_FN_DNS_ZONE_NAME}${quote}, \
               ${quote}rdata${quote}: ${quote}${CERTBOT_VALIDATION}${quote}, \
               ${quote}rtype${quote}: ${quote}TXT${quote}, \
               ${quote}ttl${quote}: 60}]"

# Give the record some time to propogate
sleep 20

echo "** PRE AUTHORIZATION HOOK FINISH **"