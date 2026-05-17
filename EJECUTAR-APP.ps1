# Abre Pocket Card en el navegador (mas rapido que Flutter)
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

Write-Host "Iniciando Pocket Card..." -ForegroundColor Cyan

docker compose up -d 2>&1 | Out-Null
Start-Sleep -Seconds 5

$apiOk = $false
try {
    $h = Invoke-RestMethod "http://localhost:3000/health" -TimeoutSec 3
    $apiOk = $h.status -eq "ok"
} catch {}

if (-not $apiOk) {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$Root\backend'; npm start"
    Start-Sleep -Seconds 5
}

Start-Process "http://localhost:3000/app"
Write-Host ""
Write-Host "App abierta en: http://localhost:3000/app" -ForegroundColor Green
Write-Host "Login: 70000001  PIN: 1234" -ForegroundColor Yellow
Write-Host ""
