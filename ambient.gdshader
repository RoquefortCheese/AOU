shader_type canvas_item;
uniform float displacement;

float random(vec2 uv) {
    return mod(float(int(uv.x * 9137152.495) ^ int(uv.y * 3138278.634)), 89.) / 89.;
}

void fragment() {
	float disp = displacement * pow(2., 12.);
	vec2 disppos = vec2(disp, -disp) / 6.;
	vec2 totalpos = (SCREEN_UV + disppos) / pow(2., 9. + displacement * 5.);
	float dieroll = random(totalpos);
	int index = int(mod(dieroll * 3., 3.));
	switch (index) {
		case 0:
			COLOR.rgb = vec3(0, 0, 1);
			break;
		case 1:
			COLOR.rgb = vec3(1, 0, 1);
			break;
		case 2:
			COLOR.rgb = vec3(0, 1, 1);
			break;
	}
}