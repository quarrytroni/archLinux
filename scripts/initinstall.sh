#!/bin/bash

# Instalamos el sistema base en /mnt
# pacstrap -i /mnt base base-devel fuse linux-zen linux-zen-headers linux-firmware intel-ucode usbutils nano less git btrfs-progs exfat-utils ntfs-3g grub efibootmgr networkmanager wget
# exfat-utils es obsoleto, usar exfatprogs

# Para AMD
pacstrap -i /mnt base base-devel archlinux-keyring fuse linux-zen linux-zen-headers linux-firmware amd-ucode arch-install-scripts usbutils nano less git btrfs-progs exfatprogs ntfs-3g grub efibootmgr networkmanager wget


# Limpiar los archivos temporales
sudo rm -f "$0"
exit 0
