#!/bin/bash
set -eEo pipefail

# Configuration
CONFIGS_PATH="/etc/wireguard"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find available VPN configurations
mapfile -t configs < <(find "${CONFIGS_PATH}" -maxdepth 1 -name "*.conf" -exec basename {} .conf \; 2>/dev/null | sort)

if [[ ${#configs[@]} -eq 0 ]]; then
  echo "No WireGuard configurations found in ${CONFIGS_PATH}"
  exit 1
fi

# Present a selection menu
echo "Select a VPN configuration (0 to cancel):"
select vpn_name in "${configs[@]}"; do
  # Check if user entered 0 to cancel
  if [[ "${REPLY}" == "0" ]]; then
    echo "Selection cancelled"
    exit 0
  fi
  
  if [[ -n "${vpn_name}" ]]; then
    # Get the current VPN name
    source "${SCRIPT_DIR}/vpn.conf"
    
    # Update vpn.conf
    echo "VPN_NAME=\"${vpn_name}\"" > "${SCRIPT_DIR}/vpn.conf"
    echo "VPN configuration updated to ${vpn_name}"
    
    # If a VPN is connected, disconnect it
    if ip link show | grep -q "${VPN_NAME}"; then
      echo "Disconnecting from ${VPN_NAME}..."
      sudo wg-quick down "${VPN_NAME}"
      
      # Connect to the new VPN
      echo "Connecting to ${vpn_name}..."
      sudo wg-quick up "${vpn_name}"
    fi
    
    break
  else
    echo "Invalid selection."
  fi
done
