#!/bin/bash

# Verificar si se está ejecutando como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi


# === Configurar parámetro de arrenque de root en GRUB ===
echo "Añadiendo cryptroot"
sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="root=/dev/mapper/cryptroot"/' /etc/default/grub && \
echo "cryptroot añadirdo correctamente" || \
echo "ERROR: No se ha podido añadir cryptroot a la configuración del grub"


# === MEJORA AQUÍ: Configurar parámetro de sonido en GRUB ===
# echo "Configurando parámetros de kernel para HDA Intel PCH..."
# sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet snd_hda_intel.dmic_detect=0"/' /etc/default/grub

# === MEJORA AQUÍ: Configurar parámetro del GRUB sin HDA Intel PCH ===
echo "Configurando parámetros del grub"
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"/' /etc/default/grub



# Verificar si la modificación fue exitosa
if [ $? -ne 0 ]; then
  echo "Error: No se pudo actualizar /etc/default/grub."
  exit 1
fi

# Generar la configuración de GRUB
echo "Generando la configuración de GRUB..."
grub-mkconfig -o /boot/grub/grub.cfg

# Verificar si la generación fue exitosa
if [ $? -ne 0 ]; then
  echo "Error: La generación de la configuración de GRUB falló."
  exit 1
fi

echo "GRUB ha sido instalado y configurado correctamente con soporte para HDA Intel PCH."

# Limpiar el script temporal
sudo rm -f "$0"
exit 0
