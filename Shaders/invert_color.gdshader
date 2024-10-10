shader_type canvas_item;
render_mode unshaded;

uniform float strength : hint_range( 0.0, 1.0 ) = 0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment(){
	vec4 color = texture(screen_texture, SCREEN_UV);
	COLOR.rgba = vec4(1.0 - color.rgb + (1.0-strength) * (2.0 * color.rgb - 1.0), color.a);
} 
