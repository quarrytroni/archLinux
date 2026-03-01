#!/bin/bash
# Instalamos y preparamos sistema para el uso de bluetooth

# Asegúrate de que el script se ejecute como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

CONFIG_FILE="/etc/bluetooth/main.conf"

pacman -Sy

# Instalación de drivers y herramientas para bluetooth
install() {
    local option="$1"
    if ! pacman -Qi $option > /dev/null 2>&1; then
    sudo pacman -S --noconfirm $option
  fi
}

install "bluez"

install "bluez-utils"

install "bluedevil"

# Verificar y habilitar bluetooth.service
if systemctl --user is-active --quiet bluetooth.service > /dev/null 2>&1; then
    echo "bluetooth.service ya está activo."
else
    echo "bluetooth.service no está activo.\nProcediendo a habilitar e iniciar..."
    systemctl --user enable bluetooth.service > /dev/null 2>&1
    echo "bluetooth.service ha sido habilitado."
fi

echo "Configurando BlueZ para soporte A2DP..."

# Crear backup del archivo original
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
echo "Backup creado en: ${CONFIG_FILE}.bak"

# Cambiar FastConnectable = false a FastConnectable = true
sudo sed -i 's/^#FastConnectable = false/FastConnectable = true/' "$CONFIG_FILE"
sudo sed -i 's/^FastConnectable = false/FastConnectable = true/' "$CONFIG_FILE"

# Descomentar AutoEnable=true
sudo sed -i 's/^#AutoEnable=true/AutoEnable=true/' "$CONFIG_FILE"


echo "Configuracion del bluetooth terminada."

# Limpiar los archivos temporales
sudo rm -f "$0"
exit 0
