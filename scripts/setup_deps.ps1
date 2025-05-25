Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"


# --- CONFIG ---
$thirdPartyPath = Join-Path $PSScriptRoot "..\third_party"
$opencvBuildPath = Join-Path $thirdPartyPath "opencv\build"
$glewVersion = "2.2.0"
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

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
# --- CONFIG ---
$thirdPartyPath = Join-Path $PSScriptRoot "..\third_party"
$opencvBuildPath = Join-Path $thirdPartyPath "opencv\build"
$glewVersion = "2.2.0"
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

function Get-ZipDependencyIfMissing($name, $url) {
    $target = Join-Path $thirdPartyPath $name
    if (-not (Test-Path $target)) {
        Write-Host "⬇️ Downloading $name..."
        $tempZip = Join-Path $env:TEMP "$name.zip"
        $tempExtract = Join-Path $env:TEMP "$name-extract"
        try {
            Invoke-WebRequest -Uri $url -OutFile $tempZip
            Write-Host "📦 Extracting $name..."
            Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
            
            # Handle nested directory structure (e.g., glew-2.2.0 folder inside zip)
            $extractedItems = @(Get-ChildItem $tempExtract)
            if ($extractedItems.Length -eq 1 -and $extractedItems[0].PSIsContainer) {
                # Single folder extracted - move its contents to target
                Move-Item $extractedItems[0].FullName $target
            } else {
                # Multiple items or files - move temp extract folder to target
                Move-Item $tempExtract $target
            }
            
            Remove-Item $tempZip -Force
            if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
        } catch {
            Write-Error "❌ Failed to download or extract $name`: $_"
            if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
            if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
            exit 1
        }
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
Get-ZipDependencyIfMissing "glew" "https://github.com/nigels-com/glew/releases/download/glew-$glewVersion/glew-$glewVersion-win32.zip"


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


# --- SETUP GLEW (Use pre-built binaries) ---
$glewLibPath = Join-Path $glewFinalPath "lib\Release\x64\glew32.lib"
if (-not (Test-Path $glewLibPath)) {
    Write-Host "`n📦 Setting up GLEW (using pre-built binaries)..."
    $expectedPaths = @(
        (Join-Path $glewFinalPath "lib\Release\x64\glew32.lib"),
        (Join-Path $glewFinalPath "lib\Release\x64\glew32s.lib"),
        (Join-Path $glewFinalPath "include\GL\glew.h")
    )
   
    $allPathsExist = $true
    foreach ($path in $expectedPaths) {
        if (-not (Test-Path $path)) {
            Write-Warning "⚠️ Missing expected GLEW file: $path"
            $allPathsExist = $false
        }
    }
   
    if ($allPathsExist) {
        Write-Host "✅ GLEW pre-built binaries ready!"
        Write-Host "📍 Static lib: $(Join-Path $glewFinalPath "lib\Release\x64\glew32s.lib")"
        Write-Host "📍 Headers: $(Join-Path $glewFinalPath "include")"
    } else {
        Write-Error "❌ GLEW setup incomplete - some required files are missing"
        Write-Host "💡 Try deleting the GLEW folder and re-running the setup script"
    }
} else {
    Write-Host "✅ GLEW already set up, skipping."
}
Write-Host "`n🚀 All dependencies ready!"