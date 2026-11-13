#!/usr/bin/env bash
# ==============================================================================
# Script: hdd-smart-health-audit.sh
# Description: Audits the 3TB HDD S.M.A.R.T. telemetry (temperature, power-on hours,
#              reallocated sectors, pending sectors) and capacity usage.
# Usage: sudo ./scripts/hdd-smart-health-audit.sh /dev/sdb
# ==============================================================================

set -euo pipefail

DISK_DEV="${1:-/dev/sdb}"
MOUNT_POINT="/mnt/storage3tb"

echo "======================================================================"
echo "  OPTIPLEX HOMELAB — 3TB HDD S.M.A.R.T. & STORAGE HEALTH AUDITOR"
echo "  Target Device: ${DISK_DEV} | Mount: ${MOUNT_POINT}"
echo "======================================================================"

if ! command -v smartctl >/dev/null 2>&1; then
    echo "[ERROR] smartmontools is not installed. Run: sudo apt install smartmontools"
    exit 1
fi

# 1. Overall SMART Health Assessment
echo -e "\n[1] S.M.A.R.T. Overall Health Status:"
sudo smartctl -H "${DISK_DEV}" | grep -E "overall-health|result" || true

# 2. Key Mechanical & Thermal Attributes
echo -e "\n[2] Critical Mechanical & Thermal Attributes:"
sudo smartctl -A "${DISK_DEV}" | grep -E "Reallocated_Sector_Ct|Spin_Retry_Count|Current_Pending_Sector|Offline_Uncorrectable|Temperature_Celsius|Power_On_Hours|Load_Cycle_Count" || true

# 3. Filesystem Utilization Breakdown on the 3TB Drive
echo -e "\n[3] 3TB Partition Capacity & Directory Usage:"
if [ -d "${MOUNT_POINT}" ]; then
    df -h "${MOUNT_POINT}"
    echo ""
    du -sh "${MOUNT_POINT}"/* 2>/dev/null || true
else
    echo "Mount point ${MOUNT_POINT} not currently mounted."
fi

echo "======================================================================"
