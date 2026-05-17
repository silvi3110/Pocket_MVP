# Pocket Card - Inicia Docker, Backend y opcionalmente Flutter
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "`n=== POCKET CARD - Inicio completo ===`n" -ForegroundColor Magenta

# 1. Docker PostgreSQL
Write-Host "[1/4] Docker PostgreSQL..." -ForegroundColor Cyan
Set-Location $Root
docker compose up -d 2>&1 | Out-Null
Start-Sleep -Seconds 6
$ready = docker exec pocket-postgres-1 pg_isready -U postgres 2>&1
if ($ready -match "accepting") {
    Write-Host "  OK PostgreSQL listo" -ForegroundColor Green
} else {
    Write-Host "  AVISO: Abre Docker Desktop y vuelve a ejecutar este script" -ForegroundColor Yellow
}

# 2. Backend
Write-Host "[2/4] Backend API puerto 3000..." -ForegroundColor Cyan
$backendRunning = $false
try {
    $h = Invoke-RestMethod -Uri "http://localhost:3000/health" -TimeoutSec 2
    if ($h.status -eq "ok") { $backendRunning = $true }
} catch {}

if (-not $backendRunning) {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$Root\backend'; npm start" -WindowStyle Normal
    Start-Sleep -Seconds 4
    Write-Host "  OK Backend iniciado en nueva ventana" -ForegroundColor Green
} else {
    Write-Host "  OK Backend ya corriendo" -ForegroundColor Green
}

# 3. Verificar API
Write-Host "[3/4] Verificando API..." -ForegroundColor Cyan
try {
    $health = Invoke-RestMethod "http://localhost:3000/health"
    Write-Host "  OK $($health.app)" -ForegroundColor Green
} catch {
    Write-Host "  ERROR API no responde" -ForegroundColor Red
}

# 4. Flutter
Write-Host "[4/4] Flutter..." -ForegroundColor Cyan
$flutterBat = "$Root\tools\flutter\bin\flutter.bat"
if (Test-Path $flutterBat) {
    & $flutterBat --version 2>&1 | Select-Object -First 1
    Write-Host "  Para abrir la app ejecuta:" -ForegroundColor Yellow
    Write-Host "  .\EJECUTAR-APP.ps1" -ForegroundColor White
} else {
    Write-Host "  Flutter no instalado. Ejecuta primero: .\INSTALAR-FLUTTER.ps1" -ForegroundColor Yellow
}

Write-Host "`n=== Listo ===" -ForegroundColor Green
Write-Host "Login demo: 70000001 / PIN 1234`n"
