@echo off
title Pocket Flutter
cd /d "%~dp0"

set FLUTTER=C:\Users\Usuario\flutter-sdk\bin\flutter.bat

echo ========================================
echo   POCKET - App Flutter
echo ========================================
echo.

echo [1] Docker...
docker compose up -d
timeout /t 6 /nobreak >nul

echo [2] Backend...
start "Pocket API" cmd /k "cd /d %~dp0backend && npm start"
timeout /t 5 /nobreak >nul

echo [3] Flutter setup...
cd pocket_app
if not exist android (
  "%FLUTTER%" create . --project-name pocket_app --platforms=android,web,windows
)
"%FLUTTER%" pub get

echo [4] Iniciando app en Chrome (vista movil)...
echo     Login: 70000001 / 1234
echo.
"%FLUTTER%" run -d chrome --web-port=8888 --dart-define=API_URL=http://localhost:3000

pause
