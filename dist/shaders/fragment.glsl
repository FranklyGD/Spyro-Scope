#version 150 core

in vec4 color;
in float specular;
in vec2 uv;

out vec4 fragColor;

uniform float retroShading;
uniform sampler2D texture0;

void main() {
    // Sample Texture
    vec4 tex = texture(texture0, uv);

    // Discard Pixels (has alpha and black)
    if (retroShading > 0.5 && tex.r < 0.001 && tex.g < 0.001 && tex.b < 0.001)
        discard;

    // Final Shading
    float power = 1 + retroShading * (1 - tex.a);
    vec3 linearColor = color.rgb * pow(tex.rgb, vec3(1.0 / 2.2)) * power;
    vec3 finalColor = clamp(pow(linearColor, vec3(2.2)), 0, 1) + vec3(specular);
    fragColor.rgb = finalColor;
    fragColor.a = color.a * mix(tex.a, 1, retroShading);
}