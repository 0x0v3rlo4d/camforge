set -euo pipefail

# --- CONFIG ---
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THIRD_PARTY_DIR="$ROOT_DIR/third_party"
OPENCV_BUILD_DIR="$THIRD_PARTY_DIR/opencv/build"
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

# --- CHECK TOOLCHAIN ---
echo "🔍 Checking tools..."
check_tool git
check_tool cmake
check_tool wget
check_tool unzip

# --- SETUP ---
echo "📦 Setting up dependencies in $THIRD_PARTY_DIR"
mkdir -p "$THIRD_PARTY_DIR"

# --- CLONE OTHER DEPS ---
clone_if_missing "glfw" "https://github.com/glfw/glfw.git"
clone_if_missing "glslang" "https://github.com/KhronosGroup/glslang.git"
clone_if_missing "opencv" "https://github.com/opencv/opencv.git"

# --- DOWNLOAD & EXTRACT GLEW ---
if [[ ! -d "$GLEW_FINAL" ]]; then
  echo "⬇️ Downloading GLEW $GLEW_VERSION..."
  wget -O "$GLEW_ZIP_PATH" "$GLEW_ZIP_URL"

  echo "📂 Extracting GLEW..."
  unzip -q "$GLEW_ZIP_PATH" -d "$THIRD_PARTY_DIR"

  echo "📁 Moving to final path..."
  mv "$GLEW_EXTRACTED" "$GLEW_FINAL"
  rm "$GLEW_ZIP_PATH"
else
  echo "✅ GLEW already set up, skipping."
fi

# --- BUILD OPENCV (optional) ---
if [[ ! -d "$OPENCV_BUILD_DIR/install" ]]; then
  echo ""
  echo "🔨 Building OpenCV..."
  mkdir -p "$OPENCV_BUILD_DIR"
  pushd "$OPENCV_BUILD_DIR" >/dev/null

  cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=install
  cmake --build . --config Release

  popd >/dev/null
else
  echo "✅ OpenCV already built, skipping."
fi

echo ""
echo "🚀 All dependencies ready!"
