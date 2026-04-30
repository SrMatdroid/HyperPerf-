#!/system/bin/sh
# ── HyperPerf+ Service ─────────────────────────────────────────
CONF="/data/adb/modules/sr.mat/hypervulkan.conf"

# ── Esperar al sistema ────────────────────────────────────────
TIMEOUT=45
COUNT=0
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
    COUNT=$((COUNT + 1))
    [ $COUNT -ge $TIMEOUT ] && break
done
sleep 5

# ── Helper: leer clave del config ────────────────────────────
# Uso: cfg KEY DEFAULT
cfg() {
    local val
    val=$(grep "^${1}=" "$CONF" 2>/dev/null | cut -d'=' -f2-)
    [ -n "$val" ] && echo "$val" || echo "$2"
}

# ── Helper: aplicar prop solo si hay valor en config ─────────
setprop_if() {
    # $1 = clave config, $2 = prop Android
    local val
    val=$(grep "^${1}=" "$CONF" 2>/dev/null | cut -d'=' -f2-)
    [ -n "$val" ] && resetprop -n "$2" "$val" 2>/dev/null
}

# ── Valores por defecto (si no hay config) ────────────────────
ZRAM_SIZE=4294967296
ZRAM_COMP=lzo-rle
SWAPPINESS=60
SCHEDULER=mq-deadline
GOVERNOR=schedutil
READ_AHEAD_KB=2048

# ── Cargar config del WebUI ───────────────────────────────────
if [ -f "$CONF" ]; then
    ZRAM_SIZE=$(cfg ZRAM_SIZE 4294967296)
    ZRAM_COMP=$(cfg ZRAM_COMP lzo-rle)
    SWAPPINESS=$(cfg SWAPPINESS 60)
    SCHEDULER=$(cfg SCHEDULER mq-deadline)
    GOVERNOR=$(cfg GOVERNOR schedutil)
    READ_AHEAD_KB=$(cfg READ_AHEAD_KB 2048)
fi

# ── ZRAM ──────────────────────────────────────────────────────
if [ -b /dev/block/zram0 ]; then
    swapoff /dev/block/zram0 2>/dev/null
    echo 1 > /sys/block/zram0/reset 2>/dev/null
    echo "$ZRAM_SIZE" > /sys/block/zram0/disksize 2>/dev/null
    echo "$ZRAM_COMP" > /sys/block/zram0/comp_algorithm 2>/dev/null
    mkswap /dev/block/zram0 2>/dev/null
    swapon /dev/block/zram0 2>/dev/null
fi

# ── VM ────────────────────────────────────────────────────────
echo "$SWAPPINESS" > /proc/sys/vm/swappiness 2>/dev/null

VFS=$(cfg VFS_PRESSURE "")
[ -n "$VFS" ] && echo "$VFS" > /proc/sys/vm/vfs_cache_pressure 2>/dev/null

DIRTY=$(cfg DIRTY_RATIO "")
[ -n "$DIRTY" ] && echo "$DIRTY" > /proc/sys/vm/dirty_ratio 2>/dev/null

# ── I/O Scheduler ────────────────────────────────────────────
for q in /sys/block/*/queue/scheduler; do
    [ -f "$q" ] && grep -q "$SCHEDULER" "$q" 2>/dev/null && echo "$SCHEDULER" > "$q" 2>/dev/null
done

# ── CPU Governor ─────────────────────────────────────────────
for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [ -f "$g" ] || continue
    avail="${g%scaling_governor}scaling_available_governors"
    grep -q "$GOVERNOR" "$avail" 2>/dev/null && echo "$GOVERNOR" > "$g" 2>/dev/null
done

# ── UFS Read-ahead ───────────────────────────────────────────
for b in /sys/block/sd*/queue/read_ahead_kb; do
    [ -f "$b" ] && echo "$READ_AHEAD_KB" > "$b" 2>/dev/null
done

# ── TCP ──────────────────────────────────────────────────────
TCP_CC=$(cfg TCP_CC "")
if [ -n "$TCP_CC" ]; then
    echo "$TCP_CC" > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null
    resetprop -n net.tcp.default_tcp_congestion_control "$TCP_CC" 2>/dev/null
fi

TCP_FO=$(cfg TCP_FASTOPEN "")
[ -n "$TCP_FO" ] && echo "$TCP_FO" > /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null

