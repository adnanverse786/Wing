# DexOS (Android 11 / API 30) Build Guide for Redmi Note 8 (ginkgo)

This guide explains a realistic, beginner-friendly workflow to build **DexOS** as a lightweight Android 11 ROM based on **LineageOS 18.1 / AOSP 11** for **Xiaomi Redmi Note 8 (ginkgo)**.

---

## 1) Build Environment Setup (Ubuntu/Linux)

## Recommended host OS
- **Ubuntu 20.04 LTS** is the safest/common choice for Android 11 ROM trees.
- Ubuntu 22.04 can work, but older Android build scripts may need extra compatibility tweaks.

## Hardware requirements
- **CPU:** modern 6+ cores recommended.
- **RAM:**
  - Minimum: 16 GB (builds will be slow and may fail under memory pressure)
  - Recommended: 32 GB+
- **Storage (SSD strongly recommended):**
  - Source tree + out dir + ccache can exceed **250 GB**
  - Keep at least **350 GB free** for comfortable work.

## Required packages
Run:

```bash
sudo apt update
sudo apt install -y \
  bc bison build-essential ccache curl flex g++-multilib gcc-multilib \
  git git-lfs gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev \
  lib32z1-dev libelf-dev libgl1-mesa-dev liblz4-tool libncurses5-dev \
  libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync \
  schedtool squashfs-tools xsltproc zip zlib1g-dev \
  python3 python-is-python3 adb fastboot unzip fontconfig
```

> If `python-is-python3` is unavailable, install `python3` and ensure `python` resolves to Python 3 (via update-alternatives or symlink).

## Repo tool installation

```bash
mkdir -p ~/.local/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.local/bin/repo
chmod a+x ~/.local/bin/repo
echo 'export PATH=~/.local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
repo version
```

## Java version requirement
- For LineageOS 18.1, use **OpenJDK 11**.

```bash
sudo apt install -y openjdk-11-jdk
java -version
```

If multiple JDKs are installed, select 11:

```bash
sudo update-alternatives --config java
sudo update-alternatives --config javac
```

## Optional but highly recommended: ccache

```bash
export USE_CCACHE=1
ccache -M 100G
```

Put `export USE_CCACHE=1` in your shell profile for persistence.

---

## 2) Source Code Initialization (LineageOS 18.1 / Android 11)

## Create workspace

```bash
mkdir -p ~/android/dexos
cd ~/android/dexos
```

## Initialize repo for LOS 18.1

```bash
repo init -u https://github.com/LineageOS/android.git -b lineage-18.1
```

## Sync sources

```bash
repo sync --force-sync --current-branch --no-clone-bundle --no-tags -j$(nproc --all)
```

First sync can take a long time (hours depending on connection/storage).

## Common sync issues and fixes

1. **Network disconnect / RPC failures**
   - Retry sync with lower parallelism:
   ```bash
   repo sync -j4 --fail-fast
   ```

2. **Out-of-space errors**
   - Free disk, remove stale `out/`, and re-run sync.

3. **Corrupt project checkout**
   - Re-sync specific project:
   ```bash
   repo sync --force-sync path/to/project
   ```

4. **Git LFS object problems** (for projects using LFS)
   ```bash
   git lfs install
   repo sync -j4
   ```

---

## 3) Device-Specific Requirements (ginkgo)

For any ROM build you need three major device-side components:

1. **Device tree** (`device/xiaomi/ginkgo`)
2. **Kernel source** (`kernel/xiaomi/ginkgo` or similar)
3. **Vendor blobs** (`vendor/xiaomi/ginkgo`)

## Device tree purpose
Device tree declares how Android is assembled for the device:
- Product makefiles (`device.mk`, `lineage_ginkgo.mk`)
- Board config (`BoardConfig.mk`)
- Init scripts, fstab, overlays, SELinux rules
- Partition and hardware configuration

## Kernel source usage
Kernel source provides Linux kernel + device drivers and defconfig for ginkgo hardware.
- Must match Android 11 requirements and vendor userspace expectations.
- Wrong kernel branch/defconfig commonly causes boot failures, broken Wi-Fi, camera, sensors, or modem issues.

## Vendor blobs explanation
Vendor blobs are proprietary binaries from Xiaomi/MIUI (camera HAL, media codecs, radio components, graphics userspace, etc.).
- Typically extracted from MIUI firmware matching your Android base/vendor image expectations.
- Without correct blobs, build may finish but ROM can fail at runtime (camera crash, no RIL, no audio, bootloop).

## ginkgo vs other devices
Compared to “generic” Android device bring-up, ginkgo has device-specific differences:
- Different partition layouts and mount behavior
- Hardware-specific HAL stack (camera/audio/display/radio)
- Unique kernel defconfig and dtbo expectations
- Recovery and firmware compatibility constraints

Never reuse another Xiaomi model’s tree/kernel/blobs directly, even if chipset is similar.

## Fetching ginkgo trees (example flow)
Use known working LOS 18.1 sources from maintainers/communities.
Typical approach:
- Add local manifests under `.repo/local_manifests/roomservice.xml`
- Point to device/kernel/vendor repos compatible with LOS 18.1

Then:

```bash
repo sync -j$(nproc --all)
```

---

## 4) Building DexOS

## Set up build environment

```bash
cd ~/android/dexos
source build/envsetup.sh
```

## Select target (lunch)
Common pattern for LOS-based trees:

```bash
lunch lineage_ginkgo-userdebug
```

If your product name is customized for DexOS in product makefiles, it may be something like:

