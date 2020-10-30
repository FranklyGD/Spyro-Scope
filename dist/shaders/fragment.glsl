#version 150 core

in vec4 color;
in vec2 uv;

out vec4 fragColor;

uniform float retroShading;
uniform sampler2D texture0;

void main() {
    vec4 tex = texture(texture0, uv);

    if (tex.r < 0.001 && tex.g < 0.001 && tex.b < 0.001)
        discard;

    float power = (1 + retroShading * 3) * (1 + retroShading * (1 - tex.a) * 3);
    vec3 finalColor = clamp(color.rgb * tex.rgb * power, 0, 1);
    fragColor.rgb = finalColor;
    fragColor.a = color.a * (tex.a * (1 - retroShading) + retroShading);
}