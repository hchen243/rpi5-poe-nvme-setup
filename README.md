# rpi5-poe-nvme-setup
Automated setup / rebuild scripts for Raspberry Pi 5 with 52Pi EP-0241 PoE+ HAT and NVMe SSD

# Raspberry Pi 5 PoE+ NVMe Setup

This repository stores the automated setup / rebuild script for a Raspberry Pi 5 with a 52Pi EP-0241 PoE+ HAT and NVMe SSD.

## Repository contents

- `bootstrap.sh` – main environment bootstrap script to run on a fresh OS install.

## Quick usage

On a freshly installed Raspberry Pi OS (booting from NVMe, powered via PoE+):

```bash
curl -sS https://raw.githubusercontent.com/hchen243/rpi5-poe-nvme-setup/main/bootstrap.sh | bash
