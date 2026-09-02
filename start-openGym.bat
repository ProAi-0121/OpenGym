@echo off
setlocal
title openGym Launcher
cd /d "%~dp0"

rem ---------------------------------------------------------------
rem   openGym one-click launcher (Windows)
rem   Detects your LAN IPv4, installs deps if needed, then starts:
rem     - media  : python http.server on :8888  (exercise images/GIFs)
rem     - api    : Node backend on :3000        (auth + your data)
rem     - web    : Vite dev server on :5173     (HTTPS, bound to 0.0.0.0)
rem   Open the app at  https://<LAN-IP>:5173  from any device on your LAN.
rem
rem   HTTPS uses self-signed certs made by `mkcert` (data/opengym-cert.pem),
rem   whose CA is already trusted by THIS machine. For passkey login from
rem   OTHER devices, they must also trust that CA (see instructions below).
rem ---------------------------------------------------------------

rem ---- auto-detect the primary LAN IPv4 ----
for /f "usebackq delims=" %%i in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\scripts\detect-ip.ps1"`) do set "LANIP=%%i"
if not defined LANIP set "LANIP=127.0.0.1"

set "SCHEME=https"
if not exist "%CD%\data\opengym-cert.pem" set "SCHEME=http"

echo.
echo  =====================================================
echo   openGym is starting...
echo.
echo   Open it on THIS machine at:   %SCHEME%://%LANIP%:5173
echo   On any LAN device, browse to: %SCHEME%://%LANIP%:5173
echo  =====================================================
echo.

rem ---- one-time dependency install (skipped if already done) ----
if not exist "api\node_modules" (
    echo [1/3] Installing API dependencies...
    pushd api
    call npm ci
    popd
)
if not exist "frontend\node_modules" (
    echo [2/3] Installing frontend dependencies...
    pushd frontend
    call npm ci
    popd
)

rem ---- env vars for the API backend (passed to its own window) ----
set "DATA_DIR=%~dp0data"
set "ORIGIN=%SCHEME%://%LANIP%:5173"
set "RP_ID=%LANIP%"

rem ---- launch the three servers, each in its own window ----
echo [3/3] Starting servers in separate windows...
start "openGym - media  (close this window to stop)" cmd /k "cd /d %~dp0media && python -m http.server 8888"
start "openGym - api    (close this window to stop)" cmd /k "cd /d %~dp0api && node server.js"
start "openGym - web    (close this window to stop)" cmd /k "cd /d %~dp0frontend && npm run dev"

rem ---- open the app in your browser ----
timeout /t 5 /nobreak >nul
start "" "%SCHEME%://%LANIP%:5173"

echo.
echo  All servers are running.
echo  - Each server window shows live logs; close a window to stop that server.
echo  - Keep the three windows running while you use op.
echo.
if "%SCHEME%"=="http" (
    echo  [i] No HTTPS cert found - running on plain http.
    echo      Passkey login needs HTTPS. Run install-https.bat to enable it.
    echo.
)
echo  [i] Passkey login on OTHER devices: they must trust this machine's CA
echo      certificate or the browser blocks passkeys. On each device, install
echo      and trust the root CA, then use %SCHEME%://%LANIP%:5173 :
echo        CA file : %CD%\data\mkcert-rootCA.pem
echo.
pause
endlocal