# Tiny Media Manager Installer

A bash script to install Tiny Media Manager on Linux systems. Installs to `/opt` and creates a start menu shortcut accessible by all users.

## Features

- Installs Tiny Media Manager to `/opt/tinyMediaManager`
- Creates desktop shortcut for all users
- Adds command-line access via `tinyMediaManager` and `tmm` commands
- Sets proper permissions for multi-user access
- Supports ARM64 architecture

## Requirements

- curl
- tar with xz support
- Java 17 or later (will be detected and prompted if missing)
- sudo privileges

## Usage

### Make the script executable:
   ```bash
   chmod +x install-tmm.sh 
   ```

### Run the script:
``` bash
sudo ./install-tmm.sh
```
Follow the prompts and enter your sudo password when required

### After Installation

    GUI: Find "Tiny Media Manager" in your application menu

    Terminal: Run tinyMediaManager or tmm

    All users on the system will have access

## Configuration

Each user gets their own configuration in:

    ~/.config/tinyMediaManager/

    ~/.local/share/tinyMediaManager/

## Support

If you encounter any issues:

    Ensure you have all dependencies installed

    Check that you have sufficient disk space

    Verify your internet connection for the download

## ☕ Buy Me a Coffee

If this script saved you time and you'd like to show your appreciation, you can buy me a coffee!

<a href="https://www.buymeacoffee.com/grimsbygeek" target="_blank">
  <img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-%230079FF.svg?style=for-the-badge&logo=buymeacoffee&logoColor=white" alt="Buy Me A Coffee" />
</a>

## License

This script is provided as-is under the MIT License. Feel free to modify and distribute.

## Disclaimer
This is an unofficial installation script. Tiny Media Manager is a trademark of its respective owners. This script simply automates the installation process for convenience.