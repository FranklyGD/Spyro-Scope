#version 150 core

in vec3 vertexPosition;
in vec3 vertexNormal;
in uvec4 vertexColor;
in vec2 vertexTextureMapping;

in mat4 instanceModel;
in vec3 instanceTint;

uniform mat4 view;
uniform mat4 viewInv;
uniform mat4 projection;

uniform float specularAmount;
uniform float zdepthOffset;
uniform float retroShading;

out vec4 color;
out float specular;
out vec2 uv;

void main() {
    // Geometry
    gl_Position.xyzw = projection * viewInv * instanceModel * vec4(vertexPosition, 1.0);
    gl_Position.z += zdepthOffset;
    vec3 normal = normalize((instanceModel * vec4(vertexNormal, 0.0)).xyz);

    // Input Scales
    color = vec4(vertexColor) / 255.0;
    specular = dot((view * normalize(vec4(-1,1,2,0))).xyz, normal);

    // Output
    color.rgb *= instanceTint * (1 + retroShading);

    float diffuse = mix((dot(normal, vec3(0,0,1)) + 1.2) / 2.2, 1, retroShading);
    float specDiffuse = (specular + 0.25) / 1.25;

    color.rgb *= mix(diffuse, specDiffuse, specularAmount);
    specular = clamp((specular - 0.75) * 4, 0, 1) * specularAmount;

    uv = vertexTextureMapping;
}