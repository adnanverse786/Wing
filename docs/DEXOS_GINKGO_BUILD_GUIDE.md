# DexOS Android 11 Build Guide (Redmi Note 8 / ginkgo)

This guide explains a **realistic beginner workflow** for building a lightweight Android 11 custom ROM (DexOS) using a LineageOS 18.1 / AOSP 11 base.

> Scope note: there is no true "one-click ROM creation." A working ROM requires proper device tree, kernel, proprietary vendor blobs, and repeated debug/flash/test cycles.

## 1) Build environment setup (Ubuntu/Linux)

## 1.1 Recommended host OS
- Ubuntu 20.04 LTS (most common for Android 11 trees)
- Ubuntu 22.04 can work, but some older trees/toolchains may need compatibility fixes.

## 1.2 Hardware requirements (practical)
- **CPU**: 8+ threads recommended.
- **RAM**: 16 GB minimum; 32 GB preferred.
- **Disk**:
  - source checkout + out dir: 220–350 GB
  - ccache (optional but recommended): +50–100 GB
  - keep at least 450 GB free to avoid failed builds.

## 1.3 Required packages
```bash
sudo apt update
sudo apt install -y \
  bc bison build-essential ccache curl flex g++-multilib gcc-multilib git gnupg gperf \
  imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev libelf-dev libgl1-mesa-dev \
  liblz4-tool libncurses5 libncurses5-dev libsdl1.2-dev libssl-dev libxml2 libxml2-utils \
  lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev \
  python3 python-is-python3 openjdk-11-jdk repo
```

If `repo` is unavailable from your distro package, install it manually (next section).

## 1.4 Repo tool installation (manual fallback)
```bash
mkdir -p ~/.local/bin
curl -L https://storage.googleapis.com/git-repo-downloads/repo -o ~/.local/bin/repo
chmod a+rx ~/.local/bin/repo
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
repo version
```

## 1.5 Java requirement
- Android 11 / LineageOS 18.1 should use **OpenJDK 11**.
- Verify:
```bash
java -version
```
Expected major version: 11.

## 2) Source code initialization

## 2.1 Create workspace + init lineage-18.1
```bash
mkdir -p ~/android/dexos
cd ~/android/dexos
repo init -u https://github.com/LineageOS/android.git -b lineage-18.1 --git-lfs
```

## 2.2 Sync source
```bash
repo sync -c --no-clone-bundle --no-tags -j$(nproc --all)
```

For unstable networks, reduce parallelism (for example `-j4`) and rerun; `repo sync` is resumable.

## 2.3 Common sync issues
- **HTTP/2 stream reset / RPC failed**: rerun sync, lower `-j`, and ensure disk isn't full.
- **`fatal: not a git repository` in project**: remove broken project folder and rerun sync.
- **`repo: command not found`**: fix PATH and re-open shell.
- **quota/disk exhaustion**: clean old `out/` dirs and run `df -h` before another sync.

## 3) Device-specific requirements (ginkgo)

DexOS cannot boot from AOSP source alone. You need three essential components:

1. **Device tree** (`device/xiaomi/ginkgo`)
   - BoardConfig, product makefiles, init scripts, fstab/recovery configs.
2. **Kernel source** (`kernel/xiaomi/ginkgo` or vendor-common kernel)
   - Contains board-specific drivers and defconfig for ginkgo.
3. **Vendor blobs** (`vendor/xiaomi/ginkgo`)
   - Proprietary binaries/HAL libs (camera, modem, audio, GPU, etc.) extracted from MIUI/stock firmware.

## 3.1 Why ginkgo differs from other devices
Even when two phones share a Qualcomm family:
- display panel drivers can differ,
- camera stack and sensor firmware differ,
- fingerprint and touch ICs differ,
- partition layout and dtbo/dtb packaging can differ.

So a ROM from another codename is not directly portable without adaptation.

## 3.2 Add local manifests for device/kernel/vendor
Create `.repo/local_manifests/ginkgo.xml` pointing to your chosen repos. Example template is provided in this repository at `dexos/manifests/ginkgo_roomservice.xml`.

Then sync again:
```bash
repo sync -c --no-clone-bundle --no-tags -j$(nproc --all)
```

## 4) Building DexOS

From source root (`~/android/dexos`):

```bash
source build/envsetup.sh
lunch lineage_ginkgo-userdebug
mka bacon
```

Alternative lineage target in some trees:
```bash
brunch ginkgo
```

## 4.1 Output artifacts
Typical outputs under:
- `out/target/product/ginkgo/`

