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
rem ---------------------------------------------------------------

rem ---- make sure mkcert is available (install via winget if needed) ----
where mkcert >nul 2>nul
if errorlevel 1 (
    echo Installing mkcert via winget...
    winget install FiloSottile.mkcert --accept-package-agreements --accept-source-agreements
    rem refresh PATH for this session
    set "PATH=%PATH%;%LOCALAPPDATA%\Microsoft\WinGet\Links"
)

rem ---- auto-detect the primary LAN IPv4 ----
for /f "usebackq delims=" %%i in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\scripts\detect-ip.ps1"`) do set "LANIP=%%i"
if not defined LANIP set "LANIP=127.0.0.1"

rem ---- install the local CA and generate certs covering LAN IP + localhost ----
echo Installing local CA into the system trust store...
mkcert -install

echo Generating HTTPS certificate for %LANIP%, localhost, 127.0.0.1 ...
mkcert -key-file data\opengym-key.pem -cert-file data\opengym-cert.pem %LANIP% localhost 127.0.0.1

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