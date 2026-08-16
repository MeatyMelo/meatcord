@echo off
setlocal
title Meatcord launcher

REM Always serve from the folder this script lives in, whatever the CWD was.
cd /d "%~dp0"

if not exist "meatcord.html" (
  echo.
  echo   meatcord.html was not found next to this script.
  echo   Keep start.bat in the same folder as meatcord.html.
  echo.
  pause
  exit /b 1
)

REM --- find Python -----------------------------------------------------------
set "PY="
where python >nul 2>nul && set "PY=python"
if not defined PY where py >nul 2>nul && set "PY=py"
if not defined PY (
  echo.
  echo   Python was not found on your PATH.
  echo   Install it from https://www.python.org/downloads/
  echo   and tick "Add Python to PATH" during setup.
  echo.
  pause
  exit /b 1
)

REM --- if it's already serving, just open the browser -------------------------
netstat -ano | findstr ":8000" | findstr "LISTENING" >nul
if not errorlevel 1 (
  echo Server already running on port 8000 - opening browser.
  start "" "http://localhost:8000/meatcord.html"
  exit /b 0
)

REM --- start the server in its own window, then open the app ------------------
REM Bound to 127.0.0.1 so it is reachable from this machine only, never the LAN.
REM serve.py is http.server with caching disabled — without that the browser can
REM silently keep running an older copy of meatcord.html after you edit it.
start "Meatcord server (close this window to stop)" %PY% serve.py 8000

REM Give it a moment to bind before the browser asks for the page.
REM ping, not timeout: timeout aborts with "input redirection is not supported"
REM whenever stdin isn't a real console, which breaks the launcher when it's
REM started from anything other than a double-click.
ping -n 3 127.0.0.1 >nul

start "" "http://localhost:8000/meatcord.html"

echo.
echo   Meatcord is running at http://localhost:8000/meatcord.html
echo   Close the "Meatcord server" window to stop it.
echo.
ping -n 5 127.0.0.1 >nul
exit /b 0
