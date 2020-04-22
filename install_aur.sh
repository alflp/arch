#!/bin/bash

git clone https://aur.archlinux.org/yay-bin.git # менеджер пакетов aur
cd yay-bin
makepkg -si --skipinteg

cd ..
rm -rf yay-bin

# ставим сразу программы из aur, самое главное гуй для pacman — pamac
yay -S flameshot pamac-aur xorg-xkill inxi --noconfirm  
