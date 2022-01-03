#!/bin/bash

set -ex

if [[ -z "${PROTOBUF_UE4_VERSION}" ]]; then
  echo "PROTOBUF_UE4_VERSION is not set, exit."
  exit 1
else
  echo "PROTOBUF_UE4_VERSION: ${PROTOBUF_UE4_VERSION}"
fi

if [[ -z "${PROTOBUF_UE4_PREFIX}" ]]; then
  echo "PROTOBUF_UE4_PREFIX is not set, exit."
  exit 1
else
  echo "PROTOBUF_UE4_PREFIX: ${PROTOBUF_UE4_PREFIX}"
fi

if [[ -z "${PROTOBUF_UE4_IOS_DEPLOYMENT_TARGET}" ]]; then
  echo "PROTOBUF_UE4_IOS_DEPLOYMENT_TARGET is not set, exit."
  exit 1
else
  echo "PROTOBUF_UE4_IOS_DEPLOYMENT_TARGET: ${PROTOBUF_UE4_IOS_DEPLOYMENT_TARGET}"
fi

if ! command -v git &> /dev/null; then
    echo "git could not be found"
    exit 1
fi

# clone repository
readonly PROTOBUF_URL=git@github.com:protocolbuffers/protobuf.git
readonly PROTOBUF_DIR=protobuf-${PROTOBUF_UE4_VERSION}

git clone  --depth=1 --single-branch ${PROTOBUF_URL} ${PROTOBUF_DIR} -b v${PROTOBUF_UE4_VERSION}
git -C ${PROTOBUF_DIR} submodule update --init --recursive --recommend-shallow --depth=1 

# Apply patch if the patch file exists
readonly PATCH_FILE=v${PROTOBUF_UE4_VERSION}.patch

if [ -f "$PATCH_FILE" ]; then
  pushd ${PROTOBUF_DIR}
    git apply < ../${PATCH_FILE}
  popd
fi

# Make install dest path
mkdir -p "${PROTOBUF_UE4_PREFIX}"

# Build library
readonly CORE_COUNT=$(sysctl -n machdep.cpu.core_count)

pushd ${PROTOBUF_DIR}/cmake
  cmake -DCMAKE_INSTALL_PREFIX="${PROTOBUF_UE4_PREFIX}" . -G "Xcode" -T buildsystem=1
  xcodebuild -project protobuf.xcodeproj                               \
    -target libprotobuf                                                \
    -configuration Release                                             \
    -sdk iphoneos                                                      \
    -arch arm64                                                        \
    IPHONEOS_DEPLOYMENT_TARGET=${PROTOBUF_UE4_IOS_DEPLOYMENT_TARGET}   \
    GCC_SYMBOLS_PRIVATE_EXTERN=YES                                     \
    -jobs ${CORE_COUNT}                                                \
    build
  xcodebuild -project protobuf.xcodeproj                               \
    -target libprotobuf-lite                                           \
    -configuration Release                                             \
    -sdk iphoneos                                                      \
    -arch arm64                                                        \
    IPHONEOS_DEPLOYMENT_TARGET=${PROTOBUF_UE4_IOS_DEPLOYMENT_TARGET}   \
    GCC_SYMBOLS_PRIVATE_EXTERN=YES                                     \
    -jobs ${CORE_COUNT}                                                \
    build
  xcodebuild -target install build

  # TODO: delete the code below, shoud use xcodebuild config.
  mv Release-iphoneos/libprotobuf.a "${PROTOBUF_UE4_PREFIX}/lib/libprotobuf.a"
  mv Release-iphoneos/libprotobuf-lite.a "${PROTOBUF_UE4_PREFIX}/lib/libprotobuf-lite.a"

  lipo -info "${PROTOBUF_UE4_PREFIX}/lib/libprotobuf.a"
  lipo -info "${PROTOBUF_UE4_PREFIX}/lib/libprotobuf-lite.a"
popd
