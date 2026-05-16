$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$LauncherDir = "$ProjectRoot\launcher"
$BackendBaseUrl = "http://31.97.166.250"
$UpdatesUrl = "$BackendBaseUrl/static/updates/p41/version.json"
$CatalogUrl = "$BackendBaseUrl/static/bootstrap/p41/global_lookup.sqlite"
$ImagesUrl = "$BackendBaseUrl/static/bootstrap/p41/imagenes_productos.zip"
$BuildOutputCandidates = @(
    "$LauncherDir\build\windows\x64\runner\Release",
    "$LauncherDir\build\windows\runner\Release"
)

Write-Host "--- Building Launcher ---" -ForegroundColor Cyan
Set-Location $LauncherDir
flutter clean
flutter pub get
flutter build windows --release `
  --dart-define="P41_API_BASE_URL=$BackendBaseUrl" `
  --dart-define="P41_UPDATES_URL=$UpdatesUrl" `
  --dart-define="P41_CATALOG_URL=$CatalogUrl" `
  --dart-define="P41_IMAGES_URL=$ImagesUrl"
if ($LASTEXITCODE -ne 0) {
    throw "flutter build windows --release failed for launcher."
}

$BuildOutputDir = $BuildOutputCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $BuildOutputDir) {
    Write-Error "Launcher build output directory not found. Checked: $($BuildOutputCandidates -join ', ')"
}

Write-Host "Launcher build complete." -ForegroundColor Green
