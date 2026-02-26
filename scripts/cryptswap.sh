#!/bin/bash

# Asegúrate de que el script se ejecute como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

# Partición swap
SWAP_PART="/dev/nvme0n1p9"
# Nombre del dispositivo desencriptado
SWAP_CRYPT="volatileswap"

# Ruta de los archivos en el sistema
CRYPTTAB_FILE="/etc/crypttab"
FSTAB_FILE="/etc/fstab"

# Contador de intentos
attempts=0
max_attempts=3
SWAP_UUID=""

# Obtener el UUID con reintentos
while [ $attempts -lt $max_attempts ]; do
    SWAP_UUID=$(blkid -s UUID -o value "$SWAP_PART")
    
    if [ -n "$SWAP_UUID" ]; then
        echo "✓ UUID encontrado: $SWAP_UUID (intento $((attempts + 1)))"
        break
    else
        echo "Intento $((attempts + 1)): No se encontró UUID. Reintentando..."
        attempts=$((attempts + 1))
        sleep 1
    fi
done

if [ -z "$SWAP_UUID" ]; then
    echo "ERROR: No se pudo obtener el UUID de la partición $SWAP_PART"
    exit 1
fi

# Añadir al crypttab (USANDO UUID Y /dev/urandom)
echo "Añadiendo a $CRYPTTAB_FILE..."
cat >> "$CRYPTTAB_FILE" << EOF

# Swap encriptada con clave aleatoria en cada arranque
# $SWAP_CRYPT    UUID=$SWAP_UUID    /dev/urandom    swap,cipher=aes-xts-plain64,size=256
# fuente archLinux
$SWAP_CRYPT    UUID=$SWAP_UUID    /dev/urandom    swap,offset=2048,cipher=aes-xts-plain64,size=512,sector-size=4096
EOF

echo "Añadido '$SWAP_CRYPT' a $CRYPTTAB_FILE"

# Añadir al fstab
echo "Añadiendo a $FSTAB_FILE..."
cat >> "$FSTAB_FILE" << EOF

# Swap encriptada
/dev/mapper/$SWAP_CRYPT    none    swap    sw    0 0
EOF

echo "Añadido '$SWAP_CRYPT' a $FSTAB_FILE"

echo ""
echo "============================================"
echo "Configuración de swap completada."
echo "============================================"

exit 0
