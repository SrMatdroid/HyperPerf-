# ⚡ HyperPerf+
### Kernel & System Configurator para HyperOS / MIUI con Root

`sr.matdroid® • HyperOS+ • v1.0 • GPLv3`

---

## 🛠️ ¿Qué hace este módulo?

HyperPerf+ aplica en el arranque un conjunto de optimizaciones de kernel y sistema que HyperOS/MIUI no expone al usuario, y añade una **WebUI** accesible desde KSU/Magisk para ajustar y guardar cada parámetro en tiempo real, sin tocar archivos a mano.

No es un módulo de props genérico copiado de internet. Cada ajuste está revisado y probado en hardware Snapdragon real.

---

## 🎛️ ¿Qué configura?

### Kernel
| Parámetro | Descripción |
|-----------|-------------|
| **ZRAM** | Tamaño (1–8 GB) y algoritmo de compresión (lzo-rle / lz4 / zstd) |
| **Swappiness** | Preferencia RAM vs ZRAM. Ticks de referencia: 10 gaming · 60 balance · 100 default |
| **I/O Scheduler** | mq-deadline (recomendado) / bfq / none |
| **CPU Governor** | schedutil / performance / conservative y demás disponibles en el kernel |
| **UFS Read-Ahead** | Prefetch de lectura. Ticks: 1K gaming · 2K recomendado |
| **BORE Scheduler** | Activar si el kernel lo soporta (burst-oriented responsive) |
| **VFS Cache Pressure** | Retención de caché de filesystem en RAM (50 perf · 100 default) |
| **Dirty Ratio** | Agresividad de flush de escrituras a UFS |
| **Adreno GPU Pool** | Memoria reservada para el GPU (512 mid-range · 1024 flagship) |

### Tweaks de sistema
- Props de rendimiento para SurfaceFlinger, HWUI y renderthread
- Optimización de audio: buffer size, offload, Bluetooth LDAC/A2DP
- Game Turbo / MIGT para reconocimiento de procesos de juego en HyperOS
- Blur disable (fixes lag en Control Center)
- Props de integridad del sistema

### vbmeta / AVB
- Lectura del estado de verificación de arranque (`green` / `orange` / `red`)
- Backup de la partición vbmeta → `/data/adb/vbmeta_backup.img`
- Patch para deshabilitar AVB (requerido en algunos kernels modificados)
- Restore desde backup con un botón

---

## 📱 Compatibilidad

Probado en **Redmi Note 13 Pro 5G** (garnet / Snapdragon 7s Gen 2 / Adreno 710 / HyperOS 3).

Diseñado para ser universal: los ajustes de kernel leen el hardware disponible antes de aplicar, no asume governor ni scheduler fijo.

> Snapdragon · MediaTek(REVISA POST-FS-DATA) — siempre que el kernel exponga los nodos estándar de Linux.

---

## 📦 Instalación

1. Descarga el `.zip` desde **Releases**.
2. Instala desde **Magisk**, **KernelSU** o **APatch**.
3. Reinicia.
4. Abre la **WebUI** desde el gestor (botón ▶ junto al módulo en KSU, o vía navegador en `http://localhost:PUERTO`).

> ⚠️ Se necesita root con acceso a `resetprop`, `sysctl` y escritura en `/sys`. Funciona en KernelSU-Next y Magisk Delta/Official.

---

## 🌐 WebUI

La interfaz web corre localmente en el dispositivo vía el servidor integrado en KSU/Magisk WebUI. No necesita internet.

- Sliders con **marcas de valores óptimos** (gaming · balance · default del kernel)
- Cambios aplicados en caliente + guardado persistente para el reinicio
- Registro de operaciones con timestamps
- Sección vbmeta colapsable (para quien no la necesite)

---

## 📜 Licencia

**GPL v3** — El código es libre y debe seguir siéndolo. Si lo usas como base, comparte los cambios y cita la fuente.

---

## ⚠️ Aviso

Modificar parámetros de kernel puede causar inestabilidad si se combinan valores extremos. La sección vbmeta escribe directamente en la partición — haz siempre backup antes. El autor no se hace responsable de bricks por configuraciones incorrectas.
