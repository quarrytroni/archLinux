#!/bin/bash

# Script para diagnosticar problemas de arranque en ArchLinux
# Este script debe ejecutarse desde el entorno chroot del sistema instalado

# Verificar si se está ejecutando como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

echo "=== DIAGNÓSTICO DE PROBLEMAS DE ARRANQUE ARCHLINUX ==="
echo ""

# 1. Verificar logs del sistema
echo "1. REVISANDO LOGS DEL SISTEMA..."
echo "Journal del último arranque:"
if [ -d /var/log/journal ]; then
    journalctl -b -1 --priority=3 --no-pager | tail -20
else
    echo "No hay journal persistente, revisando dmesg..."
    dmesg | grep -i "error\|fail\|warn" | tail -10
fi
echo ""

# 2. Verificar configuración de GRUB
echo "2. CONFIGURACIÓN ACTUAL DE GRUB:"
cat /etc/default/grub | grep -E "^(GRUB_CMDLINE_LINUX|GRUB_DEFAULT|GRUB_TIMEOUT)"
echo ""

# 3. Verificar dispositivos de video detectados
echo "3. DISPOSITIVOS DE VIDEO DETECTADOS:"
lspci | grep -i vga
echo ""

# 4. Verificar módulos de kernel cargados relacionados con video
echo "4. MÓDULOS DE VIDEO CARGADOS:"
lsmod | grep -E "(amdgpu|radeon|i915|nouveau|nvidia)"
echo ""

# 5. Verificar errores de DRM (Direct Rendering Manager)
echo "5. ERRORES DRM:"
dmesg | grep -i "drm\|hdmi\|display" | tail -10
echo ""

# 6. Verificar salidas de video disponibles
echo "6. SALIDAS DE VIDEO DISPONIBLES:"
if [ -d /sys/class/drm ]; then
    for connector in /sys/class/drm/card*-*; do
        if [ -e "$connector/status" ]; then
            echo "$(basename $connector): $(cat $connector/status)"
        fi
    done
else
    echo "No se encontró /sys/class/drm"
fi
echo ""

# 7. Verificar configuración de mkinitcpio
echo "7. CONFIGURACIÓN DE MKINITCPIO:"
grep -E "^(MODULES|HOOKS)" /etc/mkinitcpio.conf
echo ""

# 8. Verificar initramfs
echo "8. IMAGENES INITRAMFS:"
ls -la /boot/initramfs*.img
echo ""

# 9. Sugerencias de parámetros de kernel
echo "9. PARÁMETROS DE KERNEL SUGERIDOS PARA TU CONFIGURACIÓN:"
echo "Basándome en tu hardware detectado, prueba con estos parámetros:"

if lspci | grep -qi amd; then
    echo "Para AMD Radeon:"
    echo "  - amdgpu.dc=0 (deshabilita Display Core)"
    echo "  - video=HDMI-A-1:e (forzar HDMI)"
    echo "  - radeon.modeset=1 (para GPUs antiguas)"
fi

if lspci | grep -qi intel; then
    echo "Para Intel:"
    echo "  - i915.modeset=1"
    echo "  - video=HDMI-A-1:e"
fi

echo ""
echo "Para añadir parámetros al arranque:"
echo "1. Edita /etc/default/grub"
echo "2. Modifica GRUB_CMDLINE_LINUX_DEFAULT"
echo "3. Ejecuta: grub-mkconfig -o /boot/grub/grub.cfg"
echo ""

# 10. Crear script de recuperación
echo "10. CREANDO SCRIPT DE RECUPERACIÓN..."
cat > /root/recuperar_video.sh << 'EOF'
#!/bin/bash
echo "Intentando recuperar el video..."
# Forzar reconexión de HDMI
for card in /sys/class/drm/card*; do
    if [ -d "$card" ]; then
        echo "detected" > "$card/card0-HDMI-A-1/status" 2>/dev/null || true
    fi
done
# Reiniciar servicio de display
systemctl restart systemd-logind 2>/dev/null || true
echo "Hecho. Prueba cambiar a tty2 con Ctrl+Alt+F2"
EOF

chmod +x /root/recuperar_video.sh

echo "Script de recuperación creado en /root/recuperar_video.sh"
echo ""
echo "=== DIAGNÓSTICO COMPLETADO ==="
echo ""
echo "PASOS RECOMENDADOS:"
echo "1. Revisa los errores mostrados arriba"
echo "2. Añade los parámetros de kernel sugeridos"
echo "3. Si el sistema arranca pero sin imagen, ejecuta /root/recuperar_video.sh"
echo "4. Considera probar diferentes cables o puertos HDMI"