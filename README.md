# protobuf-ue4

Build Protobuf for Unreal Engine 4

## Supported Platforms

- Mac
- iOS
- Windows(x64)

### Currently unsupported

- Linux
- Android

## Prerequesties

- Mac/iOS
  - Xcode
  - Git
  - CMake
- Windows
  - Visual Studio Professional (If you wanna use Community Edition, you have to modify the path string to Visual Studio in the batch file.)
  - Git
  - CMake


## Patches

### v3.19.1

- `fix: Respect protobuf_MSVC_STATIC_RUNTIME option when using (CMake 3.15+)` (original: [https://github.com/protocolbuffers/protobuf/pull/9153](https://github.com/protocolbuffers/protobuf/pull/9153))
- `fix: Use #ifdef for undefined identifiers` (original: [https://github.com/protocolbuffers/protobuf/pull/9201](https://github.com/protocolbuffers/protobuf/pull/9201))
- `fix: disable warning C4946 (Windows)`

