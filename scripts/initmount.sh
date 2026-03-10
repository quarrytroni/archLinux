#!/bin/bash
# Montamos las particiones iniciales

# --- NUEVA SECCIÓN: Selección de disco ---

echo "Listando discos NVMe disponibles:"
lsblk | grep nvme

# Pedimos el número al usuario
read -p "Introduce el número del disco NVMe a usar (ejemplo: 0 para nvme0, 1 para nvme1): " NUM_DISCO

# Construimos el identificador base. 
# Nota: Los discos NVMe suelen ser nvme0n1, nvme1n1, etc.
DISCO="/dev/nvme${NUM_DISCO}n1"

# Verificamos que el disco exista antes de continuar
if [ ! -b "$DISCO" ]; then
    echo "Error: El disco $DISCO no existe. Verifica el número introducido."
    exit 1
fi

echo "Se utilizará el disco: $DISCO"
echo "Las particiones se asumirán como: ${DISCO}p1, ${DISCO}p2, etc."
read -p "Presiona Enter para continuar o Ctrl+C para cancelar..."

# --- FIN NUEVA SECCIÓN ---

mount /dev/mapper/cryptroot /mnt && echo "cryptroot montado"
sleep 2

mkdir /mnt/boot && echo "Directorio /boot creado"
mount ${DISCO}p5 /mnt/boot && echo "boot montado"
sleep 2

mkdir /mnt/boot/efi && echo "Directorio /boot/efi creado"
mount ${DISCO}p1 /mnt/boot/efi && echo "efi montado"
sleep 2

mkdir /mnt/mnt && mkdir /mnt/mnt/DATOS && echo "Directorio /mnt/DATOS creado"
mount /dev/mapper/cryptdatos /mnt/mnt/DATOS && echo "DATOS montado"
sleep 2

mkdir /mnt/mnt/WINLINUX && echo "Directorio intercambio con Windows creado"
mount ${DISCO}p7 /mnt/mnt/WINLINUX && echo "Directorio intercambio con Windows montado"
sleep 2

# mkdir /mnt/mnt/Win11 && echo "Directorio /mnt/Win11 creado"
# mount /dev/nvme0n1p3 /mnt/mnt/Win11 && echo "Win11 montado, cuidado cualquier cambio puede dañar Windows"

# Limpiar los archivos temporales
sudo rm -f "$0"
exit 0
