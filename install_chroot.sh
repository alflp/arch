#!/bin/bash

# Временная зона
ln -svf /usr/share/zoneinfo/Europe/Moscow /etc/localtime

# Добавляем русскую локаль системы
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen 

# Обновим текущую локаль системы
locale-gen

# Указываем язык системы
echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf

# Прописываем локаль в консоли
echo 'KEYMAP=ru' >> /etc/vconsole.conf
echo 'FONT=cyr-sun16' >> /etc/vconsole.conf

# файл hosts
echo "127.0.1.1 $username" >> /etc/hosts
echo "127.0.0.1 localhost" >> /etc/hosts

#Пересоздать образ initramfs
mkinitcpio -p linux

# объявляем переменные
username=alex
hostname=acer

# Прописываем имя компьютера
echo $hostname > /etc/hostname

# Добавляем пользователя
useradd -m -G wheel -s /bin/bash $username # группа wheel — для работы с sudo
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers # настраиваем sudo

# Создаем root пароль
echo 'Enter passwd root'
passwd

# Создаем пароль пользователя
echo "Enter passwd $username"
passwd $username

# ставим grub
pacman -S grub efibootmgr --noconfirm
grub-install
grub-mkconfig -o /boot/grub/grub.cfg

clear

#Скачать reflector
pacman -S reflector
reflector -p http -c 'RU' -n 5 --sort rate --save /etc/pacman.d/mirrorlist

###################################################################
pacman -S virtualbox-guest-utils # только для виртуальной машины!!!
###################################################################

systemctl enable dhcpcd.service
