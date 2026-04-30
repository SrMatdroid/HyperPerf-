#!/sbin/sh
##########################################################################################
#
# HyperPerf+ - Magisk Module Installer Script
# Dispositivo: Universal (Snapdragon / MediaTek
# Autor: @srmatdroid
# Versión: v1.0 stable
# Licencia: GPLv3
#
##########################################################################################

SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=true
LATESTARTSERVICE=true
SKIPUNZIP=0

##########################################################################################
# REPLACE LIST
##########################################################################################

REPLACE="
"

##########################################################################################
# PRINT MODNAME (Cabecera del instalador)
##########################################################################################

print_modname() {
  ui_print " "
  ui_print "  ╔═══════════════════════════════════════════════════════════════╗"
  ui_print "  ║                                                               ║"
  ui_print "  ║                                                               ║"
  ui_print "  ║                                                               ║"
  ui_print "  ║                   HyperPerf+ v1   stable                     ║"
  ui_print "  ║          Optimización para HyperOS / MIUI / AOSP              ║"
  ui_print "  ║                                                               ║"
  ui_print "  ║                       Dispositivo: Universal                  ║"
  ui_print "  ║              configurado para: Snapdragon por defecto         ║"
  ui_print "  ║              (configurar post-fs-data para MTK)        ║"
  ui_print "  ║                                                               ║"
  ui_print "  ║                     @srmatdroid®  •  2026/GPLv3               ║"
  ui_print "  ║ https://github.com/SrMatdroid/Hyper-Vulkan-Dynamic-Switcher   ║"
  ui_print "  ╚═══════════════════════════════════════════════════════════════╝"
  ui_print " "
}

##########################################################################################
# Instalación principal
##########################################################################################

on_install() {
  ui_print "  ┌───────────────────────────────────────────────────────────────┐"
  ui_print "  │                      📱 DISPOSITIVO                           │"
  ui_print "  └───────────────────────────────────────────────────────────────┘"
  ui_print "  "
  ui_print "     • Modelo      : $(getprop ro.product.model 2>/dev/null || echo "Desconocido")"
  ui_print "     • Marca       : $(getprop ro.product.brand 2>/dev/null || echo "Desconocida")"
  ui_print "     • Android     : $(getprop ro.build.version.release 2>/dev/null || echo "Desconocido")"
  ui_print "     • SDK         : $(getprop ro.build.version.sdk 2>/dev/null || echo "Desconocido")"
  ui_print "     • Kernel      : $(uname -r 2>/dev/null || echo "Desconocido")"
  ui_print "     • Arquitectura: $(getprop ro.product.cpu.abi 2>/dev/null || echo "Desconocida")"
  
  # Detectar GPU
  GPU=$(getprop ro.hardware.egl 2>/dev/null || echo "Desconocida")
  ui_print "     • GPU         : $GPU"
  ui_print "  "
  
  ui_print "  ┌───────────────────────────────────────────────────────────────┐"
  ui_print "  │                      ⚙️  MÓDULO                               │"
  ui_print "  └───────────────────────────────────────────────────────────────┘"
  ui_print "  "
  ui_print "     ✅ Modo universal activado"
  ui_print "     ✅ Optimizaciones adaptativas para HyperOS/MIUI/AOSP"
  ui_print "     ✅ WebUI integrada para control en tiempo real"
  ui_print "  "
  
  ui_print "  ┌───────────────────────────────────────────────────────────────┐"
  ui_print "  │                      📦 INSTALANDO                            │"
  ui_print "  └───────────────────────────────────────────────────────────────┘"
  ui_print "  "
  
  # Crear estructura de directorios
  ui_print "     • Creando directorios..."
  mkdir -p $MODPATH/webroot
  mkdir -p $MODPATH
  
  # Extraer archivos
  ui_print "     • Extrayendo archivos del módulo..."
  unzip -o "$ZIPFILE" '*' -d $MODPATH >&2
  
  # Verificar archivos esenciales
  if [ -f "$MODPATH/post-fs-data.sh" ]; then
    ui_print "     ✅ post-fs-data.sh instalado"
    chmod 755 $MODPATH/post-fs-data.sh
  else
    ui_print "     ❌ ERROR: post-fs-data.sh no encontrado"
    abort "     ❌ Instalación fallida - Archivo faltante"
  fi
  
  if [ -f "$MODPATH/service.sh" ]; then
    ui_print "     ✅ service.sh instalado"
    chmod 755 $MODPATH/service.sh
  else
    ui_print "     ❌ ERROR: service.sh no encontrado"
    abort "     ❌ Instalación fallida - Archivo faltante"
  fi
  
  # Verificar WebUI
  if [ -f "$MODPATH/webroot/index.html" ]; then
    ui_print "     ✅ WebUI (index.html) instalada"
    chmod 644 $MODPATH/webroot/index.html
  else
    ui_print "     ⚠️  WebUI no encontrada - el control gráfico no estará disponible"
  fi
  
  # Verificar y crear system.prop si no existe
  if [ ! -f "$MODPATH/system.prop" ]; then
    ui_print "     • Creando system.prop por defecto..."
    echo "# HyperPerf+ - System Properties" > $MODPATH/system.prop
    echo "ro.hyperperf.version=v1" >> $MODPATH/system.prop
    echo "ro.hyperperf.universal=true" >> $MODPATH/system.prop
  fi
  
  ui_print "     ✅ Permisos configurados correctamente"
  ui_print "  "
  
  ui_print "  ┌───────────────────────────────────────────────────────────────┐"
  ui_print "  │                      🎮 CONFIGURACIÓN                         │"
  ui_print "  └───────────────────────────────────────────────────────────────┘"
  ui_print "  "
  ui_print "     • Kernel       : ZRAM, scheduler, governor, read-ahead"
  ui_print "     • GPU          : Adreno turbo, LRZ, mem pool, HWUI renderer"
  ui_print "     • Red          : TCP congestion (BBR), buffers, fast open"
  ui_print "     • Audio        : HiFi BT, LDAC, resampler, offload"
  ui_print "     • MIUI/HyperOS : SPTM, cloud overrides, blur desactivado"
  ui_print "     • Animaciones  : Escalas personalizables"
  ui_print "     • Dalvik/ART   : dex2oat threads, filtro speed, heap"
  ui_print "     • Cámara       : Fast launch, HFR perf"
  ui_print "     • Térmica      : Límites configurables"
  ui_print "     • WebUI        : Control total en tiempo real"
  ui_print "  "
  
  ui_print "  ┌───────────────────────────────────────────────────────────────┐"
  ui_print "  │                      🌐 WEBUI                                 │"
  ui_print "  └───────────────────────────────────────────────────────────────┘"
  ui_print "  "
  ui_print "     📱 Accede desde la app de Magisk/KernelSU > Módulos > HyperPerf+"
  ui_print "     🔧 Pestaña KERNEL: ZRAM, swappiness, scheduler, governor, read-ahead"
  ui_print "     🛠️  Pestaña TWEAKS: GPU, audio, red, animaciones, MIUI, cámara, VM"
  ui_print "     💾 Los cambios se aplican en caliente y se guardan para el reinicio"
  ui_print "  "
  
  ui_print "  ┌───────────────────────────────────────────────────────────────┐"
  ui_print "  │                      ✅ INSTALACIÓN COMPLETA                  │"
  ui_print "  └───────────────────────────────────────────────────────────────┘"
  ui_print "  "
  ui_print "     📌 Archivos instalados:"
  ui_print "        • /data/adb/modules/sr.mat/post-fs-data.sh"
  ui_print "        • /data/adb/modules/sr.mat/service.sh"
  ui_print "        • /data/adb/modules/sr.mat/webroot/index.html"
  ui_print "        • /data/adb/modules/sr.mat/module.prop"
  ui_print "  "
  ui_print "     📌 Para verificar funcionamiento:"
  ui_print "        • Abre la WebUI desde Magisk/KernelSU"
  ui_print "        • Termux: getprop debug.performance.tuning"
  ui_print "        • Termux: cat /proc/sys/net/ipv4/tcp_congestion_control"
  ui_print "        • Logs: logcat -s HyperVulkan"
  ui_print "  "
  ui_print "     ⚠️  Reinicia el dispositivo para aplicar todos los cambios"
  ui_print "     💡 Usa la WebUI para configurar cada opción a tu gusto"
  ui_print "  "
}

