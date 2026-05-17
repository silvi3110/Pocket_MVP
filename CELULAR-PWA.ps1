# Pocket Card - Abrir en CELULAR (misma Wi-Fi)
# Ejecutar como Administrador si el celular no conecta (firewall)
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Get-LanIp {
    $addrs = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object {
        $_.IPAddress -notmatch '^127\.|^169\.|^172\.(1[6-9]|2[0-9]|3[01])\.' -and
        $_.InterfaceAlias -notmatch 'WSL|Hyper-V|Loopback|vEthernet'
    }
    $wifi = $addrs | Where-Object { $_.InterfaceAlias -match 'Wi-Fi|Wireless' } | Select-Object -First 1
    if ($wifi) { return $wifi.IPAddress }
    $eth = $addrs | Where-Object { $_.InterfaceAlias -match 'Ethernet' } | Select-Object -First 1
    if ($eth) { return $eth.IPAddress }
    $line = ipconfig | Select-String -Pattern 'Adaptador de LAN inal' -Context 0,5 | Select-String 'IPv4'
    if ($line -match '(\d+\.\d+\.\d+\.\d+)') { return $matches[1] }
    return $null
}

$ip = Get-LanIp
if (-not $ip) {
    Write-Host "No se detecto IP Wi-Fi. Conecta la PC a Wi-Fi." -ForegroundColor Red
    exit 1
}

$urlApp = "http://${ip}:3000/app"
$urlQr  = "http://${ip}:3000/m"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  POCKET EN TU CELULAR" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  1) Misma Wi-Fi PC + celular" -ForegroundColor Cyan
Write-Host "  2) En Chrome del celular abre:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  $urlApp" -ForegroundColor Yellow -BackgroundColor DarkMagenta
Write-Host ""
Write-Host "  O escanea QR en la PC:" -ForegroundColor Cyan
Write-Host "  $urlQr" -ForegroundColor White
Write-Host ""
Write-Host "  Login: 70000001  PIN: 1234" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Set-Location $Root

Write-Host "[1/4] Docker PostgreSQL..." -ForegroundColor Cyan
docker compose up -d 2>&1 | Out-Null
Start-Sleep -Seconds 5

Write-Host "[2/4] Firewall puerto 3000..." -ForegroundColor Cyan
netsh advfirewall firewall delete rule name="Pocket API 3000" 2>$null | Out-Null
netsh advfirewall firewall add rule name="Pocket API 3000" dir=in action=allow protocol=TCP localport=3000 2>$null | Out-Null

Write-Host "[3/4] Backend API..." -ForegroundColor Cyan
$apiOk = $false
try {
    $h = Invoke-RestMethod "http://localhost:3000/health" -TimeoutSec 2
    $apiOk = $h.status -eq 'ok'
} catch {}

if (-not $apiOk) {
    Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue | ForEach-Object {
        Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 2
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$Root\backend'; npm start"
    Start-Sleep -Seconds 5
}

try {
    $h = Invoke-RestMethod "http://localhost:3000/health" -TimeoutSec 8
    Write-Host "  OK API $($h.app)" -ForegroundColor Green
} catch {
    Write-Host "  AVISO: API aun iniciando - espera 10 s y abre la URL" -ForegroundColor Yellow
}

Write-Host "[4/4] Abriendo pagina QR en esta PC..." -ForegroundColor Cyan
Start-Process $urlQr

Write-Host ""
Write-Host "PWA: Chrome celular - menu - Instalar app" -ForegroundColor Magenta
Write-Host ""
