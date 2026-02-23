#!/usr/bin/env bash
set -euo pipefail

# Build helper for DexOS on Redmi Note 8 (ginkgo).
# Run from Android source root.

if [[ ! -f build/envsetup.sh ]]; then
  echo "[ERROR] Run this script from the Android source root." >&2
  exit 1
fi

source build/envsetup.sh
lunch lineage_ginkgo-userdebug
mka bacon

echo "[OK] Build completed. Check out/target/product/ginkgo/."
