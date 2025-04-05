#!/bin/bash
# reg_server, 2024-01-09

set -e

# check arguments
if [[ $# != 2 ]]; then
    >&2 echo "Invalid arguments!"
    echo "Usage: $0 torzu|sudachi <build dir>"
    exit 1
fi

BUILD_APP="$1"
if [[ "${BUILD_APP}" != "torzu" && "${BUILD_APP}" != "sudachi" ]]; then
    >&2 echo "Invalid arguments!"
    echo "Usage: $0 torzu|sudachi <build dir>"
    exit 1
fi

BUILD_DIR=$(realpath "$2")
if [[ ! -d "${BUILD_DIR}" ]]; then
    >&2 echo "Invalid arguments!"
    echo "'$2' is not a directory"
    exit 1
fi

DEPLOY_LINUX_FOLDER="${BUILD_DIR}/deploy-linux"
DEPLOY_LINUX_APPDIR_FOLDER="${BUILD_DIR}/deploy-linux/AppDir"
BIN_FOLDER="${BUILD_DIR}/bin"
BIN_EXE="${BIN_FOLDER}/${BUILD_APP//torzu/yuzu}"

CPU_ARCH=$(uname -m)

#export DISPLAYVERSION="1.2.3" # before cmake

BIN_EXE_MIME_TYPE=$(file -b --mime-type "${BIN_EXE}")
if [[ "${BIN_EXE_MIME_TYPE}" != "application/x-pie-executable" && "${BIN_EXE_MIME_TYPE}" != "application/x-executable" ]]; then
    >&2 echo "Invalid or missing main executable (${BIN_EXE})!"
    exit 1
fi

mkdir -p "${DEPLOY_LINUX_FOLDER}"
rm -rf "${DEPLOY_LINUX_APPDIR_FOLDER}"

cd "${BUILD_DIR}"

# deploy/install to deploy-linux/AppDir
DESTDIR="${DEPLOY_LINUX_APPDIR_FOLDER}" ninja install

cd "${DEPLOY_LINUX_FOLDER}"

curl -fsSLo ./linuxdeploy "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-${CPU_ARCH}.AppImage"
chmod +x ./linuxdeploy

curl -fsSLo ./linuxdeploy-plugin-qt "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-${CPU_ARCH}.AppImage"
chmod +x ./linuxdeploy-plugin-qt

curl -fsSLo ./linuxdeploy-plugin-checkrt.sh https://github.com/darealshinji/linuxdeploy-plugin-checkrt/releases/download/continuous/linuxdeploy-plugin-checkrt.sh
chmod +x ./linuxdeploy-plugin-checkrt.sh

# Add Qt 6 specific environment variables
export QT_QPA_PLATFORM="wayland;xcb"
export EXTRA_PLATFORM_PLUGINS="libqwayland-egl.so;libqwayland-generic.so;libqxcb.so"
export EXTRA_QT_PLUGINS="svg;wayland-decoration-client;wayland-graphics-integration-client;wayland-shell-integration;waylandcompositor;xcb-gl-integration;platformthemes/libqt6ct.so"

NO_STRIP=1 APPIMAGE_EXTRACT_AND_RUN=1 ./linuxdeploy --appdir ./AppDir --plugin qt --plugin checkrt

# remove libwayland-client because it has platform-dependent exports and breaks other OSes
rm -fv ./AppDir/usr/lib/libwayland-client.so*

# remove libvulkan because it causes issues with gamescope
rm -fv ./AppDir/usr/lib/libvulkan.so*

./linuxdeploy --appimage-extract
./squashfs-root/plugins/linuxdeploy-plugin-appimage/usr/bin/appimagetool ./AppDir -g
