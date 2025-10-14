@echo off
REM Pre-build script for V8Ray (Windows)
REM This script runs before Flutter build to prepare dependencies

echo === V8Ray Pre-Build Script ===

REM Get script directory
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..

echo Project root: %PROJECT_ROOT%

REM 1. Build Rust Core (generate download info)
echo.
echo Step 1: Building Rust Core...
cd /d "%PROJECT_ROOT%\core"

REM Check build type
set BUILD_MODE=%1
if "%BUILD_MODE%"=="" set BUILD_MODE=debug

if "%BUILD_MODE%"=="release" (
    echo Building in release mode...
    cargo build --release --lib
) else (
    echo Building in debug mode...
    cargo build --lib
)

if errorlevel 1 (
    echo Error: Rust build failed
    exit /b 1
)

echo.
echo √ Pre-build completed successfully
echo.
echo Note: Xray Core will be downloaded after Flutter build to the bundle directory

