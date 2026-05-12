$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$LauncherDir = "$ProjectRoot\launcher"
$InstallerDir = "$ProjectRoot\launcher\installer"
$DistDir = "$ProjectRoot\launcher\dist_launcher"
$AppDir = "$ProjectRoot\app"
$AppDistDir = "$ProjectRoot\launcher\dist_app"
$LauncherBuildOutputCandidates = @(
    "$LauncherDir\build\windows\x64\runner\Release",
    "$LauncherDir\build\windows\runner\Release"
)
$AppBuildOutputCandidates = @(
    "$AppDir\build\windows\x64\runner\Release",
    "$AppDir\build\windows\runner\Release"
)
$BuildOutputDir = $LauncherBuildOutputCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
$AppBuildOutputDir = $AppBuildOutputCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

Write-Host "--- Creating Launcher Installer ---" -ForegroundColor Cyan

if (-not $BuildOutputDir) {
    Write-Error "Launcher build output directory not found. Checked: $($LauncherBuildOutputCandidates -join ', ')"
    exit 1
}

if (-not $AppBuildOutputDir) {
    Write-Error "App build output directory not found. Checked: $($AppBuildOutputCandidates -join ', ')"
    exit 1
}

# 1. Sync files to dist_launcher (used by .iss)
if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir -Force | Out-Null
}
if (-not (Test-Path $AppDistDir)) {
    New-Item -ItemType Directory -Path $AppDistDir -Force | Out-Null
}

Write-Host "Syncing build files to dist folder..." -ForegroundColor Gray
Remove-Item "$DistDir\*" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item "$BuildOutputDir\*" -Destination $DistDir -Recurse -Force
Remove-Item "$AppDistDir\*" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item "$AppBuildOutputDir\*" -Destination $AppDistDir -Recurse -Force

# 2. Rename executable if needed (legacy fallback)
if ((-not (Test-Path "$DistDir\P41Bootstrap.exe")) -and (Test-Path "$DistDir\launcher.exe")) {
    Rename-Item -Path "$DistDir\launcher.exe" -NewName "P41Bootstrap.exe" -Force
}

if ((-not (Test-Path "$DistDir\P41Bootstrap.exe")) -and (Test-Path "$DistDir\HorseLauncher.exe")) {
    Rename-Item -Path "$DistDir\HorseLauncher.exe" -NewName "P41Bootstrap.exe" -Force
}

if (-not (Test-Path "$DistDir\P41Bootstrap.exe")) {
    Write-Error "Bundled launcher executable not found in dist_launcher."
    exit 1
}

if ((-not (Test-Path "$AppDistDir\p41.exe")) -and (-not (Test-Path "$AppDistDir\horsepos.exe")) -and (-not (Test-Path "$AppDistDir\horsepos_pro.exe")) -and (-not (Test-Path "$AppDistDir\Runner.exe"))) {
    Write-Error "Bundled app executable not found in dist_app."
    exit 1
}

$LauncherVersionLine = Select-String -Path "$LauncherDir\pubspec.yaml" -Pattern "^version: " | Select-Object -First 1
$LauncherVersion = $LauncherVersionLine.Line -replace "version: ", ""
$LauncherVersion = $LauncherVersion.Trim()
if (-not $LauncherVersion) {
    $LauncherVersion = "1.0.0"
}

# 3. Find ISCC.exe
$Iscc = "iscc"
$PossiblePaths = @(
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 5\ISCC.exe"
)

foreach ($Path in $PossiblePaths) {
    if (Test-Path $Path) {
        $Iscc = $Path
        break
    }
}

# 4. Compile Installer
Write-Host "Compiling setup with Inno Setup..." -ForegroundColor Yellow
Set-Location $InstallerDir
& $Iscc "/DMyAppVersion=$LauncherVersion" "launcher_setup.iss"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Inno Setup compilation failed!"
    exit 1
}

Write-Host "Installer created successfully in $InstallerDir\output" -ForegroundColor Green
