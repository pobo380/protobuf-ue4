@echo off

@REM 
@REM Please make sure the following environment variables are set before calling this script:
@REM PROTOBUF_UE4_VERSION - Release version string.
@REM PROTOBUF_UE4_PREFIX  - Absolute install path prefix string.
@REM 

@if "%PROTOBUF_UE4_VERSION%"=="" (
    echo PROTOBUF_UE4_VERSION is not set, exit.
    exit /b 1
)

@if "%PROTOBUF_UE4_PREFIX%"=="" (
    echo PROTOBUF_UE4_PREFIX is not set, exit.
    exit /b 1
)

@if "%COMPILER%"=="" (
    echo COMPILER_VERSION is not set, exit.
    exit /b 1
)

where git.exe >nul 2>nul
@if not ERRORLEVEL 0 (
    echo git could not be found, exit.
    exit /b 1
)

set CURRENT_DIR=%cd%
@REM We only need x64 (VsDevCmd.bat defaults arch to x86, pass -help to see all available options)
set PROTOBUF_ARCH=x64
@REM Tell CMake to use dynamic CRT (/MD) instead of static CRT (/MT)
set PROTOBUF_CMAKE_OPTIONS=-Dprotobuf_BUILD_SHARED_LIBS=ON -Dprotobuf_MSVC_STATIC_RUNTIME=OFF

@REM -----------------------------------------------------------------------
@REM Set Environment Variables for the Visual Studio %COMPILER% Command Line
set VSDEVCMD=C:\Program Files (x86)\Microsoft Visual Studio\%COMPILER%\Professional\Common7\Tools\VsDevCmd.bat
if exist "%VSDEVCMD%" (
    @REM Tell VsDevCmd.bat to set the current directory, in case [USERPROFILE]\source exists. See:
    @REM C:\Program Files (x86)\Microsoft Visual Studio\%COMPILER%\Professional\Common7\Tools\vsdevcmd\core\vsdevcmd_end.bat
     set VSCMD_START_DIR=%CD%
     call "%VSDEVCMD%" -arch=%PROTOBUF_ARCH%
      ) else (
     echo ERROR: Cannot find Visual Studio %COMPILER%
     exit /b 2
)

@REM Clone Repository
set PROTOBUF_URL=git@github.com:protocolbuffers/protobuf.git
set PROTOBUF_DIR=protobuf-%PROTOBUF_UE4_VERSION%

git clone --depth=1 --single-branch %PROTOBUF_URL% %PROTOBUF_DIR% -b v%PROTOBUF_UE4_VERSION%
git -C %PROTOBUF_DIR% submodule update --init --recursive --recommend-shallow --depth=1

@REM Apply patch if the patch file exists
set PATCH_FILE=%cd%\patch\v%PROTOBUF_UE4_VERSION%.patch

if exist "%PATCH_FILE%" (
    pushd %PROTOBUF_DIR%
        git apply --ignore-whitespace < %PATCH_FILE%
    popd
) else (
    echo protobuf-%PROTOBUF_UE4_VERSION% has not been modified
)

@REM Make install dest path
mkdir "%PROTOBUF_UE4_PREFIX%"
cd "%CURRENT_DIR%"

@REM Build library

pushd %PROTOBUF_DIR%\cmake
    cmake -G "NMake Makefiles" ^
        -DCMAKE_BUILD_TYPE=Release ^
        -DCMAKE_INSTALL_PREFIX="%PROTOBUF_UE4_PREFIX%" ^
        %PROTOBUF_CMAKE_OPTIONS% .
    nmake
    nmake check
    nmake install
popd
