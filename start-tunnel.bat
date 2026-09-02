@echo off
setlocal
title openGym - Tunnel Launcher (plain HTTP)
cd /d "%~dp0"

rem ---------------------------------------------------------------
rem  openGym for use behind an HTTP tunneling system.
rem
rem  Your tunnel publishes a plain-http URL (e.g. http://IP:PORT/)
rem  that forwards to this machine's port 5173. So the local web
rem  server MUST run as plain HTTP (Vite TLS is disabled here), or
rem  the tunnel can't proxy it - HTTPS-to-HTTP gives errors / blank.
rem
rem  EDIT THIS to match your tunnel's public URL:
set "TUNNEL_URL=http://141.148.197.20:1010"

rem  NOTE: over plain http the browser will NOT allow passkey login.
rem  This launcher is for viewing/using the app through the tunnel.
rem  For passkeys you need an HTTPS tunnel (Cloudflare/ngrok).
rem ---------------------------------------------------------------

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

rem ---- compute RP_ID = host of the tunnel url (strip scheme + port) ----
set "RP_ID=%TUNNEL_URL%"
set "RP_ID=%RP_ID:http://=%"
set "RP_ID=%RP_ID:https://=%"
for /f "tokens=1 delims=:/" %%h in ("%RP_ID%") do set "RP_ID=%%h"

rem ---- env for the API backend ----
set "DATA_DIR=%~dp0data"
set "ORIGIN=%TUNNEL_URL%"

rem ---- launch the three servers (web forced to plain http) ----
echo [3/3] Starting servers in separate windows...
echo    Tunnel URL : %TUNNEL_URL%
echo    API origin : %ORIGIN%
start "openGym - media (tunnel)" cmd /k "cd /d %~dp0media && python -m http.server 8888"
start "openGym - api   (tunnel)" cmd /k "cd /d %~dp0api && node server.js"
start "openGym - web   (tunnel)" cmd /k "cd /d %~dp0frontend && set "DISABLE_HTTPS=1" && npm run dev"

echo.
echo  All servers are running.
echo  - Point your tunnel client at localhost:5173 (target_local_port).
echo  - Once the tunnel is up, open the public URL:
echo      %TUNNEL_URL%
echo.
echo  NOTE: plain http means passkey login is disabled. This is for
echo  using the app through the tunnel. Use LAN HTTPS (start-openGym.bat)
echo  for passkey login.
echo.
pause
endlocal