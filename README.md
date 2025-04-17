# MPTCP on Raspberry Pi 4B? Yes, it's possible.

> [!NOTE]  
> These scripts follow the [Raspberry Pi Cross-compile Documentation](https://www.raspberrypi.com/documentation/computers/linux_kernel.html#cross-compile-the-kernel).


First of all, you will need to clone this repo:

```sh
git clone https://github.com/tiagojoseas/raspberry-mptcp
```

> [!IMPORTANT]  
> This script will mount the Linux system onto an SD card with **16GB or more**. Ensure you have one inserted and detectable on your machine.  
> You can verify this using the `lsblk` command to check for `sdX` devices. For example:

```sh
sda          29.1G                 
├─sda1        256M vfat     boot   /media/<...>
└─sda2       28.9G ext4     rootfs /media/<...>
```

After identifying your SD card, modify the `script.sh` and/or `boot.sh` files to specify the correct devices for mounting your system:

```sh
sudo mount /dev/sd<FAT> mnt/boot/
sudo mount /dev/sd<EXT4> mnt/root/

# Example:
# sudo mount /dev/sda1 mnt/boot/
# sudo mount /dev/sda2 mnt/root/
```

After changing the devices, you can use any of the methods below:



## **Method 1:** Unzip and Boot

Simply run the `boot.sh` script.

## **Method 2:** Rebuild from Scratch

This method provides more control over the versions you want to install.  

Note: Merge conflicts for the versions used in the script (`rpi-5.4.y` and `mptcp_trunk`) are resolved automatically during the build process—I've already handled that headache for you 😅. However, if you change the versions, you may encounter different merge conflicts.

During the script execution, you'll be prompted to configure some MPTCP options. Accept all defaults:

```
MPTCP: advanced scheduler control (MPTCP_SCHED_ADVANCED) [Y/n/?] y
  MPTCP BLEST (MPTCP_BLEST) [Y/n/m/?] y
  MPTCP Round-Robin (MPTCP_ROUNDROBIN) [Y/n/m/?] y
  MPTCP Redundant (MPTCP_REDUNDANT) [Y/n/m/?] y
  MPTCP ECF (MPTCP_ECF) [N/m/y/?] (NEW) 
```


Now, just wait... Eventually, you'll see a message like this:

```sh
You are ready to go :)
```

At this point, you can remove the SD card, boot your Raspberry Pi 4B, and enjoy using MPTCP.

## What you need to do in your Rapsberry 4B?

```
sudo apt update
sudo apt install bc bison flex libssl-dev make libc6-dev libncurses5-dev -y

cd /usr/src
sudo wget https://github.com/tiagojoseas/raspberry-mptcp/releases/download/v1.0/raspy4_mptcp_arm64-aarch64-linux-gnu-tar.gz
sudo tar -xvf raspy4_mptcp_arm64-aarch64-linux-gnu-tar.gz 
sudo ln -s -f /usr/src/linux/ /lib/modules/5.4.83-rpi_mptcp+/build 
cd /lib/modules/5.4.83-rpi_mptcp+/build 

make modules_prepare
make oldconfig && make prepare
```