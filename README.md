# DexOS (Android 11 / R) — Lightweight Gaming ROM Design

## 1) Project Vision
DexOS is a custom Android 11 ROM concept focused on three core goals:
- **Stable gaming performance** on Snapdragon midrange chipsets.
- **Low system footprint** to maximize free storage and reduce memory pressure.
- **Thermally balanced behavior** for sustained play sessions without unsafe tweaks.

Primary target device is **Redmi Note 8 (ginkgo)** (Snapdragon 665, arm64), with a portability model for compatible Qualcomm devices.

---

## 2) High-Level ROM Architecture
DexOS follows a modular architecture based on AOSP/CAF Android 11 foundations:

### A. Base Layer
- **AOSP Android 11 (R)** framework as core.
- CAF-aligned Qualcomm components where practical for Snapdragon tuning.
- SELinux enforcing, verified boot-compatible build assumptions.

### B. Device Abstraction Layer
- **Per-device trees** (`device/<vendor>/<codename>`) to isolate board configs.
- **Common Qualcomm platform tree** for reusable Snapdragon 660/665/675 family settings.
- Vendor-specific overlays to avoid framework hacks.

### C. Kernel + Vendor Interface
- Device-specific kernel source/defconfig alignment.
- Strict compatibility with stock vendor partition expectations.
- HAL contracts preserved (camera/audio/sensors/radio/thermal/power).

### D. Performance Control Layer
- Tuned scheduler/governor parameters via safe defaults.
- LMKD + memory pressure tuning for foreground app stability.
- SurfaceFlinger and input stack adjustments for lower interaction latency.

### E. Product Layer (User Space)
- Minimal app set only (Phone, Messages, Settings, Files, Play Store, required GMS core).
- No duplicate dialer/messages/file manager.
- Removed nonessential packages and background receivers.

---

## 3) Redmi Note 8 (ginkgo) Device Strategy

### Hardware Profile
- SoC: Snapdragon 665 (SM6125)
- CPU topology: performance + efficiency clusters
- GPU: Adreno class suited for sustained 30/60 FPS gaming with proper thermal controls
- RAM/storage class: benefits strongly from low-resident system services

### Device-Tree Implementation (Primary)
- `device/xiaomi/ginkgo` as primary product tree.
- `vendor/xiaomi/ginkgo` for proprietary integration and board-level overlays.
- `kernel/xiaomi/ginkgo` (or equivalent) pinned to Android 11-compatible branch.
- Commonization path:
  - move reusable Qualcomm configs to `device/qcom/sm6125-common` where possible,
  - keep panel/camera/fingerprint specifics in device-local overlays.

### ginkgo-Specific Optimizations
- Conservative CPU frequency scaling profile prioritizing sustained clocks over peak bursts.
- GPU governor profile tuned for frame-time consistency instead of benchmark spikes.
- I/O scheduler and read-ahead tuned for game asset loading without aggressive battery drain.
- Touch input path tuned (sampling/debounce/input boost window) for lower perceived latency.
- Camera and media HAL left close to vendor behavior for daily-driver stability.

---

## 4) Performance & Gaming Optimization Blueprint

### Scheduler and CPU Policy
- Keep EAS/scheduler behavior close to kernel-supported defaults, then apply measured deltas only.
- Foreground/top-app cpuset prioritization for game process responsiveness.
- Restrict heavy background task migration during active gameplay.

### Memory Management
- Tune LMKD minfree thresholds for game retention.
- Enable zRAM with balanced size and lz4 compression for multitasking resilience.
- Disable/trim persistent debugging services and analytics daemons.

### Stable FPS Focus
- Prioritize frame pacing and consistent render-time over short-lived peak FPS.
- Minimize background wakeups/alarms during screen-on gaming sessions.
- Optional per-app performance profiles (default-safe).

### No Unsafe Overclocking
- No CPU/GPU overclocking by default.
- No undervolt assumptions requiring silicon lottery.
- Thermal and power limits remain enforced through Android thermal stack.

### Touch Latency
- Input boost window with strict timeout to avoid sustained heat/power penalties.
- Surface/input thread prioritization within safe scheduler boundaries.

---

## 5) Thermal Management Design (Android 11-Compliant)

### Thermal HAL Logic
- Use Android 11 thermal HAL framework and proper sensor mapping.
- Multi-stage throttling strategy:
  1. soft mitigation (minor frequency caps),
  2. sustained mitigation,
  3. protective cap under prolonged high skin/SoC temperature.

