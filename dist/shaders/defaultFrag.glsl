#version 150 core

in vec4 color;
in vec2 uv;

out vec4 fragColor;

uniform sampler2D texture0;

void main() {
    // Sample Texture
    vec4 tex = texture(texture0, uv);

    // Final Shading
    vec3 linearColor = color.rgb * pow(tex.rgb, vec3(1.0 / 2.2));
    vec3 finalColor = clamp(pow(linearColor, vec3(2.2)), 0, 1);
    fragColor.rgb = finalColor;
    fragColor.a = color.a * tex.a;
}