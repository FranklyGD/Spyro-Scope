#version 150 core

in float depth;

out vec4 fragColor;

float near = 200.0;
float far = 200000.0;

float linearizeDepth(float depth) {
	return (2.0 * near * far) / ((far + near) - (depth * 2.0 - 1.0) * (far - near));
}

void main() {
   fragColor.rgb = vec3(linearizeDepth(gl_FragCoord.z) / 1000.0);
   fragColor.a = 1;
}