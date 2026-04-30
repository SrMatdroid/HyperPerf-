#!/system/bin/sh
MODDIR="${0%/*}"
# ╔══════════════════════════════════════════════════════════════╗
# ║                    HYPERVULKAN ENGINE v4  @srmatdroid GPLv3║
# ║         Módulo de optimización para HyperOS / MIUI           ║
# ║              Dispositivo objetivo: Universal                 ║
# ║            Configurado para: Snapdragon por defecto          ║
# ║                                                              ║
# ║  ☝️ PARA MEDIATEK :                                  ║
# ║     Lee los comentarios [MTK]  en cada línea       ║
# ║     Comenta las líneas específicas de Snapdragon             ║
# ║                                                              ║
# ║  AVISO: Si algo falla tras instalar este módulo, lee los     ║
# ║  comentarios de cada sección para identificar qué línea      ║
# ║  puede estar causando el problema y coméntala con #          ║
# ║                                                              ║
# ║  NOTA: Este script aplica OPTIMIZACIONES BASE FIJAS.         ║
# ║  Las props dinámicas (Vulkan/OpenGL) son gestionadas por     ║
# ║  service.sh para evitar conflictos.                          ║
# ╚══════════════════════════════════════════════════════════════╝

attempts=0
while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ]; do
    sleep 2
    attempts=$((attempts + 1))
    if [ $attempts -gt 90 ]; then
        break  # Fallback tras 3 minutos
    fi
done
log -t SAFE "--- [HYPERVULKAN ENGINE v4]: Iniciando Optimizacion BASE ---"

