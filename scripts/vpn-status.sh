#!/bin/bash
set -eEo pipefail

# Output JSON status for Waybar
output_status() {
  local status=$1
  local tooltip=$2
  echo "{\"text\":\"\",\"alt\":\"${status}\",\"class\":\"${status}\",\"tooltip\":\"${tooltip}\"}"
}

# Source VPN configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if vpn.conf exists
if [[ ! -f "${SCRIPT_DIR}/vpn.conf" ]]; then
  output_status "none" "VPN config missing: vpn.conf not found"
  exit 0
fi

source "${SCRIPT_DIR}/vpn.conf"

# Check if VPN_NAME is set
if [[ -z "${VPN_NAME}" ]]; then
  output_status "none" "VPN not configured: VPN_NAME not set"
  exit 0
fi

# Check if VPN is connected and output status for Waybar
if ip link show | grep -q "${VPN_NAME}"; then
  output_status "connected" "VPN Connected: ${VPN_NAME}"
else
  output_status "disconnected" "VPN Disconnected: ${VPN_NAME}"
fi
