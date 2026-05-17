# Instala Flutter SDK en tools/flutter (solo la primera vez)
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$FlutterPath = "$Root\tools\flutter"

Write-Host "Instalando Flutter SDK en $FlutterPath ..." -ForegroundColor Cyan
Write-Host "Puede tardar 5-10 minutos la primera vez.`n"

if (Test-Path "$FlutterPath\bin\flutter.bat") {
    Write-Host "Flutter ya esta instalado." -ForegroundColor Green
    & "$FlutterPath\bin\flutter.bat" --version
    exit 0
}

New-Item -ItemType Directory -Force -Path "$Root\tools" | Out-Null
git clone https://github.com/flutter/flutter.git -b stable --depth 1 $FlutterPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR al clonar Flutter. Verifica que tienes Git instalado." -ForegroundColor Red
    exit 1
}

& "$FlutterPath\bin\flutter.bat" doctor
Write-Host "`nListo. Ahora ejecuta: .\EJECUTAR-APP.ps1" -ForegroundColor Green
