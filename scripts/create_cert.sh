#!/bin/bash
# name: Certificate Generator
# description: Generates trusted local SSL certificates for a specific domain

DOMAIN=$1
CERTS_DIR="./certs"

if [ -z "$DOMAIN" ]; then
    echo "❌ Usage: ./scripts/create_cert.sh <domain.com>"
    exit 1
fi

mkdir -p "$CERTS_DIR"

echo "🔐 Generating certificates for $DOMAIN..."

# FIX: Removed the space between *. and $DOMAIN
mkcert -cert-file "$CERTS_DIR/$DOMAIN.pem" \
       -key-file "$CERTS_DIR/$DOMAIN-key.pem" \
       "$DOMAIN" "*.$DOMAIN" "localhost" "127.0.0.1"

echo "✅ Success! Certificates created in $CERTS_DIR"
