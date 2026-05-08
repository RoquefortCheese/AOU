shader_type canvas_item;
uniform sampler2D screen: hint_screen_texture, filter_nearest_mipmap;
const int pixelsize = 12;

void fragment() {
	COLOR = texture(screen, floor((SCREEN_UV / SCREEN_PIXEL_SIZE + vec2(float(pixelsize))) / float(pixelsize)) * float(pixelsize) * SCREEN_PIXEL_SIZE);
}