shader_type canvas_item;

uniform vec2 player_pos;
uniform vec4 light_color : source_color = vec4(1.0, 1.0, 0.8, 0.5); // Color of the light, including alpha for intensity
uniform float light_radius : hint_range(0.0, 1.0, 0.01) = 0.3; // Radius of the light effect (normalized)
uniform float fade_power : hint_range(0.1, 10.0, 0.1) = 2.0; // Controls how quickly the light fades
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	//vec2 screen_pos = FRAGCOORD.xy;
	vec2 screen_pos = UV;
	
    float dist = length(screen_pos - player_pos);
	
    float normalized_dist = dist / light_radius;
    normalized_dist = clamp(normalized_dist, 0.0, 1.0);
    float light_intensity = 1.0 - pow(normalized_dist, fade_power);
    light_intensity = clamp(light_intensity, 0.0, 1.0); // Ensure intensity is between 0 and 1
	vec4 old_color = textureLod(screen_texture, SCREEN_UV, 0.0);
	if(old_color.r > 0.05 && old_color.g > 0.05 && old_color.b > 0.05){
    	COLOR = vec4(light_color.rgb * light_intensity, light_color.a * light_intensity);
	}
	else{
		COLOR = old_color;
	}
}