#!/usr/bin/env bash
# ==============================================================================
# Script: bootstrap-optiplex.sh
# Description: Initial setup for Dell OptiPlex Homelab (i5-3470 / 8GB DDR3 / 3TB HDD)
#   1. Creates directory hierarchy on the 3TB HDD (/mnt/storage3tb) for:
#      - Samba Shares & FileBrowser (/shares)
#      - Immich Photo Library (/photos)
#      - Jellyfin & Navidrome Media (/media/movies, /series, /music, /videos)
#      - Minecraft Server (/minecraft_data) & Local Backups (/backups)
#   2. Frees UDP/TCP port 53 from systemd-resolved so Pi-hole can bind cleanly
#   3. Applies Linux VM & TCP sysctl tuning for 8GB RAM + Gigabit Samba + Minecraft
# ==============================================================================

set -euo pipefail

MOUNT_POINT="/mnt/storage3tb"

echo "[1/4] Preparing 3TB HDD directory layout at ${MOUNT_POINT}..."
sudo mkdir -p "${MOUNT_POINT}/shares/public"
sudo mkdir -p "${MOUNT_POINT}/shares/personal"
sudo mkdir -p "${MOUNT_POINT}/photos"
sudo mkdir -p "${MOUNT_POINT}/media/movies"
sudo mkdir -p "${MOUNT_POINT}/media/series"
sudo mkdir -p "${MOUNT_POINT}/media/videos"
sudo mkdir -p "${MOUNT_POINT}/media/music"
sudo mkdir -p "${MOUNT_POINT}/minecraft_data"
sudo mkdir -p "${MOUNT_POINT}/backups/minecraft"
sudo mkdir -p "${MOUNT_POINT}/backups/pihole"
sudo mkdir -p "${MOUNT_POINT}/backups/immich-db"
sudo mkdir -p "${MOUNT_POINT}/appdata/pihole/etc-pihole"
sudo mkdir -p "${MOUNT_POINT}/appdata/pihole/etc-dnsmasq.d"
sudo mkdir -p "${MOUNT_POINT}/appdata/filebrowser/database"
sudo mkdir -p "${MOUNT_POINT}/appdata/filebrowser/config"
sudo mkdir -p "${MOUNT_POINT}/appdata/immich-postgres"
sudo mkdir -p "${MOUNT_POINT}/appdata/jellyfin"
sudo mkdir -p "${MOUNT_POINT}/appdata/navidrome"

sudo chown -R 1000:1000 "${MOUNT_POINT}/shares" "${MOUNT_POINT}/photos" "${MOUNT_POINT}/media" "${MOUNT_POINT}/minecraft_data" "${MOUNT_POINT}/appdata"
sudo chmod -R 775 "${MOUNT_POINT}/shares" "${MOUNT_POINT}/media"

echo "[2/4] Disabling systemd-resolved DNS stub listener on port 53 (required for Pi-hole)..."
if [ -f /etc/systemd/resolved.conf ]; then
    sudo sed -i 's/^#*DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
    sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
    sudo systemctl restart systemd-resolved || true
fi

echo "[3/4] Applying kernel sysctl tuning for 8GB DDR3 RAM & Gigabit SMB/Minecraft..."
cat << 'EOF' | sudo tee /etc/sysctl.d/99-optiplex-homelab.conf >/dev/null
# Avoid premature swap usage when Minecraft + Immich + Jellyfin run together
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# Smooth writeback to the 3TB mechanical HDD (prevents I/O lag spikes)
vm.dirty_background_ratio = 5
vm.dirty_ratio = 15

# Gigabit LAN buffer optimization for Samba SMB3 & Jellyfin streaming
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_congestion_control = bbr
EOF
sudo sysctl --system >/dev/null

echo "[4/4] Verifying smartmontools & hdparm for 3TB HDD health monitoring..."
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq smartmontools hdparm curl tar
fi

echo "Bootstrap completed! Copy .env.example to .env and run: docker compose up -d"
