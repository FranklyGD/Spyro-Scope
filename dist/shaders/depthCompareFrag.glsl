#version 150 core

uniform sampler2D depth0;
uniform sampler2D depth1;

out vec4 fragColor;

void main() {
    ivec2 texcoord = ivec2(floor(gl_FragCoord.xy));
    float d0 = texelFetch(depth0, texcoord, 0).r;
    float d1 = texelFetch(depth1, texcoord, 0).r;

	float difference = abs(d0 - d1);
	float alpha = clamp(pow(floor(difference * 10.0) / 10.0, 2.2), 0.0, 1.0) / 2.0;

	fragColor.a = alpha;

	if (d0 < d1) {
		fragColor.rg = vec2(0,1);
	} else {
		fragColor.rg = vec2(1,0);
	}

	fragColor.b = floor(difference * 1.0) / 10.0;

	fragColor.rgb *= mix(0.5, 1, mod(floor((gl_FragCoord.x + gl_FragCoord.y) / 10.0), 2));
}

