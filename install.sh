#!/usr/bin/env bash
set -euo pipefail

trap 'echo "Error on line $LINENO"; exit 1' ERR

DISK=""

choose_disk() {
  echo ""
  echo "Available disks:"
  mapfile -t DEVICES < <(lsblk -ndpo NAME,TYPE | awk '$2 == "disk" {print $1}')

  for i in "${!DEVICES[@]}"; do
    echo "[$i] ${DEVICES[i]}"
  done

  echo ""
  read -rp "Select disk by number (e.g., 0): " index
  if ! [[ "$index" =~ ^[0-9]+$ ]] || (( index < 0 || index >= ${#DEVICES[@]} )); then
    echo "Invalid selection."
    exit 1
  fi

  DISK="${DEVICES[index]}"
}

choose_disk

echo ""
echo "WARNING: This will erase ALL data on $DISK!"
read -rp "Type 'YES' to continue: " confirm
if [[ "$confirm" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

HOSTNAME="nixos"
USER_FLAKE="https://api.mynixos.com/elcarom/nixos/archive/main.tar.gz"

echo ""
echo "Partitioning $DISK..."
parted --script "$DISK" \
  mklabel gpt \
  mkpart ESP fat32 1MiB 512MiB \
  set 1 esp on \
  mkpart primary ext4 512MiB 100%

sleep 2

EFI_PART="${DISK}1"
ROOT_PART="${DISK}2"

echo ""
echo "Formatting partitions..."
mkfs.fat -F32 -n boot "$EFI_PART"
mkfs.ext4 -L nixos "$ROOT_PART"

echo ""
echo "Mounting filesystems..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot

if ! command -v nix >/dev/null; then
  echo ""
  echo "Nix not found. Installing temporarily..."
  curl -L https://nixos.org/nix/install | sh
  . ~/.nix-profile/etc/profile.d/nix.sh
fi

echo ""
echo "Installing NixOS from flake..."
nixos-install --flake "$USER_FLAKE#$HOSTNAME" --no-root-password --option tarball-ttl 0

echo ""
echo "Installation complete. You may now reboot."
