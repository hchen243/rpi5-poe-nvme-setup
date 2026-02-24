#!/usr/bin/env bash
set -euo pipefail

LOG=/var/log/pi-bootstrap.log
exec > >(tee -a "$LOG") 2>&1

# 1. Update and upgrade the system
sudo apt update
sudo apt full-upgrade -y

# 2. Install base packages
sudo apt install -y git vim htop curl wget python3-pip

# 3. Clone your configuration repository (if not already present)
CONFIG_DIR="$HOME/pi-setup" # Change this to your desired config directory
if [ ! -d "$CONFIG_DIR" ]; then
  git clone https://github.com/hchen243/rpi5-poe-nvme-setup.git "$CONFIG_DIR"
fi

# 4. Apply system configuration (examples – customize for your setup)
# sudo cp "$CONFIG_DIR/etc/your-service.service" /etc/systemd/system/
# sudo systemctl enable your-service.service
# sudo systemctl start your-service.service

# 5. Restore user-level configuration
# cp -r "$CONFIG_DIR/home/.config" "$HOME/"
# cp "$CONFIG_DIR/home/.bashrc" "$HOME/"

# 6. Install and configure additional tools (for example Docker)
# curl -fsSL https://get.docker.com | sh
# sudo usermod -aG docker $USER

# 7. Final reboot to ensure all services start correctly
sudo reboot