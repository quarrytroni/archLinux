#!/bin/bash

# Asegúrate de que el script se ejecute como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

# Particiones
ROOT_PART="/dev/nvme0n1p5"
DATOS_PART="/dev/nvme0n1p6" # Cambia esto si la partición de datos es diferente

# Ruta del archivo a modificar
CRYPTTAB_FILE="/etc/crypttab.initramfs"

# Contador de intentos
attempts=0
max_attempts=3

# Función para obtener el UUID
get_uuid() {
    local part=$1
    local uuid=""
    attempts=0

    while [ $attempts -lt $max_attempts ]; do
        uuid=$(blkid -s UUID -o value "$part")
        
        if [ -n "$uuid" ]; then
            echo "$uuid"
            return 0
        else
            echo "Intento $((attempts + 1)): No se encontró UUID para $part. Reintentando..."
            attempts=$((attempts + 1))
            sleep 1
        fi
    done

    echo ""
    return 1
}

# Obtener UUIDs
ROOT_UUID=$(get_uuid "$ROOT_PART")
DATOS_UUID=$(get_uuid "$DATOS_PART")

# Si se encontraron UUIDs, añadimos al archivo crypttab.initramfs
if [ -n "$ROOT_UUID" ] && [ -n "$DATOS_UUID" ]; then
    [ ! -e "$CRYPTTAB_FILE" ] && cp /etc/crypttab "$CRYPTTAB_FILE"
    {
        echo ""
        echo "# Montar root como /dev/mapper/cryptroot usando LUKS."
        echo "cryptroot    UUID=$ROOT_UUID    none    luks,no-read-workqueue,no-write-workqueue,password-echo=no"
        
        echo ""
        echo "# Montar datos como /dev/mapper/cryptdatos usando LUKS."
        echo "cryptdatos   UUID=$DATOS_UUID   none    luks,no-read-workqueue,no-write-workqueue,password-echo=no"
    } >> "$CRYPTTAB_FILE"

    echo "Añadido a $CRYPTTAB_FILE: cryptroot y cryptdatos"
else
    echo "No se pudo encontrar ambos UUIDs después de $max_attempts intentos."
fi


# Limpiar los archivos temporales
sudo rm -f "$0"
exit 0
