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

if [[ -z "${PROTOBUF_UE4_MACOS_DEPLOYMENT_TARGET}" ]]; then
  echo "PROTOBUF_UE4_MACOS_DEPLOYMENT_TARGET is not set, exit."
  exit 1
else
  echo "PROTOBUF_UE4_MACOS_DEPLOYMENT_TARGET: ${PROTOBUF_UE4_MACOS_DEPLOYMENT_TARGET}"
fi

if ! command -v git &> /dev/null; then
    echo "git could not be found"
    exit 1
fi

# clone repository
readonly PROTOBUF_URL=git@github.com:protocolbuffers/protobuf.git
readonly PROTOBUF_DIR=protobuf-${PROTOBUF_UE4_VERSION}

git clone --depth=1 --single-branch ${PROTOBUF_URL} ${PROTOBUF_DIR} -b v${PROTOBUF_UE4_VERSION}
git -C ${PROTOBUF_DIR} submodule update --init --recursive --recommend-shallow --depth=1

# Apply patch if the patch file exists
readonly PATCH_FILE=patch/v${PROTOBUF_UE4_VERSION}.patch

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
  cmake .                                                                 \
    -Dprotobuf_BUILD_SHARED_LIBS=OFF                                      \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=${PROTOBUF_UE4_MACOS_DEPLOYMENT_TARGET} \
    -DCMAKE_BUILD_TYPE=Release                                            \
    -DCMAKE_INSTALL_PREFIX="${PROTOBUF_UE4_PREFIX}"

  make -j${CORE_COUNT}
  make check
  make install

  otool -hv "${PROTOBUF_UE4_PREFIX}/lib/libprotobuf.a" | head -n 25
popd
