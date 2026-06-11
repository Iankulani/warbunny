#!/bin/bash
# WARBUNNY Docker Entrypoint Script

set -e

echo "🐇 WARBUNNY v2.0.0 - Docker Container Starting"
echo "================================================"

# Create necessary directories
mkdir -p ${WARBUNNY_CONFIG}
mkdir -p /var/log/warbunny

# Check if running as root (for network capabilities)
if [ "$(id -u)" = "0" ]; then
    echo "⚠️  Running as root - enabling advanced network features"
    
    # Allow ping for non-root users
    sysctl -w net.ipv4.ping_group_range="0 2147483647" > /dev/null 2>&1 || true
    
    # Set capabilities for Python binary
    if command -v setcap >/dev/null 2>&1; then
        setcap cap_net_raw,cap_net_admin=eip /usr/bin/python3.10 || true
    fi
    
    # Switch to warbunny user
    exec su -c "$*" warbunny
else
    echo "✅ Running as warbunny user"
    exec "$@"
fi