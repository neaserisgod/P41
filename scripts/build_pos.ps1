param(
    [ValidateSet("Auto", "Always", "Never")]
    [string]$RunCodegen = "Auto",
    [switch]$FullRebuild = $false,
    [string]$BackendBaseUrl = "http://31.97.166.250"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$AppDir = "$ProjectRoot\app"

function Test-CodegenRequired {
    param([string]$ProjectDir)

    $generatorOutputs = @(
        (Join-Path $ProjectDir "lib\data\local\database.g.dart")
    )

    foreach ($output in $generatorOutputs) {
        if (-not (Test-Path $output)) {
            Write-Host "Codegen required: missing generated file $output" -ForegroundColor Yellow
            return $true
        }
    }

    $gitAvailable = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitAvailable) {
        Write-Host "Git not available. Skipping automatic codegen detection." -ForegroundColor DarkYellow
        return $false
    }

    $headExists = $false
    try {
        git -C $ProjectDir rev-parse --verify HEAD~1 | Out-Null
        $headExists = ($LASTEXITCODE -eq 0)
    } catch {
        $headExists = $false
    }

    if (-not $headExists) {
        Write-Host "No previous commit available for diff. Skipping automatic codegen." -ForegroundColor DarkYellow
        return $false
    }

    $changedFiles = git -C $ProjectDir diff --name-only HEAD~1 HEAD
    $codegenPatterns = @(
        'pubspec.yaml',
        'build.yaml',
        'lib/data/local/database.dart',
        'lib/core/providers/*.dart',
        'lib/features/*/presentation/providers/*.dart',
        'lib/features/*/data/models/*.dart',
        'lib/data/models/*.dart',
        'lib/domain/models/*.dart'
    )

    foreach ($file in $changedFiles) {
        foreach ($pattern in $codegenPatterns) {
            if ($file -like $pattern) {
                Write-Host "Codegen required due to changed file: $file" -ForegroundColor Yellow
                return $true
            }
        }
    }

    return $false
}

Write-Host "Building POS Application (Windows)..."
Set-Location $AppDir

if ($FullRebuild) {
    Write-Host "Full rebuild requested: running flutter clean" -ForegroundColor Yellow
    flutter clean
}

flutter pub get

$shouldRunCodegen = switch ($RunCodegen) {
    "Always" { $true }
    "Never" { $false }
    default { Test-CodegenRequired -ProjectDir $AppDir }
}

if ($shouldRunCodegen) {
    Write-Host "Running build_runner..." -ForegroundColor Yellow
    dart run build_runner build --delete-conflicting-outputs
} else {
    Write-Host "Skipping build_runner for fast deploy path." -ForegroundColor Green
}

flutter build windows --release --dart-define="P41_API_BASE_URL=$BackendBaseUrl"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    throw "flutter build windows --release failed."
}
Write-Host "POS App build complete." -ForegroundColor Green
