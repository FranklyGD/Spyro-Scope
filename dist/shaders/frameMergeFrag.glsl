#version 150 core

uniform sampler2D color0;
uniform sampler2D color1;
uniform sampler2D depth0;
uniform sampler2D depth1;

out vec4 fragColor;

float near = 200.0;
float far = 200000.0;

float linearizeDepth(float depth) {
	return (2.0 * near * far) / ((far + near) - (depth * 2.0 - 1.0) * (far - near));
}

void main()
{
    ivec2 texcoord = ivec2(floor(gl_FragCoord.xy));
    float d0 = linearizeDepth(texelFetch(depth0, texcoord, 0).r);
    float d1 = linearizeDepth(texelFetch(depth1, texcoord, 0).r);

		float alpha = abs(d0 - d1) / 1000;

		if (d0 < d1) {
        	fragColor = vec4(0,1,0,alpha);
		} else {
			fragColor = vec4(1,0,0,alpha);
		}
}

