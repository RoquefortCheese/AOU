shader_type canvas_item;
uniform sampler2D screen: hint_screen_texture, filter_nearest_mipmap;
const float mindim = 0.005;
const float maxdim = 0.02;
const float deviation = 0.025;

float random(vec2 uv) {
    return mod(float(int(uv.x * 9137152.495) ^ int(uv.y * 3138278.634)), 89.) / 89.;
}

void addcross(inout vec3 color, vec2 uv, vec2 pixelsize) {
	vec2 fromcent = abs(uv - vec2(0.5)) * pixelsize.y / pixelsize;
	if (min(fromcent.x, fromcent.y) <= mindim && max(fromcent.x, fromcent.y) <= maxdim) {
		color.rg = vec2(min(color.r, color.g));
		color = vec3(1.) - color;
	}
}

void addnoise(inout vec3 color, vec2 uv) {
	color = min(vec3(1.), color * (1. - deviation + random(uv + vec2(mod(TIME, 4.))) * deviation * 2.));
}

void fragment() {
	vec3 color = texture(screen, SCREEN_UV).rgb;
	addnoise(color, SCREEN_UV);
	addcross(color, SCREEN_UV, SCREEN_PIXEL_SIZE);
	COLOR.rgb = color;
}