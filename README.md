# WireGuard VPN Toggle for Omarchy's Waybar

A clean, automated installer for adding a WireGuard VPN toggle to Omarchy's Waybar status bar. Provides a convenient visual indicator and quick toggle for your WireGuard VPN connections.

Based on the guide from [Omarchy Discussion #1366](https://github.com/basecamp/omarchy/discussions/1366).

## Features

- 🔒 **One-click VPN toggle** - Left-click to connect/disconnect
- 🎨 **Visual status indicator** - Integrates with Omarchy's icon theming
- 🔄 **Profile switching** - Right-click menu to switch between VPN configs
- ⚡ **Passwordless operation** - Optional sudoers configuration
- 🛡️ **The Omarchy way** - All scripts follow Omarchy bash practices with proper error handling
- 📦 **Automated installation** - Simple installer handles everything for Omarchy setups

## Prerequisites

**⚠️ This tool is designed specifically for [Omarchy](https://github.com/basecamp/omarchy) setups only.**

- **Omarchy** - This VPN toggle is designed to integrate with Omarchy's Waybar configuration
- **Bash** 4.0+
- **WireGuard** (`wireguard-tools`)
- **jq** (JSON processor for safe config manipulation)
- **WireGuard configuration files** in `/etc/wireguard/`

### Install Dependencies

Since Omarchy is designed for Arch Linux:

```bash
sudo pacman -S wireguard-tools waybar jq
```

## Installation

### Quick Install (One-Liner)

Install directly from GitHub with a single command:

**Using curl:**
```bash
curl -fsSL https://raw.githubusercontent.com/JacobusXIII/omarchy-wireguard-vpn-toggle/main/install.sh | bash
```

**Using wget:**
```bash
wget -qO- https://raw.githubusercontent.com/JacobusXIII/omarchy-wireguard-vpn-toggle/main/install.sh | bash
```

This will:
- Automatically detect one-liner mode
- Download the repository to /tmp
- Run the full installation with interactive prompts
- Clean up temporary files when done
- Ask for sudoers configuration (optional passwordless toggling)

**Note:** You'll need WireGuard configuration files before the VPN toggle will work (see step 2 below).

---

### Manual Installation

#### 1. Clone the Repository

```bash
git clone https://github.com/JacobusXIII/omarchy-wireguard-vpn-toggle.git
cd omarchy-wireguard-vpn-toggle
```

#### 2. Set Up WireGuard Configuration

If you haven't already, you need WireGuard configuration files in `/etc/wireguard/`.

**For ProtonVPN users:**

1. Visit the [ProtonVPN downloads page](https://account.protonvpn.com/downloads)
2. Download WireGuard configuration files
3. Copy them to `/etc/wireguard/`:
   ```bash
   sudo cp your-config.conf /etc/wireguard/
   ```
4. Set proper permissions (600 or stricter):
   ```bash
   sudo chmod 600 /etc/wireguard/*.conf
   ```

See the [ProtonVPN WireGuard guide](https://protonvpn.com/support/wireguard-linux) for detailed instructions.

**For other VPN providers:**

Most VPN providers offer WireGuard configuration files. Download them and place in `/etc/wireguard/`, then ensure they have proper permissions (600 or stricter) with `sudo chmod 600 /etc/wireguard/*.conf`.

#### 3. Run the Installer

```bash
./install.sh
```

The installer will:
- ✅ Check for required dependencies
- ✅ Verify WireGuard configurations exist
- ✅ Install scripts to `~/.config/waybar/scripts/`
- ✅ Add `custom/vpn` module to Omarchy's Waybar config (after network module)
- ✅ Add `#custom-vpn` to style.css alongside `#custom-omarchy`
- ✅ Optionally configure sudoers for passwordless operation

#### 4. Restart Waybar

```bash
killall waybar && waybar &
```

Or restart your compositor.

## Usage

### Toggle VPN Connection

**Left-click** on the VPN icon in Omarchy's Waybar to connect or disconnect.

### Switch VPN Profile

**Right-click** on the VPN icon to open an interactive menu where you can select a different WireGuard configuration.

### Manual Control

You can also use the scripts directly from the command line:

```bash
# Toggle VPN on/off
~/.config/waybar/scripts/vpn-toggle.sh

# Check current status
~/.config/waybar/scripts/vpn-status.sh

# Select VPN profile
~/.config/waybar/scripts/vpn-select.sh
```

## Customization

### Styling

The installer automatically adds `#custom-vpn` to your `style.css` alongside other icons:

```css
#custom-omarchy,
#custom-vpn {
  /* Your existing Omarchy icon styles */
}
```

By default, the VPN icon inherits the same styling as your other custom modules (colors, spacing, etc.). You can customize this by:

- **Keeping it grouped** with other icons to inherit their styles
- **Separating it** to apply custom styles only to the VPN icon:
  ```css
  #custom-vpn {
    color: #your-color;
    /* Your custom styles */
  }
  ```

### Change Icons

The VPN icons can be changed by editing your Omarchy Waybar config's `format-icons`:

```json
"format-icons": {
  "default": "",    // Default/fallback icon (blank)
  "none": "󰻌",       // No config
  "connected": "󰦝",   // VPN connected
  "disconnected": "󰦞" // VPN disconnected
}
```

Replace the Nerd Font icons with your preferred icons or emoji.

## Project Structure

```
omarchy-wireguard-vpn-toggle/
├── scripts/              # VPN toggle scripts
│   ├── vpn-status.sh    # Checks VPN connection status
│   ├── vpn-toggle.sh    # Toggles VPN on/off
│   └── vpn-select.sh    # Interactive VPN profile selector
├── install.sh           # Main installer script
├── LICENSE              # MIT License
├── README.md            # This file
└── .gitignore
```

### Installed Files

The installer creates/modifies these files:

**In `~/.config/waybar/scripts/`:**
- `vpn-status.sh` - Checks VPN connection status (returns JSON with icon state)
- `vpn-toggle.sh` - Toggles VPN on/off
- `vpn-select.sh` - Interactive VPN profile selector
- `vpn.conf` - Stores currently selected VPN configuration

**In `~/.config/waybar/`:**
- `config.jsonc` or `config` - Waybar config (adds custom/vpn module with format-icons)
- `style.css` - Waybar styles (adds #custom-vpn alongside #custom-omarchy)
- `*.backup.YYYYMMDD-HHMMSS` - Timestamped backups of modified files

## Troubleshooting

### Password Prompt When Toggling

If you're prompted for a password when toggling VPN:

1. Run the installer again and choose to configure sudoers
2. Or manually add this line using `sudo visudo`:
   ```
   %wheel ALL=(ALL) NOPASSWD: /usr/bin/wg-quick
   ```

### VPN Icon Not Appearing

1. **Check Waybar config is valid JSON:**
   ```bash
   cat ~/.config/waybar/config.jsonc | jq
   ```

2. **Ensure scripts are executable:**
   ```bash
   chmod +x ~/.config/waybar/scripts/vpn-*.sh
   ```

3. **Check Waybar logs:**
   ```bash
   journalctl --user -u waybar -f
   ```

4. **Verify scripts exist:**
   ```bash
   ls -lh ~/.config/waybar/scripts/vpn-*.sh
   ```

### "No WireGuard configurations found"

Ensure you have `.conf` files in `/etc/wireguard/`:

```bash
ls -lh /etc/wireguard/
```

If empty, download configuration files from your VPN provider.

### Connection Fails

Test manually to identify the issue:

```bash
# Try connecting manually
sudo wg-quick up your-config-name

# Check status
sudo wg show

# Try disconnecting
sudo wg-quick down your-config-name
```

Check for errors in the output.

### Script Syntax Errors

All scripts follow strict bash practices. If you modify them, validate syntax:

```bash
bash -n ~/.config/waybar/scripts/vpn-status.sh
bash -n ~/.config/waybar/scripts/vpn-toggle.sh
bash -n ~/.config/waybar/scripts/vpn-select.sh
```

## Security Considerations

### Sudoers Configuration

The sudoers configuration allows running `wg-quick` without a password. This is limited to:
- Only the `/usr/bin/wg-quick` binary
- Only for users in the `wheel`/`sudo` group

This is generally safe, but be aware that anyone with access to your user account can control VPN connections without additional authentication.

If this is a concern in your environment, you can skip the sudoers setup and enter your password each time you toggle the VPN.

### Configuration File Permissions

WireGuard configuration files in `/etc/wireguard/` typically contain private keys. Ensure they have proper permissions:

```bash
sudo chmod 600 /etc/wireguard/*.conf
sudo chown root:root /etc/wireguard/*.conf
```

## Uninstallation

To remove the VPN toggle:

1. **Remove the scripts:**
   ```bash
   rm -rf ~/.config/waybar/scripts
   ```

2. **Remove from Waybar config:**
   - Delete `"custom/vpn"` from `modules-right` array
   - Delete the `"custom/vpn"` configuration block
   - (Or restore from timestamped backup: `~/.config/waybar/config.jsonc.backup.YYYYMMDD-HHMMSS`)

3. **Remove from `~/.config/waybar/style.css`:**
   - Remove `#custom-vpn,` from the line with `#custom-omarchy`
   - (Or restore from timestamped backup: `~/.config/waybar/style.css.backup.YYYYMMDD-HHMMSS`)

4. **Remove sudoers rule:**
   ```bash
   sudo rm /etc/sudoers.d/wireguard-vpn-toggle
   ```

5. **Restart Waybar:**
   ```bash
   killall waybar && waybar &
   ```

## Development

### Code Style

All bash scripts follow the Omarchy way - bash practices observed in the [Omarchy](https://github.com/basecamp/omarchy) repository:

- Shebang and strict mode: `#!/bin/bash` with `set -eEo pipefail`
- Error handling: `trap catch_errors ERR INT TERM; trap exit_handler EXIT`
- Function definitions: `name() { ... }` (no `function` keyword)
- Use `local` for function-scoped variables
- `[[ ... ]]` for conditions
- Quoted variable expansions: `"${VAR}"`
- Command availability: `command -v tool &>/dev/null`
- 2-space indentation
- UPPER_SNAKE_CASE for globals, lower_snake_case for locals

### Testing

Validate syntax of all scripts:

```bash
bash -n install.sh
for script in scripts/*.sh; do bash -n "$script"; done
```

## Credits

Based on the manual setup guide by [@rulonder](https://github.com/rulonder) in [Omarchy Discussion #1366](https://github.com/basecamp/omarchy/discussions/1366).

This project was built with a little help from [Cursor AI](https://cursor.com) - a great way to enforce Omarchy bash practices, maintain code consistency, and write comprehensive documentation. 🤖

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to:
- Report bugs by opening an issue
- Suggest features or improvements
- Submit pull requests

When contributing code, please follow the existing bash style guide.

## Related Projects

- [Omarchy](https://github.com/basecamp/omarchy) - Configuration framework this is designed for
- [Waybar](https://github.com/Alexays/Waybar) - Highly customizable Wayland bar
- [WireGuard](https://www.wireguard.com/) - Fast, modern VPN protocol
- [ProtonVPN](https://protonvpn.com/) - Privacy-focused VPN service

---

**Enjoy your new VPN toggle!** 🔒✨

