#version 150 core

in vec4 color;
in vec2 uv;

out vec4 fragColor;

uniform sampler2D texture0;

void main() {
    fragColor = color * texture(texture0, uv);
}