```bash
lunch dexos_ginkgo-userdebug
```

Use `lunch` with no args to list available products.

## Build command

```bash
mka bacon -j$(nproc --all)
```

If `bacon` target is not present in your tree, use:

```bash
mka otapackage -j$(nproc --all)
```

## Output files
Usually in:

```text
out/target/product/ginkgo/
```

Common outputs:
- `boot.img`
- `recovery.img` (if built)
- `dtbo.img` (if applicable)
- `vbmeta.img` (if generated)
- ROM package zip (flashable OTA/update zip)

## Source tree vs flashable ZIP
- **Source tree**: all code/config used to compile Android.
- **Flashable ZIP**: packaged build artifacts + updater scripts used by recovery/update engine to install on the device.

You do **not** flash raw source; you flash generated images/zip.

---

## 5) ROM Customization (Lightweight DexOS)

## Remove bloatware safely
Prefer removing optional apps from product package lists rather than deleting core framework components.

Where to adjust:
- Device/product makefiles (`PRODUCT_PACKAGES += ...`)
- Inherited package lists

Examples of safe removals:
- Extra wallpapers/live wallpapers
- Non-essential AOSP apps you don’t need
- Unused debug/demo apps

Avoid removing critical services (SetupWizard equivalents, Telephony components on phone builds, permissions controllers, etc.) unless you understand dependency graph.

## Reduce storage footprint
- Keep only required locales (if your policy allows)
- Reduce bootanimation size (resolution/fps/compression)
- Exclude unnecessary media/fonts
- Use `WITH_GMS := false` unless you intentionally ship GMS (licensing implications)

## Basic performance tuning concepts
- Keep scheduler/governor defaults from stable device maintainers.
- Minimize background services, logging verbosity, and debug props in user builds.
- Prefer upstream LOS performance improvements over aggressive “tweaks”.

## Safe thermal considerations
Do **not** disable/relax thermal throttling to chase benchmark scores.
- Keep thermal HAL and kernel thermal configs sane.
- Overheating causes throttling, battery degradation, and instability.
- Stable sustained performance is better than short burst scores.

---

## 6) Boot Animation

## How `bootanimation.zip` works
A zip with:
- `desc.txt`
- One or more frame directories (`part0`, `part1`, ...)
- Sequentially numbered image frames inside each part

## `desc.txt` format
Typical line format:

```text
<width> <height> <fps>
p <loop_count> <pause> <folder_name>
```

Example:

```text
1080 2340 30
p 1 0 part0
p 0 0 part1
```

- `p 1 0 part0` plays once
- `p 0 0 part1` loops forever until boot complete

## Resolution and timing
- Use device-appropriate resolution (or optimized scaled size to reduce memory/IO).
- Typical fps: 24–30 for smoothness without heavy overhead.

## Placement in ROM
Common paths:
- `/system/media/bootanimation.zip`
- or `/product/media/bootanimation.zip` (depends on product configuration)

Set through product makefiles by copying/prebuilt package directives.

---

## 7) Common Build/Boot Errors and Debugging

## Missing vendor blobs
Symptoms:
- Build errors referencing proprietary modules
- Runtime failures in camera/RIL/media

Fix:
- Re-extract blobs from correct MIUI base
- Verify proprietary-files lists and makefile entries

## Kernel compile failures
Symptoms:
- `ninja` failure in kernel target
- Missing symbols/headers/defconfig issues

Fix:
- Confirm correct kernel branch for Android 11
- Verify defconfig name and board config linkage
- Check toolchain expectations used by the device tree

## Bootloop causes
Common causes:
- Incompatible vendor/firmware
- Wrong SELinux policies (denials during init)
- Broken fstab/mount points
- Mismatched dtbo/vbmeta/AVB handling

## Debugging basics
1. Capture logs:
   ```bash
   adb logcat
   adb shell dmesg
   ```
2. For early boot issues, use recovery logs and kernel logs.
3. Review `last_kmsg`/ramoops if available after crash.
4. Compare with known-working build’s init/fstab/SEPolicy.

---

## 8) Flashing Requirements and Safety

## Bootloader unlock is mandatory
You cannot flash custom ROMs safely on locked bootloader devices.
- Use Xiaomi official unlock flow and wait periods.

## Recovery requirements
Use a recovery compatible with ginkgo and Android 11 builds (commonly an updated TWRP/OrangeFox variant compatible with encryption and dynamic behaviors expected by your ROM).

## Clean flash baseline (recommended for first boot)
1. Backup all data.
2. In recovery: wipe `data`, `cache`, `dalvik/art`, and system-related partitions as required by your ROM instructions.
3. Flash required firmware/vendor compatibility package if needed.
4. Flash DexOS zip.
5. Optionally flash add-ons (e.g., Magisk/GApps) only if build policy supports them.
6. Reboot and wait patiently for first boot.

## Safety precautions
- Keep battery > 60%.
- Verify file checksums before flashing.
- Keep a known-good recovery image and stock fastboot ROM handy for unbrick/recovery.
- Do not mix random firmware packages from different Android bases.

---

## 9) Practical Beginner Workflow (Recommended)

1. Build plain LOS 18.1 for ginkgo first (no customization).
2. Boot-test basic hardware (RIL, Wi-Fi, audio, camera, sensors, GPS).
3. Create DexOS branding + minimal app/package removals.
4. Rebuild and regression test.
5. Change one subsystem at a time; keep changelog per build.
6. Tag working milestones in git.

This “small-step” method is the fastest way to learn ROM bring-up without getting stuck in hard-to-debug bootloops.
