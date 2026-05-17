# Pocket Card - Demo automatico de 10 pasos contra la API
param(
    [string]$BaseUrl = "http://localhost:3000",
    [switch]$UseSeedUser
)

$ErrorActionPreference = "Stop"

function Write-Step($n, $msg) {
    Write-Host ""
    Write-Host "=== Paso $n : $msg ===" -ForegroundColor Cyan
}
function Write-Ok($msg) { Write-Host "  OK: $msg" -ForegroundColor Green }
function Write-Fail($msg) { Write-Host "  ERROR: $msg" -ForegroundColor Red; exit 1 }

function Invoke-Api {
    param(
        [string]$Method,
        [string]$Path,
        [object]$Body = $null,
        [string]$Token = $null
    )
    $headers = @{ "Content-Type" = "application/json" }
    if ($Token) { $headers["Authorization"] = "Bearer $Token" }

    $uri = "$BaseUrl$Path"
    $params = @{ Uri = $uri; Method = $Method; Headers = $headers }

    if ($null -ne $Body) {
        $params["Body"] = ($Body | ConvertTo-Json -Depth 5)
    }

    try {
        return Invoke-RestMethod @params
    } catch {
        $err = $_.ErrorDetails.Message
        if ($err) {
            try {
                $parsed = $err | ConvertFrom-Json
                Write-Fail $parsed.error
            } catch {
                Write-Fail $err
            }
        }
        Write-Fail $_.Exception.Message
    }
}

Write-Host ""
Write-Host "Pocket Card - Demo API" -ForegroundColor Magenta
Write-Host "Base: $BaseUrl"
Write-Host ""

try {
    $health = Invoke-RestMethod -Uri "$BaseUrl/health" -Method GET
    Write-Ok "API activa: $($health.app)"
} catch {
    Write-Fail "No se conecta a $BaseUrl. Corre npm start en backend y PostgreSQL con Docker."
}

$token = $null
$phone = "70088888"
$ci = "99887766"

if ($UseSeedUser) {
    Write-Step 1 "Login usuario seed 70000001"
    $login = Invoke-Api -Method POST -Path "/api/auth/login" -Body @{ phone = "70000001"; pin = "1234" }
    $token = $login.token
    Write-Ok "Login $($login.user.full_name) KYC $($login.user.kyc_level)"
} else {
    Write-Step 1 "Registro nuevo usuario"
    $registered = $false
    try {
        $reg = Invoke-Api -Method POST -Path "/api/auth/register" -Body @{
            phone       = $phone
            pin         = "1234"
            full_name   = "Demo Hackathon"
            ci          = $ci
            viva_linked = $false
        }
        $token = $reg.token
        $registered = $true
        Write-Ok "Registrado $phone KYC $($reg.user.kyc_level)"
    } catch {
        Write-Host "  Usuario ya existe, login..." -ForegroundColor Yellow
    }
    if (-not $registered) {
        $login = Invoke-Api -Method POST -Path "/api/auth/login" -Body @{ phone = $phone; pin = "1234" }
        $token = $login.token
        Write-Ok "Login $($login.user.full_name)"
    }

    Write-Step 2 "Vincular linea VIVA"
    $link = Invoke-Api -Method POST -Path "/api/me/vincular-viva" -Body @{ numero_linea = $phone } -Token $token
    Write-Ok $link.message

    Write-Step 2 "Subir a KYC nivel 2"
    $kyc = Invoke-Api -Method POST -Path "/api/auth/upgrade-kyc" -Body @{ level = 2 } -Token $token
    Write-Ok "KYC $($kyc.kyc_level)"
}

Write-Step 3 "Cargar Bs 300 en wallet"
$dep = Invoke-Api -Method POST -Path "/api/wallet/deposit" -Body @{ monto = 300 } -Token $token
Write-Ok "Wallet BOB $($dep.user.bob_balance)"

Write-Step 4 "Activar Pocket Card"
$act = Invoke-Api -Method POST -Path "/api/card/activate" -Token $token
Write-Ok "Tier $($act.card.tier) activa $($act.card.activa)"

Write-Step 5 "Transferir Bs 150 wallet a tarjeta"
$load = Invoke-Api -Method POST -Path "/api/card/load" -Body @{ monto = 150 } -Token $token
Write-Ok "Saldo tarjeta $($load.user.card_balance)"

Write-Step 6 "Tres pagos con tarjeta"
$payments = @(
    @{ amount = 25; type = "qr"; merchant = "Farmacia Demo" },
    @{ amount = 40; type = "online"; merchant = "Tienda Online" },
    @{ amount = 15; type = "qr"; merchant = "Cafeteria" }
)
foreach ($p in $payments) {
    $pay = Invoke-Api -Method POST -Path "/api/transactions/pay" -Body $p -Token $token
    Write-Ok "Bs $($p.amount) +$($pay.points_earned) pts +$($pay.megas_earned) MB cashback $($pay.viva_cashback)"
}

Write-Step 7 "Ver home"
$homeData = Invoke-Api -Method GET -Path "/api/me/home" -Token $token
Write-Ok "Puntos $($homeData.alva_points) Megas $($homeData.megas_acumuladas) VIVA $($homeData.viva_balance)"
if ($homeData.stats_mes) {
    Write-Ok "Mes: $($homeData.stats_mes.puntos_ganados) pts $($homeData.stats_mes.megas_ganadas) MB"
}

Write-Step 8 "Convertir ALVA a puntos Pocket"
$alva = Invoke-Api -Method POST -Path "/api/points/convert-alva" -Body @{ cantidad_alva = 100 } -Token $token
Write-Ok $alva.message

Write-Step 9 "Canjear Gift Card"
$catalog = Invoke-Api -Method GET -Path "/api/points/gift-cards/catalog" -Token $token
$cheapest = $catalog[0]
$redeem = Invoke-Api -Method POST -Path "/api/points/gift-cards/redeem" -Body @{ gift_card_id = $cheapest.id } -Token $token
Write-Ok "Canje $($cheapest.name) codigo $($redeem.codigo_canje)"

Write-Step 10 "Historial"
$hist = Invoke-Api -Method GET -Path "/api/transactions/history?limit=10" -Token $token
Write-Ok "$($hist.items.Count) transacciones"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  DEMO COMPLETADA - 10/10 pasos OK" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