##########################################################################################
# SET PERMISSIONS (Permisos de archivos)
##########################################################################################

set_permissions() {
  ui_print "  ┌───────────────────────────────────────────────────────────────┐"
  ui_print "  │                      🔒 PERMISOS                              │"
  ui_print "  └───────────────────────────────────────────────────────────────┘"
  ui_print "  "
  
  # Permisos generales del módulo
  set_perm_recursive "$MODPATH" 0 0 0755 0644
  
  # Scripts ejecutables
  set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
  set_perm "$MODPATH/service.sh" 0 0 0755
  
  # WebUI
  set_perm "$MODPATH/webroot/index.html" 0 0 0644
  
  # Archivo de propiedades (opcional)
  [ -f "$MODPATH/system.prop" ] && set_perm "$MODPATH/system.prop" 0 0 0644
  
  ui_print "     ✅ Permisos aplicados correctamente"
  ui_print "  "
}

##########################################################################################
# POST INSTALL (Mensaje final)
##########################################################################################

post_install() {
  ui_print "  ╔═══════════════════════════════════════════════════════════════╗"
  ui_print "  ║                        🎉 ¡ÉXITO! 🎉                          ║"
  ui_print "  ║                                                               ║"
  ui_print "  ║     HyperPerf+ v1 ha sido instalado correctamente             ║"
  ui_print "  ║                                                               ║"
  ui_print "  ║     🔄 Reinicia tu dispositivo para activar el módulo         ║"
  ui_print "  ║     🌐 Usa la WebUI para configurar todo a tu gusto           ║"
  ui_print "  ║                                                               ║"
  ui_print "  ║     📱 Desarrollado por @srmatdroid                           ║"
  ui_print "  ║     🎮 Compatible con Snapdragon | MediaTek           ║"
  ui_print "  ║     ⚙️     HyperOS / MIUI / AOSP                                 ║"
  ui_print "  ║     🐢 PARA MTK REVISA POST-FS-DATA ANTES DE INSTALAR  ║"
  ui_print "  ╚═══════════════════════════════════════════════════════════════╝"
  ui_print " "
}

# Ejecutar instalación, permisos y mensaje final
on_install
set_permissions
post_install