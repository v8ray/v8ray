@echo off
REM Build script for V8Ray (Windows)
REM Usage: build.bat [debug|release] [--force-xray]

setlocal

REM Get script directory
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..

REM Default build type
set BUILD_TYPE=%1
if "%BUILD_TYPE%"=="" set BUILD_TYPE=debug

set FORCE_XRAY=%2

echo === V8Ray Build Script ===
echo Build type: %BUILD_TYPE%

REM Run pre-build script
echo.
call "%SCRIPT_DIR%\pre_build.bat" %BUILD_TYPE%

if errorlevel 1 (
    echo Error: Pre-build failed
    exit /b 1
)

REM Build Flutter application
echo.
echo Step 2: Building Flutter application...
cd /d "%PROJECT_ROOT%\app"

if "%BUILD_TYPE%"=="release" (
    echo Building Flutter app in release mode...
    flutter build windows --release
) else (
    echo Building Flutter app in debug mode...
    flutter build windows --debug
)

if errorlevel 1 (
    echo Error: Flutter build failed
    exit /b 1
)

REM Run post-build script (download Xray Core)
echo.
call "%SCRIPT_DIR%\post_build.bat" %BUILD_TYPE% %FORCE_XRAY%

if errorlevel 1 (
    echo Error: Post-build failed
    exit /b 1
)

echo.
echo √ Build completed successfully
echo.
echo Executable location:
if "%BUILD_TYPE%"=="release" (
    echo   %PROJECT_ROOT%\app\build\windows\x64\runner\Release\v8ray.exe
    echo Xray Core location:
    echo   %PROJECT_ROOT%\app\build\windows\x64\runner\Release\bin\xray.exe
) else (
    echo   %PROJECT_ROOT%\app\build\windows\x64\runner\Debug\v8ray.exe
    echo Xray Core location:
    echo   %PROJECT_ROOT%\app\build\windows\x64\runner\Debug\bin\xray.exe
)

endlocal

