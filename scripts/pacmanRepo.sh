#!/bin/bash

# Instalamos previamente rsync para que reflector se ejecute correctamente
if ! pacman -Qi rsync > /dev/null 2>&1; then
    sudo pacman -Sy --noconfirm rsync
fi

# Verificar si reflector está instalado
if ! pacman -Qi reflector > /dev/null 2>&1; then
    sudo pacman -S --noconfirm reflector
fi

# Hacemos una copia de seguridad
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

# Obtener la lista de servidores desde el sitio oficial
# sudo curl -o /etc/pacman.d/mirrorlist https://archlinux.org/mirrorlist/all/

# Ordenar los Espejos por Velocidad: 
# Arch Linux proporciona una herramienta llamada reflector que puede ayudarte a clasificar los espejos por velocidad.
sudo reflector --country 'Spain,Portugal,France,Germany,Switzerland' --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist

systemctl enable reflector.timer

# Sincronizar la base de datos de pacman
sudo pacman -Syy

# Limpiar los archivos temporales
sudo rm -f "$0"
exit 0
