#!/bin/bash
#Диск должен быть размечен по схеме:
#sda1 - boot-раздел
#sda2 - swap-раздел
#sda3 - root-раздел
#sda4 - home-раздел

mkfs.vfat -F32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mkfs.ext4 /dev/sda3
mkfs.ext4 /dev/sda4

mount /dev/sda3 /mnt #сначала корень
mkdir /mnt/{boot,home}
mkdir /mnt/boot/efi
mount /dev/sda4 /mnt/home
mount /dev/sda1 /mnt/boot/efi

pacman -Syy # обновляем репозитории
pacman -S reflector # программа для работы с зеркалами, устанавливаем
reflector -p http -c 'RU' -n 5 --sort rate --save /etc/pacman.d/mirrorlist

pacstrap /mnt base base-devel linux linux-firmware nano dhcpcd
genfstab -pU /mnt >> /mnt/etc/fstab
clear
echo " Конец первой части. Перейти в установленную систему командой arch-chroot /mnt"
echo " Скачать wget pacman -S wget"
