Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$rawBuildDir = Join-Path $projectRoot "..\build"

if (-not (Test-Path $rawBuildDir)){
    New-Item -ItemType Directory -Path $rawBuildDir | Out-Null
}

$buildDir = Resolve-Path $rawBuildDir| Select-Object -ExpandProperty Path
$expectedExePath = Join-Path $buildDir "Release\camforge.exe"

Push-Location $buildDir

Write-Host "⚙️  Configuring CMake..."
if (-not (cmake -S .. -B . -G "Visual Studio 17 2022" -A x64)) {
   Write-Error "❌ CMake configuration failed."
   exit 1
}

Write-Host "🔨 Building project..."
if (-not (cmake --build . --config Release)) {
    Write-Error "❌ Build failed."
    exit 1
}

Pop-Location

Write-Host "`n✅ Build finished! Binaries are in: $buildDir"

# Try to find the real binary (in case it's not in expected location)
$exe = Get-ChildItem -Path $buildDir -Recurse -Filter camforge.exe | Select-Object -First 1

if ($exe) {
    if ($exe.FullName -eq $expectedExePath) {
        Write-Host "✅ Found built binary in expected path: $($exe.FullName)"
    } else {
        Write-Warning "⚠️ Built binary was found, but not in the expected path!"
        Write-Host "📍 Actual location: $($exe.FullName)"
    }
} else {
    Write-Warning "⚠️ Couldn't find built binary at all. Expected: $expectedExePath"
}