### Sustained Performance Strategy
- Target stable long-session performance instead of peak-first behavior.
- Keep skin temperature within comfortable envelope under common 30–60 min gaming loads.
- Avoid oscillating throttle behavior (rapid up/down frequency jumps).

### Safety
- Preserve vendor thermal trip points and hardware protections.
- Never bypass critical thermal shutdown safeguards.

---

## 6) Storage Optimization Plan

### System Image Minimization
- Remove bloat, demos, nonessential media, redundant overlays.
- Strip noncritical debug packages from user builds.
- Prefer lightweight defaults and shared libraries where compatible.

### Essential App Policy (Only)
Preload:
- Phone
- Messages
- Settings
- Files
- Play Store
- Required Google services (core only)

Exclude:
- Duplicate productivity/media/social apps
- Unused OEM extras
- Secondary app stores

---

## 7) Minimal GApps Integration

### Package Philosophy
- Preintegrated **minimal GApps** profile (pico/core style).
- Include only components required for:
  - Play Store functionality,
  - account sign-in,
  - push notifications,
  - Play Services compatibility.

### Duplicate Prevention
- Keep AOSP app set aligned so Google equivalents do not create duplicates.
- One app per category (dialer, sms, files) unless mandatory dependency exists.

### Lightweight Configuration
- Disable unnecessary pre-granted Google app bundles.
- Keep setup wizard flow short and low-overhead.

---

## 8) Device-Tree Portability Strategy
DexOS portability is based on **device-tree-driven bring-up**, not a universal single build.

### Target Compatibility Class
Designed for devices that have:
- Qualcomm SoC
- arm64 architecture
- unlockable bootloader
- available vendor blobs/proprietary files
- active custom ROM ecosystem (maintained trees/kernels)

### Candidate Devices
- Redmi Note 7 (lavender)
- Redmi Note 8 Pro (begonia, note: MTK variant requires separate path)
- Poco M2 / M3 family (model-dependent feasibility)
- Other Snapdragon 660 / 665 / 675 class phones

### Porting Workflow
1. Bring up device tree and kernel against Android 11 branch.
2. Extract/align proprietary vendor blobs.
3. Validate HAL matrix (audio/camera/RIL/sensors/GNSS/NFC if present).
4. Apply DexOS common performance + thermal overlays.
5. Run CTS/basic stability/regression checks.

---

## 9) Why Full Universal Compatibility Is Impossible
DexOS can be portable, but never truly universal due to:
- **Kernel differences** (drivers, defconfig, scheduler behavior).
- **Vendor partition coupling** (binary compatibility constraints).
- **HAL implementation variance** (camera/audio/display/biometrics behavior differs).
- **Proprietary drivers/blobs** tied to chipset, panel, modem, and firmware versions.

This means each supported device requires dedicated maintenance, testing, and release validation.

---

## 10) Android 11-Specific Engineering Considerations
- Respect Android 11 partitioning model and dynamic partition constraints where used.
- Maintain SELinux enforcing policy quality for security and app compatibility.
- Validate scoped storage behavior with game launchers and file managers.
- Ensure Power HAL / Thermal HAL cooperation for sustained gaming workloads.
- Keep SafetyNet/Play Integrity implications documented (where applicable to unlock/root states).

---

## 11) Boot Animation Specification (DexOS Branding)
Target animation length: **~3–5 seconds**, modern and smooth.

### Visual Sequence
1. **Frame 0–30%**: Minimal dark background fade-in.
2. **Frame 30–60%**: Stylized animated eye appears (subtle glow/pulse).
3. **Frame 60–80%**: Eye morphs into a GitHub-style icon/logo silhouette.
4. **Frame 80–100%**: Text `DexOS` appears exactly **30 px below** the final logo.

### Typography & Color
- Text: `DexOS`
- Position: centered horizontally, 30 px below logo anchor.
- Fill: red → yellow linear gradient.
- Anti-aliased vector-like rendering for clean look on HD/FHD panels.

### Packaging Notes
- Implement with Android bootanimation zip sequence (`desc.txt` + PNG/WebP frames).
- Keep asset size compressed to preserve lightweight ROM goal.

---

## 12) Daily-Driver Stability Policy
- Prioritize reliability for calls, data, Wi-Fi, Bluetooth, camera, GPS, and sensors.
- Ship conservative defaults first; expose advanced tuning as optional.
- Use staged release validation (internal -> beta -> stable).

DexOS should feel fast and light every day, while still delivering consistent gaming performance without thermal abuse.
