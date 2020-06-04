#version 460 core

in vec3 vertexPosition;
in vec3 vertexNormal;
in uvec3 vertexColor;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

uniform vec3 tint = vec3(1);
uniform float zdepthOffset = 0.0;

out vec3 color;

void main() {
    gl_Position.xyzw = projection * view * model * vec4(vertexPosition, 1.0);
    gl_Position.w += zdepthOffset;

    color = vec3(vertexColor) / 255.0 * tint;

    vec4 normal = model * vec4(vertexNormal, 0.0);
    color *= (dot(normalize(normal.xyz), vec3(0,0,1)) + 1.0) / 2.0;
}