#!/usr/bin/env bash
# ==============================================================================
# Script: backup-local-3tb.sh
# Description: Safe hot-backup of the Minecraft world (via RCON save-off/save-all)
#              and Pi-hole configuration directly onto the 3TB HDD with SHA-256
#              checksums and automatic 14-day retention pruning.
# ==============================================================================

set -euo pipefail

STORAGE_ROOT="/mnt/storage3tb"
MC_DATA_DIR="${STORAGE_ROOT}/minecraft_data"
PIHOLE_DIR="${STORAGE_ROOT}/appdata/pihole"
BACKUP_DIR="${STORAGE_ROOT}/backups"
RETENTION_DAYS=14
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

mkdir -p "${BACKUP_DIR}/minecraft" "${BACKUP_DIR}/pihole"

echo "=== [$(date)] Starting OptiPlex Homelab Local Backup on 3TB HDD ==="

# 1. Safe Minecraft World Backup (Flush chunks and pause disk writes via RCON)
if docker ps --format '{{.Names}}' | grep -q "^optiplex-minecraft$"; then
    echo "[Minecraft] Flushing world chunks via rcon-cli..."
    docker exec optiplex-minecraft rcon-cli save-off || true
    docker exec optiplex-minecraft rcon-cli save-all flush || true
    sleep 2
fi

if [ -d "${MC_DATA_DIR}" ]; then
    MC_ARCHIVE="${BACKUP_DIR}/minecraft/mc_world_${TIMESTAMP}.tar.gz"
    echo "[Minecraft] Compressing world data to ${MC_ARCHIVE}..."
    tar -czf "${MC_ARCHIVE}" -C "${MC_DATA_DIR}" .
    sha256sum "${MC_ARCHIVE}" > "${MC_ARCHIVE}.sha256"
fi

if docker ps --format '{{.Names}}' | grep -q "^optiplex-minecraft$"; then
    echo "[Minecraft] Re-enabling world auto-save via rcon-cli..."
    docker exec optiplex-minecraft rcon-cli save-on || true
fi

# 2. Pi-hole Configuration & Blocklist Backup
if [ -d "${PIHOLE_DIR}" ]; then
    PIHOLE_ARCHIVE="${BACKUP_DIR}/pihole/pihole_config_${TIMESTAMP}.tar.gz"
    echo "[Pi-hole] Archiving DNS & blocklist configs to ${PIHOLE_ARCHIVE}..."
    tar -czf "${PIHOLE_ARCHIVE}" -C "${PIHOLE_DIR}" .
    sha256sum "${PIHOLE_ARCHIVE}" > "${PIHOLE_ARCHIVE}.sha256"
fi

# 3. Prune backups older than RETENTION_DAYS on the 3TB drive
echo "[Cleanup] Removing archives older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}/minecraft" -type f -mtime +"${RETENTION_DAYS}" -delete
find "${BACKUP_DIR}/pihole" -type f -mtime +"${RETENTION_DAYS}" -delete

echo "=== [$(date)] Backup completed successfully! ==="
df -h "${STORAGE_ROOT}" || true
