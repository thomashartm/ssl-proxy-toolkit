#!/bin/bash
# name: Project Bootstrapper
# description: Creates a new config, generates certs, and updates hosts

# Determine the project root directory (one level up from /scripts)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( dirname "$SCRIPT_DIR" )"

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
error_log "$PROJECT_DIR/logs/error.log" warn;
pid "$PROJECT_DIR/logs/nginx.pid";

# increase to 1024 if needed - but increase ulimit -n 1024 as well
events { worker_connections 256; }

http {
    access_log "$PROJECT_DIR/logs/access.log";

    server {
        listen 443 ssl;
        server_name $DOMAIN *.$DOMAIN;

        ssl_certificate     "$PROJECT_DIR/certs/$DOMAIN.pem";
        ssl_certificate_key "$PROJECT_DIR/certs/$DOMAIN-key.pem";

        # Landing Page dashboard
        location = / {
            root "$PROJECT_DIR/www";
            index index.html;
        }

        # Main Proxy Logic
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
