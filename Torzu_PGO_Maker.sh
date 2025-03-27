#!/bin/bash

git clone --depth 1 https://notabug.org/litucks/torzu.git
cd torzu
git submodule update --init --recursive -j$(nproc)

# Start to build torzu PGO instrument
mkdir build
cd $HOME/torzu/build
cmake .. -GNinja -DYUZU_USE_BUNDLED_VCPKG=ON -DYUZU_TESTS=OFF -DYUZU_USE_LLVM_DEMANGLE=OFF -DYUZU_CMD=OFF -DYUZU_ENABLE_LTO=ON -DYUZU_ENABLE_PGO_INSTRUMENT=ON -DYUZU_ENABLE_PGO_OPTIMIZE=OFF -DCMAKE_CXX_FLAGS="-march=znver2 -mtune=znver2 -O3 -ffast-math -flto=auto -Wno-error=missing-profile" -DCMAKE_C_FLAGS="-march=znver2 -mtune=znver2 -O3 -ffast-math -flto=auto -Wno-error=missing-profile" -DCMAKE_SYSTEM_PROCESSOR=x86_64 -DCMAKE_BUILD_TYPE=Release
ninja

# Start to build PGO optimized after running the PGO instrument build for several times to generate engough profiles
cd $HOME/torzu/build
cmake .. -GNinja -DYUZU_USE_BUNDLED_VCPKG=ON -DYUZU_TESTS=OFF -DYUZU_USE_LLVM_DEMANGLE=OFF -DYUZU_CMD=OFF -DYUZU_ENABLE_LTO=ON -DYUZU_ENABLE_PGO_INSTRUMENT=OFF -DYUZU_ENABLE_PGO_OPTIMIZE=ON -DCMAKE_CXX_FLAGS="-march=znver2 -mtune=znver2 -O3 -ffast-math -flto=auto -fprofile-correction -Wno-error=missing-profile" -DCMAKE_C_FLAGS="-march=znver2 -mtune=znver2 -O3 -ffast-math -fprofile-correction -flto=auto -Wno-error=missing-profile" -DCMAKE_SYSTEM_PROCESSOR=x86_64 -DCMAKE_BUILD_TYPE=Release
ninja

# Zip the outcome binaries, rename and move the final zip to any desired place for sharing
cd $HOME/torzu/build/bin
zip -r torzu.zip ./
LATEST_ZIP=$(ls -1t torzu*.zip | head -n 1) # find the most recent zip
COMM_HASH="$(git rev-parse --short=9 HEAD)"
BUILD_DATE=$(date +"%Y%m%d")
ZIP_NAME="torzu-${BUILD_DATE}-${COMM_HASH}-x86_64.zip"
sudo mv -v -f "${LATEST_ZIP}" "${ZIP_NAME}"
FILESIZE=$(du -h ${ZIP_NAME}  | awk '{ print $1 }')
SHA256SUM=$(sha256sum "./${ZIP_NAME}" | awk '{ print $1 }')
echo -e "\033[31m${ZIP_NAME}\033[0m has been moved to \033[32m$HOME/Emu/Switch/torzu/zip/\033[0m"
echo -e "File Size=\033[31m${FILESIZE}\033[0m | SHA256SUM=\033[31m${SHA256SUM}\033[0m"
sudo mv -f $HOME/torzu/build/bin/torzu*.zip $HOME/Emu/Switch/torzu/zip/


# Create appimage using torzu Appimage_builder,the resulting torzu.AppImage will be in the torzu folder
cd .. && ./AppImage-build.sh

# Delete the build folder for building cleanly next time
cd $HOME/torzu
sudo rm -rf $HOME/torzu/build
