#!/bin/bash

# Created by S. W.
# latest update 22.05.2017
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
pacman -S --needed --noconfirm grub
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
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice=UUID='"${TempUUID}"':crypt0"/g' /etc/default/grub
echo "#"
echo "#Cleaning up..."
rm ~/tempUUID.txt
echo "#"
echo "#Install grub to disk..."
grub-install /dev/sda
echo "#"
echo "#Generate Grub config..."
grub-mkconfig -o /boot/grub/grub.cfg
echo "#"
echo "##################"
echo "# xorg server... #"
echo "##################"
pacman -S --needed --noconfirm xorg-server xorg-server-utils xorg-xinit
localectl --no-convert set-x11-keymap de pc105 nodeadkeys
echo "#"
echo "######################"
echo "# some basic pkgs... #"
echo "######################"
pacman -S --needed --noconfirm acpid ntp htop cronie zip unzip unrar smartmontools rsync pciutils p7zip openssh openssl hdparm lm_sensors net-tools nmap bind-tools openbsd-netcat sudo mtr whois linux-headers wget curl bash-completion parted git vim dosfstools ntfs-3g
systemctl enable acpid
systemctl enable cronie
systemctl enable smartd
ntpdate -u 0.de.pool.ntp.org
hwclock -w
echo "#"
echo "#######################"
echo "# graphical driver... #"
echo "#######################"
pacman -S --needed --noconfirm xf86-video-intel
# fallback gpu driver - xf86-video-vesa
pacman -S --needed --noconfirm xf86-video-vesa
echo "#"
echo "###################"
echo "# gnome+extras... #"
echo "###################"
pacman -S --needed --noconfirm gnome gnome-extra networkmanager networkmanager-openvpn networkmanager-vpnc network-manager-applet
systemctl enable gdm.service
systemctl enable NetworkManager.service
echo "#"
echo "###########################"
echo "# remove unwanted pkgs... #"
echo "###########################"
pacman -R baobab empathy epiphany totem accerciser aisleriot anjuta atomix five-or-more four-in-a-row gnome-2048 gnome-chess gnome-klotski gnome-mahjongg gnome-mines gnome-music gnome-nibbles gnome-robots gnome-sudoku gnome-taquin gnome-tetravex hitori iagno lightsoff orca quadrapassel swell-foop tali
echo "#"
echo "#Exit from chroot environment..."
exit

