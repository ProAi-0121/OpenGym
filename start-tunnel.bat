@echo off
setlocal
title openGym - Tunnel Launcher (plain HTTP)
cd /d "%~dp0"

rem ---------------------------------------------------------------
rem  openGym for use behind a tunneling system / reverse proxy.
rem
rem  Your proxy terminates HTTPS publicly (e.g. https://harsh.run.place)
rem  and forwards plain http to this machine's port 5173. So the local
rem  web server MUST run as plain HTTP (Vite TLS is disabled here), or
rem  the proxy can't reach it - HTTPS-to-HTTP gives errors / blank.
rem
rem  EDIT THIS to match your public URL:
set "TUNNEL_URL=https://harsh.run.place"

rem  With a real domain, passkeys are bound to that hostname - the most
rem  stable setup (they survive LAN IP changes). The API derives the RP ID
rem  from the browser's Origin header, so it matches automatically, as long
rem  as your proxy forwards the Origin header (Cloudflare and ngrok do).
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
echo  Passkeys: bound to the hostname in TUNNEL_URL (=%RP_ID%).
echo  They work as long as the public side is https and your proxy
echo  forwards the browser's Origin header. If you ever change the
echo  domain, existing passkeys must be re-created (new profile).
echo.
pause
endlocal