shader_type spatial;
render_mode unshaded;

float random(vec2 uv) {
    return mod(float(int(uv.x * 9137152.495) ^ int(uv.y * 3138278.634)), 89.) / 89.;
}

float notsine(float n) {
	return (sqrt(1. - pow(2. * mod(n, 1.) - 1., 2.)) * (2. * mod(floor(n), 2.) - 1.) + 1.) / 2.;
}

void fragment() {
	float modtime = mod(TIME, 1.);
	ALBEDO = vec3(0.);
	ALPHA = notsine(UV.y * 6. - TIME) * 0.25 + random(UV + vec2(modtime, modtime)) * 0.25;
}