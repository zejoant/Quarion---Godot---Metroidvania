shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0); //Shine color
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform bool ignore_black = false;
uniform vec4 replace_color : source_color = vec4(1.0);


void fragment()
{
	COLOR.rgba = (replace_color == vec4(1.0) || distance(COLOR.rgba, replace_color) < 0.01) ? mix(COLOR.rgba, COLOR.a == 0.0 ? vec4(color.rgb, 0.0) : (ignore_black && COLOR.rgba == vec4(0, 0, 0, 1)?COLOR.rgba:color.rgba), strength) : COLOR.rgba;
}