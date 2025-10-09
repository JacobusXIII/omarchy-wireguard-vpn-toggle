#!/bin/bash
set -eEo pipefail

# Source VPN configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/vpn.conf"

# Toggle VPN connection
if ip link show | grep -q "${VPN_NAME}"; then
  sudo wg-quick down "${VPN_NAME}"
else
  sudo wg-quick up "${VPN_NAME}"
fi
