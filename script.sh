#!/bin/bash

set -e

sudo apt install bc bison flex libssl-dev make libc6-dev libncurses5-dev

rm -rf *.log

WORKDIR=$(pwd)

rm -rf $WORKDIR/linux

clone_repo() {

    if [ -d "$WORKDIR/res/linux.clone" ]; then
        echo "> Linux kernel source backup exists. Skipping clone."
        cp -r $WORKDIR/res/linux.clone $WORKDIR/linux
        return
    else
        git clone https://github.com/raspberrypi/linux
        cd linux
        git checkout -b rpi_mptcp origin/rpi-5.4.y
        git remote add mptcp https://github.com/multipath-tcp/mptcp
        git fetch mptcp

        mkdir -p $WORKDIR/res
        cp -r $WORKDIR/linux $WORKDIR/res/linux.clone
    fi
}

# Check if $WORKDIR/res/linux.merged.backup exists
if [ -d "$WORKDIR/res/linux.merged.backup" ]; then
    echo "> Linux kernel source merged backup exists. Skipping clone."
    cp -r $WORKDIR/res/linux.merged.backup $WORKDIR/linux
    cd linux
elif [ -d "$WORKDIR/res/linux" ]; then
    echo "> Linux kernel source exists. Skipping clone."
    cp -r $WORKDIR/res/linux $WORKDIR/linux
    cd linux
else
    echo "> Linux kernel source merged backup does not exist. Cloning..."

    clone_repo

    cd $WORKDIR/linux

    # Check if the branch already exists
    git branch

    printf "Starting MPTCP merge...\n"

    git diff --name-only mptcp/mptcp_trunk > ../diff_files.log

    git merge mptcp/mptcp_trunk --allow-unrelated-histories | tee ../merge.log

    # Copy files to resolve merge conflicts
    # printf "Manual merge required.\n"
    # printf "Don't worry, there are only a few conflicts, and you just need to accept the changes from 'mptcp_trunk'.\n"
    # printf "Once the merge is complete, run the following command to continue:\n"

    printf "\t > Copying files to resolve merge conflicts...\n"
    cp -r $WORKDIR/res/sock.c $WORKDIR/linux/net/core/sock.c
    cp -r $WORKDIR/res/syncookies_4.c $WORKDIR/linux/net/ipv4/syncookies.c
    cp -r $WORKDIR/res/tcp_input.c $WORKDIR/linux/net/ipv4/tcp_input.c
    cp -r $WORKDIR/res/tcp_output.c $WORKDIR/linux/net/ipv4/tcp_output.c
    cp -r $WORKDIR/res/tcp.c $WORKDIR/linux/net/ipv4/tcp.c
    cp -r $WORKDIR/res/syncookies_6.c $WORKDIR/linux/net/ipv6/syncookies.c

    printf "> MPTCP merge completed.\n"

    # remove git configurations from $WORKDIR/linux

    cp -r "$WORKDIR/linux" "$WORKDIR/res/linux.merged.backup"

    #rm -rf $WORKDIR/res/linux.clone
    # zip the linux directory
    # zip -r $WORKDIR/res/linux.zip $WORKDIR/linux
fi


# Check if the merge was successful
KERNEL=kernel8
make mrproper | tee ../make0.log
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig 2>&1 | tee ../make1.log
#make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- nconfig | tee ../make2.log

