#!/bin/bash
set -eEo pipefail

# WireGuard VPN Toggle Installer for Omarchy's Waybar
# Based on: https://github.com/basecamp/omarchy/discussions/1366
# 
# Can be used as:
# 1. Local install: ./install.sh
# 2. One-liner: curl -fsSL https://raw.githubusercontent.com/JacobusXIII/omarchy-wireguard-vpn-toggle/main/install.sh | bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# GitHub configuration for one-liner mode
GITHUB_USER="JacobusXIII"
GITHUB_REPO="omarchy-wireguard-vpn-toggle"
GITHUB_BRANCH="main"

# Runtime configuration
WAYBAR_CONFIG_DIR="${HOME}/.config/waybar"
SCRIPTS_DIR="${WAYBAR_CONFIG_DIR}/scripts"
VPN_CONFIGS_PATH="/etc/wireguard"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "/tmp")"
REPO_SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
TEMP_INSTALL_DIR=""

# Error handling
catch_errors() {
  local exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    print_error "Installation failed with exit code ${exit_code}"
    # Clean up temp directory if it exists
    if [[ -n "${TEMP_INSTALL_DIR}" ]] && [[ -d "${TEMP_INSTALL_DIR}" ]]; then
      rm -rf "${TEMP_INSTALL_DIR}"
    fi
  fi
  return "${exit_code}"
}

exit_handler() {
  local exit_code=$?
  # Clean up temp directory if it exists and installation was successful
  if [[ ${exit_code} -eq 0 ]] && [[ -n "${TEMP_INSTALL_DIR}" ]] && [[ -d "${TEMP_INSTALL_DIR}" ]]; then
    rm -rf "${TEMP_INSTALL_DIR}"
  fi
  exit "${exit_code}"
}

trap catch_errors ERR INT TERM
trap exit_handler EXIT

# Print functions
print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

# Check if scripts need to be downloaded (not running from repo)
need_download() {
  # Check if scripts directory exists
  if [[ ! -d "${REPO_SCRIPTS_DIR}" ]]; then
    return 0
  fi
  
  return 1
}

# Download repository for oneliner mode
download_repository() {
  print_info "Downloading repository..."
  
  TEMP_INSTALL_DIR="/tmp/omarchy-wireguard-vpn-toggle-$$"
  
  # Try git clone first
  if command -v git &>/dev/null; then
    if git clone --depth 1 --branch "${GITHUB_BRANCH}" \
        "https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git" \
        "${TEMP_INSTALL_DIR}" &>/dev/null; then
      print_success "Repository downloaded via git"
      REPO_SCRIPTS_DIR="${TEMP_INSTALL_DIR}/scripts"
      return 0
    fi
  fi
  
  # Fallback to tarball download
  print_info "Downloading repository tarball..."
  local tarball_url="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/refs/heads/${GITHUB_BRANCH}.tar.gz"
  
  mkdir -p "${TEMP_INSTALL_DIR}"
  
  if command -v curl &>/dev/null; then
    if curl -fsSL "${tarball_url}" | tar -xz -C "${TEMP_INSTALL_DIR}" --strip-components=1 2>/dev/null; then
      print_success "Repository downloaded via curl"
      REPO_SCRIPTS_DIR="${TEMP_INSTALL_DIR}/scripts"
      return 0
    fi
  elif command -v wget &>/dev/null; then
    if wget -qO- "${tarball_url}" | tar -xz -C "${TEMP_INSTALL_DIR}" --strip-components=1 2>/dev/null; then
      print_success "Repository downloaded via wget"
      REPO_SCRIPTS_DIR="${TEMP_INSTALL_DIR}/scripts"
      return 0
    fi
  fi
  
  print_error "Failed to download repository"
  print_error "Please install git, curl, or wget"
  exit 1
}

# Main installation logic
main() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}WireGuard VPN Toggle for Omarchy${NC}"
  echo -e "${BLUE}========================================${NC}\n"

  # Download repository if scripts not present
  if need_download; then
    print_info "Running in one-liner mode"
    download_repository
    echo ""
  fi

  # Check if running as root
  if [[ ${EUID} -eq 0 ]]; then
    print_error "Please do not run this script as root. It will prompt for sudo when needed."
    exit 1
  fi

  check_dependencies
  check_wireguard_configs
  create_waybar_directory
  verify_repo_scripts
  install_scripts
  create_vpn_config
  update_waybar_config
  update_waybar_styles
  configure_sudoers
  show_completion_message
  restart_waybar
}

