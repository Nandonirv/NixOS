#!/usr/bin/env bash
set -euo pipefail

# Trap errors for graceful debugging
trap 'echo "Error on line $LINENO"; exit 1' ERR

# Function to list and choose available disks
choose_disk() {
  echo "Available disks:"
  mapfile -t DEVICES < <(lsblk -ndpo NAME,TYPE | awk '$2=="disk" {print $1}')

  for i in "${!DEVICES[@]}"; do
    echo "[$i] ${DEVICES[i]}"
  done

  echo ""
  read -rp "Select disk by number (e.g., 0): " index
  if ! [[ "$index" =~ ^[0-9]+$ ]] || (( index < 0 || index >= ${#DEVICES[@]} )); then
    echo "Invalid selection."
    exit 1
  fi

  echo "${DEVICES[index]}"
}

# Select target disk
DISK=$(choose_disk)

# Confirm destructive operation
echo -e "\n⚠️  WARNING: This will erase ALL data on $DISK!"
read -rp "Type 'YES' to continue: " confirm
if [[ "$confirm" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

# Define hostname and flake URL
HOSTNAME="nixos"
USER_FLAKE="https://api.mynixos.com/elcarom/nixos/archive/main.tar.gz"

# Partition disk using GPT and create EFI/ext4 layout
echo "Partitioning $DISK..."
parted --script "$DISK" \
  mklabel gpt \
  mkpart ESP fat32 1MiB 512MiB \
  set 1 esp on \
  mkpart primary ext4 512MiB 100%

sleep 2  # Wait for partitions to settle

EFI_PART="${DISK}1"
ROOT_PART="${DISK}2"

# Format partitions
echo "Formatting partitions..."
mkfs.fat -F32 -n BOOT "$EFI_PART"
mkfs.ext4 -L nixos "$ROOT_PART"

# Mount
echo "Mounting filesystems..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot

# Ensure Nix is available
if ! command -v nix >/dev/null; then
  echo "Nix not found. Installing temporarily..."
  curl -L https://nixos.org/nix/install | sh
  . ~/.nix-profile/etc/profile.d/nix.sh
fi

# Install NixOS with flake
echo "Installing NixOS from flake..."
nixos-install --flake "$USER_FLAKE#$HOSTNAME" --no-root-password --option tarball-ttl 0

echo "Installation complete. You may now reboot!"
