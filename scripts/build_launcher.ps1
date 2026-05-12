$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$LauncherDir = "$ProjectRoot\launcher"
$BuildOutputCandidates = @(
    "$LauncherDir\build\windows\x64\runner\Release",
    "$LauncherDir\build\windows\runner\Release"
)

Write-Host "--- Building Launcher ---" -ForegroundColor Cyan
Set-Location $LauncherDir
flutter clean
flutter pub get
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    throw "flutter build windows --release failed for launcher."
}

$BuildOutputDir = $BuildOutputCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $BuildOutputDir) {
    Write-Error "Launcher build output directory not found. Checked: $($BuildOutputCandidates -join ', ')"
}

Write-Host "Launcher build complete." -ForegroundColor Green
