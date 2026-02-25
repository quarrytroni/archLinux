#!/bin/bash

# Asegúrate de que el script se ejecute como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

# Particiones
ROOT_PART="/dev/nvme0n1p6"
DATOS_PART="/dev/nvme0n1p8"

# Archivos de configuración
CRYPTTAB_INITRAMFS="/etc/crypttab.initramfs"
CRYPTTAB_FILE="/etc/crypttab"

# Contador de intentos
attempts=0
max_attempts=3

# Función para obtener el UUID
get_uuid() {
    local part=$1
    local uuid=""
    local tries=0

    while [ $tries -lt $max_attempts ]; do
        uuid=$(blkid -s UUID -o value "$part")
        
        if [ -n "$uuid" ]; then
            echo "$uuid"
            return 0
        else
            echo "Intento $((tries + 1)): No se encontró UUID para $part. Reintentando..." >&2
            tries=$((tries + 1))
            sleep 1
        fi
    done

    echo ""
    return 1
}

# Obtener UUIDs
ROOT_UUID=$(get_uuid "$ROOT_PART")
DATOS_UUID=$(get_uuid "$DATOS_PART")

if [ -z "$ROOT_UUID" ] || [ -z "$DATOS_UUID" ]; then
    echo "ERROR: No se pudo encontrar ambos UUIDs después de $max_attempts intentos."
    exit 1
fi

echo "UUIDs encontrados:"
echo "  ROOT:  $ROOT_UUID"
echo "  DATOS: $DATOS_UUID"

# ============================================
# ROOT -> /etc/crypttab.initramfs (para arrancar)
# ============================================
[ ! -e "$CRYPTTAB_INITRAMFS" ] && [ -e "/etc/crypttab" ] && cp /etc/crypttab "$CRYPTTAB_INITRAMFS"

cat >> "$CRYPTTAB_INITRAMFS" << EOF

# Root encriptado - necesario para arrancar
cryptroot    UUID=$ROOT_UUID    none    luks,no-read-workqueue,no-write-workqueue,password-echo=no
EOF

echo "✓ Añadido 'cryptroot' a $CRYPTTAB_INITRAMFS"

# ============================================
# DATOS -> /etc/crypttab normal (post-arranque)
# ============================================
cat >> "$CRYPTTAB_FILE" << EOF

# Partición de datos encriptada
cryptdatos   UUID=$DATOS_UUID   none    luks,no-read-workqueue,no-write-workqueue,password-echo=no
EOF

echo "✓ Añadido 'cryptdatos' a $CRYPTTAB_FILE"

echo ""
echo "============================================"
echo "Configuración completada. Recuerda:"
echo "1. Regenerar initramfs: mkinitcpio -P"
echo "2. Crear el punto de montaje: mkdir -p /mnt/DATOS"
echo "============================================"

# Limpiar los archivos temporales
sudo rm -f "$0"
exit 0