Expected files include:
- `lineage-18.1-<date>-UNOFFICIAL-ginkgo.zip` (flashable ROM package)
- `boot.img`
- `recovery.img` (if built)
- `dtbo.img` / `vbmeta.img` (tree dependent)

## 4.2 Source tree vs flashable ZIP
- **Source tree**: complete code + configs used to compile Android.
- **Flashable ZIP**: prebuilt package updater-script/payload that recovery can install.

Users flash the ZIP; developers edit source and rebuild ZIP.

## 5) ROM customization (lightweight focus)

## 5.1 Remove bloat safely
- Remove nonessential packages from product makefiles (`PRODUCT_PACKAGES` entries).
- Keep core telephony, setup, media codecs, and required permission controllers.
- Remove duplicates (only one dialer/messages/files app set).

## 5.2 Reduce storage footprint
- prefer `user`/`userdebug` without debug extras for release builds,
- strip preloaded wallpapers/media/demo apps,
- avoid shipping duplicate libraries and overlays.

## 5.3 Basic performance tuning
- LMKD minfree tuning for better game process retention,
- balanced zRAM size (avoid over-allocation),
- conservative scheduler/governor defaults for sustained performance.

## 5.4 Thermal safety (important)
- Do **not** disable thermal HAL or throttle policies.
- Keep vendor thermal trip points intact.
- Avoid extreme CPU/GPU overclock or persistent input boost hacks.

## 6) Boot animation integration

## 6.1 How `bootanimation.zip` works
Inside zip:
- `desc.txt`
- folders like `part0/`, `part1/` containing sequential PNG frames.

Example `desc.txt`:
```txt
1080 2340 30
p 1 0 part0
p 0 0 part1
```
Meaning: width, height, FPS, then play parts (loop rules per line).

## 6.2 Resolution and timing
- Match target display aspect ratio when possible.
- Keep fps moderate (24–30) for size and boot-time efficiency.
- Keep total animation length around 3–5 seconds for DexOS.

## 6.3 Placement in ROM
Common placement:
- `vendor/prebuilt/common/bootanimation.zip`
- or product copy files rule in your device/product makefile.

A starter structure is included here under `dexos/templates/bootanimation/`.

## 7) Common build errors and first-line debugging

## 7.1 Missing vendor blobs
Symptoms:
- `module ... not found`
- linker errors for proprietary libs
- runtime camera/RIL crashes

Fix:
- re-extract blobs from matching MIUI build,
- verify proprietary-files lists and makefile copy rules.

## 7.2 Kernel compile failures
Symptoms:
- clang/gcc errors in kernel objects,
- missing defconfig or headers mismatch.

Fix:
- use kernel branch intended for lineage-18.1,
- validate `TARGET_KERNEL_CONFIG` and clang compatibility.

## 7.3 Bootloop causes
Common causes:
- wrong/sepolicy-denied init services,
- bad fstab/mount points,
- mismatched vendor and system blobs,
- broken overlays causing SystemUI crash at boot.

Debug basics:
```bash
adb logcat
adb shell dmesg
adb shell getprop ro.build.fingerprint
```
Capture logs right after first boot attempt.

## 8) Flashing requirements and safety

## 8.1 Bootloader unlock is mandatory
- Xiaomi bootloader must be unlocked first.
- Locked bootloader will block unsigned custom images.

## 8.2 Recovery requirement
Use up-to-date custom recovery compatible with Android 11 dynamic partitions (for example recent OrangeFox/TWRP builds for ginkgo).

## 8.3 Flash flow (high level)
1. Backup current ROM and persist partition where relevant.
2. Reboot to recovery.
3. Wipe data/cache/system as required by your migration path.
4. Flash DexOS zip.
5. Flash optional addons (e.g., Magisk) only after base ROM first boot test.
6. Reboot and wait.

## 8.4 Safety precautions
- verify downloaded zips/checksums,
- keep battery above 50%,
- never interrupt flashing,
- keep known-good stock fastboot package available for recovery.

## 9) Minimal file set checklist for custom ROM bring-up

At minimum, a practical device bring-up needs:
- `device/xiaomi/ginkgo/AndroidProducts.mk`
- `device/xiaomi/ginkgo/lineage_ginkgo.mk`
- `device/xiaomi/ginkgo/BoardConfig.mk`
- `device/xiaomi/ginkgo/vendorsetup.sh`
- `kernel/xiaomi/ginkgo/*` with valid defconfig
- `vendor/xiaomi/ginkgo/*` proprietary blobs + makefiles
- optional `device/xiaomi/sm6125-common/*` if using common tree split
- local manifest entries for all the above

This repository includes starter templates and helper script stubs under `dexos/` to show expected structure.
