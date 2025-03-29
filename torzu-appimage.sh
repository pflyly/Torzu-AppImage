#!/bin/sh

set -e

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME=$(wget -q https://api.github.com/repos/VHSgunzo/uruntime/releases -O - \
	| sed 's/[()",{} ]/\n/g' | grep -oi "https.*appimage.*dwarfs.*$ARCH$" | head -1)
ICON="https://notabug.org/litucks/torzu/raw/02cfee3f184e6fdcc3b483ef399fb5d2bb1e8ec7/dist/yuzu.png"
ICON_BACKUP="https://free-git.org/Emulator-Archive/torzu/raw/branch/master/dist/yuzu.png"

# Check for optimized build flag
if [ "$1" = 'v3' ]; then
	echo "Making optimized build of torzu"
        ARCH_FLAGS="-march=znver2 -mtune=znver2 -O3 -ffast-math -flto=auto"
else
	ARCH_FLAGS=""
fi

UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# Clone the Torzu repository from notabug mirror if it doesn't exist
if [ ! -d ./torzu ]; then
	git clone --depth 1 https://notabug.org/litucks/torzu.git
fi

# Build Torzu

cd ./torzu
COMM_HASH="$(git rev-parse --short HEAD)"
VERSION="${COMM_HASH}"
git submodule update --init --recursive -j$(nproc)
#Replaces 'boost::asio::io_service' with 'boost::asio::io_context' for compatibility with Boost.ASIO versions 1.74.0 and later
find src -type f -name '*.cpp' -exec sed -i 's/boost::asio::io_service/boost::asio::io_context/g' {} \;
	
mkdir build
cd build
cmake .. -GNinja \
	 -DYUZU_USE_BUNDLED_VCPKG=OFF \
	 -DYUZU_USE_BUNDLED_QT=OFF \
	 -DYUZU_USE_BUNDLED_FFMPEG=OFF \
	 -DYUZU_TESTS=OFF \
         -DYUZU_CMD=OFF \
	 -DYUZU_CHECK_SUBMODULES=OFF \
	 -DYUZU_USE_LLVM_DEMANGLE=OFF \
         -DYUZU_USE_BUNDLED_SDL2=ON \
 	 -DYUZU_USE_EXTERNAL_SDL2=OFF \
	 -DYUZU_ENABLE_LTO=ON \
	 -DCMAKE_INSTALL_PREFIX=/usr \
	 -DCMAKE_CXX_FLAGS="$ARCH_FLAGS -Wno-error" \
	 -DCMAKE_C_FLAGS="$ARCH_FLAGS" \
	 -DCMAKE_SYSTEM_PROCESSOR="$(uname -m)" \
	 -DCMAKE_BUILD_TYPE=Release
ninja
sudo ninja install
echo "$VERSION" >~/version

# NOW MAKE APPIMAGE, use AppImage-build.sh to generate target dir
cd ..
chmod +x ./AppImage-build.sh
./AppImage-build.sh
rm -rf ./torzu*.AppImage # Delete the generated appimage, cause it's useless now
cp /usr/lib/libSDL3.so* ./AppImageBuilder/build/ # Copying libsdl3 to the already done appdir

# turn build dir into appimage
cd ..
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
printf "$UPINFO" > data.upd_info
llvm-objcopy --update-section=.upd_info=data.upd_info \
	--set-section-flags=.upd_info=noload,readonly ./uruntime
printf 'AI\x02' | dd of=./uruntime bs=1 count=3 seek=8 conv=notrunc

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S23 -B16 \
	--header uruntime \
	-i ./torzu/AppImageBuilder/build -o Torzu-"$VERSION"-Steamdeck-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
echo "All Done!"
