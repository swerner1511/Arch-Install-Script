#!/usr/bin/bash
#
# Created by S. W. alias swerner1511
#
# A script that simplify the installation of "pacaur" an AUR Helper

# Change dir to tmp
cd /tmp || exit 1
buildroot="$(mktemp -d)"

# Ask for user passwort once
sudo -v

# Fetch gpg key to be able to verifty cower
gpg --recv-keys 1EB2638FF56C0C53

# Install needed packages to build packages and installs git
sudo pacman -S --needed --noconfirm base-devel git

# Create temp buildroot
mkdir -p "$buildroot"
cd "$buildroot" || exit 1

# Clone cower, build package and installs it
git clone "https://aur.archlinux.org/cower.git"
cd "${buildroot}/cower" || exit 1
makepkg --syncdeps --install --noconfirm

# Change dir back to buildroot
cd "$buildroot" || exit 1

# Clone pacaur, build package and installs it
git clone "https://aur.archlinux.org/pacaur.git"
cd "${buildroot}/pacaur" || exit 1
makepkg --syncdeps --install --noconfirm

# Change dir and removes the tmp build path
cd /tmp || exit 1
rm -rf  "$buildroot"
