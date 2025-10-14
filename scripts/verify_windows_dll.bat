@echo off
REM Verify that v8ray_core.dll is correctly installed in Windows build

setlocal

set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..

echo === V8Ray Windows DLL Verification ===
echo.

REM Check build type
set BUILD_TYPE=%1
if "%BUILD_TYPE%"=="" set BUILD_TYPE=release

echo Build type: %BUILD_TYPE%
echo.

REM Set paths based on build type
if "%BUILD_TYPE%"=="release" (
    set RUST_DLL=%PROJECT_ROOT%\core\target\release\v8ray_core.dll
    set BUNDLE_DIR=%PROJECT_ROOT%\app\build\windows\x64\runner\Release
) else (
    set RUST_DLL=%PROJECT_ROOT%\core\target\debug\v8ray_core.dll
    set BUNDLE_DIR=%PROJECT_ROOT%\app\build\windows\x64\runner\Debug
)

set BUNDLE_DLL=%BUNDLE_DIR%\v8ray_core.dll

echo Checking Rust DLL source...
if exist "%RUST_DLL%" (
    echo [OK] Rust DLL found: %RUST_DLL%
    dir "%RUST_DLL%" | findstr "v8ray_core.dll"
) else (
    echo [ERROR] Rust DLL not found: %RUST_DLL%
    echo Please build Rust library first:
    if "%BUILD_TYPE%"=="release" (
        echo   cd core ^&^& cargo build --release --lib
    ) else (
        echo   cd core ^&^& cargo build --lib
    )
    exit /b 1
)

echo.
echo Checking bundle directory...
if exist "%BUNDLE_DIR%" (
    echo [OK] Bundle directory exists: %BUNDLE_DIR%
) else (
    echo [ERROR] Bundle directory not found: %BUNDLE_DIR%
    echo Please build Flutter app first:
    if "%BUILD_TYPE%"=="release" (
        echo   cd app ^&^& flutter build windows --release
    ) else (
        echo   cd app ^&^& flutter build windows --debug
    )
    exit /b 1
)

echo.
echo Checking DLL in bundle...
if exist "%BUNDLE_DLL%" (
    echo [OK] DLL found in bundle: %BUNDLE_DLL%
    dir "%BUNDLE_DLL%" | findstr "v8ray_core.dll"
    echo.
    echo [SUCCESS] v8ray_core.dll is correctly installed!
) else (
    echo [ERROR] DLL not found in bundle: %BUNDLE_DLL%
    echo.
    echo This means CMake install step did not copy the DLL.
    echo.
    echo Listing bundle directory contents:
    dir "%BUNDLE_DIR%"
    echo.
    echo Expected files in bundle:
    echo   - v8ray.exe
    echo   - v8ray_core.dll  ^<-- MISSING
    echo   - flutter_windows.dll
    echo   - data\
    echo.
    exit /b 1
)

echo.
echo === All checks passed! ===

endlocal

