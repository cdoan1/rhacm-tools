#!/bin/bash

export DOMAIN=${DOMAIN:-"*.red-chesterfield.com"}

# Use acme.sh to generate the signed certificate
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} ./acme.sh --issue --dns dns_aws -d "${DOMAIN}"

cd ~/acme.sh/${DOMAIN}

if [[ ! -f ${DOMAIN}.key || ! -f fullchain.cer ]]; then
  exit 1
fi

# the command will ask for the password to encrypt the .pfx file
openssl pkcs12 -export -in fullchain.cer -inkey "${DOMAIN}.key" -out fullchain.pfx

echo "Created .pfx file:"
ls -al fullchain.pfx
