#!/bin/bash -ex
git clone --depth 1 https://notabug.org/litucks/torzu.git

cd ./torzu
git submodule update --init --recursive

COUNT="$(git rev-list --count HEAD)"
HASH="$(git rev-parse --short HEAD)"
DATE="$(date +"%Y%m%d")"

case "$1" in
    msvc)
        echo "Making Trozu for Windows (MSVC)"
        if ! echo "$PATH" | grep -q "/c/ProgramData/chocolatey/bin"; then
            export PATH="$PATH:/c/ProgramData/chocolatey/bin"
        fi
        echo "PATH is: $PATH"
        TARGET="Windows-MSVC"
        ;;
    msys2)
        echo "Making Torzu for Windows (MSYS2)"
        TARGET="Windows-MSYS2"
        ;;
esac
EXE_NAME="Torzu-${DATE}-${COUNT}-${HASH}-${TARGET}"

mkdir build
cd build
cmake .. -G Ninja \
    -DYUZU_TESTS=OFF \
    -DENABLE_QT6=ON \
    -DENABLE_WEB_SERVICE=OFF \
    -DYUZU_ENABLE_LTO=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_TOOLCHAIN_FILE=${{ github.workspace }}/vcpkg/scripts/buildsystems/vcpkg.cmake \
    -DVCPKG_TARGET_TRIPLET=<triplet> \
    -DVCPKG_MANIFEST_MODE=OFF
ninja

# Use windeployqt to gather dependencies
EXE_PATH=./bin/torzu.exe
mkdir deploy
cp -r ./bin deploy/
windeployqt --release --no-compiler-runtime --no-transitive-include-plugins --dir deploy "$EXE_PATH"

if [ "$1" = "msys2" ]; then
    if command -v strip >/dev/null 2>&1; then
            strip -s deploy/*.exe || true
    fi        
fi

# Pack for upload
mkdir -p artifacts
mkdir "$EXE_NAME"
cp -r deploy/* "$EXE_NAME"
ZIP_NAME="$EXE_NAME.zip"

if [ "$1" = "msvc" ]; then
    powershell Compress-Archive "$EXE_NAME" "$ZIP_NAME"
else
    zip -r "$ZIP_NAME" "$EXE_NAME"
fi

mv "$ZIP_NAME" artifacts/

echo "Build completed successfully."
