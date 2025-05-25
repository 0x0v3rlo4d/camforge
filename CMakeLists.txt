cmake_minimum_required(VERSION 3.15)
project(camforge)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

message(STATUS "🛠 Generator: ${CMAKE_GENERATOR}")

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
)

# --- OpenCV ---
if(EXISTS "${OPENCV_INSTALL_DIR}/OpenCVConfig.cmake")
    set(OpenCV_DIR "${OPENCV_INSTALL_DIR}")
elseif(EXISTS "${OPENCV_INSTALL_DIR}/x64/vc16/lib/OpenCVConfig.cmake")
    set(OpenCV_DIR "${OPENCV_INSTALL_DIR}/x64/vc16/lib")
else()
    message(FATAL_ERROR "❌ Could not find OpenCVConfig.cmake in expected paths!")
endif()

find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})

# --- Source Files ---
file(GLOB_RECURSE SOURCES src/*.cpp)
file(GLOB_RECURSE HEADERS src/*.h)
message(STATUS "🧩 Sources: ${SOURCES}")

# --- Executable ---
add_executable(camforge ${SOURCES} ${HEADERS})

# --- Set output directories (multi-config safe) ---
set_target_properties(camforge PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/bin"
    ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/lib"
    LIBRARY_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/lib"
    ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/lib"
    LIBRARY_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/lib"
)


# --- Platform-specific setup ---
if (WIN32)
    # Link against OpenGL and static GLFW/GLEW on Windows
    target_link_libraries(camforge
        ${OpenCV_LIBS}
        opengl32
        glfw3
        glew32
    )

    # Copy OpenCV DLLs to output folder
    add_custom_command(TARGET camforge POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${OpenCV_DIR}/../bin"
        $<TARGET_FILE_DIR:camforge>
    )
elseif(APPLE)
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

# --- Output Info ---
message(STATUS "🎯 Output binary: ${CMAKE_BINARY_DIR}/camforge")
message(STATUS "✅ Linked with OpenCV: ${OpenCV_VERSION}")
