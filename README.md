# Tiny Media Manager Installer

A bash script to install Tiny Media Manager on Linux systems. Installs to `/opt` and creates a start menu shortcut accessible by all users.

## Features

- Installs Tiny Media Manager to `/opt/tinyMediaManager`
- Creates desktop shortcut for all users
- Adds command-line access via `tinyMediaManager` and `tmm` commands
- Sets proper permissions for multi-user access
- Supports amd64/arm64 architecture

## Requirements

- curl
- tar with xz support
- Java 17 or later (will be detected and prompted if missing)
- sudo privileges

## Usage

1. Make the script executable:
   ```bash
   chmod +x install.sh
2. Then Execute
   ```bash
   sudo .install.sh