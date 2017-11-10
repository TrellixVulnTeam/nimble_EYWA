@echo off
cd "%~dp0"
cd "../.."

set BASE_DIR=%cd:\=/%
cd torch/lib

set INSTALL_DIR=%cd:\=/%/tmp_install
set PATH=%INSTALL_DIR%/bin;%PATH%
set BASIC_C_FLAGS= /DTH_INDEX_BASE=0 /I%INSTALL_DIR%/include /I%INSTALL_DIR%/include/TH /I%INSTALL_DIR%/include/THC /I%INSTALL_DIR%/include/THS /I%INSTALLDIR%/include/THCS /I%INSTALLDIR%/include/THPP /I%INSTALLDIR%/include/THNN /I%INSTALLDIR%/include/THCUNN
set BASIC_CUDA_FLAGS= -DTH_INDEX_BASE=0 -I%INSTALL_DIR%/include -I%INSTALL_DIR%/include/TH -I%INSTALL_DIR%/include/THC -I%INSTALL_DIR%/include/THS -I%INSTALLDIR%/include/THCS -I%INSTALLDIR%/include/THPP -I%INSTALLDIR%/include/THNN -I%INSTALLDIR%/include/THCUNN
set LDFLAGS=/LIBPATH:%INSTALL_DIR%/lib
:: set TORCH_CUDA_ARCH_LIST=6.1

set CWRAP_FILES=%BASE_DIR%/torch/lib/ATen/Declarations.cwrap;%BASE_DIR%/torch/lib/ATen/Local.cwrap;%BASE_DIR%/torch/lib/THNN/generic/THNN.h;%BASE_DIR%/torch/lib/THCUNN/generic/THCUNN.h;%BASE_DIR%/torch/lib/ATen/nn.yaml
set C_FLAGS=%BASIC_C_FLAGS% /D_WIN32 /Z7 /EHa /DNOMINMAX
set LINK_FLAGS=/DEBUG:FULL

mkdir tmp_install

IF "%~1"=="--with-cuda" (
  set /a NO_CUDA=0
  shift
) ELSE (
  set /a NO_CUDA=1
)

IF "%CMAKE_GENERATOR%"=="" (
  set CMAKE_GENERATOR_COMMAND=
  set MAKE_COMMAND=msbuild INSTALL.vcxproj /p:Configuration=Release
) ELSE (
  set CMAKE_GENERATOR_COMMAND=-G "%CMAKE_GENERATOR%"
  IF "%CMAKE_GENERATOR%"=="Ninja" (
    set CC=cl.exe
    set CXX=cl.exe
    set MAKE_COMMAND=cmake --build . --target install --config Release -- -j%NUMBER_OF_PROCESSORS% || exit /b 1
  ) ELSE (
    set MAKE_COMMAND=msbuild INSTALL.vcxproj /p:Configuration=Release
  )
)


:read_loop
if "%1"=="" goto after_loop
if "%1"=="ATen" (
  call:build_aten %~1
) ELSE (
  call:build %~1
)
shift
goto read_loop

:after_loop

copy /Y tmp_install\lib\* .
IF EXIST ".\tmp_install\bin" (
  copy /Y tmp_install\bin\* .
)
xcopy /Y /E tmp_install\include\*.* include\*.*
xcopy /Y ..\..\aten\src\THNN\generic\THNN.h  .
xcopy /Y ..\..\aten\src\THCUNN\generic\THCUNN.h .

goto:eof

:build
  @setlocal
  IF NOT "%PREBUILD_COMMAND%"=="" call "%PREBUILD_COMMAND%" %PREBUILD_COMMAND_ARGS%
  mkdir build\%~1
  cd build/%~1
  cmake ../../%~1 %CMAKE_GENERATOR_COMMAND% ^
                  -DCMAKE_MODULE_PATH=%BASE_DIR%/cmake/FindCUDA ^
                  -DTorch_FOUND="1" ^
                  -DCMAKE_INSTALL_PREFIX="%INSTALL_DIR%" ^
                  -DCMAKE_C_FLAGS="%C_FLAGS%" ^
                  -DCMAKE_SHARED_LINKER_FLAGS="%LINK_FLAGS%" ^
                  -DCMAKE_CXX_FLAGS="%C_FLAGS% %CPP_FLAGS%" ^
                  -DCUDA_NVCC_FLAGS="%BASIC_CUDA_FLAGS%" ^
                  -Dcwrap_files="%CWRAP_FILES%" ^
                  -DTH_INCLUDE_PATH="%INSTALL_DIR%/include" ^
                  -DTH_LIB_PATH="%INSTALL_DIR%/lib" ^
                  -DTH_LIBRARIES="%INSTALL_DIR%/lib/ATen.lib" ^
                  -DTHS_LIBRARIES="%INSTALL_DIR%/lib/ATen.lib" ^
                  -DTHC_LIBRARIES="%INSTALL_DIR%/lib/ATen.lib" ^
                  -DTHCS_LIBRARIES="%INSTALL_DIR%/lib/ATen.lib" ^
                  -DATEN_LIBRARIES="%INSTALL_DIR%/lib/ATen.lib" ^
                  -DTHNN_LIBRARIES="%INSTALL_DIR%/lib/ATen.lib" ^
                  -DTHCUNN_LIBRARIES="%INSTALL_DIR%/lib/ATen.lib" ^
                  -DTH_SO_VERSION=1 ^
                  -DTHC_SO_VERSION=1 ^
                  -DTHNN_SO_VERSION=1 ^
                  -DTHCUNN_SO_VERSION=1 ^
                  -DNO_CUDA=%NO_CUDA% ^
                  -Dnanopb_BUILD_GENERATOR=0 ^
                  -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=TRUE ^
                  -DCMAKE_BUILD_TYPE=Release

  %MAKE_COMMAND%
  cd ../..
  @endlocal

goto:eof

:build_aten
  @setlocal
  IF NOT "%PREBUILD_COMMAND%"=="" call "%PREBUILD_COMMAND%" %PREBUILD_COMMAND_ARGS%
  mkdir build\%~1
  cd build/%~1
  cmake ../../../../%~1 %CMAKE_GENERATOR_COMMAND% ^
                  -DCMAKE_INSTALL_PREFIX="%INSTALL_DIR%" ^
                  -DNO_CUDA=%NO_CUDA% ^
                  -DCUDNN_INCLUDE_DIR="%CUDNN_INCLUDE_DIR%" ^
                  -DCUDNN_LIB_DIR="%CUDNN_LIB_DIR%" ^
                  -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=TRUE ^
                  -DCMAKE_BUILD_TYPE=Release

  %MAKE_COMMAND%
  cd ../..
  @endlocal

goto:eof

