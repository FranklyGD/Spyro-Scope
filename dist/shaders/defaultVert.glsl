#version 150 core

in vec3 vertexPosition;
in vec3 vertexNormal;
in uvec4 vertexColor;
in vec2 vertexTextureMapping;

in mat4 instanceModel;
in vec3 instanceTint;

layout (std140) uniform camera
{
    uniform mat4 view;
    uniform mat4 viewInv;
    uniform mat4 projection;
};

uniform float zdepthOffset;

out vec4 color;
out vec2 uv;

void main() {
    // Geometry
    gl_Position.xyzw = projection * viewInv * instanceModel * vec4(vertexPosition, 1.0);
    gl_Position.z += zdepthOffset;
    vec3 normal = normalize((instanceModel * vec4(vertexNormal, 0.0)).xyz);

    // Input Scales
    color = vec4(vertexColor) / 255.0;

    // Output
    color.rgb *= instanceTint;

    float diffuse = (dot(normal, vec3(0,0,1) /* up */ ) + 1.2) / 2.2;
	color.rgb *= diffuse;

    uv = vertexTextureMapping;
}