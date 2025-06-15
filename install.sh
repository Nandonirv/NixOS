#!/usr/bin/env bash

set -euo pipefail

# Function to list available disks
choose_disk() {
  echo "Available disks:"
  lsblk -d -n -o NAME,SIZE,MODEL | while read -r name size model; do
    echo " - /dev/$name: $size ($model)"
  done

  echo ""
  read -rp "Enter the disk to install NixOS on (e.g., sda): " disk_name
  echo "/dev/$disk_name"
}

# Select the disk
DISK=$(choose_disk)

# Confirm disk wipe
echo "WARNING: This will erase all data on $DISK!"
read -rp "Type 'YES' to continue: " confirm
if [[ "$confirm" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

# Hostname and flake configuration
HOSTNAME="nixos"
GITHUB_FLAKE="github:yourusername/yourflake"  # Replace with your GitHub flake

echo "Starting NixOS install on $DISK with flake $GITHUB_FLAKE..."

# Partitioning (UEFI + ext4)
parted --script "$DISK" \
  mklabel gpt \
  mkpart ESP fat32 1MiB 512MiB \
  set 1 boot on \
  mkpart primary ext4 512MiB 100%

# Wait for /dev nodes to settle
sleep 2

EFI_PART="${DISK}1"
ROOT_PART="${DISK}2"

# Format partitions with labels
echo "Formatting EFI partition as FAT32 with label 'boot'..."
mkfs.fat -F32 -n boot "$EFI_PART"

echo "Formatting root partition as ext4 with label 'nixos'..."
mkfs.ext4 -L nixos "$ROOT_PART"

# Mounting
echo "Mounting partitions..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot

# Ensure nix is installed
nix-env -iA nixpkgs.nix || true

# Install NixOS from flake
echo "Installing NixOS..."
nixos-install --flake "$GITHUB_FLAKE#$HOSTNAME" --no-root-password

echo "✅ Installation complete. You may now reboot."
