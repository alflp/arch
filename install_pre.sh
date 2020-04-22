#!/bin/bash

mkfs.vfat -F32 /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda3

mount /dev/sda2 /mnt #сначала корень
mkdir /mnt/{boot,home}
mkdir /mnt/boot/efi
mount /dev/sda3 /mnt/home
mount /dev/sda1 /mnt/boot/efi

pacman -Syy # обновляем репозитории
pacman -S reflector # программа для работы с зеркалами, устанавливаем
reflector -p http -c 'RU' -n 5 --sort rate --save /etc/pacman.d/mirrorlist

pacstrap /mnt base base-devel linux linux-firmware nano dhcpcd
genfstab -pU /mnt >> /mnt/etc/fstab
