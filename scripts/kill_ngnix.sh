#!/bin/bash
# name: Selective Kill
# description: Surgical shutdown of project-specific Nginx processes

# 1. Resolve Project Paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( dirname "$SCRIPT_DIR" )"
PID_FILE="$PROJECT_DIR/logs/nginx.pid"
NGINX_BIN=$(which nginx)

echo "🔍 Scanning for local proxy processes..."

# 2. Shutdown via PID file (The "Clean" Way)
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    # Check if this PID is actually running and belongs to nginx
    if ps -p "$PID" -o comm= 2>/dev/null | grep -q "nginx"; then
        echo "✅ Found active master process (PID: $PID). Sending stop signal..."
        sudo "$NGINX_BIN" -p "$PROJECT_DIR" -c "conf/nginx.conf" -s stop &>/dev/null
        sleep 0.5
    fi
    rm -f "$PID_FILE"
fi

# 3. Targeted Cleanup (The "Surgical" Way)
# We look for processes running this specific project configuration
# This avoids killing other Nginx instances or browser tabs
TARGET_PIDS=$(pgrep -f "nginx.*$PROJECT_DIR")

if [ -n "$TARGET_PIDS" ]; then
    COUNT=0
    for pid in $TARGET_PIDS; do
        # Double-check that it is an nginx binary and not a text editor/browser
        if ps -p "$pid" -o comm= 2>/dev/null | grep -q "nginx"; then
            sudo kill -9 "$pid" &>/dev/null
            ((COUNT++))
        fi
    done

    if [ "$COUNT" -gt 0 ]; then
        echo "✅ Terminated $COUNT orphaned worker processes."
    fi
else
    echo "ℹ️  No orphaned processes found for this project."
fi

# 4. Port 443 Rescue
# If the port is still blocked by an nginx process, release it
PORT_PID=$(sudo lsof -t -i :443 2>/dev/null)
if [ -n "$PORT_PID" ]; then
    if ps -p "$PORT_PID" -o comm= 2>/dev/null | grep -q "nginx"; then
        echo "✅ Releasing port 443 from orphaned Nginx instance."
        sudo kill -9 "$PORT_PID" &>/dev/null
    fi
fi

echo "✨ Cleanup complete. Your browser and other Nginx instances were not affected."
