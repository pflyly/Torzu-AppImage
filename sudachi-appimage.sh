#!/bin/sh

set -e

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

pkgver="1.0.15"
HOME_DIR=$(realpath "./")
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
SUDACHI="https://github.com/emuplace/sudachi.emuplace.app/releases/download/v${pkgver}/latest.zip"
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
ARCH_FLAGS="-march=znver2 -mtune=znver2 -O3 -flto=auto"


echo "Making optimized build of sudachi"
# BUILD SUDACHI
if [ ! -d ./sudachi ]; then
	wget -q "$SUDACHI"
	mkdir ./sudachi
	unzip latest.zip -d ./sudachi
 	cp -f ./CMakeLists.txt ./sudachi/src/sudachi_cmd/ #disable non-needed CMD file
fi

cd ./sudachi
# List of submodule paths
submodule_paths=(
    "externals/enet"
    "externals/dynarmic"
    "externals/libusb/libusb"
    "externals/discord-rpc"
    "externals/vulkan-headers"
    "externals/sirit"
    "externals/mbedtls"
    "externals/xbyak"
    "externals/opus"
    "externals/cpp-httplib"
    "externals/ffmpeg/ffmpeg"
    "externals/cpp-jwt"
    "externals/libadrenotools"
    "externals/VulkanMemoryAllocator"
    "externals/breakpad"
    "externals/simpleini"
    "externals/oaknut"
    "externals/Vulkan-Utility-Libraries"
    "externals/vcpkg"
    "externals/nx_tzdb/tzdb_to_nx"
    "externals/cubeb"
    "externals/SDL3"
)

for path in "${submodule_paths[@]}"; do
    if [ -d "$path" ]; then
        echo "Deleting existing folder: $path"
        rm -rf "$path"
    fi
done

git init

git submodule add https://github.com/lsalzman/enet externals/enet
git submodule add https://github.com/sudachi-emu/dynarmic externals/dynarmic
git submodule add https://github.com/libusb/libusb externals/libusb/libusb
git submodule add https://github.com/sudachi-emu/discord-rpc externals/discord-rpc
git submodule add https://github.com/KhronosGroup/Vulkan-Headers externals/vulkan-headers
git submodule add https://github.com/sudachi-emu/sirit externals/sirit
git submodule add https://github.com/sudachi-emu/mbedtls externals/mbedtls
git submodule add https://github.com/herumi/xbyak externals/xbyak
git submodule add https://github.com/xiph/opus externals/opus
git submodule add https://github.com/yhirose/cpp-httplib externals/cpp-httplib
git submodule add https://github.com/FFmpeg/FFmpeg externals/ffmpeg/ffmpeg
git submodule add https://github.com/arun11299/cpp-jwt externals/cpp-jwt
git submodule add https://github.com/bylaws/libadrenotools externals/libadrenotools
git submodule add https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator externals/VulkanMemoryAllocator
git submodule add https://github.com/sudachi-emu/breakpad externals/breakpad
git submodule add https://github.com/brofield/simpleini externals/simpleini
git submodule add https://github.com/sudachi-emu/oaknut externals/oaknut
git submodule add https://github.com/KhronosGroup/Vulkan-Utility-Libraries externals/Vulkan-Utility-Libraries
git submodule add https://github.com/microsoft/vcpkg externals/vcpkg
git submodule add https://github.com/lat9nq/tzdb_to_nx externals/nx_tzdb/tzdb_to_nx
git submodule add https://github.com/mozilla/cubeb externals/cubeb
git submodule add https://github.com/libsdl-org/sdl externals/SDL3

git submodule update --init --recursive

cd externals/cpp-httplib && git checkout 65ce51aed7f15e40e8fb6d2c0a8efb10bcb40126
cd "${HOME_DIR}"/sudachi/externals/xbyak && git checkout v6.68

cd "${HOME_DIR}"/sudachi
mkdir build
cd build
cmake .. -GNinja \
	 -DSUDACHI_USE_BUNDLED_VCPKG=ON \
         -DENABLE_QT6=ON \
	 -DSUDACHI_USE_BUNDLED_FFMPEG=ON \
	 -DSUDACHI_TESTS=OFF \
	 -DSUDACHI_CHECK_SUBMODULES=OFF \
	 -DENABLE_QT_TRANSLATION=ON \
	 -DSUDACHI_ENABLE_LTO=ON \
  	 -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
	 -DCMAKE_INSTALL_PREFIX=/usr \
	 -DCMAKE_CXX_FLAGS="$ARCH_FLAGS -Wno-error -w" \
	 -DCMAKE_C_FLAGS="$ARCH_FLAGS" \
	 -DCMAKE_SYSTEM_PROCESSOR="$(uname -m)" \
	 -DCMAKE_BUILD_TYPE=Release
ninja
VERSION="${pkgver}"
echo "$VERSION" >~/version
echo "$(cat ~/version)"

# use appimage-builder.sh to generate target dir
cd "${HOME_DIR}"
chmod +x ./appimage-builder.sh
./appimage-builder.sh sudachi ./sudachi/build

# turn appdir into appimage
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
	-i ./sudachi/build/deploy-linux/AppDir -o sudachi-v${pkgver}-steamdeck-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
echo "All Done!"
