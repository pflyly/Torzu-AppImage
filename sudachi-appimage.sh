#!/bin/sh

set -e

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"
export pkgver=1.0.14

LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
SUDACHI="https://github.com/emuplace/sudachi.emuplace.app/releases/download/v${pkgver}/latest.zip"

if [ "$1" = 'v3' ]; then
	echo "Making optimized build of sudachi"
	ARCH_FLAGS="-march=znver2 -mtune=znver2 -O3 -flto=auto"
fi

UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# BUILD SUDACHI
if [ ! -d ./sudachi ]; then
	wget -q "$SUDACHI"
	mkdir ./sudachi
	unzip latest.zip -d ./sudachi
fi

cd ./sudachi
git init
git submodule update --init --recursive

#Replaces 'boost::asio::io_service' with 'boost::asio::io_context' for compatibility with Boost.ASIO versions 1.74.0 and later
find src -type f -name '*.cpp' -exec sed -i 's/boost::asio::io_service/boost::asio::io_context/g' {} \;

COMM_HASH="$(git rev-parse --short HEAD)"
VERSION="${COMM_HASH}"
mkdir build
cd build
cmake .. -GNinja \
	 -DSUDACHI_USE_BUNDLED_VCPKG=OFF \
	 -DSUDACHI_USE_BUNDLED_QT=OFF \
	 -DSUDACHI_USE_BUNDLED_FFMPEG=OFF \
	 -DSUDACHI_TESTS=OFF \
	 -DSUDACHI_CHECK_SUBMODULES=OFF \
	 -DSUDACHI_USE_LLVM_DEMANGLE=OFF \
	 -DENABLE_QT_TRANSLATION=ON \
	 -DSUDACHI_ENABLE_LTO=ON \
	 -DCMAKE_INSTALL_PREFIX=/usr \
	 -DCMAKE_CXX_FLAGS="$ARCH_FLAGS -Wno-error" \
	 -DCMAKE_C_FLAGS="$ARCH_FLAGS" \
	 -DCMAKE_SYSTEM_PROCESSOR="$(uname -m)" \
	 -DCMAKE_BUILD_TYPE=Release
ninja
sudo ninja install
echo "$VERSION" >~/version

# NOW MAKE APPIMAGE, use appimage-builder.sh to generate target dir
cd
chmod +x ./appimage-builder.sh
./appimage-builder.sh sudachi ./sudachi/build
rm -rf ./sudachi/build/deploy-linux/sudachi*.AppImage # Delete the generated appimage, cause it's useless now
cp /usr/lib/libSDL3.so* ./sudachi/build/deploy-linux/AppDir/usr/lib/ # Copying libsdl3 to the already done appdir

# turn appdir into appimage
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
	--compression zstd:level=22 -S26 -B32 \
	--header uruntime \
	-i ./sudachi/build/deploy-linux/AppDir -o sudachi-"$VERSION"-steamdeck-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
echo "All Done!"