# Función auxiliar para aplicar props de forma segura
set_prop() {
    if command -v resetprop >/dev/null 2>&1; then
        resetprop "$1" "$2"
    else
        setprop "$1" "$2"
    fi
}
# ═══════════════════════════════════════════════════════════════
# VBMETA / BOOT INTEGRITY
# Simula un estado de arranque verificado y seguro.
# Necesario para pasar SafetyNet/Play Integrity con root activo.
# ⚠ No modificar estos valores, son específicos del dispositivo.
#  [UNIVERSAL] Funciona en todos los procesadores
# ═══════════════════════════════════════════════════════════════
# IDENTIDAD DE LA COMPILACIÓN Y CERTIFICACIÓN ---
#es vital que el fingerprint no contenga "test-keys" 
#set_prop ro.build.tags release-keys
#set_prop ro.build.type user
#set_prop ro.build.display.id "$(getprop ro.build.id) release-keys"
set_prop ro.debuggable 0
set_prop ro.secure 1
set_prop ro.adb.secure 1
# ESTADO DEL BOOTLOADER Y VERIFIED BOOT (AVB) ---
set_prop ro.boot.verifiedbootstate green
set_prop ro.boot.flash.locked 1
set_prop ro.boot.veritymode enforcing
set_prop ro.secureboot.lockstate locked
set_prop ro.boot.vbmeta.device_state locked
set_prop vendor.boot.vbmeta.device_state locked
set_prop ro.boot.vbmeta.avb_version 2.0
# METADATOS DE VBMETA (CONGRUENCIA) ---
set_prop ro.boot.vbmeta.size 4096
set_prop ro.boot.vbmeta.hash_alg sha256
set_prop ro.boot.vbmeta.digest fa7c7e4466b8c58315a969969e474479379dabff62af7a18ab386eefaa823bd8
# INDICADORES DE GARANTÍA (WARRANTY VOID) ---
set_prop ro.boot.warranty_bit 0
set_prop ro.vendor.boot.warranty_bit 0
set_prop ro.vendor.warranty_bit 0
set_prop ro.warranty_bit 0
# SIMULACIÓN DE SEGURIDAD PARA GOOGLE PAY ---
# Forzamos a que el sistema crea que el parche de seguridad es reciente
#set_prop ro.build.version.security_patch 2026-03-01
# Ocultamos indicios de depuración en el kernel
set_prop ro.kernel.android.checkjni 0
set_prop ro.kernel.checkjni 0
# ═══════════════════════════════════════════════════════════════
# BLUR DESACTIVADO
# Desactiva el desenfoque de fondo en la UI (Control Center,
# recientes, notificaciones). Mejora el rendimiento de
# SurfaceFlinger al eliminar un paso de composición costoso.
# ⚠ Si quieres blur, comenta todas las líneas de esta sección.
# ☝️ [UNIVERSAL] Funciona en todos los procesadores
# ═══════════════════════════════════════════════════════════════
set_prop ro.surface_flinger.supports_background_blur 1                     # Desactiva soporte de blur en SurfaceFlinger(activado para mantener notificaciones trasparentes dentro de juego )
set_prop ro.sf.blurs_are_expensive 1                                       # Trata el blur como costoso (Android AOSP)
set_prop persist.sys.sf.native_blur_supported 0                            # Desactiva blur nativo de SF
set_prop persist.sys.sf.disable_blurs 1                                    # Fuerza desactivar blur de ventanas/capas
set_prop persist.sys.sf.disable_blur 1                                     # Alias usado por algunas ROMs
set_prop persist.sys.miui.blur_supported true                             # Desactiva blur en la capa MIUI/HyperOS(activado para mantener notificaciones trasparentes dentro de juego )
set_prop persist.sysui.disable_blur true                                   # Flag extra para SystemUI en ROMs modificadas
set_prop persist.sys.background_blur_supported true                      # Compatibilidad adicional en capas OEM(activado para mantener notificaciones trasparentes dentro de juego )
set_prop persist.sys.miui_optimization false
set_prop persist.miui.extm.on 1
set_prop persist.sys.miui.game_float_notification 1
# Refuerzo runtime: algunas ROMs reescriben estos valores tras el arranque.
settings put global disable_window_blurs 1 2>/dev/null                     # Desactiva blur de ventanas vía settings globales
settings put secure background_blur_enable 0 2>/dev/null                   # Desactiva blur de fondo en settings de usuario
settings put secure miui_blur_enable 0 2>/dev/null                         # Desactiva blur MIUI en settings de usuario
# ═══════════════════════════════════════════════════════════════
# SISTEMA BASE: CPU / SCHEDULER / I/O / MEMORIA
# Optimizaciones generales del runtime, scheduler y memoria.
#  [UNIVERSAL] Funciona en todos los procesadores
# ═══════════════════════════════════════════════════════════════
set_prop persist.sys.dalvik.vm.lib.2 libart.so                            # Fuerza el uso de ART como runtime (por defecto en Android moderno)
set_prop ro.config.hw_quickpoweron 1                                       # Encendido rápido de hardware al salir de suspensión
set_prop persist.sys.perf.topAppRenderThreadBoost.enable true              # Boost de CPU al hilo de render de la app en primer plano
set_prop persist.sys.job_delay true                                        # Retrasa trabajos en segundo plano para priorizar la app activa
set_prop ro.config.max_starting_bg 4                                      # Número máximo de procesos en background al arrancar apps
set_prop persist.sys.use_boot_compact true                                 # Compacta memoria al arranque para liberar RAM rápidamente
set_prop persist.sys.perf.debug 0                                          # Desactiva el modo debug del subsistema de rendimiento
set_prop persist.sampling_profiler 0                                       # Desactiva el sampling profiler (reduce overhead de CPU)
set_prop ro.config.fha_enable true                                         # Activa la aceleración hardware rápida (FHA) del sistema
set_prop persist.sys.purgeable_assets 0                                    # Evita que el sistema descarte assets en memoria para reciclaje forzado
# ☝️ [MTK/EXYNOS] La siguiente línea es específica de Qualcomm FastCV
# Si tienes MTK o Exynos, COMENTA esta línea (pon # al principio)
set_prop ro.vendor.extension_library /vendor/lib/rfsa/adsp/libfastcvopt.so # [SNAPDRAGON] Activa FastCV - COMENTAR en MTK/Exynos
# --- Memoria y presión de caché ---
#set_prop persist.sys.vm.swappiness 10                                     # Reduce la tendencia del kernel a usar swap (10 = prioriza mantener datos en RAM)
#set_prop vm.vfs_cache_pressure 30                                         # Reduce la presión sobre la caché de sistema de ficheros (30 = retiene más páginas en RAM)
# --- I/O Prefetch (iorapd) ---
set_prop ro.iorapd.enable true                                            # Activa el prefetch de I/O predictivo para apps (iorapd)
set_prop persist.iorapd.enable true                                       # Hace persistente la activación de iorapd tras reinicios
set_prop ro.iorapd.perfetto.enable true                                   # Activa el trazado Perfetto para el análisis de I/O predictivo
# --- Límites de background (comentados, ajustar según dispositivo) ---
set_prop ro.vendor.qti.sys.fw.bg_apps_limit 64                           # [SNAPDRAGON] Límite de apps en background - COMENTAR en MTK/Exynos
set_prop ro.sys.fw.bg_apps_limit 64                                      # Límite global de apps en background
# set_prop ro.config.low_ram.threshold_gb 2                                # Umbral en GB para activar el modo low RAM
# --- Térmica (comentada por defecto, ajustar según dispositivo) ---
set_prop ro.thermal.warm_limit 600                                        # Temperatura de aviso térmico en décimas de grado (600 = 60°C)
set_prop ro.thermal.cool_limit 500                                        # Temperatura de enfriamiento activo en décimas de grado (500 = 50°C)
set_prop persist.sys.thermal.config 0                                     # Desactiva el perfil térmico personalizado del vendor
# ═══════════════════════════════════════════════════════════════
# MIUI / HYPEROS - OPTIMIZACIONES GLOBALES
# Props específicas de la capa MIUI/HyperOS.
# ☝️ [UNIVERSAL] Funciona en MIUI/HyperOS de cualquier procesador
# ═══════════════════════════════════════════════════════════════
set_prop view.draw_optimize true
set_prop view.scroll_optimize true
set_prop pm.dexopt.boot verify 
set_prop ro.config.cpu_level_vibrant 1
#set_prop persist.sys.miui.sf.vsync 1                                     # Habilita VSync en SurfaceFlinger para MIUI
set_prop persist.sys.ui.hw true                                            # Fuerza aceleración hardware en la UI del sistema
set_prop video.accelerate.hw 1                                             # Activa aceleración hardware para reproducción de vídeo
set_prop persist.sys.miui_booster 1                                        # Activa el booster de rendimiento de MIUI
set_prop persist.sys.smart_power 0                                         # Desactiva la gestión de energía inteligente (puede limitar rendimiento)
set_prop persist.sys.doze_powersave true                                   # Mantiene el ahorro de energía en Doze mode
set_prop persist.miui.speed_up_freeform true                               # Acelera ventanas en modo freeform
#set_prop persist.miui.migt.enable 1                                        # Activa el Game Turbo de MIUI (MIGT)
#set_prop persist.miui.migt.game_boost 1                                    # Activa el boost específico para juegos dentro de MIGT
set_prop persist.sys.miui_anim_res_direct 1                                # Renderizado directo de recursos de animación
#set_prop persist.sys.miui_prio_render 1                                    # Prioridad alta al hilo de render de MIUI
set_prop persist.sys.stability.smartfocusio on                             # Activa el Smart Focus I/O de MIUI para priorizar I/O de la app en primer plano
set_prop persist.miui.home_reuse_leash true                                # Permite reutilizar el proceso del launcher para reducir el tiempo de vuelta al inicio
set_prop persist.miui.extm.dm_opt.enable true                              # Activa la optimización de memoria dinámica para almacenamiento externo en MIUI
set_prop ro.HOME_APP_ADJ 1                                                 # Ajuste OOM del launcher (1 = alta prioridad, el sistema lo destruye menos)
# set_prop persist.sys.freeform_support true                               # Soporte de ventanas en modo freeform (experimental)
# --- MIUI SPTM / Shell / Cloud overrides ---
set_prop persist.sys.mirim.enable false                                    # Desactiva MIRIM (módulo de renderizado en espejo de MIUI, usado en capas de animación avanzadas)
set_prop persist.sys.enable_ignorecloud_rtmode true                        # Ignora los overrides de cloud para el modo RT de MIUI (evita que la nube cambie parámetros de rendimiento)
set_prop ro.miui.shell_anim_enable_fcb false                               # Desactiva el Frame Cache Buffer en las animaciones del shell de MIUI (reduce latencia visual)
set_prop persist.sys.miui_slow_startup_mode.enable false                   # Desactiva el modo de arranque lento de MIUI (no limita recursos al lanzar apps)
set_prop persist.sys.miui_sptm_new.enable false                            # Desactiva el nuevo módulo SPTM (System Performance & Thermal Management) de MIUI
set_prop persist.sys.miui_sptm.enable false                                # Desactiva el módulo SPTM clásico de MIUI (el rendimiento térmico lo gestiona el módulo externo)
set_prop persist.sys.miui_sptm.ignore_cloud_enable true                    # Fuerza que SPTM ignore los overrides de configuración desde la nube de Xiaomi
set_prop persist.sys.miui_sptm_animation.enable false                      # Desactiva las animaciones propias del subsistema SPTM (evita overhead visual añadido)
# ═══════════════════════════════════════════════════════════════
# GPU / VULKAN - RENDERING CORE (SOLO PROPS ESTÁTICAS)
# Optimizaciones de GPU y el pipeline de renderizado.
# ⚠ Si aparecen glitches visuales o pantalla negra en alguna
#   app, revisa primero esta sección.
# ⚠ NOTA: Las props de renderer (skiavk/skiagl) y render_thread
#   son GESTIONADAS DINÁMICAMENTE por service.sh para el switcher.
# ☝️ [SNAPDRAGON] Esta sección está optimizada para Adreno GPU
# ☝️ [MTK] Para GPU Mali, muchas props son diferentes o no existen
# ☝️ [EXYNOS] Para GPU Mali o Xclipse, muchas props son diferentes
# ═══════════════════════════════════════════════════════════════
# --- Adreno Core ---
# ☝️ [MTK/EXYNOS] La siguiente línea es específica de Adreno GPU
#    En MTK/Exynos, COMENTA esta línea (no existe ro.adreno.agp.turbo)
set_prop ro.adreno.agp.turbo 1                                             # [SNAPDRAGON] Modo turbo Adreno - COMENTAR en MTK/Exynos
# ☝️ [MTK/EXYNOS] UBWC es compresión exclusiva de Adreno
# En MTK/Exynos, COMENTA las 2 líneas siguientes
#set_prop debug.gralloc.enable_fb_ubwc 1                                    # [SNAPDRAGON] Activa UBWC (compresión de framebuffer Adreno) - COMENTAR en MTK/Exynos
#set_prop debug.gralloc.gfx_ubwc_disable 0                                  # [SNAPDRAGON] Confirma UBWC activo (0 = no deshabilitar) - COMENTAR en MTK/Exynos
# --- Renderizado EGL / Framebuffer ---
set_prop debug.egl.hw 1                                                    # Fuerza renderizado EGL por hardware
set_prop persist.sys.force_sw_gles 0                                       # Desactiva el fallback a renderizado GLES por software
set_prop debug.egl.buffercount 4                                           # Número de buffers EGL en la cadena de swap (4 = quad buffering)
set_prop debug.gr.num_framebuffer_frames 3                                 # Número de framebuffers en la cadena de presentación (triple buffering)
#set_prop debug.egl.swapinterval -1                                         # Desactiva el VSync forzado de EGL (-1 = presentación inmediata, puede causar tearing)
# --- Shaders y pipeline ---
#set_prop debug.renderengine.cache_shaders true                             # Cachea shaders compilados para evitar stutters en la primera ejecución
set_prop debug.performance.tuning 1                                        # Activa el modo tuning de rendimiento general del sistema
set_prop debug.gr.texture_swizzle 1
set_prop debug.enable.texture_swizzle 1
set_prop ro.config.low_ram false
set_prop debug.egl.force_mssa 1
set_prop media.stagefright.less-secure true
set_prop dalvik.vm.usejit true
set_prop debug.hwui.render_dirty_regions false                           # Desactiva el redibujado solo de regiones dañadas (puede mejorar estabilidad en algunas ROMs)
set_prop debug.sf.early_phase_offset_ns 500000                           # Offset de fase anticipada de SF en ns (ajuste fino del pipeline de composición)
set_prop debug.sf.early_app_phase_offset_ns 500000                       # Offset de fase anticipada de la app en ns (adelanta el frame antes de que SF lo componga)
# --- Caché de HWUI ---
# Controlan cuánta memoria reserva HWUI para texturas y capas.
# Valores más altos = menos recarga de assets, más RAM usada.
# ☝️ [UNIVERSAL] Las cachés HWUI funcionan en todos los procesadores
# Los valores se pueden ajustar según la RAM del dispositivo
# (8GB = 70-88, 12GB = 88-96, 6GB = 50-70)
#set_prop ro.hwui.texture_cache_size 60                                     # Tamaño de caché de texturas en MB
#set_prop ro.hwui.layer_cache_size 33                                       # Tamaño de caché de capas en MB
#set_prop ro.hwui.r_buffer_cache_size 17                                    # Caché del render buffer en MB
#set_prop ro.hwui.gradient_cache_size 4                                     # Caché de gradientes en MB
#set_prop ro.hwui.path_cache_size 29                                        # Caché de paths vectoriales en MB
#set_prop ro.hwui.drop_shadow_cache_size 8                                  # Caché de sombras en MB
#set_prop ro.hwui.font_cache_size 8                                         # Caché de fuentes en MB
#set_prop debug.hwui.use_hint_manager true                                  # Activa el gestor de hints de HWUI para optimizar la carga de GPU
#set_prop debug.hwui.shader_cache_max_entries 3096                         # Número máximo de entradas en la caché de shaders HWUI (evita recompilación)
#set_prop debug.hwui.shader_cache_size 3097152                             # Tamaño máximo de la caché de shaders HWUI en bytes (2MB)
# --- Adreno avanzado (SNAPDRAGON) ---
# ☝️ [MTK/EXYNOS] Las props debug.adreno.* son exclusivas de Qualcomm Adreno
#    COMENTAR todas en MTK/Exynos
#set_prop debug.adreno.gles.submitframe 1                                  # Fuerza submit de frame en cada draw call (reduce stalls de textura)
set_prop debug.adreno.mem.mb 512                                          # Aumenta el pool de memoria GPU disponible en MB
set_prop debug.adreno.syncobj_timeline 1                                  # Reduce latencia de flush de comandos GPU
set_prop debug.adreno.lrz.enable 1                                        # Activa LRZ de Adreno (compresión de profundidad en baja resolución para culling anticipado)
set_prop debug.adreno.gpu_bimc_clk 1                                      # Reduce stalls entre CPU y GPU durante streaming
# --- Skia ---
# ☝️ [UNIVERSAL] Funciona en todos los procesadores
#set_prop renderthread.skia.reduceopstasksplitting true                     # Reduce el splitting de tareas en el pipeline de Skia (menos overhead)
# --- Composición GPU ---
# NOTA: persist.sys.composition.type NO se fuerza aquí para no interferir
# con el service.sh que lo activa/desactiva según el juego.
#set_prop persist.sys.compose_unit 0                                        # Unidad de composición del pipeline gráfico (0 = valor por defecto del sistema)
# set_prop persist.sys.use_dithering 0                                     # Desactiva el dithering de color (puede reducir calidad visual en gradientes)
# resetprop persist.sys.composition.type gpu                               # [DESACTIVADO] Forzaba composición por GPU ignorando HWC - ROMPE vídeos en redes sociales si se fuerza siempre
#  LAS SIGUIENTES PROPS SON DINÁMICAS (comentadas - las gestiona service.sh)
# set_prop debug.hwui.renderer skiavk                                      # [GESTIONADO POR service.sh] Renderizador HWUI - skiavk = Vulkan, skiagl = OpenGL
# set_prop debug.hwui.render_thread true                                   # [GESTIONADO POR service.sh] Hilo dedicado de renderizado HWUI - Mejora rendimiento en juegos
# set_prop ro.hwui.use_vulkan true                                         # [GESTIONADO POR service.sh] Permite a HWUI usar Vulkan como backend de renderizado
# set_prop debug.vulkan.frame.pacing 1                                     # [GESTIONADO POR service.sh] Sincronización de frames Vulkan para evitar tearing y stuttering
# set_prop debug.hwui.vulkan.use_pipeline_cache true                       # [GESTIONADO POR service.sh] Cachea pipelines Vulkan compilados para reducir stutter inicial
# set_prop debug.hwui.vulkan.enable_shared_image true                      # [GESTIONADO POR service.sh] Permite compartir imágenes entre GPU y CPU en Vulkan
# set_prop debug.hwui.use_vulkan_texture_filtering true                    # [GESTIONADO POR service.sh] Filtrado de texturas vía Vulkan (mejor calidad visual)
# set_prop debug.hwui.fbpipeline true                                      # [GESTIONADO POR service.sh] Pipeline de framebuffer optimizado para Vulkan
# set_prop debug.skia.threaded true                                        # [DESACTIVADO] Ejecuta operaciones de Skia en múltiples hilos (no implementado en service.sh - experimental)
# set_prop debug.cpurend.disable 1                                         # [GESTIONADO POR service.sh] Desactiva renderizado por CPU, fuerza todo a GPU
# set_prop debug.hwui.use_gpu_pixel_buffers true                           # [DESACTIVADO] Usa buffers de píxeles en GPU para operaciones de píxel rápido (no implementado en service.sh)
# set_prop debug.hwui.skip_empty_damage true                               # [GESTIONADO POR service.sh] Salta regiones dañadas vacías (ahorra ciclos de render)
# set_prop debug.hwui.webview_overlays_enabled true                        # [GESTIONADO POR service.sh] Habilita overlays de WebView en el pipeline de composición
set_prop sys.use_fifo_ui true                                            # Usa el scheduler FIFO para el hilo de UI del sistema (máxima prioridad, mejora fluidez de la interfaz)
# set_prop debug.renderengine.vulkan.disable_vblank_wait true              # [GESTIONADO POR service.sh] Elimina espera de VBlank en Vulkan (reduce latencia pero puede causar tearing)
# set_prop debug.perf.vulkan.use_gpu_memcpy 1                              # [DESACTIVADO] Usa copias de memoria aceleradas por GPU en Vulkan (no implementado en service.sh)
# set_prop debug.perf.vulkan.enable_robustness 0                           # [GESTIONADO POR service.sh] Desactiva robustez en Vulkan (menor overhead, más rendimiento)
# set_prop vulkan.pipeline_cache.enabled true                              # [GESTIONADO POR service.sh] Habilita caché global de pipelines Vulkan
# set_prop debug.cpurender true                                            # [DESACTIVADO] Activa renderizado por CPU (uso diagnóstico - no implementado en service.sh)
set_prop ro.media.rescan_on_reboot 0
# ═══════════════════════════════════════════════════════════════
# SURFACEFLINGER / FRAME PACING / DISPLAY
# Control del compositor de pantalla, cadencia de frames y tasa de refresco.
# ⚠ Si el vídeo se ve entrecortado en redes sociales,
#   revisa primero latch_unsignaled (está desactivado por eso).
# ☝️ [UNIVERSAL] Funciona en todos los procesadores
# ═══════════════════════════════════════════════════════════════
#set_prop debug.sf.set_idle_timer_ms 4000                                   # SF espera 4000ms antes de bajar la tasa de refresco por inactividad (debug, anula el ro.*)
set_prop debug.sf.enable_transaction_tracing false                         # Desactiva el tracing de transacciones de SF (reduce overhead de logging)
#set_prop debug.sf.disable_backpressure 1                                   # Deshabilita la backpressure del compositor (SF no espera a la app para presentar)
# resetprop debug.sf.latch_unsignaled 1                                   # [DESACTIVADO] Presentaba frames antes de que el decoder los llenara - ROMPE reproducción de vídeo en Facebook, Telegram, Twitter y otras apps
# set_prop ro.surface_flinger.uclamp.min 205                              # [SNAPDRAGON] Frecuencia mínima de CPU para SF - MTK/EXYNOS puede no soportarlo, comentar si hay problemas
# --- Idle timers de refresco (0 = desactiva la bajada automática de Hz) ---
set_prop ro.surface_flinger.set_idle_timer_ms 0                            # SF no baja la tasa de refresco por inactividad general (evita drops de Hz inesperados)
set_prop ro.surface_flinger.set_touch_timer_ms 0                           # SF no baja la tasa de refresco al perder el touch (evita drops al levantar el dedo)
set_prop ro.surface_flinger.set_display_power_timer_ms 0                   # SF no baja la tasa de refresco por el timer de energía del display
# --- DFPS del vendor ---
#set_prop ro.vendor.dfps.enable false                                       # Desactiva el DFPS dinámico del vendor (usa el control de SF en su lugar)
#set_prop ro.vendor.smart_dfps.enable false                                 # Desactiva el Smart DFPS del vendor (puede interferir con el idle timer manual)
# --- Latencia y respuesta táctil ---
# ☝️ [UNIVERSAL] Funciona en todos los procesadores
set_prop ro.max.fling_velocity 15000                                       # Velocidad máxima de fling (scroll rápido) en píxeles/segundo
set_prop ro.min_pointer_dur 0                                              # Duración mínima del puntero táctil (0 = máxima respuesta)
# ═══════════════════════════════════════════════════════════════
# UNITY GAME SCHEDULER
# Indica al scheduler del kernel qué hilos y librerías son
# de juegos Unity para darles prioridad de CPU.
# ☝️ [UNIVERSAL] Funciona en todos los procesadores con Unity
# ═══════════════════════════════════════════════════════════════
set_prop sched_thread_name UnityMain,UnityGfxDeviceW,UnityMultiRende,UnityPreload,GameThread,RenderThread,RHIThread,AudioThread,WorkerThread,sdkMain,cocos2d,MainThread,GLThread  # Hilos de juego reconocidos para boost de scheduler
set_prop sched_lib_name libunity.so,libUE4.so,libUE5.so,libil2cpp.so,libmono.so,libmonodroid.so,libcocos2dcpp.so,libgdxnatives.so,libSDL2.so,libSDL2main.so,libfmod.so,libfmodstudio.so,libOpenAL.so,libgamesdk.so,libgame.so,libgodot.so,libgodot_android.so,libflutter.so,libxlua.so,liblua.so,libslua.so,libtolua.so  # Librerías Unity, Unreal, Godot, etc. reconocidas para boost de scheduler
set_prop sched_lib_mask_force 255                                          # Máscara de CPUs disponibles para hilos de juego (255 = todos los cores)
set_prop media.stagefright.cache 2048                                      # Caché de Stagefright para media en KB (útil para juegos con muchos assets de audio)
# ═══════════════════════════════════════════════════════════════
# UI/UX - ANIMACIONES E INPUT
# Velocidad de animaciones del sistema y respuesta de entrada.
# ⚠ Si las animaciones se ven raras o muy rápidas, ajusta
#   los tres primeros valores (0.5 = mitad de velocidad stock).
# ☝️ [UNIVERSAL] Funciona en todos los procesadores
# ═══════════════════════════════════════════════════════════════
set_prop persist.sys.window_animation_scale 0.4                            # Velocidad de animaciones de ventana (1.0 = stock, 0.5 = el doble de rápido)
set_prop persist.sys.transition_animation_scale 0.4                       # Velocidad de animaciones de transición entre apps
set_prop persist.sys.animator_duration_scale 0.4                          # Duración general de animaciones del sistema
set_prop persist.sys.miui.anim_sw_threshold 68                            # Umbral de carga de CPU (%) antes de que MIUI pase animaciones a software rendering
set_prop windowsmgr.max_events_per_sec 120                                # Máximo de eventos de input procesados por segundo (ajustado a 120Hz)
set_prop view.scroll_priority 1                                            # Prioridad de hilos de scroll en la cola de input (1 = alta prioridad para scroll fluido)
set_prop ro.input.noresample 1                                             # Desactiva el resampling de eventos táctiles (menor latencia táctil)
# ═══════════════════════════════════════════════════════════════
# RENDIMIENTO DE HILOS / DALVIK
# ☝️ [UNIVERSAL] Funciona en todos los procesadores
# ═══════════════════════════════════════════════════════════════
set_prop dalvik.vm.dex2oat-threads 6                                       # Hilos para compilar apps instaladas con dex2oat
set_prop dalvik.vm.image-dex2oat-threads 6                                 # Hilos para compilar la imagen de arranque (boot image) con dex2oat
set_prop dalvik.vm.boot-dex2oat-threads 4                                  # Hilos para compilar dex en el arranque inicial del sistema
set_prop dalvik.vm.dex2oat-filter speed                                    # Filtro de compilación AOT de ART (speed = compila más código, ejecuta más rápido)
# ═══════════════════════════════════════════════════════════════
# MEDIA / CODECS
# Control del framework de reproducción multimedia Stagefright.
# ⚠ Si alguna app no reproduce vídeo, revisa esta sección.
# ☝️ [UNIVERSAL] Funciona en todos los procesadores
# ═══════════════════════════════════════════════════════════════
# set_prop media.stagefright.enable-player true                             # Habilita el player nativo de Stagefright
# set_prop media.stagefright.enable-meta true                               # Habilita la lectura de metadatos por Stagefright
# resetprop audio.offload.video true                                       # [DESACTIVADO] Offload de audio en reproducción de vídeo - Puede causar desincronización audio/vídeo
# resetprop audio.offload.pcm.16bit.enable true                            # [DESACTIVADO] Offload de PCM 16bit al DSP - ROMPE reproducción de vídeo en Twitter
# resetprop audio.offload.pcm.24bit.enable true                            # [DESACTIVADO] Offload de PCM 24bit al DSP - ROMPE reproducción de vídeo en Twitter
# resetprop audio.offload.track.enabled true                               # [DESACTIVADO] Offload de tracks de audio al DSP - Puede causar conflictos con múltiples streams
# ═══════════════════════════════════════════════════════════════
# AUDIO - CORE
# Pipeline principal de audio del sistema.
# ⚠ Esta sección es la más sensible. Si algo falla con el audio
# (vídeos que no arrancan, lag de volumen, sonidos que
# desaparecen en juegos), empieza comentando líneas aquí.
# ☝️ [UNIVERSAL] La mayoría funciona, pero algunas props son Qualcomm
# ═══════════════════════════════════════════════════════════════
set_prop audio.offload.buffer.size.kb 640                                  # Tamaño del buffer de audio offload en KB (550 = compromiso entre latencia y estabilidad del stream)
set_prop audio.playback.capture.pcm.quality high                           # Calidad de captura PCM en alta resolución
set_prop ro.audio.flinger_standbytime_ms 3000                              # Tiempo antes de que AudioFlinger entre en standby (3000ms = sin lag de reconexión)
set_prop ro.audio.pcm.cb.size 128                                          # Tamaño del callback buffer de PCM (128-256, menor = menos latencia)
# set_prop af.resampler.quality 5                                          # Calidad del resampler de AudioFlinger (rango 0-8)
# set_prop audio.deep_buffer.media 1                                       # [DESACTIVADO] Activa el buffer profundo de media para audio continuo - puede afectar latencia
# set_prop persist.audio.lowprio true                                      # [DESACTIVADO] Baja la prioridad del hilo de audio (puede causar conflictos con A2DP)
# ☝️ [MTK/EXYNOS] La siguiente línea es específica de Qualcomm DSP
# En MTK/Exynos, COMENTA esta línea si hay problemas de audio
set_prop persist.vendor.audio.offload.multiple.enabled true                # [SNAPDRAGON] Habilita múltiples streams de audio offload simultáneos en el DSP - COMENTAR en MTK/Exynos
# resetprop audio.offload.min.duration.secs 30                             # [DESACTIVADO] Activaba offload para audios de más de 30 segundos - ROMPE Twitter
set_prop audio.deep_buffer.media.bufsize 32768
set_prop debug.sf.reuse_layer_content 1
set_prop ro.surface_flinger.max_frame_buffer_acquired_buffers 3
set_prop audio.offload.gapless.enabled true
set_prop ro.vendor.qti.am.reschedule_service true
set_prop dalvik.vm.heaptargetutilization 0.75
set_prop dalvik.vm.heapsize 768m
set_prop persist.sys.fw.use_trim_settings false
# --- Sample Rates ---
# TODAS DESACTIVADAS: mapear sample rates al DSP provoca que
# apps como Telegram no reproduzcan vídeo.
# ☝️ [UNIVERSAL] NO activar en NINGÚN procesador
# resetprop ro.audio.samplerate.8000 48000                                 # [DESACTIVADO] Remuestrea 8kHz - ROMPE Telegram
# resetprop ro.audio.samplerate.11025 48000                                # [DESACTIVADO] Remuestrea 11.025kHz - ROMPE Telegram
# resetprop ro.audio.samplerate.12000 48000                                # [DESACTIVADO] Remuestrea 12kHz - ROMPE Telegram
# resetprop ro.audio.samplerate.16000 48000                                # [DESACTIVADO] Remuestrea 16kHz - ROMPE Telegram
# resetprop ro.audio.samplerate.22050 48000                                # [DESACTIVADO] Remuestrea 22.05kHz - ROMPE Telegram
# resetprop ro.audio.samplerate.24000 48000                                # [DESACTIVADO] Remuestrea 24kHz - ROMPE Telegram
# resetprop ro.audio.samplerate.32000 48000                                # [DESACTIVADO] Remuestrea 32kHz - ROMPE Telegram
# resetprop ro.audio.samplerate.44100 48000                                # [DESACTIVADO] Remuestrea 44.1kHz - ROMPE Telegram
# --- HiFi Audio ---
# DESACTIVADO: enruta el audio por el DAC dedicado del dispositivo.
# ⚠ ROMPE el audio por Bluetooth en TODOS los procesadores
# ☝️ [UNIVERSAL] NO activar en NINGÚN procesador si usas Bluetooth
# resetprop persist.audio.hifi true                                        # [DESACTIVADO] ROMPE Bluetooth en todos los dispositivos
# resetprop persist.vendor.audio.hifi true                                 # [DESACTIVADO] ROMPE Bluetooth en todos los dispositivos
# --- Fluence (micrófonos / cancelación de ruido) ---
# ☝️ [SNAPDRAGON] Fluence es tecnología Qualcomm
# ☝️ [MTK/EXYNOS] Estas props no existen, COMENTAR todas
# resetprop persist.vendor.audio.fluence.game false                        # [SNAPDRAGON] Cancelación de ruido en juegos - COMENTAR en MTK/Exynos
# resetprop persist.audio.fluence.voicecall true                           # [SNAPDRAGON] Cancelación de ruido en llamadas - COMENTAR en MTK/Exynos
# resetprop persist.audio.fluence.speaker false                            # [SNAPDRAGON] Cancelación de ruido por altavoz - COMENTAR en MTK/Exynos
# resetprop ro.qc.sdk.audio.fluencetype fluence                            # [SNAPDRAGON] Tipo de Fluence activo - COMENTAR en MTK/Exynos
# ═══════════════════════════════════════════════════════════════
# BOSE SIGNATURE TONE (Sound Profile)
# Perfil de sonido experimental - [UNIVERSAL] pero depende del hardware
# ═══════════════════════════════════════════════════════════════
set_prop ro.vendor.audio.voice.enhance 1                                   # [EXPERIMENTAL] Claridad vocal - Probar en cada dispositivo
set_prop ro.vendor.audio.surround.support true                             # [EXPERIMENTAL] Soporte de audio surround - Probar en cada dispositivo
# resetprop ro.vendor.audio.dolby.hp_advanced true                         # [EXPERIMENTAL] Dolby avanzado para auriculares - Probar en cada dispositivo
# resetprop ro.vendor.audio.dolby.hph.virtualizer 1                        # [EXPERIMENTAL] Virtualización Dolby - Probar en cada dispositivo
# resetprop ro.vendor.audio.dolby.hph.surround 1                           # [EXPERIMENTAL] Surround Dolby - Probar en cada dispositivo
# resetprop ro.vendor.audio.bass.enhancer.enable true                      # [EXPERIMENTAL] Realce de graves Bose - Probar en cada dispositivo
# resetprop ro.vendor.audio.bass.boost.level 6                             # [EXPERIMENTAL] Nivel de realce de graves (1-10) - Probar en cada dispositivo
# ═══════════════════════════════════════════════════════════════
# BLUETOOTH - AUDIO WIRELESS
# Optimizaciones para A2DP y LDAC.
# ☝️ [SNAPDRAGON] LDAC y AAC whitelist son específicos de Qualcomm
# ☝️ [MTK/EXYNOS] Algunas props pueden no existir, comentar si hay problemas
# ═══════════════════════════════════════════════════════════════
set_prop persist.audio.bt.a2dp.hifi true                                   # Modo HiFi Bluetooth A2DP - Universal
set_prop persist.bluetooth.a2dp.aac_vbr true                              # AAC VBR (Variable Bit Rate) - Universal
set_prop persist.bluetooth.a2dp.aac_frame_ctl true                        # Control de frames AAC - Universal
set_prop persist.bluetooth.a2dp.ldac.quality hq                           # Calidad LDAC máxima (hq) - Universal si el dispositivo soporta LDAC
set_prop persist.bluetooth.a2dp.ldac.abr true                             # LDAC ABR (Adaptive Bit Rate) - Universal
set_prop persist.bluetooth.a2dp.aac_whitelist true                        # [SNAPDRAGON] Whitelist de dispositivos para AAC - COMENTAR en MTK/Exynos si no funciona
# ═══════════════════════════════════════════════════════════════
# RED / CONECTIVIDAD
# ☝️ [UNIVERSAL] TCP y RIL funcionan en todos los procesadores
# ═══════════════════════════════════════════════════════════════

