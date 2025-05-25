Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- CONFIG ---
$thirdPartyPath = Join-Path $PSScriptRoot "..\third_party"
$opencvBuildPath = Join-Path $thirdPartyPath "opencv\build"
$glewVersion = "2.2.0"
$glewZipUrl = "https://github.com/nigels-com/glew/releases/download/glew-${glewVersion}/glew-${glewVersion}.zip"
$glewZipPath = Join-Path $thirdPartyPath "glew.zip"
$glewExtractedPath = Join-Path $thirdPartyPath "glew-${glewVersion}"
$glewFinalPath = Join-Path $thirdPartyPath "glew"

# --- UTILITIES ---
function Test-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        Write-Error "❌ Required tool '$name' not found in PATH."
        exit 1
    }
}

function Get-DependencyIfMissing($name, $repo) {
    $target = Join-Path $thirdPartyPath $name
    if (-not (Test-Path $target)) {
        Write-Host "⬇️ Cloning $name..."
        git clone --depth 1 $repo $target
    } else {
        Write-Host "✅ $name already exists, skipping."
    }
}

# --- CHECK TOOLCHAIN ---
Write-Host "🔍 Checking tools..."
Test-Command git
Test-Command cmake
Test-Command Expand-Archive
Test-Command Invoke-WebRequest

# --- START SETUP ---
Write-Host "📦 Setting up dependencies in $thirdPartyPath"
New-Item -ItemType Directory -Force -Path $thirdPartyPath | Out-Null

# --- CLONE OTHER DEPS ---
Get-DependencyIfMissing "glfw" "https://github.com/glfw/glfw.git"
Get-DependencyIfMissing "glslang" "https://github.com/KhronosGroup/glslang.git"
Get-DependencyIfMissing "opencv" "https://github.com/opencv/opencv.git"

# --- GLEW ZIP DOWNLOAD & SETUP ---
if (-not (Test-Path $glewFinalPath)) {
    Write-Host "⬇️ Downloading GLEW $glewVersion..."
    Invoke-WebRequest -Uri $glewZipUrl -OutFile $glewZipPath

    Write-Host "📂 Extracting GLEW..."
    Expand-Archive -Path $glewZipPath -DestinationPath $thirdPartyPath -Force

    Write-Host "📁 Moving to final path..."
    Move-Item -Path $glewExtractedPath -Destination $glewFinalPath -Force

    Remove-Item $glewZipPath -Force
} else {
    Write-Host "✅ GLEW already set up, skipping."
}

# --- BUILD OPENCV ---
if (-not (Test-Path "$opencvBuildPath\install")) {
    Write-Host "`n🔨 Building OpenCV..."

    New-Item -ItemType Directory -Force -Path $opencvBuildPath | Out-Null
    Push-Location $opencvBuildPath

    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=install
    cmake --build . --config Release
    cmake --install . --config Release

    Pop-Location
} else {
    Write-Host "✅ OpenCV already built, skipping."
}

Write-Host "`n🚀 All dependencies ready!"
