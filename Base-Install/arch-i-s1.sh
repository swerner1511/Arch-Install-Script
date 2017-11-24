#!/bin/bash

# Created by S. W.
# latest update 22.11.2017
#
# A script for archlinux to prepare the hard disk, 
# install 'base base-devel wpa_supplicant dialog' and etc.

# Loading default keymap for Arch live system
loadkeys de-latin1-nodeadkeys

##1# Preparing the hard disk
echo "###########################"
echo "# Preparing the hard disk #"
echo "###########################"
echo "#"
echo "#Creating the partition layout..."
parted --script /dev/sda \
    mklabel msdos \
    mkpart primary 1MB 513MB \
    set 1 boot on \
    mkpart primary 513MB 100% \
    quit

# Preparing the encrypted system partitions
echo "#"
echo "#Creating of the LUKS device.."
cryptsetup -v --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 10000 --use-urandom --verify-passphrase luksFormat /dev/sda2
echo "#"
echo "Opening encrypted device..."
cryptsetup luksOpen /dev/sda2 crypt0
echo "#"
echo "#Creating partitions within the Luks device using LVM..."
pvcreate /dev/mapper/crypt0
vgcreate vg0 /dev/mapper/crypt0
lvcreate -L 1GiB -n SWAP vg0
lvcreate -L 50GiB -n ROOT vg0
lvcreate -l 100%FREE -n HOME vg0
echo "#"
echo "#Formatting the partitions..."
mkfs.ext2 -L BOOT /dev/sda1
mkfs.ext4 -L ROOT /dev/mapper/vg0-ROOT
mkfs.ext4 -L HOME /dev/mapper/vg0-HOME
mkswap -L SWAP /dev/mapper/vg0-SWAP
echo "#"
echo "#Mount partitions..."
mount -t ext4 /dev/mapper/vg0-root /mnt
mkdir /mnt/boot && mount -t ext2 /dev/sda1 /mnt/boot
mkdir /mnt/home && mount -t ext4 /dev/mapper/vg0-HOME /mnt/home
swapon /dev/mapper/vg0-SWAP

##2# Installing & configuring Arch Linux
echo "#######################################"
echo "# Installing & configuring Arch Linux #"
echo "#######################################"
echo "#"
echo "#Bootstrapping Arch..."
pacstrap /mnt base base-devel wpa_supplicant dialog intel-ucode bash-completion

#download the second script for chroot part
wget https://raw.githubusercontent.com/swerner1511/Arch-Install-Script/master/Base-Install/arch-i-s2.sh
#copy second script to /mnt 
cp arch-i-s2.sh /mnt
#Generate fstab
echo "#"
echo "#Generate fstab..."
genfstab -p -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
read
echo "#"
echo "#Chroot into the new install..."
arch-chroot /mnt su -c "sh arch-i-s2.sh"

#### Waiting for finishing chroot session

##3# Clean up, unmount all and reboot
rm /mnt/arch-i-s2.sh
echo "#"
echo "#Unmounting all partitions..."
umount /mnt/boot
umount /mnt/home
umount /mnt
echo "#"
echo "#Deactivating swap..."
swapoff -a
echo "#"
echo "Deactivating volume group..."
vgchange -an
echo "#"
echo "#Closing Luks device..."
cryptsetup luksClose crypt0
echo "#"
echo "#Reboot and remove media ..."
echo "Press any key to reboot..."
read
reboot

