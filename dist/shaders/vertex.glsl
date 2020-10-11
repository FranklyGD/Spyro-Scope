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
    gl_Position.z += zdepthOffset;

    color = vec4(vertexColor) / 255.0;
    color.rgb *= instanceTint;

    vec3 normal = normalize((instanceModel * vec4(vertexNormal, 0.0)).xyz);
    color.rgb *= (dot(normal, vec3(0,0,1)) + 1.03) / 2.03;

    uv = vertexTextureMapping;
}