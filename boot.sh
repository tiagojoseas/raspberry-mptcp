#!/bin/bash

set -e

rm -rf *.log

WORKDIR=$(pwd) 
KERNEL=kernel8

VERSION=$(cat "$WORKDIR"/version)

printf "> Raspberry Pi MPTCP kernel version: $VERSION\n"

FILE_GZ=raspy4_mptcp_arm64-aarch64-linux-gnu-tar.gz

if [ -f "$WORKDIR/$FILE_GZ" ]; then
    printf "\n> File $FILE_GZ already exists. Skipping download.\n"
else
    printf "\n> Downloading $FILE_GZ...\n"
    LINK=https://github.com/tiagojoseas/raspberry-mptcp/releases/download/$VERSION/$FILE_GZ
    sudo wget $LINK
fi

rm -rf $WORKDIR/linux

printf "\n> Extracting $FILE_GZ...\n"
tar -xvf $FILE_GZ

cd "$WORKDIR/linux"

printf "\n> Mounting SD Card\n"
mkdir mnt
mkdir mnt/boot
mkdir mnt/root

sudo mount /dev/sda1 mnt/boot/
sudo mount /dev/sda2 mnt/root/

printf "\n> Compiling kernel modules to the root filesystem...\n"
sudo env PATH=$PATH make -j "$(nproc)" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=mnt/root modules_install 2>&1 | tee ../make_install.log

printf "\n> Copying kernel modules to the boot filesystem...\n"
sudo cp mnt/boot/$KERNEL.img mnt/boot/$KERNEL-backup.img
sudo cp arch/arm64/boot/Image mnt/boot/$KERNEL.img
sudo cp arch/arm64/boot/dts/broadcom/*.dtb mnt/boot/
sudo cp arch/arm64/boot/dts/overlays/*.dtb* mnt/boot/overlays/
sudo cp arch/arm64/boot/dts/overlays/README mnt/boot/overlays/

printf "\n> Kernel modules copied to the root filesystem.\n"

sudo umount mnt/boot
sudo umount mnt/root

printf "\n> Kernel modules unmounted.\n"
printf "\n> You are ready to go :)\n"

exit 0
