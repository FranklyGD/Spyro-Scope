#version 150 core

in vec4 color;
in vec2 uv;

out vec4 fragColor;

uniform float retroShading;
uniform sampler2D texture0;

void main() {
    vec4 tex = texture(texture0, uv);
    tex.r = pow(tex.r, 1 + retroShading * 1.2);
    tex.g = pow(tex.g, 1 + retroShading * 1.2);
    tex.b = pow(tex.b, 1 + retroShading * 1.2);
    float power = 1 + retroShading * 2;
    fragColor = clamp(color * tex * power, 0, 1);
}