#!/bin/sh

set -e

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"

echo "Making optimized build of torzu"
ARCH_FLAGS="-march=znver2 -mtune=znver2 -O3 -flto=auto"

UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# Clone the Torzu repository from notabug mirror if it doesn't exist
if [ ! -d ./torzu ]; then
	git clone --depth 1 https://notabug.org/litucks/torzu.git
fi

# Build Torzu
cd ./torzu
COUNT="$(git rev-list --count HEAD)"
HASH="$(git rev-parse --short HEAD)"
DATE="$(date +"%Y%m%d")"
VERSION="${HASH}"
git submodule update --init --recursive -j$(nproc)

# Replaces 'boost::asio::io_service' with 'boost::asio::io_context' for compatibility with Boost.ASIO versions 1.74.0 and later
find src -type f -name '*.cpp' -exec sed -i 's/boost::asio::io_service/boost::asio::io_context/g' {} \;
	
mkdir build
cd build
cmake .. -GNinja \
	 -DYUZU_USE_BUNDLED_VCPKG=OFF \
  	 -DENABLE_QT6=ON \
	 -DYUZU_USE_BUNDLED_QT=OFF \
	 -DYUZU_USE_BUNDLED_FFMPEG=OFF \
	 -DYUZU_TESTS=OFF \
         -DYUZU_CMD=OFF \
	 -DYUZU_CHECK_SUBMODULES=OFF \
	 -DYUZU_USE_LLVM_DEMANGLE=OFF \
         -DYUZU_USE_BUNDLED_SDL2=ON \
 	 -DYUZU_USE_EXTERNAL_SDL2=OFF \
	 -DYUZU_ENABLE_LTO=ON \
  	 -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
	 -DCMAKE_INSTALL_PREFIX=/usr \
	 -DCMAKE_CXX_FLAGS="$ARCH_FLAGS -Wno-error" \
	 -DCMAKE_C_FLAGS="$ARCH_FLAGS" \
	 -DCMAKE_SYSTEM_PROCESSOR="$(uname -m)" \
	 -DCMAKE_BUILD_TYPE=Release
ninja
sudo ninja install
echo "$VERSION" >~/version

# use appimage-builder.sh to generate target dir
cd ..
cd ..
chmod +x ./appimage-builder.sh
./appimage-builder.sh torzu ./torzu/build

# turn build dir into appimage
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S26 -B32 \
	--header uruntime \
	-i ./torzu/build/deploy-linux/AppDir -o Torzu-"${DATE}"-"${COUNT}"-"${HASH}"-Steamdeck.AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
echo "All Done!"
