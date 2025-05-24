#version 330 core
out vec4 FragColor;
in vec2 vUV;
uniform sampler2D uFrame;
void main() {
    vec3 color = texture(uFrame, vUV).rgb;
    FragColor = vec4(vec3(1.0) - color, 1.0); // Invert effect
}