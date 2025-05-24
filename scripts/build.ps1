# Strict mode and early exit
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Directories
$projectRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$buildDir = Join-Path $projectRoot "..\build"

# Create build dir if missing
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

# Go to build dir
Push-Location $buildDir

# Run CMake config + build
Write-Host "⚙️  Configuring CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

Write-Host "🔨 Building project..."
cmake --build . --config Release

Pop-Location

Write-Host "`n✅ Build finished! Binaries are in: $buildDir"
