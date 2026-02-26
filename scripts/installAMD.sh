#!/bin/bash
# Instalamos y preparamos sistema para el procesador Ryzen

# Asegúrate de que el script se ejecute como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

pacman -Sy

# Instalación de drivers y herramientas para AMD
install() {
    local option="$1"
    if ! pacman -Qi $option > /dev/null 2>&1; then
      sudo pacman -S --noconfirm $option
    fi
}

# CPU

# Auto-CPUFreq y cpupower
install "auto-cpufreq"
# Para mayor control de la frecuencia de la CPU
install "cpupower"

# GPU

install "mesa"
install "vulkan-radeon"
install "vulkan-tools"
install "vulkan-icd-loader"

herramiente par monitorizar sensores
install "zenmonitor"

# Para monitorear el rendimiento de tu GPU AMD en Wayland
install "radeon-profile"

# thermald: herramienta es específica y casi exclusiva para CPUs Intel.
# Daemon para monitorear y controlar la temperatura del sistema.
# install "thermald"


# Verificar y habilitar thermald.service
if systemctl --user is-active --quiet thermald.service > /dev/null 2>&1; then
    echo "thermald.service ya está activo."
else
    echo "thermald.service no está activo. Procediendo a habilitar e iniciar..."
    systemctl --user enable thermald.service > /dev/null 2>&1
    echo "thermald.service ha sido habilitado."
fi

# Configuración para Xorg, para Wayland no realizar
# install "xorg-server"
# install "xorg-xinit"

# Creamos una configuración para el manejo gráfico en Xorg
CONFIG_FILE="/etc/X11/xorg.conf.d/20-amd.conf"
CONFIG_DIR="/etc/X11/xorg.conf.d"

# Función para crear el archivo de configuración
crear_configuracion() {
    cat > "$CONFIG_FILE" << EOF
Section "Device"
    Identifier  "AMD Graphics"
    Driver      "amdgpu"

    # Opciones para mejorar la experiencia visual
    Option      "TearFree"     "true"  # Elimina el desgarro de la pantalla
    Option      "TripleBuffer"  "true"  # Mejora la fluidez en la reproducción de video y juegos
EndSection
EOF
}

# Verificar si el archivo de configuración existe
if [ -f "$CONFIG_FILE" ]; then
    echo "El archivo $CONFIG_FILE ya existe."
    
    # Verificar si el archivo contiene la palabra "amdgpu"
    if ! grep -q "amdgpu" "$CONFIG_FILE"; then
        echo "El archivo no contiene la palabra 'amdgpu'. Se sobrescribirá el archivo."
        crear_configuracion
        echo "El archivo de configuración ha sido sobrescrito."
    else
        echo "El archivo ya contiene la palabra 'amdgpu'. No se realizarán cambios."
    fi
else
    echo "El archivo $CONFIG_FILE no existe. Se creará el archivo."
    crear_configuracion
    echo "El archivo de configuración ha sido creado."
fi

echo "Configuración para Ryzen terminada."

# Limpiar los archivos temporales
sudo rm -f "$0"
exit 0
