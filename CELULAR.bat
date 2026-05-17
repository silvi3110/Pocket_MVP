@echo off
title Pocket - Celular
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0CELULAR-PWA.ps1"
pause
