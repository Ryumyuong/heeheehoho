@echo off
title heeheehoho
echo.
echo   Starting heeheehoho ...  (no internet required)
echo   Address: http://127.0.0.1:5000/
echo.
rem Open the browser from a separate process after the server is up.
rem Opening it inside the server script hangs on some PCs.
start "" /min cmd /c "timeout /t 3 >nul & start "" http://127.0.0.1:5000/"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0offline_server.ps1"
pause