TCP_ECN=$(cfg TCP_ECN "")
[ -n "$TCP_ECN" ] && echo "$TCP_ECN" > /proc/sys/net/ipv4/tcp_ecn 2>/dev/null

TCP_WS=$(cfg TCP_WSCALE "")
[ -n "$TCP_WS" ] && echo "$TCP_WS" > /proc/sys/net/ipv4/tcp_window_scaling 2>/dev/null

TCP_MTU=$(cfg TCP_MTU_PROBING "")
[ -n "$TCP_MTU" ] && echo "$TCP_MTU" > /proc/sys/net/ipv4/tcp_mtu_probing 2>/dev/null

TCP_SACK=$(cfg TCP_SACK "")
[ -n "$TCP_SACK" ] && echo "$TCP_SACK" > /proc/sys/net/ipv4/tcp_sack 2>/dev/null

TCP_TWR=$(cfg TCP_TWREUSE "")
[ -n "$TCP_TWR" ] && echo "$TCP_TWR" > /proc/sys/net/ipv4/tcp_tw_reuse 2>/dev/null

# ── System props desde WebUI config ──────────────────────────
# Solo se aplican si el usuario las guardó explícitamente.
# Sobreescriben lo que puso post-fs-data.sh con las preferencias del usuario.

if [ -f "$CONF" ]; then

    # Animaciones
    setprop_if WINDOW_SCALE      persist.sys.window_animation_scale
    setprop_if TRANSITION_SCALE  persist.sys.transition_animation_scale
    setprop_if ANIMATOR_SCALE    persist.sys.animator_duration_scale
    setprop_if FLING_VELOCITY    ro.max.fling_velocity
    setprop_if MIUI_ANIM_SW      persist.sys.miui.anim_sw_threshold

    # GPU y rendimiento
    setprop_if PERF_TUNING       debug.performance.tuning
    setprop_if RENDER_BOOST      persist.sys.perf.topAppRenderThreadBoost.enable
    setprop_if MIUI_BOOSTER      persist.sys.miui_booster
    setprop_if ADRENO_MEM_MB     debug.adreno.mem.mb
    setprop_if GPU_COMPOSE       persist.sys.composition.type
    setprop_if HWUI_RENDERER     debug.hwui.renderer

    # Blur
    BLUR_OFF=$(cfg BLUR_OFF "")
    if [ -n "$BLUR_OFF" ]; then
        resetprop -n persist.sys.sf.disable_blurs  "$BLUR_OFF" 2>/dev/null
        resetprop -n persist.sys.sf.disable_blur   "$BLUR_OFF" 2>/dev/null
        BLUR_UI=$([ "$BLUR_OFF" = "1" ] && echo "true" || echo "false")
        resetprop -n persist.sysui.disable_blur    "$BLUR_UI"  2>/dev/null
    fi

    # SurfaceFlinger
    setprop_if SF_VSYNC          persist.sys.miui.sf.vsync
    setprop_if SF_BACKPRESSURE   debug.sf.disable_backpressure
    setprop_if EGL_FBCOUNT       debug.gr.num_framebuffer_frames
    setprop_if EGL_BUFFERS       debug.egl.buffercount
    setprop_if SF_PHASE          debug.sf.early_phase_offset_ns

    # Gaming
    setprop_if MIGT              persist.miui.migt.enable
    setprop_if MIGT_BOOST        persist.miui.migt.game_boost
    setprop_if ADRENO_PREEMPT    debug.adreno.preemption.disable
    setprop_if FIFO_UI           sys.use_fifo_ui
    setprop_if ADRENO_LRZ        debug.adreno.lrz.enable
    setprop_if JOB_DELAY         persist.sys.job_delay

    # Audio
    setprop_if BT_HIFI           persist.audio.bt.a2dp.hifi
    setprop_if LDAC_QUALITY      persist.bluetooth.a2dp.ldac.quality
    setprop_if OFFLOAD_BUF_KB    audio.offload.buffer.size.kb
    setprop_if RESAMPLER         af.resampler.quality
    setprop_if DEEP_BUFFER       audio.deep_buffer.media
    setprop_if OFFLOAD_MULTI     persist.vendor.audio.offload.multiple.enabled
    setprop_if GAPLESS           audio.offload.gapless.enabled
    setprop_if PCM_QUALITY       audio.playback.capture.pcm.quality

    # Bluetooth
    setprop_if AAC_VBR           persist.bluetooth.a2dp.aac_vbr
    setprop_if AAC_FRAME         persist.bluetooth.a2dp.aac_frame_ctl
    setprop_if LDAC_ABR          persist.bluetooth.a2dp.ldac.abr
    setprop_if AAC_WHITELIST     persist.bluetooth.a2dp.aac_whitelist

    # Red
    setprop_if DATA_RECOVERY     persist.radio.data_con_recovery

    # MIUI / HyperOS
    setprop_if SPTM              persist.sys.miui_sptm.enable
    setprop_if SPTM_NEW          persist.sys.miui_sptm_new.enable
    setprop_if CLOUD_OVERRIDE    persist.sys.enable_ignorecloud_rtmode
    setprop_if SMART_FOCUS       persist.sys.stability.smartfocusio
    setprop_if FREEFORM          persist.miui.speed_up_freeform
    setprop_if HOME_REUSE        persist.miui.home_reuse_leash

    # Cámara
    setprop_if CAM_FAST          persist.vendor.camera.enable_fast_launch
    setprop_if CAM_HFR           persist.vendor.camera.perf.hfr.enable

    # Térmica
    setprop_if THERMAL_CONFIG    persist.sys.thermal.config
    setprop_if THERMAL_WARM      ro.thermal.warm_limit
    setprop_if THERMAL_COOL      ro.thermal.cool_limit

    # Dalvik / ART
    setprop_if DEX2OAT_THREADS   dalvik.vm.dex2oat-threads
    setprop_if DEX2OAT_FILTER    dalvik.vm.dex2oat-filter
    setprop_if HEAP_UTIL         dalvik.vm.heaptargetutilization
    setprop_if HEAP_SIZE         dalvik.vm.heapsize