cp .config .config.old
sed -i  's/CONFIG_IPV6=m/CONFIG_IPV6=y/g' .config
INSLINE=$(grep -rnw '.config' -e 'CONFIG_TCP_CONG_BBR=m' | cut -d: -f 1)
sed -i  "$(expr $INSLINE + 1)iCONFIG_TCP_CONG_LIA=y" .config
sed -i  "$(expr $INSLINE + 2)iCONFIG_TCP_CONG_OLIA=y" .config
sed -i  "$(expr $INSLINE + 3)iCONFIG_TCP_CONG_WVEGAS=y" .config
sed -i  "$(expr $INSLINE + 4)iCONFIG_TCP_CONG_BALIA=y" .config
sed -i  "$(expr $INSLINE + 5)iCONFIG_TCP_CONG_MCTCPDESYNC=y" .config
INSLINE=$(grep -rnw '.config' -e 'CONFIG_DEFAULT_CUBIC=y' | cut -d: -f 1)
sed -i  "$(expr $INSLINE + 1)i# CONFIG_DEFAULT_LIA is not set" .config
sed -i  "$(expr $INSLINE + 2)i# CONFIG_DEFAULT_OLIA is not set" .config
sed -i  "$(expr $INSLINE + 3)i# CONFIG_DEFAULT_WVEGAS is not set" .config
sed -i  "$(expr $INSLINE + 4)i# CONFIG_DEFAULT_BALIA is not set" .config
sed -i  "$(expr $INSLINE + 5)i# CONFIG_DEFAULT_MCTCPDESYNC is not set" .config
INSLINE=$(grep -rnw '.config' -e '# CONFIG_IPV6_SEG6_HMAC is not set' | cut -d: -f 1)
sed -i  "$(expr $INSLINE + 1)iCONFIG_MPTCP=y" .config
sed -i  "$(expr $INSLINE + 2)iCONFIG_MPTCP_PM_ADVANCED=y" .config
sed -i  "$(expr $INSLINE + 3)iCONFIG_MPTCP_FULLMESH=y" .config
sed -i  "$(expr $INSLINE + 4)iCONFIG_MPTCP_NDIFFPORTS=y" .config
sed -i  "$(expr $INSLINE + 5)iCONFIG_MPTCP_BINDER=y" .config
sed -i  "$(expr $INSLINE + 6)iCONFIG_MPTCP_NETLINK=y" .config
sed -i  "$(expr $INSLINE + 7)iCONFIG_DEFAULT_FULLMESH=y" .config
sed -i  "$(expr $INSLINE + 8)i# CONFIG_DEFAULT_NDIFFPORTS is not set" .config
sed -i  "$(expr $INSLINE + 9)i# CONFIG_DEFAULT_BINDER is not set" .config
sed -i  "$(expr $INSLINE + 10)i# CONFIG_DEFAULT_NETLINK is not set" .config
sed -i  "$(expr $INSLINE + 11)i# CONFIG_DEFAULT_DUMMY is not set" .config
sed -i  "$(expr $INSLINE + 12)iCONFIG_DEFAULT_MPTCP_PM=\"fullmesh\"" .config
sed -i  "$(expr $INSLINE + 13)iCONFIG_MPTCP_SCHED_ADVANCED=y" .config
sed -i  "$(expr $INSLINE + 14)iCONFIG_MPTCP_BLEST=y" .config
sed -i  "$(expr $INSLINE + 15)iCONFIG_MPTCP_ROUNDROBIN=y" .config
sed -i  "$(expr $INSLINE + 16)iCONFIG_MPTCP_REDUNDANT=y" .config
sed -i  "$(expr $INSLINE + 17)iCONFIG_DEFAULT_SCHEDULER=y" .config
sed -i  "$(expr $INSLINE + 18)i# CONFIG_DEFAULT_ROUNDROBIN is not set" .config
sed -i  "$(expr $INSLINE + 19)i# CONFIG_DEFAULT_REDUNDANT is not set" .config
sed -i  "$(expr $INSLINE + 20)iCONFIG_DEFAULT_MPTCP_SCHED=\"default\"" .config

# modify the CONFIG_LOCALVERSION to "-rpi_mptcp", regardless of its current value
sed -i 's/CONFIG_LOCALVERSION=".*"/CONFIG_LOCALVERSION="-rpi_mptcp"/g' .config

make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j "$(nproc)" Image 2>&1 | tee ../make_image.log
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j "$(nproc)" modules 2>&1 | tee ../make_modules.log
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j "$(nproc)" dtbs 2>&1 | tee ../make_dtbs.log

# remove git configurations from $WORKDIR/linux
rm -rf $WORKDIR/linux/.git
rm -rf $WORKDIR/linux/.gitignore
rm -rf $WORKDIR/linux/.gitattributes
rm -rf $WORKDIR/linux/.mailmap
rm -rf $WORKDIR/linux/.github
rm -rf $WORKDIR/linux/.gitmodules
rm -rf $WORKDIR/linux/.gitlab-ci.yml

cd $WORKDIR

# zip -r "raspy4_mptcp_arm64-aarch64-linux-gnu-tar.gz" "linux"

tar -czvf raspy4_mptcp_arm64-aarch64-linux-gnu-tar.gz linux/

exit 0
cd "$WORKDIR/linux"

mkdir mnt
mkdir mnt/boot
mkdir mnt/root
sudo mount /dev/sda1 mnt/boot/
sudo mount /dev/sda2 mnt/root/
sudo env PATH=$PATH make -j "$(nproc)" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=mnt/root modules_install 2>&1 | tee ../make_install.log

printf "\n> Copying kernel modules to the root filesystem...\n"
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