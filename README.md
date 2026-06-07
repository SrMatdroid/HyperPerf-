# HyperPerf+

**Kernel and System Configurator for HyperOS / MIUI**

HyperPerf+ is a KernelSU / Magisk module that exposes kernel parameters, system properties and runtime tunables through a WebUI embedded in KernelSU Manager. Nothing is applied until the user explicitly enables it. Uninstalling the module reverts all changes automatically.

---

## Table of Contents

- [Requirements](#requirements)
- [Architecture](#architecture)
- [Installation](#installation)
- [WebUI](#webui)
  - [Kernel Tab](#kernel-tab)
  - [Tweaks Tab](#tweaks-tab)
  - [Stats Tab](#stats-tab)
- [Configuration File](#configuration-file)
- [Boot Sequence](#boot-sequence)
- [File Structure](#file-structure)
- [Uninstall](#uninstall)
- [Compatibility](#compatibility)
- [License](#license)

---

## Requirements

| Requirement | Details |
|---|---|
| Root manager | KernelSU-Next, KernelSU, or Magisk with Zygisk |
| Android version | Android 12 or later |
| Kernel | GKI 5.10 or GKI 6.1 recommended |
| Chipset | Snapdragon (primary target), MediaTek (partial support) |
| Tested device | Redmi Note 13 Pro 5G (garnet / Snapdragon 7s Gen 2) |
| Tested ROM | HyperOS 1.x / 2.x |

---

## Architecture

The module is built around three scripts and one WebUI file.

```
post-fs-data.sh   Runs at early boot (before /data is decrypted).
                  Applies only the baseline that the kernel needs
                  from the first moment: game scheduler props and
                  root-detection mitigations.

service.sh        Runs after boot_completed. Reads hypervulkan.conf
                  and applies every value the user has enabled.
                  Also runs the VoLTE monitor loop in background.

uninstall.sh      Executed automatically by KernelSU / Magisk when
                  the module is removed. Cleans all persist.* props,
                  session props and settings database entries.

webroot/index.html  The WebUI served by KernelSU Manager. Reads live
                    kernel values, loads the config, lets the user
                    toggle options and saves to hypervulkan.conf.
```

### Opt-in by default

Every option in the Tweaks tab has an **Activar** checkbox (select/slider controls) or a toggle switch (boolean controls). A value is written to the configuration file only when explicitly activated. If a prop is not in the config, `service.sh` does not touch it — the system uses the stock value from the ROM's build.prop or kernel default.

### Configuration persistence

Changes are saved to:

```
/data/adb/modules/sr.mat/hypervulkan.conf
```

This file survives dirty flashes (it is in `/data/adb/`, not in the module's system overlay). It does not survive a clean flash or factory reset.

---

## Installation

1. Download the latest `statsHyperPerf_*.zip` from the releases page.
2. Open KernelSU Manager or Magisk Manager.
3. Go to **Modules** and tap **Install from storage**.
4. Select the ZIP and confirm the flash.
5. Reboot the device.
6. Open KernelSU Manager, tap the module, and open the **WebUI**.

> On first install nothing is changed. The system runs with its stock configuration until the user activates options from the WebUI and saves.

---

## WebUI

The interface has three tabs: **Kernel**, **Tweaks**, and **Stats**.

The language can be switched between Spanish and English using the buttons in the top right corner.

---

### Kernel Tab

The Kernel tab controls parameters that require lower-level access or that are applied on a kernel-wide basis. All values in this tab are always saved when the user presses **Guardar configuracion**.

---

#### ZRAM

| Option | Description |
|---|---|
| Size | Total ZRAM swap size in bytes. Typical values: 2 GB (2147483648), 4 GB (4294967296), 6 GB (6442450944). |
| Compression | Algorithm used by the ZRAM block device. `lzo-rle` is recommended as the best balance of speed and ratio. `lz4` prioritises speed. `zstd` prioritises ratio at the cost of more CPU. |

---

#### Memory

| Option | Description |
|---|---|
| Swappiness | Kernel preference for using ZRAM vs physical RAM. 10-40 = prefer RAM (gaming). 60 = balanced (recommended). 100 = Android default (aggressive ZRAM use). |

---

#### I/O Scheduler

| Option | Description |
|---|---|
| Scheduler | I/O scheduler applied to all UFS LUNs (sda-sdf) and eMMC (mmcblk). Available schedulers are read live from the kernel. If Auto is selected no value is applied and the kernel default remains. |

The module verifies after applying that the scheduler name appears active in the block device's queue node. The result is shown in the apply log.

---

#### CPU Governor

| Option | Description |
|---|---|
| Governor | CPU frequency scaling governor. Applied to all CPU cores after verifying it exists in `scaling_available_governors`. If Auto is selected the kernel default remains. |

---

#### UFS Read-Ahead

| Option | Description |
|---|---|
| Read-Ahead (KB) | Kilobytes the kernel reads ahead from UFS when sequential access is detected. 1024 = standard. 2048 = recommended (reduces asset pop-in in games). 4096 = aggressive (higher RAM usage). |

---

#### BORE Scheduler

| Option | Description |
|---|---|
| BORE | Budget Oriented Response Enhancement. Prioritises interactive tasks under mixed load. Reduces perceived latency in gaming alongside background load. Only available if the running kernel includes BORE support. The control is disabled automatically if the kernel node is absent. |

---

#### vbmeta / AVB

Displays the hardware Verified Boot state read from `/proc/cmdline` and `/proc/bootconfig`, and the effective spoofed state from `getprop`. The stored digest used for spoof is applied at early boot via `post-fs-data.sh`.

---

### Tweaks Tab

The Tweaks tab groups all system property and runtime tunable controls. Controls with a **toggle switch** are boolean. Controls with a **select or slider** also include an **Activar** checkbox that must be checked before the value is included in the saved config.

When a control is inactive (toggle off or Activar unchecked), the corresponding prop is not touched by the module and the system uses its stock value.

---

#### Gaming

| Option | Prop | Description |
|---|---|---|
| Game Turbo MIGT | `persist.miui.migt.enable` | HyperOS engine for games. Manages CPU, GPU and RAM when a game session is detected. |
| MIGT Game Boost | `persist.miui.migt.game_boost` | Additional CPU/GPU boost inside Game Turbo. Enable together with MIGT. |
| Adreno Preemption OFF | `debug.adreno.preemption.disable` | Disables GPU preemption between draw calls. Eliminates stutters in dense 3D scenes. Snapdragon only. |
| FIFO UI Scheduler | `sys.use_fifo_ui` | Sets the main UI thread to FIFO scheduling priority. Reduces jank under load. |
| Adreno LRZ | `debug.adreno.lrz.enable` | Low Resolution Z-buffering. Discards hidden pixels before rendering. Improves FPS in dense 3D scenes. |
| Adreno GPU Pool (kB) | `debug.adreno.mem.mb` | Memory budget for the GPU. Auto lets the driver calculate it dynamically based on available RAM. |
| Boost render app | `persist.sys.perf.topAppRenderThreadBoost.enable` | Raises CPU priority of the foreground app render thread. Reduces stutters in active apps and games. |
| Job Delay Background | `persist.sys.job_delay` | Delays background app jobs to prioritise the active app. Reduces microstutters during gameplay. |
| Adreno Syncobj Timeline | `debug.adreno.syncobj_timeline` | Reduces GPU command flush latency. Improves the CPU-to-GPU pipeline in games with many draw calls. |
| Adreno GPU BIMC Clock | `debug.adreno.gpu_bimc_clk` | Reduces memory stalls between CPU and GPU during asset streaming. Snapdragon only. |

---

#### Animations

| Option | Prop | Description |
|---|---|---|
| Window scale | `persist.sys.window_animation_scale` | Speed of window open/close animations. 0 = no animation. 0.1-0.2 = ultra fast. 1.0 = stock. |
| Transition scale | `persist.sys.transition_animation_scale` | Speed of animations between apps and activities. |
| Animator duration | `persist.sys.animator_duration_scale` | General duration of system animations (ObjectAnimator, ValueAnimator). |
| Fling velocity | `ro.max.fling_velocity` | Maximum scroll speed on fling gesture. 8000 = stock Android. 12000-20000 = fluid. 24000-32000 = very aggressive. |
| MIUI SW anim threshold | `persist.sys.miui.anim_sw_threshold` | CPU percentage at which MIUI switches animations to software rendering. 68-80 = recommended. 100+ = always hardware. |

---

#### GPU and Rendering

| Option | Prop | Description |
|---|---|---|
| Desactivar Blur | `persist.sys.sf.disable_blurs` | Removes blur on Control Center, recents and notifications. Reduces SurfaceFlinger load. |
| Tuning global | `debug.performance.tuning` | Enables the global performance tuning mode and internal graphics subsystem optimisations. |
| MIUI Booster | `persist.sys.miui_booster` | HyperOS/MIUI performance accelerator. Manages CPU and RAM proactively for priority apps. |
| Composicion GPU | `persist.sys.composition.type` | Forces GPU composition, bypassing the hardware composer. Better for Vulkan workloads. May break video in some social media apps. |
| HWUI Renderer | `debug.hwui.renderer` | `skiavk` = Vulkan backend for HWUI (system UI). `skiagl` = OpenGL backend. The module can override this per-app dynamically in games. |
| SF Transaction Tracing OFF | `debug.sf.enable_transaction_tracing` | Disables SurfaceFlinger transaction tracing. Removes compositor logging overhead. |
| Reuse Layer Content | `debug.sf.reuse_layer_content` | SF reuses unchanged layers between frames. Reduces compositor work when few layers change. |

---

#### SurfaceFlinger / Display

| Option | Prop | Description |
|---|---|---|
| VSync SF MIUI | `persist.sys.miui.sf.vsync` | Enables VSync in SurfaceFlinger for MIUI. Synchronises frames with the display refresh cycle. |
| Backpressure OFF | `debug.sf.disable_backpressure` | SF does not wait for the app to fill the buffer before presenting. May reduce latency at the cost of occasional empty frames. |
| Framebuffers | `debug.gr.num_framebuffer_frames` | Number of framebuffers in the presentation chain. 3 = triple buffering (default). |
| Buffers EGL | `debug.egl.buffercount` | Buffers in the EGL swap chain. 3 = stock. 4 = quad buffering, improves fluidity under high GPU load. |
| Early phase offset SF (ns) | `debug.sf.early_phase_offset_ns` | Phase offset of SurfaceFlinger's early wake-up relative to the VSYNC signal. |
| Early App Phase Offset (ns) | `debug.sf.early_app_phase_offset_ns` | Advances the moment the app starts producing a frame relative to the SF cycle. |
| SF Idle Timer (ms) | `ro.surface_flinger.set_idle_timer_ms` | Time before SF lowers the refresh rate on inactivity. 0 = SF never lowers Hz due to inactivity. |

---

#### Advanced Audio

| Option | Prop | Description |
|---|---|---|
| A2DP HiFi BT | `persist.audio.bt.a2dp.hifi` | HiFi mode for Bluetooth A2DP. Forces higher bitrates. Do not use with an internal DAC HiFi mode (breaks BT). |
| LDAC quality | `persist.bluetooth.a2dp.ldac.quality` | HQ = 990 kbps maximum. SQ = balanced. Auto = adjusts based on BT signal quality. |
| Audio offload buffer (KB) | `audio.offload.buffer.size.kb` | Offload buffer size sent to the DSP. More KB = more stability, higher latency. 640 recommended. |
| Resampler quality | `af.resampler.quality` | AudioFlinger resampler quality (0-8). Higher = better quality, more CPU. 5 is a good balance. |
| Deep buffer media | `audio.deep_buffer.media` | Deep buffer for continuous audio playback. May increase initial audio latency. |
| Offload multiple DSP | `persist.vendor.audio.offload.multiple.enabled` | Multiple simultaneous audio offload streams on the Snapdragon DSP. Qualcomm only. |
| Gapless playback | `audio.offload.gapless.enabled` | Gapless transition between offload audio tracks. Essential for continuous music playback. |
| PCM quality | `audio.playback.capture.pcm.quality` | PCM capture quality. High enables high-resolution capture for apps that support it. |
| AudioFlinger Standby (ms) | `ro.audio.flinger_standbytime_ms` | Time before AudioFlinger enters standby. 3000 ms avoids the reconnection lag when resuming audio. |
| PCM Callback Buffer | `ro.audio.pcm.cb.size` | PCM callback buffer size. Lower = less latency. 128 is the recommended balance. |
| Voice Enhance | `ro.vendor.audio.voice.enhance` | Improved vocal clarity. Experimental, depends on the vendor audio HAL. Snapdragon only. |
| Surround Audio | `ro.vendor.audio.surround.support` | Surround sound support. Experimental, depends on the device's vendor audio HAL. |

---

#### Bluetooth

| Option | Prop | Description |
|---|---|---|
| AAC VBR | `persist.bluetooth.a2dp.aac_vbr` | Variable Bit Rate for AAC codec. Better quality on AAC headphones without LDAC overhead. |
| AAC Frame Control | `persist.bluetooth.a2dp.aac_frame_ctl` | Frame control for AAC. Improves synchronisation and reduces transmission artefacts. |
| LDAC ABR | `persist.bluetooth.a2dp.ldac.abr` | Adaptive Bit Rate for LDAC. Reduces dropouts by adjusting quality based on BT signal stability. |
| Whitelist AAC | `persist.bluetooth.a2dp.aac_whitelist` | Forces AAC negotiation even if the paired device does not declare it correctly. |

---

#### Network and TCP

| Option | Prop / Sysctl | Description |
|---|---|---|
| TCP Congestion | `net.ipv4.tcp_congestion_control` | BBR improves latency and throughput on LTE/5G. Cubic is the kernel default. |
| TCP Fast Open | `net.ipv4.tcp_fastopen` | Reduces TCP handshake latency by sending data in the first SYN. 1 = client only (VoLTE-safe). 3 = client and server. |
| ECN | `net.ipv4.tcp_ecn` | Explicit Congestion Notification. Signals congestion without dropping packets. Disabled by default for VoLTE compatibility. |
| TCP Window Scaling | `net.ipv4.tcp_window_scaling` | Allows receive windows above 64 KB. Required to take advantage of a high rmem_max. |
| MTU Probing | `net.ipv4.tcp_mtu_probing` | Discovers the path MTU dynamically. Avoids fragmentation on links with restrictive MTU. |
| TCP SACK | `net.ipv4.tcp_sack` | Selective ACK: retransmits only lost packets instead of the entire window. Recommended for LTE/5G. |
| TCP TW Reuse | `net.ipv4.tcp_tw_reuse` | Reuses TIME_WAIT sockets for new connections. Reduces port exhaustion under high connection rates. |
| Data recovery | `persist.radio.data_con_recovery` | Automatic mobile data reconnection after signal loss. |
| Google Checkin OFF | `ro.config.nocheckin` | Disables periodic Google check-in. Reduces background traffic and unnecessary network wake-ups. |
| Data No Toggle | `persist.radio.data_no_toggle` | Prevents data toggling during modem reconnections. Reduces drops on cell handover. |
| Radio Power Save OFF | `persist.radio.add_power_save` | Disables additional modem power saving. More stable signal at a small battery cost. |

> **VoLTE protection:** A background monitor loop in `service.sh` reads `gsm.call_state` every 4 seconds. When a call is active it forces `tcp_ecn=0` and `tcp_fastopen=1`. When the call ends it restores the values configured by the user.

---

#### Kernel VM

| Option | Sysctl | Description |
|---|---|---|
| VFS Cache Pressure | `vm.vfs_cache_pressure` | Aggressiveness of filesystem cache reclaim. 50 = retains more cache (faster app re-launch). 100 = kernel default. 200 = aggressive reclaim (more free RAM). |
| Dirty Ratio | `vm.dirty_ratio` | Percentage of RAM with pending writes before a flush is forced. 10 = frequent flush. 20 = recommended balance. 40+ = aggressive throughput. |

---

#### MIUI / HyperOS

| Option | Prop | Description |
|---|---|---|
| SPTM | `persist.sys.miui_sptm.enable` | System Performance and Thermal Management (classic MIUI). Manages performance based on temperature. |
| SPTM new | `persist.sys.miui_sptm_new.enable` | Updated SPTM with revised performance management algorithms. |
| Ignorar cloud overrides | `persist.sys.enable_ignorecloud_rtmode` | Prevents Xiaomi servers from remotely modifying performance and RT mode parameters. |
| Smart Focus I/O | `persist.sys.stability.smartfocusio` | Prioritises I/O operations of the foreground app. Reduces asset loading latency in the foreground. |
| Freeform speed up | `persist.miui.speed_up_freeform` | Accelerates rendering of floating windows in freeform mode. |
| Home reutiliza proceso | `persist.miui.home_reuse_leash` | Prevents the launcher process from being destroyed on exit. Reduces return-to-home time. |
| MIUI Optimization | `persist.sys.miui_optimization` | Internal MIUI/HyperOS optimisations. Disabling can improve compatibility with non-MIUI apps. |
| MIRIM OFF | `persist.sys.mirim.enable` | Disables MIUI Mirror Rendering. Reduces overhead in animations with complex layer compositing. |
| SPTM Ignore Cloud | `persist.sys.miui_sptm.ignore_cloud_enable` | Forces SPTM to ignore performance overrides from Xiaomi servers. |
| SPTM Animation OFF | `persist.sys.miui_sptm_animation.enable` | Disables SPTM's own animations. Removes visual overhead added by the thermal manager. |
| Boot Compact | `persist.sys.use_boot_compact` | Compacts memory at boot to free RAM quickly and reduce initial footprint. |
| Slow Startup Mode OFF | `persist.sys.miui_slow_startup_mode.enable` | Disables MIUI's slow startup mode. Allows full resources when launching apps. |

---

#### Camera

| Option | Prop | Description |
|---|---|---|
| Fast launch | `persist.vendor.camera.enable_fast_launch` | Pre-loads camera resources to reduce the time from tap to ready. |
| HFR perf | `persist.vendor.camera.perf.hfr.enable` | High-performance profiles for slow-motion (HFR) recording. Snapdragon only. |

---

#### System

| Option | Prop | Description |
|---|---|---|
| I/O Predictivo (iorapd) | `ro.iorapd.enable` | Predictive I/O prefetch. The system learns each app's load patterns and pre-reads data before it is needed. |
| Video Hardware Accel | `video.accelerate.hw` | Hardware video decoding and playback. Disable only if a media player shows issues. |
| No Touch Resampling | `ro.input.noresample` | Disables touch event resampling. Lower touch latency, possible irregularity in pointer movement. |
| Purgeable Assets OFF | `persist.sys.purgeable_assets` | Prevents the system from discarding in-memory assets for recycling. Keeps assets loaded longer at a small RAM cost. |

---

#### Thermal

| Option | Prop | Description |
|---|---|---|
| Desactivar perfil vendor | `persist.sys.thermal.config` | Disables the manufacturer's custom thermal profile. The kernel uses its own thresholds. |
| Warm limit | `ro.thermal.warm_limit` | Temperature at which the system starts issuing thermal warnings (in tenths of a degree). |
| Cool limit | `ro.thermal.cool_limit` | Temperature at which the system considers the device cooled and removes throttling. |

---

#### Dalvik / ART

| Option | Prop | Description |
|---|---|---|
| dex2oat threads | `dalvik.vm.dex2oat-threads` | Threads used to compile apps with dex2oat. More threads = faster compilation on app install. Stock on Snapdragon: 4. |
| dex2oat filter | `dalvik.vm.dex2oat-filter` | Compilation filter. `speed` = full ahead-of-time compilation. `speed-profile` = compile only profiled code. `quicken` = faster, smaller output. |
| Heap target utilisation | `dalvik.vm.heaptargetutilization` | Heap fullness target before the GC triggers. Lower = more frequent GC, less pause time. 0.6 = recommended. |
| Heap size | `dalvik.vm.heapsize` | Maximum heap size per app. Stock varies by device RAM configuration. |

---

#### Spoof AVB / Identity

| Option | Prop | Description |
|---|---|---|
| Spoof AVB / Identity | Multiple `ro.boot.*` props | Applies properties that report a locked bootloader and clean verified boot state to apps and servers. Disable other identity spoof modules before enabling. |

---

### Stats Tab

The Stats tab shows live system data with rolling charts. Data is refreshed every 500 ms for the main metrics and every second for FPS. All charts are Canvas-based and drawn in the WebUI without any native binary dependency.

| Chart | Source |
|---|---|
| CPU usage per core | `/proc/stat` |
| CPU frequency per cluster | `/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq` |
| CPU temperature | Thermal zone sysfs nodes |
| RAM usage | `/proc/meminfo` |
| Battery level and current | `/sys/class/power_supply/battery/` |
| FPS | `dumpsys SurfaceFlinger --latency` with `gfxinfo framestats` fallback |

Game detection reads the foreground app from `/dev/cpuset/top-app/tasks` and cross-references it against a list of known game package names to display the active game in the header.

---

## Configuration File

```
/data/adb/modules/sr.mat/hypervulkan.conf
```

Plain text, one `KEY=VALUE` pair per line. Lines that start with `#` are ignored. An absent key means the corresponding prop is not touched. An empty value for a key that uses the **Auto** checkbox means the system manages that parameter.

Example of a minimal config activating only ZRAM and animation speed:

```
ZRAM_SIZE=4294967296
ZRAM_COMP=lzo-rle
SWAPPINESS=60
WINDOW_SCALE=0.1
TRANSITION_SCALE=0.1
ANIMATOR_SCALE=0.1
```

The file is written by the WebUI when the user presses **Guardar configuracion**. It can also be edited manually with any text editor.

---

## Boot Sequence

```
Stage 1 — post-fs-data.sh  (early boot, before /data)
  - Applies game scheduler kernel props (sched_thread_name, sched_lib_name)
  - Applies vbmeta digest spoof
  - No network changes, no system props, no TCP changes

Stage 2 — service.sh  (after boot_completed + 10 s delay)
  - Reads hypervulkan.conf
  - Applies ZRAM, swappiness, dirty_ratio, vfs_cache_pressure
  - Applies I/O scheduler and CPU governor if configured
  - Applies UFS read-ahead if configured
  - Applies all system props that are present in the config
  - Applies TCP tunables if configured
  - Starts VoLTE monitor loop in background (checks gsm.call_state every 4 s)

Runtime — WebUI
  - User changes a value: applies it immediately via ksu.exec()
  - User saves: writes hypervulkan.conf, values persist across reboots
  - Values applied at runtime are also applied by service.sh on next boot
```

---

## File Structure

```
sr.mat/
  module.prop           Module metadata (id, name, version, author)
  customize.sh          Installer script, runs during flash
  post-fs-data.sh       Early boot script
  service.sh            Post-boot script and VoLTE monitor
  uninstall.sh          Cleanup script, runs on module removal
  hypervulkan.conf      User configuration (created after first save)
  webroot/
    index.html          Full WebUI (single file, no external dependencies)
  system/               Empty, required by module format
  META-INF/             Flash metadata
```

---

## Uninstall

Remove the module from KernelSU Manager or Magisk Manager and reboot. The `uninstall.sh` script runs automatically before the reboot and performs the following cleanup:

- Deletes all `persist.*` props written by the module from both RAM and `/data/property/`
- Removes session props (`debug.*`, `dalvik.vm.*`, `audio.*`, etc.) from the current RAM state
- Resets animation scales to `1.0` in the Settings database
- Removes blur-related settings from the Settings database
- Deletes the configuration file

Kernel parameters (TCP tunables, swappiness, schedulers, governors) reset to their stock values automatically on the next boot since they are not stored on disk.

---

## Compatibility

| Component | Status |
|---|---|
| KernelSU-Next | Tested, primary target |
| KernelSU | Compatible |
| Magisk + Zygisk | Compatible |
| APatch | Compatible |
| GKI 5.10 | Tested (Templar Kernel on garnet) |
| GKI 6.1 | Compatible |
| HyperOS 1.x / 2.x | Tested |
| MIUI 14 | Compatible |
| Snapdragon | Full support |
| MediaTek | Partial support (Adreno-specific options inactive) |

BORE toggle is disabled automatically if the kernel does not expose `/proc/sys/kernel/sched_bore`. Governor and scheduler selects are populated from the live kernel, so only values valid for the running kernel appear.

---

## License

```
HyperPerf+ — Kernel and System Configurator
Copyright (C) 2024-2026  srmatdroid

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

https://www.gnu.org/licenses/gpl-3.0.html
```

---

*Author: @srmatdroid — Tested on Redmi Note 13 Pro 5G (garnet) running HyperOS with Templar Kernel and KernelSU-Next.*
