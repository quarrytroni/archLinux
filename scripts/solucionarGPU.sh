#!/bin/bash

# Script para solucionar el problema de arranque con doble GPU AMD
# Este script debe ejecutarse desde el entorno chroot del sistema instalado

# Verificar si se está ejecutando como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

echo "=== SOLUCIÓN PARA PROBLEMA DE DOBLE GPU AMD ==="
echo ""

# EXPLICACIÓN DEL PROBLEMA
echo "¿POR QUÉ OCURRE ESTE PROBLEMA?"
echo "1. Tienes dos GPUs AMD que compiten por controlar las salidas de video:"
echo "   - GPU Dedicada: AMD Radeon RX 6600/6600 XT (Navi 23) en PCI 03:00.0"
echo "   - GPU Integrada: AMD Raphael en PCI 13:00.0"
echo ""
echo "2. El kernel está cargando el driver amdgpu para ambas GPUs simultáneamente"
echo "3. El driver detecta dos tarjetas pero no puede asignar correctamente"
echo "   las salidas HDMI/DisplayPort a la GPU correcta"
echo "4. Por eso ves 'Cannot find any crtc or sizes' en los logs"
echo "5. El resultado: pantalla negra cuando conectas HDMI a la gráfica dedicada"
echo ""

# SOLUCIÓN PROPUESTA
echo "=== SOLUCIÓN: FORZAR GPU PRIMARIA ==="
echo ""
echo "OPCIÓN A: Forzar el uso de la GPU dedicada (RX 6600) - RECOMENDADA"
echo "OPCIÓN B: Deshabilitar la GPU integrada completamente"
echo "OPCIÓN C: Forzar el uso de la GPU integrada (Raphael)"
echo ""

echo "¿Qué opción prefieres? (A/B/C): "
read opcion

case $opcion in
    A|a)
        echo "Seleccionado: Forzar GPU dedicada RX 6600"
        # Parámetros para forzar la GPU dedicada
        PARAMS="loglevel=3 quiet amdgpu.dc=1 amdgpu.dpm=1 video=HDMI-A-1:e"
        # Deshabilitar GPU integrada parcialmente
        PARAMS="$PARAMS pci=nocrs"  # No usar PCI CRS para la integrada
        ;;
    B|b)
        echo "Seleccionado: Deshabilitar GPU integrada"
        # Deshabilitar completamente la GPU integrada
        PARAMS="loglevel=3 quiet video=efifb:off amdgpu.dc=1"
        # Añadir blacklisting de GPU integrada
        echo "blacklist amdgpu" > /etc/modprobe.d/disable-igpu.conf
        echo "options amdgpu si_support=0" >> /etc/modprobe.d/disable-igpu.conf
        ;;
    C|c)
        echo "Seleccionado: Forzar GPU integrada Raphael"
        # Parámetros para forzar la GPU integrada
        PARAMS="loglevel=3 quiet amdgpu.dc=1 video=HDMI-A-2:e"
        # Deshabilitar GPU dedicada
        echo "blacklist amdgpu" > /etc/modprobe.d/disable-dgpu.conf
        echo "options amdgpu si_support=0" >> /etc/modprobe.d/disable-dgpu.conf
        ;;
    *)
        echo "Opción no válida, usando configuración por defecto (GPU dedicada)"
        PARAMS="loglevel=3 quiet amdgpu.dc=1 video=HDMI-A-1:e"
        ;;
esac

echo ""
echo "Aplicando configuración con parámetros: $PARAMS"

# Hacer backup de grub
cp /etc/default/grub /etc/default/grub.backup

# Actualizar GRUB
sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"$PARAMS\""/" /etc/default/grub

echo ""
echo "Configuración actualizada en /etc/default/grub:"
grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub

echo ""
echo "Regenerando configuración de GRUB..."
grub-mkconfig -o /boot/grub/grub.cfg

if [ $? -eq 0 ]; then
    echo "GRUB actualizado correctamente"
else
    echo "Error al actualizar GRUB"
    exit 1
fi

echo ""
echo "=== CONFIGURACIÓN ADICIONAL PARA DOBLE GPU ==="

# Crear configuración específica para amdgpu
cat > /etc/modprobe.d/amdgpu.conf << EOF
# Configuración para optimizar doble GPU AMD
options amdgpu si_support=1
options amdgpu cik_support=1
options amdgpu dc=1
options amdgpu dpm=1
options amdgpu audio=1
EOF

echo "Configuración de modprobe creada en /etc/modprobe.d/amdgpu.conf"

# Si se eligió deshabilitar una GPU, mostrar advertencia
if [ "$opcion" = "B" ] || [ "$opcion" = "b" ]; then
    echo ""
    echo "⚠️  ADVERTENCIA: Has deshabilitado la GPU integrada"
    echo "   Si tienes problemas, ejecuta este script nuevamente y selecciona otra opción"
fi

# Crear script de diagnostico post-arranque
cat > /root/diagnostico-video.sh << 'EOF'
#!/bin/bash
echo "=== DIAGNÓSTICO POST-ARRANQUE ==="
echo "Estado de las GPUs AMD:"
lspci | grep -i amd
echo ""
echo "Módulos cargados:"
lsmod | grep amdgpu
echo ""
echo "Salidas de video:"
for connector in /sys/class/drm/card*-*; do
    if [ -e "$connector/status" ]; then
        echo "$(basename $connector): $(cat $connector/status)"
    fi
done
echo ""
echo "Logs recientes de DRM:"
dmesg | grep -i "drm\|amdgpu" | tail -10
EOF

chmod +x /root/diagnostico-video.sh

echo ""
echo "=== RESUMEN DE LA SOLUCIÓN ==="
echo "1. Se han aplicado parámetros específicos para tu configuración de doble GPU"
echo "2. Se ha creado /root/diagnostico-video.sh para verificar el estado post-arranque"
echo "3. Prueba reiniciar el sistema con el HDMI conectado a la gráfica dedicada"
echo "4. Si aún hay problemas, ejecuta /root/diagnostico-video.sh desde un tty"
echo ""
echo "RECOMENDACIONES ADICIONALES:"
echo "- Asegúrate de tener el último firmware AMD: pacman -S linux-firmware"
echo "- Considera instalar mesa si vas a usar aplicaciones gráficas: pacman -S mesa"
echo "- Si usas KDE, instala: pacman -S xf86-video-amdgpu"
echo ""
echo "¿Deseas reiniciar ahora? (s/N): "
read respuesta
if [ "$respuesta" = "s" ] || [ "$respuesta" = "S" ]; then
    echo "Reiniciando en 5 segundos..."
    sleep 5
    reboot
else
    echo "Recuerda reiniciar manualmente para probar los cambios"
fi