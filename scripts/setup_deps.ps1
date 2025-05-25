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

# --- BUILD GLFW ---    
if (-not (Test-Path "$thirdPartyPath\glfw\build\src\Release\glfw3.lib")) {
    Write-Host "`n🔨 Building GLFW..."

    $glfwBuildPath = Join-Path $thirdPartyPath "glfw\build"
    New-Item -ItemType Directory -Force -Path $glfwBuildPath | Out-Null
    Push-Location $glfwBuildPath

    cmake .. -G "Visual Studio 17 2022" -A x64
    cmake --build . --config Release

    Pop-Location
} else {
    Write-Host "✅ GLFW already built, skipping."
}


# --- BUILD GLEW ---
$glewLibPath = Join-Path $glewFinalPath "lib\Release\x64\glew32.lib"

if (-not (Test-Path $glewLibPath)) {
    Write-Host "`n🔨 Building GLEW..."

    $glewSourcePath = Join-Path $glewFinalPath "build/cmake"
    $glewBuildPath = Join-Path $glewFinalPath "build_vs2022"

    New-Item -ItemType Directory -Force -Path $glewBuildPath | Out-Null
    Push-Location $glewBuildPath

    # Configure GLEW with CMake
    cmake $glewSourcePath -G "Visual Studio 17 2022" -A x64 `
        -DCMAKE_INSTALL_PREFIX="$glewFinalPath" `
        -DCMAKE_BUILD_TYPE=Release `
        -DBUILD_SHARED_LIBS=OFF `
        -DBUILD_UTILS=OFF

    # Build static lib
    cmake --build . --config Release

    # Install static lib + headers to predictable layout
    cmake --install . --config Release

    Pop-Location

    Write-Host "✅ GLEW build and install complete!"
} else {
    Write-Host "✅ GLEW already built, skipping."
}




Write-Host "`n🚀 All dependencies ready!"
