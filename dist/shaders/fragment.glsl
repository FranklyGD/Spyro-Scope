#version 150 core

in vec3 color;
in vec2 uv;

out vec4 fragColor;

uniform sampler2D texture0;

void main() {
    fragColor = vec4(color, texture(texture0, uv).r);
}