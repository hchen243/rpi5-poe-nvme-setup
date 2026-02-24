#!/usr/bin/env bash
set -euo pipefail

LOG=/var/log/pi-bootstrap.log
exec > >(tee -a "$LOG") 2>&1

# ===== CONFIG CHECK FUNCTIONS =====
check_eeprom_setting() {
  local key="$1"
  local expected="$2"

  # Get current value for given key from rpi-eeprom-config
  local current
  current="$(sudo rpi-eeprom-config | awk -F= -v k="$key" '
    $1 ~ "^"k"$" {
      gsub(/^[ \t]+|[ \t]+$/, "", $2);
      print $2
    }')"

  if [[ -z "${current:-}" ]]; then
    echo "⚠️  EEPROM: Key '$key' not found"
    return 1
  fi

  if [[ "$current" == "$expected" ]]; then
    echo "✅ EEPROM: $key is set correctly to $expected"
    return 0
  else
    echo "❌ EEPROM: $key is '$current' (expected '$expected')"
    return 2
  fi
}

check_psu_max_current() {
  # For PoE+ HAT + Pi 5 you want 5000 mA max current
  check_eeprom_setting "PSU_MAX_CURRENT" "5000"
}

check_pcie_speed() {
  # Example: expect PCIe Gen 3 (PCIE_SPEED=3). Adjust if your EEPROM uses a different key or value.
  check_eeprom_setting "PCIE_SPEED" "3"
}


check_boot_order() {
  # TODO: Update this expected value to match your desired NVMe‑first boot order.
  # Check on a known-good system with:
  #   sudo rpi-eeprom-config | grep BOOT_ORDER
  local expected="0x16"
  check_eeprom_setting "BOOT_ORDER" "$expected"
}

check_pi_firmware_config() {
  echo "===== Checking Raspberry Pi EEPROM configuration ====="
  local failures=0

  echo "--- PSU max current ---"
  if ! check_psu_max_current; then
    ((failures++))
  fi

  echo "--- PCIe speed ---"
  if ! check_pcie_speed; then
    ((failures++))
  fi

  echo "--- Boot order ---"
  if ! check_boot_order; then
    ((failures++))
  fi

  if (( failures == 0 )); then
    echo "✅ All EEPROM checks passed."
  else
    echo "❌ $failures EEPROM check(s) reported problems."
  fi

  return $failures
}
``

# ===== MAIN SCRIPT =====
HOSTNAME="$(hostname)"

echo "===================================================="
echo "Bootstrap starting on host: $HOSTNAME"
echo "Log file: $LOG"
echo "===================================================="

# Soft-warning EEPROM checks
# Run EEPROM checks but NEVER abort; just warn loudly.
if [[ "$HOSTNAME" == "Pi5-Prod" ]]; then
  echo "Detected production host (Pi5-Prod) – running EEPROM checks (soft warnings only)."
  if ! check_pi_firmware_config; then
    echo "⚠️  WARNING: One or more EEPROM checks failed on Pi5-Prod."
    echo "    Please review the output above and fix EEPROM settings if needed."
  else
    echo "✅ EEPROM configuration looks good on Pi5-Prod."
  fi
else
  echo "Non-production host ($HOSTNAME) – running EEPROM checks for information only."
  if ! check_pi_firmware_config; then
    echo "⚠️  WARNING: EEPROM checks failed on $HOSTNAME (Dev/test)."
  else
    echo "✅ EEPROM configuration checks passed on $HOSTNAME."
  fi
fi

echo "===== Continuing with package installation and setup... ====="

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

echo "===================================================="
echo "All bootstrap steps finished on host: $HOSTNAME"
printf "Bootstrap complete. Rebooting now in 5 seconds...\n"
sleep 5
sudo reboot