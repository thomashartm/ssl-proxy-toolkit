#!/bin/bash
# name: Config Switcher
# description: Manages symlinks to activate specific Nginx configurations

CONF_DIR="./conf"
ACTIVE_LINK="$CONF_DIR/nginx.conf"

# 1. List available project configs
list_configs() {
    echo -e "AVAILABLE PROJECTS:"
    echo -e "--------------------------------------------------------------------------------"
    printf "%-20s | %-15s | %s\n" "FILE" "NAME" "DESCRIPTION"
    echo -e "--------------------------------------------------------------------------------"

    for file in "$CONF_DIR"/*.conf; do
        # Skip the active symlink itself
        if [[ "$file" == "$ACTIVE_LINK" ]]; then continue; fi

        filename=$(basename "$file")
        # Extract name and description from lines 2 and 3
        p_name=$(sed -n '2p' "$file" | sed 's/# name: //')
        p_desc=$(sed -n '3p' "$file" | sed 's/# description: //')

        printf "%-20s | %-15s | %s\n" "$filename" "$p_name" "$p_desc"
    done
    echo -e "--------------------------------------------------------------------------------"
}

# 2. Handle switching
if [ -z "$1" ]; then
    list_configs
    echo "Usage: ./scripts/switch.sh <filename.conf>"
    exit 0
fi

TARGET_FILE="$CONF_DIR/$1"

if [ ! -f "$TARGET_FILE" ]; then
    echo "❌ Error: Configuration file '$1' not found in $CONF_DIR"
    exit 1
fi

# Remove old symlink if it exists
rm -f "$ACTIVE_LINK"

# Create new symlink (relative path is better for portability)
ln -s "$(basename "$TARGET_FILE")" "$ACTIVE_LINK"

echo "✅ Switched to: $1"
echo "👉 Run './manage.sh reload' (or start) to apply changes."
