#version 150 core

in vec4 color;
in vec2 uv;

out vec4 fragColor;

uniform float retroShading;
uniform sampler2D texture0;

void main() {
    vec4 tex = texture(texture0, uv);
    float power = 1 + retroShading * 3;
    fragColor = clamp(color * tex * power, 0, 1);
}