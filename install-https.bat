@echo off
setlocal
title openGym - HTTPS setup
cd /d "%~dp0"

rem ---------------------------------------------------------------
rem   Set up HTTPS for openGym over your LAN (needed for passkey login).
rem   Installs mkcert (if missing), installs its local CA into THIS
rem   machine's trust store, and generates a certificate for your LAN IP.
rem   Copy the generated data\mkcert-rootCA.pem to OTHER devices and
rem   trust it there too, so their browsers accept this server.
rem
rem   Works without winget (e.g. Windows 8.1): if mkcert is not found,
rem   the mkcert.exe binary is downloaded straight from GitHub into
rem   the local "tools" folder - no package manager required.
rem ---------------------------------------------------------------

rem ---- locate or fetch mkcert ----
set "MKCERT="
where mkcert >nul 2>nul
if not errorlevel 1 set "MKCERT=mkcert"
if not defined MKCERT (
    set "LOCALMK=%~dp0tools\mkcert.exe"
    if exist "%LOCALMK%" (
        set "MKCERT=%LOCALMK%"
    ) else (
        echo [mkcert] Not found - downloading from GitHub...
        if not exist "%~dp0tools" mkdir "%~dp0tools"
        powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install-mkcert.ps1" -OutFile "%LOCALMK%"
        if exist "%LOCALMK%" (
            set "MKCERT=%LOCALMK%"
        ) else (
            echo.
            echo  ERROR: could not download mkcert. Your machine may not trust GitHub's
            echo  TLS certificate, or the connection was blocked.
            echo.
            echo  Workarounds:
            echo    1) Download it in your browser and save it here, then re-run:
            echo         https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-windows-amd64.exe
            echo       place it at:
            echo         %~dp0tools\mkcert.exe
            echo    2) Or download the installer and put mkcert.exe on your PATH.
            echo.
            pause
            exit /b 1
        )
    )
)

rem ---- auto-detect the primary LAN IPv4 ----
for /f "usebackq delims=" %%i in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\scripts\detect-ip.ps1"`) do set "LANIP=%%i"
if not defined LANIP set "LANIP=127.0.0.1"

rem ---- install the local CA and generate certs covering LAN IP + localhost ----
echo Installing local CA into the system trust store...
"%MKCERT%" -install

echo Generating HTTPS certificate for %LANIP%, localhost, 127.0.0.1 ...
"%MKCERT%" -key-file data\opengym-key.pem -cert-file data\opengym-cert.pem %LANIP% localhost 127.0.0.1

rem ---- expose the root CA so other devices can trust it ----
if exist "%LOCALAPPDATA%\mkcert\rootCA.pem" copy /y "%LOCALAPPDATA%\mkcert\rootCA.pem" data\mkcert-rootCA.pem >nul

echo.
echo  ============================================================
echo   HTTPS is ready.
echo   Start the app with start-openGym.bat, then open:
echo       https://%LANIP%:5173
echo.
echo   THIS machine already trusts the CA.
echo   For OTHER devices (phone, laptop...) install this CA file
echo   and mark it as trusted, then open the URL above:
echo       %CD%\data\mkcert-rootCA.pem
echo  ============================================================
echo.
pause
endlocal