#!/bin/zsh
# Builds ZenLib + MediaInfoLib as static libs into Vendor/out. No libcurl/libmms: the library cannot reach the network.
set -euo pipefail
cd "${0:A:h}"
OUT=$PWD/out; rm -rf build out
COMMON=(-DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_INSTALL_PREFIX=$OUT)
cmake -S src/ZenLib/Project/CMake -B build/zen $COMMON
cmake --build build/zen -j 10
cmake --install build/zen
# CMake falls back to a runtime-dlopen curl reader when curl isn't found; drop it so -DMEDIAINFO_LIBCURL_NO wins.
sed -i '' '/MEDIAINFO_LIBCURL_DLL_RUNTIME/d' src/MediaInfoLib/Project/CMake/CMakeLists.txt
cmake -S src/MediaInfoLib/Project/CMake -B build/mi $COMMON -DCMAKE_PREFIX_PATH=$OUT -DBUILD_ZENLIB=OFF -DBUILD_ZLIB=OFF \
  -DCMAKE_DISABLE_FIND_PACKAGE_CURL=ON -DCMAKE_CXX_FLAGS="-DMEDIAINFO_LIBCURL_NO -DMEDIAINFO_LIBMMS_NO"
cmake --build build/mi -j 10
cmake --install build/mi
ls -la $OUT/lib