# --- Ventana inicial TCP por tipo de red (en segmentos) ---
set_prop net.tcp.2g_init_rwnd 10                                           # Ventana inicial TCP en redes 2G (segmentos)
set_prop net.tcp.3g_init_rwnd 20                                           # Ventana inicial TCP en redes 3G
set_prop net.tcp.gprs_init_rwnd 10                                         # Ventana inicial TCP en GPRS
set_prop net.tcp.lte_init_rwnd 30                                          # Ventana inicial TCP en LTE/4G
set_prop net.tcp.init_rwnd 30                                              # Ventana inicial TCP por defecto para otras redes
set_prop net.tcp.default_tcp_congestion_control bbr                      # Algoritmo de control de congestión TCP por defecto (puedes elejir otro)   
# --- Estabilidad de datos móviles ---
set_prop persist.radio.data_con_recovery true                              # Activa la recuperación automática de la conexión de datos móviles
set_prop persist.radio.data_no_toggle 1                                    # Evita el toggle de datos durante reconexiones del modem
set_prop persist.cust.tel.e010 1                                           # Flag de personalización de telefonía del operador (mejora reconexión en algunas redes)
set_prop persist.radio.add_power_save 0                                    # Desactiva el ahorro de energía adicional del modem (mantiene señal estable)
# --- RIL (Radio Interface Layer) - [UNIVERSAL] pero puede variar ---
#set_prop ro.ril.hep 1                                                      # Activa High-Speed Packet Access Evolution en el RIL
#set_prop ro.ril.enable.dtm 1                                               # Activa Dual Transfer Mode (voz + datos simultáneos)
set_prop ro.ril.enable.managed.roaming 1                                   # Activa el roaming gestionado por la red
#set_prop ro.ril.enable.a53 1                                               # Activa la aceleración A5/3 en el RIL para datos EDGE
#set_prop ro.ril.gprsclass 12                                               # Clase GPRS máxima (12 = máximo rendimiento en GPRS)
set_prop ro.config.nocheckin 1                                           # Desactiva el checkin de Google (puede reducir tráfico de fondo)
# ═══════════════════════════════════════════════════════════════
# KERNEL TCP BUFFERS - Optimizado para LTE/5G (throughput alto)
# ═══════════════════════════════════════════════════════════════
echo "4096 87380 16777216" > /proc/sys/net/ipv4/tcp_rmem          # Buffer lectura TCP (min/default/max)
echo "4096 65536 16777216" > /proc/sys/net/ipv4/tcp_wmem          # Buffer escritura TCP
echo "16777216" > /proc/sys/net/core/rmem_max                     # Buffer máximo de recepción del socket
echo "16777216" > /proc/sys/net/core/wmem_max                     # Buffer máximo de envío del socket

