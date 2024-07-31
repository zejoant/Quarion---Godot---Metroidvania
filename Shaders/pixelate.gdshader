shader_type canvas_item;

uniform float size_x = 4;
uniform float size_y = 4;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment()
{
    vec2 uv = SCREEN_UV;
	uv -= mod(uv, vec2(size_x/1000.0, size_y/1000.0));
	
	COLOR.rgb = textureLod(SCREEN_TEXTURE, uv, 0.0).rgb;
}