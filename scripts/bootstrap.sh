#!/bin/bash
# name: Project Bootstrapper
# description: Creates a new config, generates certs, and updates hosts

# Determine the project root directory (one level up from /scripts)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( dirname "$SCRIPT_DIR" )"

# Detect current user and primary group
CURRENT_USER=$(id -un)
CURRENT_GROUP=$(id -gn)

DOMAIN=${1:-"ssl-proxy-setup.net"}
PORT=${2:-"8083"}

if [ -z "$1" ]; then
    echo "❌ Usage: ./manage.sh create <domain> <port>"
    exit 1
fi

echo "🏗️  Bootstrapping project in: $PROJECT_DIR"

# 1. Run helpers (Passing domain as argument)
"$SCRIPT_DIR/update_hosts.sh" "$DOMAIN"
"$SCRIPT_DIR/create_cert.sh" "$DOMAIN"

# 2. Create Nginx Config with Absolute Paths
# We use absolute paths for 'root', 'ssl_certificate', etc.,
# so Nginx never gets confused about its working directory.

cat <<EOF > "$PROJECT_DIR/conf/$DOMAIN.conf"
# name: $DOMAIN Proxy
# description: Forwarding https://$DOMAIN to localhost:$PORT

worker_processes 1;

# Run as the local user to avoid Permission Denied errors in home directories
user $CURRENT_USER $CURRENT_GROUP;

error_log "$PROJECT_DIR/logs/error.log" warn;
pid "$PROJECT_DIR/logs/nginx.pid";

# increase to 1024 if needed
# but increase ulimit -n 1024 as well
events { worker_connections 256; }

http {
    access_log "$PROJECT_DIR/logs/access.log";

    server {
        listen 443 ssl;
        server_name $DOMAIN *.$DOMAIN;

        ssl_certificate     "$PROJECT_DIR/certs/$DOMAIN.pem";
        ssl_certificate_key "$PROJECT_DIR/certs/$DOMAIN-key.pem";

        # 1. Distinct Healthcheck/Dashboard Location
        # Access this at https://$DOMAIN/proxy-health
        location = /proxy-health {
            root "$PROJECT_DIR/www";
            try_files /index.html =404;
        }

        # 2. Transparent Proxy for EVERYTHING else
        # This handles /, /auth, /api, etc.
        location / {
            proxy_pass http://127.0.0.1:$PORT;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;

            # Allow large file uploads
            client_max_body_size 128M;
        }
    }
}
EOF

echo "✅ Project '$DOMAIN' config created at $PROJECT_DIR/conf/$DOMAIN.conf"
