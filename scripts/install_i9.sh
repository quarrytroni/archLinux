#!/bin/bash
# Instalamos y preparamos sistema para el procesador i9

# Primero ejecuta este script y despues,
# verifica si esta cargado el modulo snd_hda_intel
# $ lsmod | grep snd_hda_intel
# Si no aparece en la lista de la izquierda
# snd_hda_intel          69632  1
# Instalar el modulo
# sudo modprobe snd_hda_intel



# Asegúrate de que el script se ejecute como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

pacman -Sy

# Instalación de drivers y herramientas para Intel
install() {
    local option="$1"
    if ! pacman -Qi $option > /dev/null 2>&1; then
    sudo pacman -S --noconfirm $option
  fi
}

# CPU

#Auto-CPUFreq y cpupower
# son dos herramientas utilizadas en sistemas Linux para gestionar y optimizar el rendimiento de la CPU, pero tienen enfoques y características diferentes.
# sin embargo Auto-CPUFreq en un ordenador de sobremesa es una excelente manera de mejorar la eficiencia energética, térmica y reducir el consumo de energía.

install "auto-cpufreq"

# mirar si se habilita al reiniciar
# sudo systemctl enable auto-cpufreq.service
# sudo systemctl start auto-cpufreq.service
# para ver estadísticas y realizar ajustes temporales
# auto-cpufreq --live

# install "cpupower"

# GPU

install "intel-media-driver"

install "mesa"

install "lib32-mesa"

install "vulkan-intel"

install "lib32-vulkan-intel"

install "vulkan-icd-loader"

install "lib32-vulkan-icd-loader"

#para monitorear el rendimiento de tu GPU Intel en Wayland
install "intel-gpu-tools"

# Daemon para monitorear y controlar la temperatura del sistema.
install "thermald"

# "¿Qué herramientas de KDE Plasma puedo usar para ajustar
# el rendimiento y la gestión de energía en Wayland?"

# Verificar y habilitar thermald.service
if systemctl --user is-active --quiet thermald.service > /dev/null 2>&1; then
    echo "thermald.service ya está activo."
else
    echo "thermald.service no está activo.\nProcediendo a habilitar e iniciar..."
    systemctl --user enable thermald.service > /dev/null 2>&1
    echo "thermald.service ha sido habilitado."
fi

# OBSOLETO

# install "libva-intel-drive", "mesa-vdpau"

# Configuración solo para Xorg, para Wayland no realizar:

# install "xorg-server"

# install "xorg-xinit"


# Creamos una configuración incluye opciones para el método de aceleración gráfico,
# la eliminación de desgarros en la pantalla, el uso de un búfer triple para
# mejorar la fluidez, y la asignación de memoria de video.

# Ruta del archivo de configuración
#CONFIG_FILE="/etc/X11/xorg.conf.d/20-intel.conf"
#CONFIG_DIR="/etc/X11/xorg.conf.d"

# Función para crear el archivo de configuración
#crear_configuracion() {
#    cat > "$CONFIG_FILE" << EOF
#Section "Device"
#    Identifier  "Intel Graphics"
#    Driver      "intel"

    # Método de aceleración gráfico
#    Option      "AccelMethod"  "sna"  # SNA es el método de aceleración recomendado para gráficos Intel

    # Opciones para mejorar la experiencia visual
#    Option      "TearFree"     "true"  # Elimina el desgarro de la pantalla
#    Option      "TripleBuffer"  "true"  # Mejora la fluidez en la reproducción de video y juegos

    # Asignación de memoria de video
    # La memoria de video se toma de la RAM del sistema
    # usar con precaución hacer pruebas con juegos e IAs.
    # Option      "VideoRam"     "4194304"  # Para 4 GB en KB
    # Option      "VideoRam"     "8388608"  # Para 8 GB en KB
    # Option      "VideoRam"     "16777216"  # Para 16 GB en KB
    # Option      "VideoRam"     "31457280"  # Para 30 GB en KB
    # Option      "VideoRam"     "16777216"  # Para 16 GB en KB

    # Configuración de pantalla completa
#    Option      "FullScreen"   "true"  # Habilita el modo de pantalla completa para aplicaciones
#EndSection
#EOF
#}

# Verificar si el archivo de configuración existe
#if [ -f "$CONFIG_FILE" ]; then
#    echo "El archivo $CONFIG_FILE ya existe."

    # Verificar si el archivo contiene la palabra "intel"
#    if ! grep -q "intel" "$CONFIG_FILE"; then
#        echo "El archivo no contiene la palabra 'intel'. Se sobrescribirá el archivo."
#        crear_configuracion
#        echo "El archivo de configuración ha sido sobrescrito."
#    else
#        echo "El archivo ya contiene la palabra 'intel'. No se realizarán cambios."
#    fi
#else
#    echo "El archivo $CONFIG_FILE no existe. Se creará el archivo."
#    crear_configuracion
#    echo "El archivo de configuración ha sido creado."
#fi

echo "Configuracion para i9 terminada."

# Limpiar los archivos temporales
sudo rm -f "$0"
exit 0
