@echo off
REM Post-build script for V8Ray (Windows)
REM This script runs after Flutter build to download Xray Core to the bundle directory

echo === V8Ray Post-Build Script ===

REM Get script directory
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..

echo Project root: %PROJECT_ROOT%

REM Get build mode
set BUILD_MODE=%1
if "%BUILD_MODE%"=="" set BUILD_MODE=debug

echo Build mode: %BUILD_MODE%

REM Download Xray Core to build output directory
echo.
echo Downloading Xray Core to bundle directory...
cd /d "%PROJECT_ROOT%\scripts"

REM Check if force update is requested
set FORCE_FLAG=
if "%2"=="--force-xray" (
    set FORCE_FLAG=--force
    echo Force update Xray Core enabled
)

dart download_xray.dart --build-mode %BUILD_MODE% %FORCE_FLAG%

if errorlevel 1 (
    echo Error: Xray download failed
    exit /b 1
)

echo.
echo √ Post-build completed successfully

