#!/bin/sh
#
# For installing NixOS having booted from the minimal USB image.
#
# To run:
#
#     sh -c "$(curl https://eipi.xyz/nixinst.sh)"

sudo fdisk -l | less
echo "Detected the following devices:"
echo

i=0
for device in $(sudo fdisk -l | grep "^Disk /dev" | awk "{print \$2}" | sed "s/://"); do
    echo "[$i] $device"
    i=$((i+1))
    DEVICES[$i]=$device
done

echo
read -p "Which device do you wish to install on? " DEVICE

DEV=${DEVICES[$(($DEVICE+1))]}

read -p "Will now partition ${DEV}. Ok? Type 'go': " ANSWER

if [ "$ANSWER" = "go" ]; then
    echo "partitioning ${DEV}..."
    (
      echo g # new gpt partition table

      echo n # new partition
      echo 2 # partition 2
      echo   # default start sector
      echo +512M # size is 512M

      echo n # new partition
      echo 1 # first partition
      echo   # default start sector
      echo   # last N GiB

      echo t # set type
      echo 1 # first partition
      echo 20 # Linux Filesystem

      echo t # set type
      echo 2 # first partition
      echo 1 # EFI System

      echo p # print layout

      echo w # write changes
    ) | sudo fdisk ${DEV}
else
    echo "cancelled."
    exit
fi

echo "checking partition alignment..."

function align_check() {
    (
      echo
      echo $1
    ) | sudo parted $DEV align-check | grep aligned | sed "s/^/partition /"
}

align_check 1
align_check 2

echo "getting created partition names..."

i=1
for part in $(sudo fdisk -l | grep $DEV | grep -v "," | awk '{print $1}'); do
    echo "[$i] $part"
    i=$((i+1))
    PARTITIONS[$i]=$part
done

P1=${PARTITIONS[2]}
P2=${PARTITIONS[3]}

echo "making filesystem on ${P1}..."

sudo mkfs.xfs -L nixos ${P1}

echo "making filesystem on ${P2}..."

sudo mkfs.fat -F 32 -n boot ${P2} 

echo "mounting filesystems..."

sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot                      
sudo mount /dev/disk/by-label/boot /mnt/boot
