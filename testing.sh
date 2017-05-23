#!/bin/bash
#
# Created by S. W.
# latest update 23.05.2017
#
# A script for archlinux installation


## Variables
KEYLAYOUT=de-latin1-nodeadkeys
TIMEZONE="Europe/Berlin"
HOSTNAME="tardis-nb"
BOOTSIZE=512M
ROOTSIZE=50GiB
SWAPSIZE=1GiB
#Home Partition will use the remaining size


# Script begin
echo "###################"
echo "# Starting script #"
echo "###################"
echo "#"
echo "#You have to edit the Variables Section to your needs."
echo "#Opening script with nano..."
nano ./01-preconfig.sh

# Loading default keymap for Arch live system
echo "#"
echo "#Set Keylayout..."
loadkeys $KEYLAYOUT

# Update system clock
timedatectl set-ntp true

### Preparing the hard disk
echo "###########################"
echo "# Preparing the hard disk #"
echo "###########################"
echo "#"
fdisk -l
echo "#Select a disk to install on (e.g. /dev/sda)"
read DISK
echo "#"
echo "#Creating the partition layout..."
# Create partition table
parted -s $DISK mklabel msdos
# Create boot parition
parted -s $DISK mkpart primary 0% $BOOTSIZE
# Create lvm partition
parted -s $DISK mkpart primary $BOOTSIZE 100%
# Make boot partition bootable
parted -s $DISK set 1 boot on

# Preparing the encrypted system partitions
echo "#"
echo "#Creating of the LUKS device.."
cryptsetup -v --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 10000 --use-urandom --verify-passphrase luksFormat /dev/${DISK}2
echo "#"
echo "Opening encrypted device..."
cryptsetup luksOpen /dev/${DISK}2 crypt0
echo "#"
echo "#Creating partitions within the Luks device using LVM..."
pvcreate /dev/mapper/crypt0
vgcreate crypt0-vg0 /dev/mapper/crypt0
lvcreate -L $SWAPSIZE -n swap crypt0-vg0
lvcreate -L $ROOTSIZE -n root crypt0-vg0
lvcreate -l 100%FREE -n home crypt0-vg0
echo "#"
echo "#Formatting the partitions..."
mkfs.ext2 -L boot /dev/${DISK}1
mkfs.ext4 -L root /dev/mapper/crypt0--vg0-root
mkfs.ext4 -L home /dev/mapper/crypt0--vg0-home
mkswap -L swap /dev/mapper/crypt0--vg0-swap
echo "#"
echo "#Mount partitions..."
mount -t ext4 /dev/mapper/crypt0--vg0-root /mnt
mkdir /mnt/boot && mount -t ext2 /dev/${DISK}1 /mnt/boot
mkdir /mnt/home && mount -t ext4 /dev/mapper/crypt0--vg0-home /mnt/home
swapon /dev/mapper/crypt0--vg0-swap

### Installing & configuring Arch Linux
echo "#######################################"
echo "# Installing & configuring Arch Linux #"
echo "#######################################"
echo "#"
echo "#Bootstrapping Arch..."
pacstrap /mnt base base-devel wpa_supplicant dialog reflactor

#Generate fstab
echo "#"
echo "#Generate fstab..."
genfstab -p -U /mnt >> /mnt/etc/fstab

# Set timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /mnt/etc/localtime

##2# Configuring new system with arch-chroot
echo "#"
echo "#Configuring new system with arch-chroot..."

echo "#"
echo "#Rank Mirrors with reflactor..."
arch-chroot /mnt REFLECTOR --verbose -l 5 -p https --sort rate --save /etc/pacman.d/mirrorlist

echo "#"
echo "#Check for Update on new system..."
arch-chroot /mnt pacman -Syu

echo "#"
echo "#Set Hostname..."
arch-chroot /mnt echo $HOSTNAME > /etc/hostname

echo "#"
echo "#Set locale..."
sed -ie 's/#de_DE/de_DE/g' /mnt/etc/locale.gen
sed -ie 's/#en_US/en_US/g' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

echo "#"
echo "#Set default locales..."
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
echo "LC_CTYPE=de_DE.UTF-8" >> /mnt/etc/locale.conf
echo "LC_NUMERIC=de_DE.UTF-8" >> /mnt/etc/locale.conf
echo "LC_TIME=de_DE.UTF-8" >> /mnt/etc/locale.conf
echo "LC_COLLATE=de_DE.UTF-8" >> /mnt/etc/locale.conf
echo "LC_MONETARY=de_DE.UTF-8" >> /mnt/etc/locale.conf
echo "LC_MESSAGES=en_US.UTF-8" >> /mnt/etc/locale.conf
echo "LC_PAPER=de_DE.UTF-8" >> /mnt/etc/locale.conf
echo "LC_NAME=de_DE.UTF-8" >> /mnt/etc/locale.conf
echo "LC_ADDRESS=de_DE.UTF-8" >> /mnt/etc/locale.conf
echo "C_TELEPHONE=de_DE.UTF-8" >> /mnt/etc/locale.conf
echo "LC_MEASUREMENT=de_DE.UTF-8" >> /mnt/etc/locale.conf
echo "LC_IDENTIFICATION=de_DE.UTF-8" >> /mnt/etc/locale.conf
echo "LC_ALL=" >> /mnt/etc/locale.conf

echo "#"
echo "#Set console keymap..."
echo "KEYMAP=de-latin1-nodeadkeys" > /mnt/etc/vconsole.conf

echo "#"
echo "#Add scripts to ramdisk..."
sed -i '/HOOKS="base udev autodetect modconf block filesystems keyboard fsck"/c\HOOKS="base udev autodetect modconf keyboard block encrypt lvm2 filesystems fsck"' /mnt/etc/mkinitcpio.conf

echo "#"
echo "#Generate ramdisk..."
arch-chroot /mnt mkinitcpio -p linux

echo "#"
echo "#Install Grub..."
arch-chroot /mnt pacman -S --needed --noconfirm grub

echo "#"
echo "#Configuring Grub..."
# TODO : shorten the UUID-Part ^^
# grep only UUID
cryptsetup luksDump /dev/sda2 | grep UUID > tempUUID.txt
# renove UUID from string
sed -ie 's/UUID:/ /g' tempUUID.txt
# remove spaces and tabs from string
sed -ie 's/^[ \t]*//' tempUUID.txt
# $UUIDtemp = Inhalt von tempUUID.txt
TempUUID=$(<tempUUID.txt)
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice=UUID='"${TempUUID}"':crypt0"/g' /mnt/etc/default/grub
echo "#"
echo "#Cleaning up..."
rm ~/tempUUID.txt

echo "#"
echo "#Install grub to disk..."
arch-chroot /mnt grub-install /dev/sda
echo "#"
echo "#Generate Grub config..."
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

echo "#"
echo "#Set default locales..."
echo "#"
echo "#Set default locales..."
echo "#"
echo "#Set default locales..."
#arch-chroot /mnt su -c "sh arch-install-script-2.sh"

##TODO: EXTRAS

### Clean up, unmount all and reboot
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