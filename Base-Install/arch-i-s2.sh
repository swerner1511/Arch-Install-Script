
#!/bin/bash

# Created by S. W.
# latest update 22.05.2017
#
# A script for archlinux to prepare the hard disk, 
# install 'base base-devel wpa_supplicant dialog' and etc.

echo "#"
echo "#install reflector"
pacman -S --needed --noconfirm reflector
echo "#"
echo "#Update mirror list..."
reflector --verbose -l 5 -p https --sort rate --save /etc/pacman.d/mirrorlist
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
#sed -ie 's/#en_US/en_US/g' /etc/locale.gen
locale-gen
echo "#"
echo "#Set default locales..."
echo "LANG=de_DE.UTF-8" > /etc/locale.conf
echo "LANGUAGE=de_DE" >> /etc/locale.conf
echo "#"
echo "#Set console keymap..."
echo "KEYMAP=de-latin1-nodeadkeys" > /etc/vconsole.conf
echo "#"
echo "#Add scripts to ramdisk..."
sed -i '/HOOKS="base udev autodetect modconf block filesystems keyboard fsck"/c\HOOKS="base udev autodetect modconf keyboard keymap block encrypt lvm2 filesystems fsck"' /etc/mkinitcpio.conf
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
# remove "UUID:" from string
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
pacman -S --needed --noconfirm xorg-server xorg-xinit
localectl --no-convert set-x11-keymap de pc105 nodeadkeys
echo "#"
echo "######################"
echo "# some basic pkgs... #"
echo "######################"
pacman -S --needed --noconfirm acpid avahi cups cronie firefox firefox-i18n-de thunderbird thunderbird-i18n-de
systemctl enable acpid
systemctl enable avahi-daemon
systemctl enable cronie
systemctl enable org.cups.cupsd.service
ntpdate -u 0.de.pool.ntp.org
hwclock -w
echo "#"
echo "#######################"
echo "# graphical driver... #"
echo "#######################"
pacman -S --needed --noconfirm xf86-video-intel
echo "#"
echo "###################"
echo "# gnome+extras... #"
echo "###################"
pacman -S --needed --noconfirm gnome gnome-extra
systemctl enable gdm.service
systemctl enable NetworkManager.service
pacman -S --needed --noconfirm system-config-printer
echo "#"
echo "###########################"
echo "# remove unwanted pkgs... #"
echo "###########################"
pacman -R --noconfirm baobab empathy epiphany totem accerciser aisleriot anjuta atomix five-or-more four-in-a-row gnome-2048 gnome-chess gnome-klotski gnome-mahjongg gnome-mines gnome-music gnome-nibbles gnome-robots gnome-sudoku gnome-taquin gnome-tetravex hitori iagno lightsoff orca quadrapassel swell-foop tali
echo "#"
echo "###########################"
echo "# create useraccount... #"
echo "###########################"
echo "Enter your username..."
read USERNAME
useradd -m -g users -G wheel,audio,video -s /bin/bash $USERNAME
passwd $USERNAME
echo "User created..."
echo "Don't forget to EDITOR=nano visudo..."
echo "Press any key..."
read
EDITOR=nano visudo
echo ""
echo "###########################"
echo "# set root password... #"
echo "###########################"
passwd
echo "#"
echo "#Exit from chroot environment..."
exit

