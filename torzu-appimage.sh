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
	echo "Making optimized build of sudachi"
fi
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# BUILD SUDACHI
if [ ! -d ./sudachi ]; then
	git clone https://aur.archlinux.org/sudachi.git sudachi
fi
cd ./sudachi

if [ "$1" = 'v3' ]; then
	sed -i 's/-march=[^"]*/-march=znver2/' ./PKGBUILD
 	sed -i 's/-mtune=[^"]*/-mtune=znver2/' ./PKGBUILD
  	sed -i 's/-Wno-unused-variable/-Wno-unused-variable -Wno-interference-size/' ./PKGBUILD
	sudo sed -i 's/-march=x86-64 /-march=znver2 /' /etc/makepkg.conf # Do I need to do this as well?
	cat /etc/makepkg.conf
else
	sed -i 's/-march=[^"]*/-march=x86-64/' ./PKGBUILD
fi
if ! grep -q -- '-O3' ./PKGBUILD; then
	sed -i 's/-march=/-O3 -march=/' ./PKGBUILD
fi
cat ./PKGBUILD

makepkg -f
sudo pacman --noconfirm -U *.pkg.tar.*
ls .
export VERSION="$(awk -F'=' '/pkgver=/{print $2; exit}' ./PKGBUILD)"
echo "$VERSION" > ~/version
cd ..

# NOW MAKE APPIMAGE
mkdir ./AppDir
cd ./AppDir

echo '[Desktop Entry]
Version=1.0
Type=Application
Name=sudachi
GenericName=Switch Emulator
Comment=Nintendo Switch video game console emulator
Icon=sudachi
TryExec=sudachi
Exec=sudachi %f
Categories=Game;Emulator;Qt;
MimeType=application/x-nx-nro;application/x-nx-nso;application/x-nx-nsp;application/x-nx-xci;
Keywords=Nintendo;Switch;
StartupWMClass=sudachi' > ./sudachi.desktop

if ! wget --retry-connrefused --tries=30 "$ICON" -O sudachi.png; then
	if ! wget --retry-connrefused --tries=30 "$ICON_BACKUP" -O sudachi.png; then
		echo "kek"
		touch ./sudachi.png
	fi
fi
ln -s ./sudachi.png ./.DirIcon

# Bundle all libs
wget --retry-connrefused --tries=30 "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -e -s -k \
	/usr/bin/sudachi* \
	/usr/lib/libGLX* \
	/usr/lib/libGL.so* \
	/usr/lib/libEGL* \
        /usr/lib/libSDL3.so* \
	/usr/lib/vdpau/* \
        /usr/lib/libgamemode.so* \
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
	--compression zstd:level=22 -S26 -B32 \
	--header uruntime \
	-i ./AppDir -o Torzu-"$VERSION"-anylinux-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
echo "All Done!"
