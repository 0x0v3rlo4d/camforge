set -euo pipefail

# --- CONFIG ---
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THIRD_PARTY_DIR="$ROOT_DIR/third_party"
OPENCV_BUILD_DIR="$THIRD_PARTY_DIR/opencv/build"
GLFW_BUILD_DIR="$THIRD_PARTY_DIR/glfw/build"
GLEW_VERSION="2.2.0"
GLEW_ZIP_URL="https://github.com/nigels-com/glew/releases/download/glew-${GLEW_VERSION}/glew-${GLEW_VERSION}.zip"
GLEW_ZIP_PATH="$THIRD_PARTY_DIR/glew.zip"
GLEW_EXTRACTED="$THIRD_PARTY_DIR/glew-${GLEW_VERSION}"
GLEW_FINAL="$THIRD_PARTY_DIR/glew"

# --- FUNCTIONS ---
function check_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ Required tool '$1' not found in PATH."
    exit 1
  }
}

function clone_if_missing() {
  local name="$1"
  local repo="$2"
  local path="$THIRD_PARTY_DIR/$name"

  if [[ ! -d "$path" ]]; then
    echo "⬇️ Cloning $name..."
    git clone --depth 1 "$repo" "$path"
  else
    echo "✅ $name already exists, skipping."
  fi
}

function install_system_deps() {
  echo "🔍 Checking for system dependencies..."
  
  # Detect package manager and install deps
  if command -v apt-get >/dev/null 2>&1; then
    echo "📦 Installing dependencies via apt..."
    sudo apt-get update
    sudo apt-get install -y \
      build-essential \
      cmake \
      pkg-config \
      libgl1-mesa-dev \
      libglu1-mesa-dev \
      libx11-dev \
      libxrandr-dev \
      libxinerama-dev \
      libxcursor-dev \
      libxi-dev \
      libglew-dev
  elif command -v dnf >/dev/null 2>&1; then
    echo "📦 Installing dependencies via dnf..."
    sudo dnf install -y \
      gcc-c++ \
      cmake \
      pkgconfig \
      mesa-libGL-devel \
      mesa-libGLU-devel \
      libX11-devel \
      libXrandr-devel \
      libXinerama-devel \
      libXcursor-devel \
      libXi-devel \
      glew-devel
  elif command -v pacman >/dev/null 2>&1; then
    echo "📦 Installing dependencies via pacman..."
    sudo pacman -S --needed \
      base-devel \
      cmake \
      mesa \
      libx11 \
      libxrandr \
      libxinerama \
      libxcursor \
      libxi \
      glew
  else
    echo "⚠️ Unknown package manager. Please install development tools, OpenGL, and X11 libraries manually."
  fi
}

# --- CHECK TOOLCHAIN ---
echo "🔍 Checking tools..."
check_tool git
check_tool cmake
check_tool wget
check_tool unzip

# --- INSTALL SYSTEM DEPENDENCIES ---
install_system_deps

# --- SETUP ---
echo "📦 Setting up dependencies in $THIRD_PARTY_DIR"
mkdir -p "$THIRD_PARTY_DIR"

# --- CLONE DEPS ---
clone_if_missing "glfw" "https://github.com/glfw/glfw.git"
clone_if_missing "glslang" "https://github.com/KhronosGroup/glslang.git"
clone_if_missing "opencv" "https://github.com/opencv/opencv.git"

# --- GLEW SETUP (prefer system package, fallback to source) ---
if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists glew; then
  echo "✅ Using system GLEW package"
  GLEW_VERSION_INSTALLED=$(pkg-config --modversion glew)
  echo "📍 System GLEW version: $GLEW_VERSION_INSTALLED"
else
  echo "📦 Setting up GLEW from source..."
  
  if [[ ! -d "$GLEW_FINAL" ]]; then
    echo "⬇️ Downloading GLEW $GLEW_VERSION..."
    wget -O "$GLEW_ZIP_PATH" "$GLEW_ZIP_URL"

    echo "📂 Extracting GLEW..."
    unzip -q "$GLEW_ZIP_PATH" -d "$THIRD_PARTY_DIR"

    echo "📁 Moving to final path..."
    mv "$GLEW_EXTRACTED" "$GLEW_FINAL"
    rm "$GLEW_ZIP_PATH"
  fi

  # Build GLEW from source (simple Makefile approach)
  if [[ ! -f "$GLEW_FINAL/lib/libGLEW.a" ]]; then
    echo "🔨 Building GLEW..."
    pushd "$GLEW_FINAL" >/dev/null
    
    # Use the auto/ directory which has simpler Makefiles
    make -C auto
    make
    
    popd >/dev/null
    echo "✅ GLEW built successfully"
  else
    echo "✅ GLEW already built, skipping."
  fi
fi

# --- BUILD GLFW ---
if [[ ! -f "$GLFW_BUILD_DIR/src/libglfw3.a" ]]; then
  echo "🔨 Building GLFW..."
  mkdir -p "$GLFW_BUILD_DIR"
  pushd "$GLFW_BUILD_DIR" >/dev/null

  cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DGLFW_BUILD_EXAMPLES=OFF \
    -DGLFW_BUILD_TESTS=OFF \
    -DGLFW_BUILD_DOCS=OFF
  
  cmake --build . --parallel "$(nproc)"

  popd >/dev/null
  echo "✅ GLFW built successfully"
else
  echo "✅ GLFW already built, skipping."
fi

# --- BUILD OPENCV ---
if [[ ! -d "$OPENCV_BUILD_DIR/install" ]]; then
  echo "🔨 Building OpenCV (this might take a while)..."
  mkdir -p "$OPENCV_BUILD_DIR"
  pushd "$OPENCV_BUILD_DIR" >/dev/null

  cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=install \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_PERF_TESTS=OFF \
    -DWITH_FFMPEG=OFF \
    -DWITH_GSTREAMER=OFF

  cmake --build . --parallel "$(nproc)"
  cmake --install . --config Release

  popd >/dev/null
  echo "✅ OpenCV built successfully"
else
  echo "✅ OpenCV already built, skipping."
fi

echo ""
echo "🚀 All dependencies ready!"
echo "📍 Next step: run ./scripts/build.sh to build CamForge"