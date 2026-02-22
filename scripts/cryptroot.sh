#!/bin/bash

# Asegúrate de que el script se ejecute como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

# Partición de root
ROOT_PART="/dev/nvme0n1p6"

# Partición de DATOS
DATOS_PART="/dev/nvme0n1p8"

# Ruta del archivo a modificar
CRYPTTAB_FILE="/etc/crypttab.initramfs"

# Contador de intentos
attempts=0
max_attempts=3
uuid_root=""
uuid_datos=""

# Verificar el UUID hasta 3 veces particion root
while [ $attempts -lt $max_attempts ]; do
    uuid_root=$(blkid -s UUID -o value $ROOT_PART)
    
    if [ -n "$uuid_root" ]; then
        echo "UUID encontrado: $uuid_root"
        echo "Numero de intentos: $((attempts + 1))"  
        break
    else
        echo "Intento $((attempts + 1)): No se encontró UUID. Reintentando..."
        attempts=$((attempts + 1))
        sleep 1  # Esperar 1 segundo antes de volver a intentar
    fi
done

# Verificar el UUID hasta 3 veces particion DATOS
while [ $attempts -lt $max_attempts ]; do
    uuid_datos=$(blkid -s UUID -o value $DATOS_PART)
    
    if [ -n "$uuid_datos" ]; then
        echo "UUID encontrado: $uuid_datos"
        echo "Numero de intentos: $((attempts + 1))"  
        break
    else
        echo "Intento $((attempts + 1)): No se encontró UUID. Reintentando..."
        attempts=$((attempts + 1))
        sleep 1  # Esperar 1 segundo antes de volver a intentar
    fi
done

# Si se encontró un UUID
# Verificamos que existe crypttab.initramfs y si no lo creamos y le añadimos las lineas necesarias
# para que encripte la partición al cada inicio
if [ -n "$uuid_root" ]; then
    [ ! -e $CRYPTTAB_FILE ] && cp /etc/crypttab $CRYPTTAB_FILE
    cat >> "$CRYPTTAB_FILE" << EOF

if [ -n "$uuid_datos" ]; then
    [ ! -e $CRYPTTAB_FILE ] && cp /etc/crypttab $CRYPTTAB_FILE
    cat >> "$CRYPTTAB_FILE" << EOF

# Mount root as /dev/mapper/cryptroot using LUKS, and prompt for the passphrase at boot time.
# No usar discard, baja la seguridad del disco, los SSD modernos tienen algoritmos de garbage collection que mitigan esto bastante bien.
cryptroot    UUID=$uuid    none    luks,no-read-workqueue,no-write-workqueue,password-echo=no
EOF
  echo "Añadido a $CRYPTTAB_FILE cryptroot"
else
    echo "No se pudo encontrar un UUID después de $max_attempts intentos."
fi

# Limpiar los archivos temporales
sudo rm -f "$0"
exit 0
