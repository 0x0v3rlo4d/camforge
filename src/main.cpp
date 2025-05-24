#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <opencv2/opencv.hpp>

int main() {
    // Init GLFW
    if (!glfwInit()) return -1;
    GLFWwindow* window = glfwCreateWindow(1280, 720, "CamForge", nullptr, nullptr);
    if (!window) return -1;
    glfwMakeContextCurrent(window);

    // Init GLEW
    glewExperimental = true;
    if (glewInit() != GLEW_OK) return -1;

    // Init camera
    cv::VideoCapture cam(0);
    if (!cam.isOpened()) return -1;

    // OpenGL texture
    GLuint texID;
    glGenTextures(1, &texID);

    while (!glfwWindowShouldClose(window)) {
        cv::Mat frame;
        cam >> frame;
        if (frame.empty()) continue;

        // Convert BGR to RGB
        cv::cvtColor(frame, frame, cv::COLOR_BGR2RGB);

        // Upload to GPU
        glBindTexture(GL_TEXTURE_2D, texID);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, frame.cols, frame.rows, 0,
                     GL_RGB, GL_UNSIGNED_BYTE, frame.data);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        // Draw fullscreen quad with shader (TODO)
        glClear(GL_COLOR_BUFFER_BIT);

        // ... draw textured quad with shader here ...

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glDeleteTextures(1, &texID);
    glfwDestroyWindow(window);
    glfwTerminate();
    return 0;
}
