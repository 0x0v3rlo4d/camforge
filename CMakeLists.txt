cmake_minimum_required(VERSION 3.15)
project(camforge)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --- Config Paths ---
set(THIRD_PARTY_DIR "${CMAKE_SOURCE_DIR}/third_party")
set(GLEW_INCLUDE_DIR "${THIRD_PARTY_DIR}/glew/include")
set(GLFW_INCLUDE_DIR "${THIRD_PARTY_DIR}/glfw/include")
set(GLSLANG_INCLUDE_DIR "${THIRD_PARTY_DIR}/glslang")
set(OPENCV_INSTALL_DIR "${THIRD_PARTY_DIR}/opencv/build/install")

# --- Include Headers ---
include_directories(
    ${GLEW_INCLUDE_DIR}
    ${GLFW_INCLUDE_DIR}
    ${GLSLANG_INCLUDE_DIR}
    ${OPENCV_INSTALL_DIR}/include
)

# --- OpenCV ---
set(OpenCV_DIR "${OPENCV_INSTALL_DIR}")
find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})

# --- Source Files ---
file(GLOB_RECURSE SOURCES src/*.cpp)
file(GLOB_RECURSE HEADERS src/*.h)

# --- Executable ---
add_executable(camforge ${SOURCES} ${HEADERS})

# --- Platform-specific setup ---
if (WIN32)
    # Windows-specific libraries
    target_link_libraries(camforge
        ${OpenCV_LIBS}
        opengl32
        glfw3
        glew32
    )
elseif(APPLE)
    # macOS
    find_library(COCOA_LIBRARY Cocoa REQUIRED)
    find_library(OpenGL_LIBRARY OpenGL REQUIRED)
    find_library(IOKIT_LIBRARY IOKit REQUIRED)
    find_library(COREVIDEO_LIBRARY CoreVideo REQUIRED)

    target_link_libraries(camforge
        ${OpenCV_LIBS}
        ${OpenGL_LIBRARY}
        glfw
        GLEW
        ${COCOA_LIBRARY}
        ${IOKIT_LIBRARY}
        ${COREVIDEO_LIBRARY}
    )
else()
    # Linux
    find_package(OpenGL REQUIRED)
    target_link_libraries(camforge
        ${OpenCV_LIBS}
        ${OPENGL_LIBRARIES}
        glfw
        GLEW
        dl
        pthread
        X11
    )
endif()

# Optional: Post-build copy OpenCV DLLs on Windows
if (WIN32)
    add_custom_command(TARGET camforge POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${OpenCV_DIR}/x64/vc16/bin"
        $<TARGET_FILE_DIR:camforge>
    )
endif()

# --- Output Info ---
message(STATUS "🎯 Output binary: ${CMAKE_BINARY_DIR}/camforge")
message(STATUS "✅ Linked with OpenCV: ${OpenCV_VERSION}")
