@echo off
title Pocket Card
echo.
echo ========================================
echo   POCKET CARD - Iniciando todo
echo ========================================
echo.

cd /d "%~dp0"

echo [1] Docker PostgreSQL...
docker compose up -d
timeout /t 8 /nobreak >nul

echo [2] Backend API...
start "Pocket API" cmd /k "cd /d %~dp0backend && npm start"
timeout /t 5 /nobreak >nul

echo [3] Abriendo app en navegador...
start "" "http://localhost:3000/app"

echo.
echo ========================================
echo   LISTO
echo   Login: 70000001  PIN: 1234
echo   API: http://localhost:3000
echo ========================================
echo.
pause
