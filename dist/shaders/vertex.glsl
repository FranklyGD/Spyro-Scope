#version 460 core

in vec3 vertexPosition;
in vec3 vertexNormal;
in uvec3 vertexColor;

in mat4 instanceModel;
in vec3 instanceTint;

uniform mat4 view;
uniform mat4 projection;

uniform float zdepthOffset = 0.0;

out vec3 color;

void main() {
    gl_Position.xyzw = projection * view * instanceModel * vec4(vertexPosition, 1.0);
    gl_Position.w += zdepthOffset;

    color = vec3(vertexColor) / 255.0 * instanceTint;

    vec4 normal = instanceModel * vec4(vertexNormal, 0.0);
    color *= (dot(normalize(normal.xyz), vec3(0,0,1)) + 1.0) / 2.0;
}