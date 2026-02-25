#!/bin/bash
# Generamos configuraciones para reconocimiento local para representar texto,
# mostrar correctamente valores monetarios regionales, formatos de fecha y hora,
# idiosincrasias alfabéticas y otros estándares específicos de la región.
# Si lo hacemos así, todos los usuarios nuevos creados con useradd -m "usuario"
# se les creará automáticamente un ~/.config/locale.conf con la configuración
# que hayamos definido en el archivo siguiente, lo prefiero de esta forma
# el sistema base, el superadmin y los logs seguirán en inglés.

# Asegúrate de que el script se ejecute como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

echo "Configurando la zona horaria..."
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc
echo "Zona horaria configurada a Europe/Madrid."

# Instalar terminus-font
echo "Actualizando el sistema y instalando terminus-font..."
pacman -Syu --noconfirm
pacman -S --noconfirm terminus-font
echo "Terminada la instalación de terminus-font."

# Configuración del sistema (Inglés con teclado español)
echo "Configurando locales..."
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
sed -i 's/^#es_ES.UTF-8/es_ES.UTF-8/' /etc/locale.gen
cat > /etc/default/locale << EOF
# Configuración regional del sistema
LANG="en_US.UTF-8"
LANGUAGE="en_US:en"
LC_ALL="en_US.UTF-8"
EOF
locale-gen
echo "Locales configurados."

echo "Configurando archivos de configuración del sistema..."
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=es" > /etc/vconsole.conf
echo "FONT=ter-v32n" >> /etc/vconsole.conf
echo "Archivos de configuración del sistema actualizados."

# Configuración para nuevos usuarios (Español)
echo "Configurando el entorno para nuevos usuarios..."
mkdir -p /etc/skel/.config

echo "LANG=es_ES.UTF-8" > /etc/skel/.config/locale.conf
echo "KEYMAP=es" > /etc/skel/.config/vconsole.conf
echo "FONT=ter-v32n" >> /etc/skel/.config/vconsole.conf
echo "FONT_MAP=UTF-8" >> /etc/skel/.config/vconsole.conf
echo "Configuración para nuevos usuarios completada."

# Configuración de X11 para el teclado español
echo "Configurando X11 para el teclado español..."
mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/00-keyboard.conf << EOF
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "es"
EndSection
EOF
echo "Configuración de X11 completada."

# Asegurar que los nuevos usuarios carguen su configuración
echo "Asegurando que los nuevos usuarios carguen su configuración..."
echo "[ -f ~/.config/locale.conf ] && . ~/.config/locale.conf" >> /etc/skel/.bash_profile
echo "[ -f ~/.config/vconsole.conf ] && . ~/.config/vconsole.conf" >> /etc/skel/.bash_profile

echo "Idioma para los usuarios configurado en español completado."

# Instalación de los manuales
install() {
    local option="$1"
    if ! pacman -Qi $option > /dev/null 2>&1; then
    sudo pacman -S --noconfirm $option
  fi
}

install "man-pages"
install "man-db"
echo "Instalado los manuales"

sudo rm -f "$0"
exit 0
