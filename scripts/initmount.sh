#!/bin/bash
# Montamos las particiones iniciales

mount /dev/mapper/cryptroot /mnt && echo "cryptroot montado"

mkdir /mnt/boot && echo "Directorio /boot creado"
mount /dev/nvme0n1p5 /mnt/boot && echo "boot montado"

mkdir /mnt/boot/efi && echo "Directorio /boot/efi creado"
mount /dev/nvme0n1p1 /mnt/boot/efi && echo "efi montado"

mkdir /mnt/mnt && mkdir /mnt/mnt/DATOS && echo "Directorio /mnt/DATOS creado"
mount /dev/mapper/cryptdatos /mnt/mnt/DATOS && echo "DATOS montado"

mkdir /mnt/mnt/WINLINUX && echo "Directorio intercambio con Windows creado"
mount /dev/nvme0n1p7 /mnt/mnt/WINLINUX && echo "Directorio intercambio con Windows montado"

# mkdir /mnt/mnt/Win11 && echo "Directorio /mnt/Win11 creado"
# mount /dev/nvme0n1p3 /mnt/mnt/Win11 && echo "Win11 montado, cuidado cualquier cambio puede dañar Windows"

# Limpiar los archivos temporales
sudo rm -f "$0"
exit 0
