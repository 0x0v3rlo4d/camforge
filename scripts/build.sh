set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
BINARY_NAME="camforge"

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "⚙️  Configuring CMake..."
if ! cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON; then
    echo "❌ CMake configuration failed"
    exit 1
fi

echo "🔨 Building project..."
NPROC=$(nproc 2>/dev/null || echo "4")
if ! cmake --build . --parallel "$NPROC"; then
    echo "❌ Build failed"
    exit 1
fi

# Find the built binary
BINARY_PATH=$(find "$BUILD_DIR" -name "$BINARY_NAME" -type f -executable | head -1)

if [[ -n "$BINARY_PATH" ]]; then
    echo ""
    echo "✅ Build finished successfully!"
    echo "📍 Binary location: $BINARY_PATH"
    echo "🏃 Run with: $BINARY_PATH"
    
    # Make it executable just in case
    chmod +x "$BINARY_PATH"
    
    # Check if shaders directory exists
    SHADER_DIR="$PROJECT_ROOT/shaders"
    if [[ -d "$SHADER_DIR" ]]; then
        echo "📁 Shaders found in: $SHADER_DIR"
    else
        echo "⚠️  No shaders directory found. Create $SHADER_DIR for hot-reload functionality."
    fi
    
else
    echo "⚠️  Build completed but couldn't locate the binary."
    echo "📂 Check build directory: $BUILD_DIR"
fi