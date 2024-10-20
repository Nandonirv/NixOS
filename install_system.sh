#!/bin/sh
#
echo "Your attached storage devices will now be listed."
read -p "Press enter to continue." NULL
clear

echo "Detected the following devices:"
echo
i=0
for device in $(sudo fdisk -l | grep "^Disk /dev" | awk "{print \$2}" | sed "s/://"); do
    echo "[$i] $device"
    i=$((i+1))
    DEVICES[$i]=$device
done
read -p "Which device do you wish to install on? " DEVICE
DEV=${DEVICES[$(($DEVICE+1))]}
echo
read -p "Partition ${DEV}? (y/n): " ANSWER

if [ "$ANSWER" = "y" ]; then
    echo "Partitioning ${DEV}..."
    printf "label: gpt\n,550M,U\n,,L\n" | sfdisk ${DEV}
else
    echo "Cancelled."
    exit
fi

i=1
for part in $(sudo fdisk -l | grep $DEV | grep -v "," | awk '{print $1}'); do
    echo "[$i] $part"
    i=$((i+1))
    PARTITIONS[$i]=$part
done

P1=${PARTITIONS[2]}
P2=${PARTITIONS[3]}

clear
read -p "Press enter to install NixOS." NULL

echo "making filesystem on ${P2}..."

sudo mkfs.ext4 -L nixos ${P2}

echo "making filesystem on ${P1}..."

sudo mkfs.fat -F 32 -n boot ${P1}            

echo "mounting filesystems..."

sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot                      
sudo mount /dev/disk/by-label/boot /mnt/boot

echo "installing NixOS..."

sudo nixos-install --flake github:Nandonirv/NixOS#officepc --no-write-lock-file

read -p "Remove installation media and press enter to reboot." NULL

reboot