# ═══════════════════════════════════════════════════════════════
# UDP BUFFERS - Gaming / tiempo real
# ═══════════════════════════════════════════════════════════════
echo "4096 87380 16777216" > /proc/sys/net/core/rmem_default             
echo "2000" > /proc/sys/net/core/netdev_max_backlog        
echo "0" > /proc/sys/net/ipv4/tcp_slow_start_after_idle          # No reinicia ventana TCP tras inactividad    
# ═══════════════════════════════════════════════════════════════
# TCP FEATURES - Mejoras de latencia y estabilidad
# ═══════════════════════════════════════════════════════════════
echo "1" > /proc/sys/net/ipv4/tcp_sack                            # Selective ACK: retransmite solo paquetes perdidos
echo "1" > /proc/sys/net/ipv4/tcp_timestamps                      # Estimación RTT precisa (necesario con BBR)
echo "1" > /proc/sys/net/ipv4/tcp_window_scaling                  # Permite ventanas >64KB (necesario con rmem alto)
echo "3" > /proc/sys/net/ipv4/tcp_fastopen                        # TCP Fast Open en cliente y servidor (reduce latencia handshake)
echo "1" > /proc/sys/net/ipv4/tcp_ecn                             # ECN: notifica congestión sin perder paquetes (bueno con BBR)
echo "1" > /proc/sys/net/ipv4/tcp_mtu_probing                     # MTU probing: evita fragmentación en 5G SA
echo "1" > /proc/sys/net/ipv4/tcp_moderate_rcvbuf                 # Auto-tune del buffer de recepción por conexión
echo "30" > /proc/sys/net/ipv4/tcp_fin_timeout                   # Reduce de 60s a 30s el tiempo en TIME_WAIT
echo "1" > /proc/sys/net/ipv4/tcp_tw_reuse                       # Reutiliza sockets TIME_WAIT para nuevas conexiones
echo "1024 65535" > /proc/sys/net/ipv4/ip_local_port_range       # Más puertos efímeros disponibles
# ═══════════════════════════════════════════════════════════════
# NETWORK CORE
# ═══════════════════════════════════════════════════════════════
echo "2000" > /proc/sys/net/core/netdev_max_backlog               # Cola de paquetes recibidos antes de procesar
# ═══════════════════════════════════════════════════════════════
# CÁMARA
# Acelerar inicio y captura - [UNIVERSAL] pero depende del fabricante
# ═══════════════════════════════════════════════════════════════
# ☝️ [MTK/EXYNOS] Las siguientes props son de Qualcomm
#    En MTK/Exynos, COMENTAR estas líneas o cambiar por las equivalentes
set_prop persist.vendor.camera.perf.hfr.enable 1                           # [SNAPDRAGON] Perfiles de alto rendimiento para HFR (slow-motion) - COMENTAR en MTK/Exynos
set_prop persist.vendor.camera.enable_fast_launch 1                        # [SNAPDRAGON] Inicio rápido de la cámara - COMENTAR en MTK/Exynos
set_prop persist.camera.focus.debug 0                                      # Velocidad de enfoque - Universal (0 = sin delay de debug)
set_prop persist.camera.shutter.speed 0                                    # Velocidad de obturador - Universal (0 = sin delay artificial)

set_prop --delete ro.modversion                                       # Elimina la prop de versión de kernel modificado (evita detección por algunas apps)

log -t SAFE "--- [HYPERVULKAN ENGINE]: Optimizacion BASE Completada con exito ---"
log -t SAFE "--- [HYPERVULKAN ENGINE]: Props dinámicas (Vulkan/OpenGL) gestionadas por service.sh ---"
log -t SAFE "--- [HYPERVULKAN ENGINE]: Si usas MTK/Exynos, revisa las líneas marcadas ---"
exit 0