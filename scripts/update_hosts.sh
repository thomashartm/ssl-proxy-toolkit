#!/bin/bash
# name: Hosts Updater
# description: Maps a domain to 127.0.0.1 in the system hosts file

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
    echo "❌ Usage: ./scripts/update_hosts.sh <domain.com>"
    exit 1
fi

# The entry we want to ensure exists
ENTRY="127.0.0.1 $DOMAIN"

# Check if the domain is already in /etc/hosts
if grep -q "[[:space:]]$DOMAIN" /etc/hosts; then
    echo "ℹ️  Entry for $DOMAIN already exists in /etc/hosts"
else
    echo "📝 Adding $DOMAIN to /etc/hosts..."
    # Use tee to append with sudo permissions
    echo "$ENTRY" | sudo tee -a /etc/hosts > /dev/null

    if [ $? -eq 0 ]; then
        echo "✅ Successfully added $DOMAIN"
    else
        echo "❌ Failed to update /etc/hosts. Check your permissions."
        exit 1
    fi
fi
