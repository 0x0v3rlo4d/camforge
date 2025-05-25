// Starter version. Full pipeline enhancements incoming.

#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <opencv2/opencv.hpp>
#include <iostream>
#include <fstream>
#include <filesystem>
#include <thread>
#include <chrono>

namespace fs = std::filesystem;

// --- Hot-reload shader utility ---
GLuint LoadShaderFromFile(GLenum type, const std::string& path) {
    std::ifstream file(path);
    if (!file.is_open()) {
        std::cerr << "Failed to open shader: " << path << std::endl;
        return 0;
    }

    std::string src((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
    GLuint shader = glCreateShader(type);
    const char* cstr = src.c_str();
    glShaderSource(shader, 1, &cstr, nullptr);
    glCompileShader(shader);

    GLint success;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        char log[512];
        glGetShaderInfoLog(shader, 512, nullptr, log);
        std::cerr << "Shader compile error in " << path << ":\n" << log << std::endl;
    }

    return shader;
}

GLuint CreateShaderProgram(const std::string& vertPath, const std::string& fragPath) {
    GLuint vs = LoadShaderFromFile(GL_VERTEX_SHADER, vertPath);
    GLuint fs = LoadShaderFromFile(GL_FRAGMENT_SHADER, fragPath);
    GLuint program = glCreateProgram();
    glAttachShader(program, vs);
    glAttachShader(program, fs);
    glLinkProgram(program);

    glDeleteShader(vs);
    glDeleteShader(fs);
    return program;
}

GLuint WatchAndReload(GLuint& program, const std::string& vsPath, const std::string& fsPath) {
    static auto lastWrite = fs::last_write_time(fsPath);
    auto now = fs::last_write_time(fsPath);
    if (now != lastWrite) {
        lastWrite = now;
        GLuint newProgram = CreateShaderProgram(vsPath, fsPath);
        if (newProgram != 0) {
            glDeleteProgram(program);
            program = newProgram;
            std::cout << "🔁 Shader hot-reloaded." << std::endl;
        }
    }
    return program;
}

// Output to virtual webcam (basic stub; real impl depends on v4l2loopback / OBS plugin)
void pipeToVirtualWebcam(const cv::Mat& frame) {
    // Placeholder for future loopback device output
    // e.g., use FFmpeg or pipe raw BGR to /dev/videoX on Linux
}

int main() {
    // --- Init GLFW and GLEW
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    GLFWwindow* win = glfwCreateWindow(1280, 720, "camforge", nullptr, nullptr);
    glfwMakeContextCurrent(win);
    glewInit();

    // --- OpenCV camera
    cv::VideoCapture cap(0);
    if (!cap.isOpened()) return -1;

    // --- Fullscreen quad setup
    float quad[] = {
        -1, -1, 0, 0,
         1, -1, 1, 0,
         1,  1, 1, 1,
        -1,  1, 0, 1
    };
    GLuint idx[] = { 0, 1, 2, 2, 3, 0 };

    GLuint vao, vbo, ebo;
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);

    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(quad), quad, GL_STATIC_DRAW);

    glGenBuffers(1, &ebo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(idx), idx, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void*)(2 * sizeof(float)));
    glEnableVertexAttribArray(1);

    GLuint tex;
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_2D, tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    // --- Shader program (hot-reloadable)
    std::string vsPath = "shaders/quad.vert";
    std::string fsPath = "shaders/filter.frag";
    GLuint program = CreateShaderProgram(vsPath, fsPath);
    glUseProgram(program);

    // --- Main loop
    while (!glfwWindowShouldClose(win)) {
        glfwPollEvents();
        program = WatchAndReload(program, vsPath, fsPath);

        cv::Mat frame;
        cap >> frame;
        if (frame.empty()) continue;
        cv::cvtColor(frame, frame, cv::COLOR_BGR2RGB);

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, frame.cols, frame.rows, 0, GL_RGB, GL_UNSIGNED_BYTE, frame.data);
        glClear(GL_COLOR_BUFFER_BIT);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
        glfwSwapBuffers(win);

        pipeToVirtualWebcam(frame);
    }

    return 0;
}