check_dependencies() {
  print_info "Checking dependencies..."

  local -a dependencies=("wireguard-tools" "waybar" "jq")
  local -a missing_deps=()

  if ! command -v wg-quick &>/dev/null; then
    missing_deps+=("wireguard-tools")
  fi

  if ! command -v waybar &>/dev/null; then
    missing_deps+=("waybar")
  fi

  if ! command -v jq &>/dev/null; then
    missing_deps+=("jq")
  fi

  if [[ ${#missing_deps[@]} -ne 0 ]]; then
    print_error "Missing dependencies: ${missing_deps[*]}"
    echo ""
    print_info "Install missing dependencies:"
    echo "  sudo pacman -S wireguard-tools waybar jq"
    exit 1
  fi

  print_success "All dependencies are installed"
}

check_wireguard_configs() {
  print_info "Checking for WireGuard configurations..."

  if [[ ! -d "${VPN_CONFIGS_PATH}" ]]; then
    print_warning "WireGuard configuration directory not found: ${VPN_CONFIGS_PATH}"
    print_info "Please install WireGuard and add your VPN configuration files."
    print_info "For ProtonVPN, see: https://protonvpn.com/support/wireguard-linux"
    
    read -p "Continue anyway? (y/N) " -n 1 -r </dev/tty
    echo
    if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
      exit 1
    fi
  else
    local config_count
    config_count=$(sudo find "${VPN_CONFIGS_PATH}" -maxdepth 1 -name "*.conf" 2>/dev/null | wc -l)
    
    if [[ ${config_count} -eq 0 ]]; then
      print_warning "No WireGuard configurations found in ${VPN_CONFIGS_PATH}"
      print_info "You'll need to add .conf files there before the VPN toggle will work."
      
      read -p "Continue anyway? (y/N) " -n 1 -r </dev/tty
      echo
      if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
        exit 1
      fi
    else
      print_success "Found ${config_count} WireGuard configuration(s)"
    fi
  fi
}

create_waybar_directory() {
  if [[ ! -d "${WAYBAR_CONFIG_DIR}" ]]; then
    print_info "Creating Waybar config directory..."
    mkdir -p "${WAYBAR_CONFIG_DIR}"
    print_success "Created ${WAYBAR_CONFIG_DIR}"
  fi
  
  if [[ ! -d "${SCRIPTS_DIR}" ]]; then
    print_info "Creating Waybar scripts directory..."
    mkdir -p "${SCRIPTS_DIR}"
    print_success "Created ${SCRIPTS_DIR}"
  fi
}

verify_repo_scripts() {
  if [[ ! -d "${REPO_SCRIPTS_DIR}" ]]; then
    print_error "Scripts directory not found: ${REPO_SCRIPTS_DIR}"
    print_error "Please ensure you're running this script from the repository root."
    exit 1
  fi
}

install_scripts() {
  print_info "Installing VPN toggle scripts..."

  local -a scripts=("vpn-status.sh" "vpn-toggle.sh" "vpn-select.sh")
  
  for script in "${scripts[@]}"; do
    if [[ -f "${REPO_SCRIPTS_DIR}/${script}" ]]; then
      cp "${REPO_SCRIPTS_DIR}/${script}" "${SCRIPTS_DIR}/"
      chmod +x "${SCRIPTS_DIR}/${script}"
      print_success "Installed ${script}"
    else
      print_error "Script not found: ${REPO_SCRIPTS_DIR}/${script}"
      exit 1
    fi
  done
}

create_vpn_config() {
  if [[ ! -f "${SCRIPTS_DIR}/vpn.conf" ]]; then
    local first_config
    first_config=$(find "${VPN_CONFIGS_PATH}" -maxdepth 1 -name "*.conf" 2>/dev/null | head -n 1 | xargs -n 1 basename -s .conf 2>/dev/null || echo "")
    
    if [[ -n "${first_config}" ]]; then
      echo "VPN_NAME=\"${first_config}\"" > "${SCRIPTS_DIR}/vpn.conf"
      print_success "Created vpn.conf with default: ${first_config}"
    else
      echo "VPN_NAME=\"wg0\"" > "${SCRIPTS_DIR}/vpn.conf"
      print_warning "Created vpn.conf with placeholder. Update it with your VPN config name."
    fi
  else
    print_info "vpn.conf already exists, skipping..."
  fi
}

update_waybar_config() {
  print_info "Updating Waybar configuration..."

  local config_file="${WAYBAR_CONFIG_DIR}/config.jsonc"
  if [[ ! -f "${config_file}" ]]; then
    config_file="${WAYBAR_CONFIG_DIR}/config"
  fi

  if [[ ! -f "${config_file}" ]]; then
    print_warning "Waybar config file not found at ${config_file}"
    return 0
  fi

  local backup_file="${config_file}.backup.$(date +%Y%m%d-%H%M%S)"
  cp "${config_file}" "${backup_file}"
  print_success "Backed up existing config to ${backup_file}"

  # Check if custom/vpn already exists
  if jq -e '.["custom/vpn"]' "${config_file}" &>/dev/null; then
    print_info "custom/vpn already present in Waybar config"
    return 0
  fi

  # Add custom/vpn to modules-right after network
  if jq -e '.["modules-right"]' "${config_file}" &>/dev/null; then
    # Find network and insert custom/vpn right after it, preserving order
    jq '.["modules-right"] = (
      .["modules-right"] | 
      to_entries | 
      map(
        if .value == "network" then 
          [., {"key": (.key + 0.5), "value": "custom/vpn"}]
        else 
          .
        end
      ) | 
      flatten | 
      sort_by(.key) | 
      map(.value)
    )' "${config_file}" > "${config_file}.tmp"
    mv "${config_file}.tmp" "${config_file}"
    print_success "Added custom/vpn to modules-right after network"
  else
    print_warning "Could not find modules-right in config"
  fi

  # Add custom/vpn module definition
  jq '. += {
    "custom/vpn": {
      "format": "{icon}",
      "format-icons": {
        "default": "",
        "none": "󰻌",
        "connected": "󰦝",
        "disconnected": "󰦞"
      },
      "interval": 3,
      "return-type": "json",
      "exec": "$HOME/.config/waybar/scripts/vpn-status.sh",
      "on-click": "$HOME/.config/waybar/scripts/vpn-toggle.sh",
      "on-click-right": "omarchy-launch-floating-terminal-with-presentation $HOME/.config/waybar/scripts/vpn-select.sh",
      "signal": 8
    }
  }' "${config_file}" > "${config_file}.tmp"
  
  mv "${config_file}.tmp" "${config_file}"
  print_success "Added custom/vpn module definition"
}

update_waybar_styles() {
  print_info "Updating Waybar styles..."

  local style_file="${WAYBAR_CONFIG_DIR}/style.css"

  if [[ -f "${style_file}" ]]; then
    local backup_file="${style_file}.backup.$(date +%Y%m%d-%H%M%S)"
    cp "${style_file}" "${backup_file}"
    print_success "Backed up existing style to ${backup_file}"
    
    # Add #custom-vpn alongside #custom-omarchy
    if grep -q "#custom-vpn" "${style_file}"; then
      print_info "#custom-vpn already present in style.css"
    elif grep -q "#custom-omarchy" "${style_file}"; then
      sed -i 's/#custom-omarchy/#custom-omarchy,\n#custom-vpn/g' "${style_file}"
      print_success "Added #custom-vpn to style.css alongside #custom-omarchy"
    else
      print_warning "Could not find #custom-omarchy in style.css"
    fi
  else
    print_warning "style.css not found at ${style_file}"
  fi
}

configure_sudoers() {
  echo ""
  print_warning "Sudoers Configuration Required"
  echo ""
  print_info "To enable passwordless VPN toggling, wg-quick needs to be added to sudoers."
  print_warning "This allows running 'wg-quick' commands without entering your password."
  echo ""
  
  read -p "Would you like to configure sudoers now? (y/N) " -n 1 -r </dev/tty
  echo

  if [[ ${REPLY} =~ ^[Yy]$ ]]; then
    print_info "Adding sudoers rule..."
    
    local user_group
    if groups | grep -q wheel; then
      user_group="wheel"
    elif groups | grep -q sudo; then
      user_group="sudo"
    else
      print_error "Could not determine your sudo group (wheel or sudo)"
      user_group="wheel"
      print_warning "Defaulting to 'wheel' group. You may need to adjust this."
    fi
    
    local sudoers_line="%${user_group} ALL=(ALL) NOPASSWD: /usr/bin/wg-quick"
    local temp_sudoers
    temp_sudoers=$(mktemp)
    
    echo "${sudoers_line}" > "${temp_sudoers}"
    
    if sudo visudo -c -f "${temp_sudoers}" &>/dev/null; then
      echo "${sudoers_line}" | sudo tee /etc/sudoers.d/wireguard-vpn-toggle > /dev/null
      sudo chmod 440 /etc/sudoers.d/wireguard-vpn-toggle
      print_success "Sudoers rule added successfully"
    else
      print_error "Sudoers validation failed"
      rm "${temp_sudoers}"
      exit 1
    fi
    
    rm "${temp_sudoers}"
  else
    print_warning "Skipping sudoers configuration."
    print_info "You'll need to manually add this line to sudoers (using 'sudo visudo'):"
    echo "  %wheel ALL=(ALL) NOPASSWD: /usr/bin/wg-quick"
    echo ""
    print_warning "Without this, you'll be prompted for your password when toggling VPN."
  fi
}

show_completion_message() {
  echo ""
  print_success "Installation complete!"
  echo ""
  print_info "Next steps:"
  echo "  1. Restart Waybar (you'll be prompted next)"
  echo "  2. Add WireGuard configs to ${VPN_CONFIGS_PATH} (if needed)"
  echo "  3. Left-click the VPN icon to toggle connection"
  echo "  4. Right-click the VPN icon to select a different VPN config (0 to cancel)"
  echo ""
  print_info "For ProtonVPN setup, see: https://protonvpn.com/support/wireguard-linux"
  echo ""
}

restart_waybar() {
  echo ""
  read -p "Would you like to restart Waybar now? (Y/n) " -n 1 -r </dev/tty
  echo
  
  if [[ ${REPLY} =~ ^[Nn]$ ]]; then
    print_info "Skipping Waybar restart"
    print_info "Remember to restart Waybar manually: killall waybar && waybar &"
    return 0
  fi
  
  print_info "Restarting Waybar..."
  if pgrep -x waybar >/dev/null; then
    killall waybar
    sleep 0.5
  fi
  
  waybar &>/dev/null &
  print_success "Waybar restarted"
}

# Run main function
main "$@"
