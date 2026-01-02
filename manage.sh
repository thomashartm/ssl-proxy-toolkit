#!/bin/bash
# local-proxy/manage.sh

# 1. Determine the absolute path of the project root
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NGINX_BIN=$(which nginx)
CONF_PATH="$PROJECT_DIR/conf/nginx.conf"

# 2. One-time Setup: Ensure logs exist and scripts are executable
mkdir -p "$PROJECT_DIR/logs"

# We only run chmod if the scripts aren't already executable
if [[ ! -x "$PROJECT_DIR/scripts/bootstrap.sh" ]]; then
    chmod +x "$PROJECT_DIR/scripts/"*.sh 2>/dev/null
fi

# 3. Command Switcher
case "$1" in
    start)
        echo "🚀 Starting Nginx..."
        ulimit -n 1024 # Increase limit for this process
        sudo "$NGINX_BIN" -p "$PROJECT_DIR" -c "$CONF_PATH"
        ;;
    stop)
        echo "🛑 Stopping Nginx..."
        sudo "$NGINX_BIN" -p "$PROJECT_DIR" -c "$CONF_PATH" -s stop
        ;;
    reload)
        echo "♻️ Reloading local config..."
        ulimit -n 1024 # Increase limit for this process
        sudo "$NGINX_BIN" -p "$PROJECT_DIR" -c "$CONF_PATH" -s reload
        ;;
    logs)
        echo "📋 Streaming Flow Logs..."
        tail -f "$PROJECT_DIR/logs/access.log" "$PROJECT_DIR/logs/error.log"
        ;;
    create)
        shift
        "$PROJECT_DIR/scripts/bootstrap.sh" "$@"
        ;;
    switch)
        shift
        "$PROJECT_DIR/scripts/switch.sh" "$@"
        ;;
    host)
        shift
        "$PROJECT_DIR/scripts/update_hosts.sh" "$@"
        ;;
    cert)
        shift
        "$PROJECT_DIR/scripts/create_cert.sh" "$@"
        ;;
    kill)
        "$PROJECT_DIR/scripts/kill_nginx.sh"
        ;;
    *)
        # Help Section
        echo "===================================================================="
        echo " 🚀 SSL Proxy Toolkit - CLI HELP "
        echo "===================================================================="
        echo "Usage: ./manage.sh [command] [arguments]"
        echo ""
        echo "CORE COMMANDS:"
        echo "  start             Launch Nginx using the active symlinked config."
        echo "  stop              Gracefully shut down Nginx."
        echo "  reload            Apply changes to the config without stopping."
        echo "  logs              Tail access and error logs in real-time."
        echo "  kill              Forcefully kill any orphaned Nginx processes."
        echo ""
        echo "WORKFLOW COMMANDS:"
        echo "  create [domain] [port]  Bootstrap a new project on local port (hosts, certs, .conf)."
        echo "  switch [file]     Switch the active project configuration."
        echo "  host [domain]     Manually map a domain to 127.0.0.1."
        echo "  cert [domain]     Manually generate trusted SSL certificates."
        echo ""
        echo "EXAMPLES:"
        echo "  ./manage.sh create ssl-proxy-setup.net 8083"
        echo "  ./manage.sh switch ssl-proxy-setup.net.conf"
        echo "  ./manage.sh start"
        echo "===================================================================="
        ;;
esac
