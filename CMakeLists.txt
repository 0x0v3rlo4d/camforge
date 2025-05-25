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

# --- GLFW Libs ---
target_link_directories(camforge PRIVATE
    "${THIRD_PARTY_DIR}/glfw/build/src/Release"
)

# --- Set output directories (multi-config safe) ---
set_target_properties(camforge PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/bin"
    ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/archive"
    LIBRARY_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/lib"
)


# --- Platform-specific setup with smart GLEW detection ---
if (WIN32)
    # Windows: Use vendored static libraries
    target_link_directories(camforge PRIVATE
        "${THIRD_PARTY_DIR}/glew/lib/Release/x64"
        "${THIRD_PARTY_DIR}/glfw/build/src/Release"
    )
    
    target_link_libraries(camforge
        ${OpenCV_LIBS}
        opengl32
        glfw3
        glew32s
    )
    
    target_compile_definitions(camforge PRIVATE GLEW_STATIC)

    # Copy OpenCV DLLs to output folder
    add_custom_command(TARGET camforge POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${OpenCV_DIR}/../bin"
        $<TARGET_FILE_DIR:camforge>
    )

elseif(APPLE)
    # macOS: Use system frameworks + vendored libs
    find_library(COCOA_LIBRARY Cocoa REQUIRED)
    find_library(OpenGL_LIBRARY OpenGL REQUIRED)
    find_library(IOKIT_LIBRARY IOKit REQUIRED)
    find_library(COREVIDEO_LIBRARY CoreVideo REQUIRED)

    # Try to find system GLEW first
    find_package(PkgConfig QUIET)
    if(PKG_CONFIG_FOUND)
        pkg_check_modules(GLEW QUIET glew)
    endif()
    
    if(GLEW_FOUND)
        message(STATUS "📦 Using system GLEW: ${GLEW_VERSION}")
        target_link_libraries(camforge ${GLEW_LIBRARIES})
        target_include_directories(camforge PRIVATE ${GLEW_INCLUDE_DIRS})
    else
        message(STATUS "📦 Using vendored GLEW")
        target_link_directories(camforge PRIVATE "${THIRD_PARTY_DIR}/glew/lib")
        target_link_libraries(camforge GLEW)
    endif()

    target_link_libraries(camforge
        ${OpenCV_LIBS}
        ${OpenGL_LIBRARY}
        glfw
        ${COCOA_LIBRARY}
        ${IOKIT_LIBRARY}
        ${COREVIDEO_LIBRARY}
    )

else()
    # Linux: Prefer system packages, fallback to vendored
    find_package(OpenGL REQUIRED)
    find_package(PkgConfig REQUIRED)
    
    # Try system GLEW first
    pkg_check_modules(GLEW QUIET glew)
    
    if(GLEW_FOUND)
        message(STATUS "📦 Using system GLEW: ${GLEW_VERSION}")
        target_link_libraries(camforge ${GLEW_LIBRARIES})
        target_include_directories(camforge PRIVATE ${GLEW_INCLUDE_DIRS})
        target_compile_options(camforge PRIVATE ${GLEW_CFLAGS_OTHER})
    else
        message(STATUS "📦 Using vendored GLEW")
        target_link_directories(camforge PRIVATE "${THIRD_PARTY_DIR}/glew/lib")
        target_link_libraries(camforge GLEW)
    endif()

    # GLFW: Use vendored version
    target_link_directories(camforge PRIVATE "${THIRD_PARTY_DIR}/glfw/build/src")
    
    target_link_libraries(camforge
        ${OpenCV_LIBS}
        ${OPENGL_LIBRARIES}
        glfw3
        dl
        pthread
        X11
    )
endif()

# --- Output Info ---
message(STATUS "🎯 Output binary: ${CMAKE_BINARY_DIR}/camforge")
message(STATUS "✅ Linked with OpenCV: ${OpenCV_VERSION}")
