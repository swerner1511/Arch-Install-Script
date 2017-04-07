#!/bin/bash

# Created by S. W.
# latest update 07.04.2017
#
# A script for archlinux to prepare the hard disk, 
# install 'base base-devel wpa_supplicant dialog' and etc.

echo "#"
echo "#Update mirror list..."
curl "https://www.archlinux.org/mirrorlist/?country=FI&country=DE&country=IS&country=LU&country=NL&country=NZ&country=CH&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on" | sed 's/#Server/Server/g' > /etc/pacman.d/mirrorlist
pacman -Syu
echo "#"
echo "#Set Hostname"
echo "tardis-nb" > /etc/hostname
echo "#"
echo "#Set Time zone"
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
echo "#"
echo "#Generate locales"
sed -ie 's/#de_DE/de_DE/g' /etc/locale.gen
sed -ie 's/#en_US/en_US/g' /etc/locale.gen
locale-gen
echo "#"
echo "#Set default locales..."
echo "LANG=en_US.UTF-8
LC_CTYPE="de_DE.UTF-8"
LC_NUMERIC="de_DE.UTF-8"
LC_TIME="de_DE.UTF-8"
LC_COLLATE="de_DE.UTF-8"
LC_MONETARY="de_DE.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_PAPER="de_DE.UTF-8"
LC_NAME="de_DE.UTF-8"
LC_ADDRESS="de_DE.UTF-8"
LC_TELEPHONE="de_DE.UTF-8"
LC_MEASUREMENT="de_DE.UTF-8"
LC_IDENTIFICATION="de_DE.UTF-8"
LC_ALL=" >> /etc/locale.conf
# echo "LANG=de_DE.UTF-8
# LC_CTYPE="de_DE.UTF-8"
# LC_NUMERIC="de_DE.UTF-8"
# LC_TIME="de_DE.UTF-8"
# LC_COLLATE="de_DE.UTF-8"
# LC_MONETARY="de_DE.UTF-8"
# LC_MESSAGES="de_DE.UTF-8"
# LC_PAPER="de_DE.UTF-8"
# LC_NAME="de_DE.UTF-8"
# LC_ADDRESS="de_DE.UTF-8"
# LC_TELEPHONE="de_DE.UTF-8"
# LC_MEASUREMENT="de_DE.UTF-8"
# LC_IDENTIFICATION="de_DE.UTF-8"
# LC_ALL=" >> /etc/locale.conf
echo "#"
echo "#Set console keymap..."
echo "KEYMAP=de-latin1-nodeadkeys" > /etc/vconsole.conf
echo "#"
echo "#Add scripts to ramdisk..."
sed -i '/HOOKS="base udev autodetect modconf block filesystems keyboard fsck"/c\HOOKS="base udev autodetect modconf keyboard block encrypt lvm2 filesystems fsck"' /etc/mkinitcpio.conf
echo "#"
echo "#Regenerate ramdisk..."
mkinitcpio -p linux
echo "#"
echo "#Install Grub..."
pacman -S grub
echo "#"
echo "#Configuring Grub..."
# TODO : shorten the UUID-Part ^^
# grep only UUID
cryptsetup luksDump /dev/sda3 | grep UUID > test.txt
# renove UUID from string
sed -ie 's/UUID:/ /g' tempUUID.txt
# remove spaces and tabs from string
sed -ie 's/^[ \t]*//' tempUUID.txt
# $UUIDtemp = Inhalt von tempUUID.txt
TempUUID=$(<tempUUID.txt)
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice=UUID='"${TempUUID}"':crypt0"/g' /etc/default/grub
echo "#"
echo "#Install grub to disk..."
grub-install /dev/sda
echo "#"
echo "#Generate Grub config..."
grub-mkconfig -o /boot/grub/grub.cfg
echo "#"
echo "#Cleaning up..."
rm ~/tempUUID.txt
echo "#"
echo "#Exit from chroot environment..."
exit

