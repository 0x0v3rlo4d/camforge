Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"


$projectRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$buildDir = Join-Path $projectRoot "..\build"

if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

Push-Location $buildDir

Write-Host "⚙️  Configuring CMake..."
if (-not (cmake .. )) {
    Write-Error "❌ CMake configuration failed."
    exit 1
}

Write-Host "🔨 Building project..."
if (-not (cmake --build . )) {
    Write-Error "❌ Build failed."
    exit 1
}

Pop-Location

$exePath = Join-Path $buildDir "bin\camforge.exe"
Write-Host "`n✅ Build finished! Binaries are in: $buildDir"

if (Test-Path $exePath) {
    Write-Host "🚀 Binary ready at: $exePath"
} else {
    Write-Warning "⚠️ Couldn't find built binary in expected path ($exePath)"
}