#!/bin/bash

# This certificate includes the Subject Alternate Name (SAN) that's required by Chrome.

echo
echo "host: $BIGPURPLE_HOST (IP: $BIGPURPLE_LBIP)"

if [ "$BIGPURPLE_HOST" != "" ] && [ "$BIGPURPLE_HOST" != "$BIGPURPLE_LBIP" ]
then
  hostEntry=",DNS:$BIGPURPLE_HOST" 
fi

if [ -f self-signed.cert.txt ]
then
    if grep -q "DNS:$BIGPURPLE_HOST" self-signed.cert.txt 
    then
        exit 0
    fi
fi

echo
echo "Creating a development self-signed certificate"

openssl req \
-x509 \
-newkey rsa:2048 \
-sha256 \
-days 35 \
-nodes \
-keyout self-signed.key \
-out self-signed.cert.pem \
-subj '/CN=bigpurplems.development/O=BigPurple MS (Development) - Self-signed' \
-extensions san \
-config <( \
  echo "[req]"; \
  echo "distinguished_name=req"; \
  echo "[san]"; \
  echo "subjectAltName=DNS:bigpurplems.local,DNS:bigpurplems.aks$hostEntry")

openssl x509 -in self-signed.cert.pem -text -noout > self-signed.cert.txt
