#version 460 core

in vec3 vertexPosition;
in vec3 vertexNormal;
in uvec3 vertexColor;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec3 color;

void main() {
    gl_Position.xyzw = projection * view * model * vec4(vertexPosition, 1.0);

    color = vec3(vertexColor) / 255.0;

    vec3 normal = normalize(vertexNormal);
    color *= (dot(normal, vec3(0,0,1)) + 1.0) / 2.0;
}