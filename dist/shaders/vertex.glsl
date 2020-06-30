#version 150 core

in vec3 vertexPosition;
in vec3 vertexNormal;
in uvec4 vertexColor;
in vec2 vertexTextureMapping;

in mat4 instanceModel;
in vec3 instanceTint;

uniform mat4 view;
uniform mat4 projection;

uniform float zdepthOffset;

out vec4 color;
out vec2 uv;

void main() {
    gl_Position.xyzw = projection * view * instanceModel * vec4(vertexPosition, 1.0);
    gl_Position.w += zdepthOffset;

    color = vec4(vertexColor) / 255.0;
    color.rgb *= instanceTint;

    vec4 normal = instanceModel * vec4(vertexNormal, 0.0);
    color.rgb *= (dot(normalize(normal.xyz), vec3(0,0,1)) + 1.0) / 2.0;

    uv = vertexTextureMapping;
}