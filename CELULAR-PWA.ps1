# Una sola URL para el celular — puerto 3000
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.InterfaceAlias -match 'Wi-Fi|Wireless' -and $_.IPAddress -notmatch '^169\.'
} | Select-Object -First 1).IPAddress

if (-not $ip) {
    $ip = (ipconfig | Select-String "Wi-Fi" -Context 0,3 | Select-String "IPv4" | ForEach-Object {
        if ($_ -match '(\d+\.\d+\.\d+\.\d+)') { $matches[1] }
    } | Select-Object -First 1)
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  COPIA ESTA URL EN TU CELULAR:" -ForegroundColor Green
Write-Host ""
Write-Host "  http://${ip}:3000/app" -ForegroundColor Yellow -BackgroundColor DarkMagenta
Write-Host ""
Write-Host "  (NO uses about:blank ni localhost)" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Set-Location $Root
docker compose up -d 2>&1 | Out-Null
Start-Sleep -Seconds 5

# Firewall puerto 3000
netsh advfirewall firewall add rule name="Pocket API 3000" dir=in action=allow protocol=TCP localport=3000 2>$null

# Reiniciar backend
Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue | ForEach-Object {
    Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$Root\backend'; npm start"
Start-Sleep -Seconds 4

try {
    $h = Invoke-RestMethod "http://localhost:3000/health" -TimeoutSec 5
    Write-Host "API OK" -ForegroundColor Green
} catch {
    Write-Host "Espera 5 seg y abre la URL en el celular" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "PWA: Chrome -> menu -> Instalar app" -ForegroundColor Cyan
Write-Host "Login: 70000001 / 1234" -ForegroundColor Yellow
Write-Host ""
