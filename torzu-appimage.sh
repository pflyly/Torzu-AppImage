#!/bin/sh

set -e

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME=$(wget -q https://api.github.com/repos/VHSgunzo/uruntime/releases -O - \
	| sed 's/[()",{} ]/\n/g' | grep -oi "https.*appimage.*dwarfs.*$ARCH$" | head -1)
ICON="https://notabug.org/litucks/torzu/raw/02cfee3f184e6fdcc3b483ef399fb5d2bb1e8ec7/dist/yuzu.png"
ICON_BACKUP="https://free-git.org/Emulator-Archive/torzu/raw/branch/master/dist/yuzu.png"

if [ "$1" = 'v3' ]; then
	echo "Making optimized build of torzu"
        ARCH_FLAGS="-march=znver2 -mtune=znver2 -O3 -ffast-math -flto=auto"
fi
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# BUILD TORZU
if [ ! -d ./torzu ]; then
	git clone --depth 1 https://notabug.org/litucks/torzu.git
fi

(
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
		-DYUZU_CHECK_SUBMODULES=OFF \
		-DYUZU_USE_LLVM_DEMANGLE=OFF \
                -DYUZU_USE_BUNDLED_SDL2=ON \
 		-DYUZU_USE_EXTERNAL_SDL2=OFF \
		-DYUZU_ENABLE_LTO=ON \
                -DENABLE_QT_TRANSLATION=ON\
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_CXX_FLAGS="$ARCH_FLAGS -Wno-error" \
		-DCMAKE_C_FLAGS="$ARCH_FLAGS" \
		-DCMAKE_SYSTEM_PROCESSOR="$(uname -m)" \
		-DCMAKE_BUILD_TYPE=Release
	ninja
	sudo ninja install
	echo "$VERSION" >~/version
)
rm -rf ./torzu
VERSION="$(cat ~/version)"

# NOW MAKE APPIMAGE
cd ..
mkdir ./AppDir
cd ./AppDir

echo '[Desktop Entry]
Version=1.0
Type=Application
Name=torzu
GenericName=Switch Emulator
Comment=Nintendo Switch video game console emulator
Icon=torzu
TryExec=yuzu
Exec=yuzu %f
Categories=Game;Emulator;Qt;
MimeType=application/x-nx-nro;application/x-nx-nso;application/x-nx-nsp;application/x-nx-xci;
Keywords=Nintendo;Switch;
StartupWMClass=yuzu' > ./torzu.desktop

if ! wget --retry-connrefused --tries=30 "$ICON" -O torzu.png; then
	if ! wget --retry-connrefused --tries=30 "$ICON_BACKUP" -O torzu.png; then
		echo "kek"
		touch ./torzu.png
	fi
fi
ln -s ./torzu.png ./.DirIcon

# Bundle all libs
wget --retry-connrefused --tries=30 "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -e -s -k \
	/usr/bin/yuzu* \
	/usr/lib/libGLX* \
	/usr/lib/libGL.so* \
	/usr/lib/libEGL* \
	/usr/lib/dri/* \
	/usr/lib/libvulkan* \
	/usr/lib/qt/plugins/audio/* \
	/usr/lib/qt/plugins/bearer/* \
	/usr/lib/qt/plugins/imageformats/* \
	/usr/lib/qt/plugins/iconengines/* \
	/usr/lib/qt/plugins/platforms/* \
	/usr/lib/qt/plugins/platformthemes/* \
	/usr/lib/qt/plugins/platforminputcontexts/* \
	/usr/lib/qt/plugins/styles/* \
	/usr/lib/qt/plugins/xcbglintegrations/* \
	/usr/lib/qt/plugins/wayland-*/* \
	/usr/lib/pulseaudio/* \
	/usr/lib/alsa-lib/*

# Prepare sharun
ln ./sharun ./AppRun
./sharun -g

# turn appdir into appimage
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
	-i ./AppDir -o Torzu-"$VERSION"-Steamdeck-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
echo "All Done!"