fi

# ── BORE ──────────────────────────────────────────────────────
BORE=$(cfg BORE_ENABLE "")
if [ -n "$BORE" ] && [ -f /proc/sys/kernel/sched_bore ]; then
    echo "$BORE" > /proc/sys/kernel/sched_bore 2>/dev/null
fi

# ── Props nuevas ──────────────────────────────────────────────
setprop_if ADRENO_SYNC    debug.adreno.syncobj_timeline
setprop_if ADRENO_BIMC    debug.adreno.gpu_bimc_clk
setprop_if SF_TRACE_OFF   debug.sf.enable_transaction_tracing
setprop_if SF_REUSE       debug.sf.reuse_layer_content
setprop_if SF_IDLE        ro.surface_flinger.set_idle_timer_ms
setprop_if APP_PHASE      debug.sf.early_app_phase_offset_ns
setprop_if AF_STANDBY     ro.audio.flinger_standbytime_ms
setprop_if PCM_CB         ro.audio.pcm.cb.size
setprop_if VOICE_ENHANCE  ro.vendor.audio.voice.enhance
setprop_if SURROUND       ro.vendor.audio.surround.support
setprop_if MIUI_OPT       persist.sys.miui_optimization
setprop_if MIRIM_OFF      persist.sys.mirim.enable
setprop_if SPTM_CLOUD     persist.sys.miui_sptm.ignore_cloud_enable
setprop_if SPTM_ANIM_OFF  persist.sys.miui_sptm_animation.enable
setprop_if BOOT_COMPACT   persist.sys.use_boot_compact
setprop_if SLOW_STARTUP_OFF persist.sys.miui_slow_startup_mode.enable
setprop_if NO_CHECKIN     ro.config.nocheckin
setprop_if DATA_NO_TOGGLE persist.radio.data_no_toggle
setprop_if RADIO_PS_OFF   persist.radio.add_power_save
setprop_if VIDEO_HW       video.accelerate.hw
setprop_if NO_RESAMPLE    ro.input.noresample
setprop_if PURGEABLE_OFF  persist.sys.purgeable_assets

IORAPD=$(cfg IORAPD "")
if [ -n "$IORAPD" ]; then
    resetprop -n ro.iorapd.enable "$IORAPD" 2>/dev/null
    resetprop -n persist.iorapd.enable "$IORAPD" 2>/dev/null
fi
