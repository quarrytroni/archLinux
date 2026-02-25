#!/bin/bash

# Verificar si se está ejecutando como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

# Ruta al archivo de configuración
MKINITCPIO_CONF="/etc/mkinitcpio.conf"
VCONSOLE_CONF="/etc/vconsole.conf"
BACKUP_CONF="/etc/mkinitcpio.conf.backup"

# Añadimos módulo amdgpu para gráficos AMD
MODULES_ORI="MODULES=()"
MODULES_MOD="MODULES=(amdgpu)"
# MODULES_MOD="MODULES=(i915)"

# Línea para comentar original
HOOKS_MODULES_ORI="HOOKS=(base systemd autodetect microcode modconf kms keyboard keymap sd-vconsole block filesystems fsck)"
HOOKS_MODULES_COMMENT="#    HOOKS=(base systemd autodetect microcode modconf kms keyboard keymap sd-vconsole block filesystems fsck)"

# Línea para descomentar y modificar para systemd original
HOOKS_MODULES_ORI_COMMENT="#    HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck)"
HOOKS_MODULES_UNCOMMENT_MOD="HOOKS=(base systemd autodetect microcode modconf kms keyboard keymap sd-vconsole sd-encrypt block filesystems fsck)"

# Hacer una copia de seguridad del archivo de configuración
cp "$MKINITCPIO_CONF" "$BACKUP_CONF"

# Inicializar la variable flag
flag=0

# Verificar si existe el archivo /etc/vconsole.conf y si contiene 'FONT='
if [ -f "$VCONSOLE_CONF" ]; then
  if grep -q '^FONT=' "$VCONSOLE_CONF"; then
    # Verificar si la línea de MODULES existe antes de modificarla
    if grep -q "^$MODULES_ORI" "$MKINITCPIO_CONF"; then
      # Modificar la línea de MODULES para procesadores AMD
      sed -i "s|^$MODULES_ORI|$MODULES_MOD|" "$MKINITCPIO_CONF"
      echo "La línea de MODULES ha sido modificada en $MKINITCPIO_CONF."
      flag=1
    else
      echo "Advertencia: La línea de MODULES no se encontró en $MKINITCPIO_CONF."
    fi

    # Verificar si la línea de HOOKS descomentada existe antes de modificarla
    if grep -q "^$HOOKS_MODULES_ORI" "$MKINITCPIO_CONF"; then
      # Comentar la línea de HOOKS descomentada original
      sed -i "s|^$HOOKS_MODULES_ORI|$HOOKS_MODULES_COMMENT|" "$MKINITCPIO_CONF"
      echo "La línea de HOOKS descomentada ha sido modificada en $MKINITCPIO_CONF."
      flag=1
    else
      echo "Advertencia: La línea de HOOKS descomentada no se encontró en $MKINITCPIO_CONF."
    fi

    # Verificar si la línea de HOOKS comentada existe antes de modificarla
    if grep -q "^$HOOKS_MODULES_ORI_COMMENT" "$MKINITCPIO_CONF"; then
      # Descomentar y modificar la línea de HOOKS comentada para systemd
      sed -i "s|^$HOOKS_MODULES_ORI_COMMENT|$HOOKS_MODULES_UNCOMMENT_MOD|" "$MKINITCPIO_CONF"
      echo "La línea de HOOKS comentada ha sido modificada en $MKINITCPIO_CONF."
      flag=1
    else
      echo "Advertencia: La línea de HOOKS comentada no se encontró en $MKINITCPIO_CONF."
    fi
  else
    echo "Advertencia: El archivo $VCONSOLE_CONF no contiene 'FONT='. Por favor, modifícalo antes de continuar."
  fi
else
  echo "Advertencia: El archivo $VCONSOLE_CONF no existe. Por favor, crea este archivo antes de continuar."
fi

# Confirmar que se han realizado los cambios
if [ $flag -eq 1 ]; then
  echo "Modificaciones realizadas en $MKINITCPIO_CONF:"
  # Mostramos las líneas modificadas
  grep '^MODULES=' "$MKINITCPIO_CONF"
  grep '^HOOKS=' "$MKINITCPIO_CONF"
  
  # Verificar si la línea de HOOKS ha devuelto una salida
  if grep -q '^HOOKS=' "$MKINITCPIO_CONF"; then
    # Regenerar la imagen del initramfs
    mkinitcpio -P
    echo "La imagen del initramfs ha sido regenerada."
  else
    echo "Error: No se encontró la línea de HOOKS en $MKINITCPIO_CONF. No se puede regenerar la imagen del initramfs."
  fi
fi

# Limpiar los archivos temporales
sudo rm -f "$0"
exit 0

