shader_type canvas_item;
uniform sampler2D screen: hint_screen_texture, filter_nearest_mipmap;
const float mindim = 0.005;
const float maxdim = 0.02;

void fragment() {
	COLOR.rgba = texture(screen, SCREEN_UV);
	vec2 fromcent = abs(SCREEN_UV - vec2(0.5)) * SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE;
	if (min(fromcent.x, fromcent.y) <= mindim && max(fromcent.x, fromcent.y) <= maxdim) {
		COLOR.rgb = vec3(1.) - COLOR.rgb;
	}
}