#!/bin/bash

echo -n 'Enter symbol work disk ( a,b,c ): ' #Выбор диска, который необходимо выровнять или разбить.
read wsymbol
wdisk=/dev/sd$wsymbol

totalsector=`parted $wdisk unit s print y 2>/dev/null | grep "Disk $wdisk:" | cut -d\  -f3 | cut -ds -f1` #Общее чило сеторов на диске.
sizesector=`parted $wdisk unit s print y 2>/dev/null | grep "Sector size" | cut -d\/ -f3 | cut -dB -f1` #Размер сетора в байтах.

echo -n 'What type partition table (gpt msdos): ' #Тип таблицы разделов.
read typetable
echo
echo "Disk: $wdisk"
echo "Type: $typetable"
echo
echo -n "You sure? (y|n): " #Подтверждение выбранных параметорв. Если что-то не устраивает, пока можно исправить =).
read answer

if [ $answer = y ]; then
    parted $wdisk mktable $typetable y
  else
    while [ $answer != y ]; do
        echo -n 'Enter work disk ( a,b,c ): '
        read wsymbol
        wdisk=/dev/sd$wsymbol

        echo -n 'What type partition table (gpt msdos): '
        read typetable
        echo
        echo "Disk: $wdisk"
        echo "Type: $typetable"
        echo
        echo -n "You sure? (y|n): "
        read answer
    done
fi

echo -n 'Enter the total number of partitions (0-9): ' #Общее число партиций на диске.
read numpart
n=3

MiB=$((1024**0))
GiB=$((1024**1))
TiB=$((1024**2))

sectortomb=$((1024**2/$sizesector)) #Количество секторов данной размерности в 1 MiB.
startsector1=$((2*1024**2/$sizesector)) #Начальный сектор. Резон стартовать с 4096 считаю есть.
echo
echo "Full size disk: $(($totalsector/$sectortomb)) MiB" #Просто информация о полной емкости HDD.
echo "Full size disk: $(($totalsector/($sectortomb*$GiB))) GiB"
echo "Full size disk: $(($totalsector/($sectortomb*$TiB))) TiB"
echo
echo -n 'Select units (default=MiB GiB TiB): '
read sunit
  if [ -z $sunit ]; then sunit=MiB; fi

echo -n "Enter size first partition in $sunit (default=100): "
read psize1
  if [ -z $psize1 ]; then psize1=100; fi

  psizes=$(($startsector1/2*$psize1*$sunit-1)) #Пересчет размера партиции в секторах.
  endsector1=$(($startsector1+$psizes))

  parted $wdisk unit s mkpart primary $startsector1 $endsector1 print free

echo -n 'You want to create another partition? (y|n): '
read answer

if [ $answer = y ]
then
  while [ $answer = y ] #Разделы будут создаваться до тех пор, пока Вы не ответите "n",
  do
    while [ $numpart -ge $n ] #и пока значение созданых разделов не привысит указанное значение.
    do
      echo -n 'Select units (MiB default=GiB TiB): '
      read sunit1
        if [ -z $sunit1 ]; then sunit1=GiB; fi
      echo -n "Enter size partition in $sunit1: "
      read psize
      startsector=$((1+`parted $wdisk unit s print | tail -n2 | head -n1 | cut -ds -f2 | cut -d\  -f3`))
      psizes=$(($sectortomb*$psize*$sunit1-1))
      endsector=$(($startsector+$psizes))

      parted $wdisk unit s mkpart primary $startsector $endsector print free
      
      echo -n 'You want to create another partition? (y|n): '
      read answer
      n=$(( $n+1 ))
    done
    answer=n
  done
    startsector2=$((1+`parted $wdisk unit s print | tail -n2 | head -n1 | cut -ds -f2 | cut -d\  -f3`)) #Последний раздел создается автоматически. Это сделано для максимально возможного использования дискового пространства.
    endsector2=$((($totalsector/8-40)*8))
    parted $wdisk unit s mkpart primary $startsector2 $endsector2 print free
fi

totalpart=`parted /dev/sda print | tail -n +8 | cut -d\  -f2` #Список номеров разделов.

parted $wdisk unit GiB print

echo -n 'What a partition is bootable? (1-32): ' #Номер загрузочного раздела. Если таковой не нужен, то ничего вводить не надо.
read bootpart

if [ -n $bootpart ]
then
  parted $wdisk set $bootpart boot on
fi

if [ $typetable = gpt -a -n $bootpart ] #Если таблица GPT и диск загрузочный, то
then
  startgrub=$(($startsector1-$sectortomb))
  endgrub=$(($startsector1-1))
  parted $wdisk unit s mkpart non-fs $startgrub $endgrub print free #создается раздел для GRUB2 загрузчика.

  numgrub=`parted $wdisk print | grep non-fs | cut -d\  -f2`
  parted $wdisk set $numgrub bios_grub on
fi

echo -n 'Select number partition for SWAP (1-32): '
read nswap

echo -n 'Select type fs (ext2,3,4): ' #Тип файловой системы, впринципе можно указать любую.
read typefs

for i in $totalpart
do
  if [ $i -ne $nswap ]
  then
    mkfs.$typefs $wdisk$i
  else
    mkswap $wdisk$nswap
    swapon $wdisk$nswap
  fi
done

parted $wdisk unit s print free
parted $wdisk unit KiB print free
parted $wdisk unit GiB print

echo 'Разметка диска завершена'
