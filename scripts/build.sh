set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "⚙️  Configuring CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

echo "🔨 Building project..."
cmake --build .

echo -e "\n✅ Build finished! Binaries are in: $BUILD_DIR"
